import React, { useState } from 'react'
import { Link } from 'react-router-dom'

import { api } from '~/lib/api'
import { useMutation, useResource, useTitle } from '~/lib/hooks'
import {
  Badge, Button, ConfirmModal, DataTable, ErrorAlert, Field, Page, PageHeader, Pagination, StatTile, Toolbar,
} from '~/components/ui'

const STATUSES = [
  ['unresolved', 'Unresolved'],
  ['resolved', 'Resolved'],
  ['all', 'All'],
]

/** Log::LEVELS — the filter is "at or above" the chosen level. */
const LEVELS = [
  ['', 'Any'],
  ['info', 'Info+'],
  ['warn', 'Warn+'],
  ['error', 'Error+'],
  ['fatal', 'Fatal'],
]

/** Log::SOURCES. */
const SOURCES = [
  ['', 'Any'],
  ['web', 'Web'],
  ['job', 'Job'],
  ['mobile', 'Mobile'],
  ['console', 'Console'],
  ['app', 'App'],
]

export const LEVEL_TONES = { fatal: 'red', error: 'red', warn: 'amber', info: 'blue' }

export function LevelBadge({ level }) {
  return <Badge tone={LEVEL_TONES[level] ?? 'gray'}>{level}</Badge>
}

export function formatLogDate(value) {
  if (!value) return '—'
  return new Date(value).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

/** Filters that narrow the server-side scope, shared by index / resolve_all. */
function filterQuery({ level, source, query }) {
  const params = new URLSearchParams()
  if (level) params.set('level', level)
  if (source) params.set('source', source)
  if (query) params.set('q', query)
  return params.toString()
}

export function LogsList() {
  useTitle('Logs')

  const [status, setStatus] = useState('unresolved')
  const [level, setLevel] = useState('')
  const [source, setSource] = useState('')
  const [search, setSearch] = useState('')   // what's typed
  const [query, setQuery] = useState('')     // what's applied (Enter / Clear)
  const [page, setPage] = useState(1)
  const [confirm, setConfirm] = useState(null) // 'resolve-all' | 'delete-resolved'

  // Any filter change resets to the first page — page 3 of the old result set is meaningless.
  const filter = (setter) => (value) => { setter(value); setPage(1) }

  const { data, loading, error, reload } = useResource(({ signal }) => {
    const params = new URLSearchParams({ page: String(page), per_page: '25', status })
    if (level) params.set('level', level)
    if (source) params.set('source', source)
    if (query) params.set('q', query)
    return api.get(`/logs.json?${params.toString()}`, { signal })
  }, [status, level, source, query, page])

  const logs = data?.logs ?? []
  const counts = data?.counts ?? {}
  const total = data?.total ?? 0
  const perPage = data?.per_page ?? 25
  const totalPages = Math.max(1, Math.ceil(total / perPage))

  const { run: toggleResolved, error: toggleError } = useMutation((log) =>
    api.patch(`/logs/${log.id}.json`, { log: { resolved: !log.resolved } })
  )
  const { run: resolveAll, pending: resolvingAll, error: resolveAllError } = useMutation(() => {
    const params = filterQuery({ level, source, query })
    return api.patch(`/logs/resolve_all.json${params ? `?${params}` : ''}`, {})
  })
  const { run: deleteResolved, pending: deletingResolved, error: deleteError } = useMutation(() =>
    api.delete('/logs/destroy_resolved.json')
  )

  const onToggle = async (log) => {
    if ((await toggleResolved(log)) !== null) reload()
  }

  const onConfirm = async () => {
    const action = confirm
    setConfirm(null)
    const result = action === 'resolve-all' ? await resolveAll() : await deleteResolved()
    if (result !== null) { setPage(1); reload() }
  }

  const clear = () => {
    setStatus('unresolved'); setLevel(''); setSource(''); setSearch(''); setQuery(''); setPage(1)
  }

  const columns = [
    { key: 'level', header: 'Level', render: (log) => <LevelBadge level={log.level} /> },
    {
      key: 'title',
      header: 'Problem',
      primary: true,
      render: (log) => (
        <div className="min-w-0">
          <Link to={`/logs/${log.id}`} className="table-link break-words">{log.title}</Link>
          {log.path ? <p className="text-xs text-ink-muted mt-0.5 break-words">{log.path}</p> : null}
        </div>
      ),
    },
    { key: 'source', header: 'Source', render: (log) => <Badge tone="gray">{log.source}</Badge> },
    { key: 'occurrences', header: 'Count', render: (log) => <span className="tabular-nums">{log.occurrences}</span> },
    { key: 'last_seen_at', header: 'Last seen', render: (log) => formatLogDate(log.last_seen_at) },
  ]

  return (
    <Page>
      <PageHeader title="Logs" subtitle="Exceptions and errors from the app, jobs and mobile clients.">
        <Button variant="secondary" to="/log-notifications">Notifications</Button>
        <Button variant="secondary" onClick={reload}>Refresh</Button>
      </PageHeader>

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={toggleError} className="mb-6" />
      <ErrorAlert error={resolveAllError} className="mb-6" />
      <ErrorAlert error={deleteError} className="mb-6" />

      <div className="grid gap-4 grid-cols-1 sm:grid-cols-3 mb-6">
        <StatTile label="Unresolved" value={counts.unresolved ?? '—'} tone="alert" />
        <StatTile label="Errors (last 24h)" value={counts.errors_24h ?? '—'} />
        <StatTile label="Active notifications" value={counts.subscriptions ?? '—'} to="/log-notifications" />
      </div>

      <Toolbar>
        <Field label="Status" as="select" value={status} onChange={filter(setStatus)} options={STATUSES} inputClassName="w-auto" />
        <Field label="Min level" as="select" value={level} onChange={filter(setLevel)} options={LEVELS} inputClassName="w-auto" />
        <Field label="Source" as="select" value={source} onChange={filter(setSource)} options={SOURCES} inputClassName="w-auto" />
        <Field
          label="Search"
          type="search"
          value={search}
          onChange={setSearch}
          placeholder="Message, error class or path"
          hint="Press Enter to search."
          className="flex-1 min-w-48"
          onKeyDown={(event) => {
            if (event.key !== 'Enter') return
            event.preventDefault()
            setQuery(search)
            setPage(1)
          }}
        />
        <Button variant="ghost" onClick={clear}>Clear</Button>
      </Toolbar>

      {logs.length ? (
        <div className="flex flex-wrap gap-2 mb-4">
          {status !== 'resolved' ? (
            <Button size="sm" variant="secondary" loading={resolvingAll} onClick={() => setConfirm('resolve-all')}>
              Resolve all matching
            </Button>
          ) : null}
          <Button size="sm" variant="ghost" loading={deletingResolved} onClick={() => setConfirm('delete-resolved')}>
            Delete resolved
          </Button>
        </div>
      ) : null}

      <DataTable
        columns={columns}
        rows={logs}
        rowKey={(log) => log.id}
        actions={(log) => (
          <>
            <Button size="sm" variant="ghost" onClick={() => onToggle(log)}>
              {log.resolved ? 'Reopen' : 'Resolve'}
            </Button>
            <Button size="sm" variant="ghost" to={`/logs/${log.id}`}>View</Button>
          </>
        )}
        empty="Nothing here — no logs match these filters."
        loading={loading}
        caption="Application logs"
      />

      <Pagination page={page} totalPages={totalPages} total={total} onChange={setPage} />

      <ConfirmModal
        open={confirm === 'resolve-all'}
        title="Resolve all matching logs?"
        message="Every unresolved log matching the current filters is marked resolved. You can reopen them individually afterwards."
        confirmText="Resolve all"
        onConfirm={onConfirm}
        onCancel={() => setConfirm(null)}
      />

      <ConfirmModal
        open={confirm === 'delete-resolved'}
        title="Delete resolved logs?"
        message="This permanently deletes every resolved log. This cannot be undone."
        confirmText="Delete"
        tone="danger"
        onConfirm={onConfirm}
        onCancel={() => setConfirm(null)}
      />
    </Page>
  )
}
