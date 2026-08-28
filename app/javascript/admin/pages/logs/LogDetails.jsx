import React, { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'

import { api, resource } from '~/lib/api'
import { useMutation, useResource, useTitle } from '~/lib/hooks'
import {
  Alert, Badge, Button, Card, ConfirmModal, DetailList, EmptyState, ErrorAlert, LoadingBlock, Page, PageHeader,
} from '~/components/ui'
import { LevelBadge } from './LogsList'

const logs = resource('/logs')

function formatDate(value) {
  if (!value) return '—'
  return new Date(value).toLocaleString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit',
  })
}

/** Message / backtrace / context, all pre-formatted and wrapped. */
function CodeSection({ title, body }) {
  if (!body) return null
  return (
    <Card>
      <h2 className="section-title mb-3">{title}</h2>
      <pre className="panel-muted text-xs whitespace-pre-wrap break-words overflow-x-auto">{body}</pre>
    </Card>
  )
}

export function LogDetails() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [confirmDelete, setConfirmDelete] = useState(false)

  const { data: log, loading, error, reload } = useResource(({ signal }) => logs.get(id, { signal }), [id])
  useTitle(log?.title ?? 'Log')

  const { run: toggleResolved, pending: toggling, error: toggleError } = useMutation(() =>
    api.patch(`/logs/${id}.json`, { log: { resolved: !log.resolved } })
  )
  const { run: destroy, pending: deleting, error: deleteError } = useMutation(() => logs.remove(id))

  const onToggle = async () => {
    if ((await toggleResolved()) !== null) reload()
  }

  const onDelete = async () => {
    setConfirmDelete(false)
    if ((await destroy()) !== null) navigate('/logs')
  }

  const context = log?.context
  const hasContext = context && typeof context === 'object' && Object.keys(context).length > 0
  const prettyContext = hasContext
    ? (() => { try { return JSON.stringify(context, null, 2) } catch { return String(context) } })()
    : null

  return (
    <Page width="max-w-5xl">
      {log ? (
        <PageHeader
          title={log.title}
          subtitle={`Seen ${log.occurrences}× · last ${formatDate(log.last_seen_at)} · first ${formatDate(log.created_at)}`}
          backTo="/logs"
          backLabel="Back to logs"
        >
          <Button variant="secondary" loading={toggling} onClick={onToggle}>
            {log.resolved ? 'Reopen' : 'Resolve'}
          </Button>
          <Button variant="danger" loading={deleting} onClick={() => setConfirmDelete(true)}>Delete</Button>
        </PageHeader>
      ) : (
        <PageHeader title="Log" backTo="/logs" backLabel="Back to logs" />
      )}

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={toggleError} className="mb-6" />
      <ErrorAlert error={deleteError} className="mb-6" />

      {loading && !log ? (
        <Card><LoadingBlock label="Loading log…" /></Card>
      ) : log ? (
        <div className="space-y-6">
          <div className="flex flex-wrap items-center gap-2">
            <LevelBadge level={log.level} />
            <Badge tone="gray">{log.source}</Badge>
            {log.error_class ? <Badge tone="brand">{log.error_class}</Badge> : null}
          </div>

          {log.resolved ? (
            <Alert tone="success">
              Resolved {formatDate(log.resolved_at)}
              {context?.resolved_by ? ` by ${context.resolved_by}` : ''}.
            </Alert>
          ) : null}

          <Card>
            <h2 className="section-title mb-4">Details</h2>
            <DetailList
              items={[
                { label: 'Error class', value: log.error_class || '—' },
                { label: 'Level', value: log.level },
                { label: 'Source', value: log.source },
                { label: 'Occurrences', value: log.occurrences },
                { label: 'Path', value: log.path || '—', wide: true },
                { label: 'User', value: log.user ? (log.user.name || log.user.email) : 'Anonymous' },
                { label: 'Request ID', value: log.request_id || '—' },
                { label: 'First seen', value: formatDate(log.created_at) },
                { label: 'Last seen', value: formatDate(log.last_seen_at) },
                { label: 'Notified', value: log.notified_at ? formatDate(log.notified_at) : 'Not notified' },
                { label: 'Fingerprint', value: (log.fingerprint || '').slice(0, 12) || '—' },
              ]}
            />
          </Card>

          <CodeSection title="Message" body={log.message} />
          <CodeSection title="Backtrace" body={log.backtrace} />
          <CodeSection title="Context" body={prettyContext} />
        </div>
      ) : !error ? (
        <EmptyState title="Not found">That log no longer exists.</EmptyState>
      ) : null}

      <ConfirmModal
        open={confirmDelete}
        title="Delete this log?"
        message="This permanently removes the log entry. This cannot be undone."
        confirmText="Delete"
        tone="danger"
        onConfirm={onDelete}
        onCancel={() => setConfirmDelete(false)}
      />
    </Page>
  )
}
