import React, { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'

import { api, resource } from '~/lib/api'
import { useMutation, useResource, useTitle } from '~/lib/hooks'
import {
  Badge, Button, ConfirmModal, DataTable, ErrorAlert, Field, Page, PageHeader, Toolbar,
} from '~/components/ui'

const features = resource('/features')

/** Feature.status enum (app/models/feature.rb). */
export const FEATURE_STATUSES = [
  ['backlog', 'Backlog'],
  ['planned', 'Planned'],
  ['in_progress', 'In Progress'],
  ['completed', 'Completed'],
  ['cancelled', 'Cancelled'],
]

/** Feature.priority enum. */
export const FEATURE_PRIORITIES = [
  ['low', 'Low'],
  ['medium', 'Medium'],
  ['high', 'High'],
  ['critical', 'Critical'],
]

const STATUS_TONES = { backlog: 'gray', planned: 'blue', in_progress: 'amber', completed: 'green', cancelled: 'red' }
const PRIORITY_TONES = { low: 'gray', medium: 'blue', high: 'amber', critical: 'red' }

export function labelFor(pairs, value) {
  return pairs.find(([option]) => option === value)?.[1] ?? value ?? '—'
}

export function StatusBadge({ status }) {
  return <Badge tone={STATUS_TONES[status] ?? 'gray'}>{labelFor(FEATURE_STATUSES, status)}</Badge>
}

export function PriorityBadge({ priority }) {
  return <Badge tone={PRIORITY_TONES[priority] ?? 'gray'}>{labelFor(FEATURE_PRIORITIES, priority)}</Badge>
}

/**
 * The roadmap list.
 *
 * The Vue original used sortablejs drag-and-drop to reorder planned features.
 * That is replaced here by explicit "Move up" / "Move down" buttons: they hit the
 * same `PATCH /features/reorder.json` endpoint, but unlike a drag handle they work
 * with a keyboard and on touch. Only `planned` features carry a position — the
 * model clears it when a feature leaves that status — so only those rows can move.
 */
export function FeaturesList() {
  useTitle('Features')

  const [status, setStatus] = useState('')
  const [priority, setPriority] = useState('')
  const [pendingDelete, setPendingDelete] = useState(null)

  const { data, loading, error, reload } = useResource(({ signal }) => features.list('', { signal }), [])

  const { run: destroy, error: deleteError } = useMutation((feature) => features.remove(feature.slug))
  const { run: saveOrder, pending: reordering, error: reorderError } = useMutation(
    (positions) => api.patch('/features/reorder.json', { positions })
  )

  const rows = useMemo(() => {
    const all = data ?? []
    return all.filter((feature) => {
      if (status && feature.status !== status) return false
      if (priority && feature.priority !== priority) return false
      return true
    })
  }, [data, status, priority])

  // Rows that can be reordered, in the order they are displayed. The index API
  // already sorts by position, so this list is the canonical planned ordering.
  const movable = useMemo(
    () => rows.filter((feature) => feature.status === 'planned' && feature.position != null),
    [rows]
  )

  const neighbour = (feature, direction) => {
    const index = movable.findIndex((candidate) => candidate.id === feature.id)
    if (index === -1) return null
    return movable[index + direction] ?? null
  }

  // Swap the two rows' position values — always a valid reorder, and it moves the
  // row past exactly the neighbour the admin can see next to it.
  const move = async (feature, direction) => {
    const target = neighbour(feature, direction)
    if (!target) return
    const result = await saveOrder([
      { id: feature.id, position: target.position },
      { id: target.id, position: feature.position },
    ])
    if (result !== null) reload()
  }

  const confirmDelete = async () => {
    const result = await destroy(pendingDelete)
    setPendingDelete(null)
    if (result !== null) reload()
  }

  const columns = [
    {
      key: 'title',
      header: 'Title',
      primary: true,
      render: (feature) => (
        <div className="min-w-0">
          <Link to={`/features/${feature.slug}`} className="table-link">{feature.title}</Link>
          {feature.description ? (
            <p className="text-xs text-ink-muted mt-0.5 line-clamp-2 break-words">{feature.description}</p>
          ) : null}
        </div>
      ),
    },
    { key: 'status', header: 'Status', render: (feature) => <StatusBadge status={feature.status} /> },
    { key: 'priority', header: 'Priority', render: (feature) => <PriorityBadge priority={feature.priority} /> },
    { key: 'area', header: 'Area', render: (feature) => feature.area || '—' },
    {
      key: 'position',
      header: 'Order',
      render: (feature) => (
        <span className="tabular-nums text-ink-muted">{feature.position ?? '—'}</span>
      ),
    },
  ]

  const actions = (feature) => (
    <>
      <Button
        size="sm"
        variant="ghost"
        disabled={reordering || !neighbour(feature, -1)}
        onClick={() => move(feature, -1)}
        aria-label={`Move ${feature.title} up`}
        title="Move up"
      >
        ↑ Up
      </Button>
      <Button
        size="sm"
        variant="ghost"
        disabled={reordering || !neighbour(feature, 1)}
        onClick={() => move(feature, 1)}
        aria-label={`Move ${feature.title} down`}
        title="Move down"
      >
        ↓ Down
      </Button>
      <Button size="sm" variant="ghost" to={`/features/${feature.slug}`}>View</Button>
      <Button size="sm" variant="ghost" to={`/features/${feature.slug}/edit`}>Edit</Button>
      <Button size="sm" variant="ghost" className="text-red-600" onClick={() => setPendingDelete(feature)}>Delete</Button>
    </>
  )

  return (
    <Page>
      <PageHeader title="Features" subtitle="Roadmap items. Planned features can be reordered with the Up / Down buttons.">
        <Button to="/features/new">New feature</Button>
      </PageHeader>

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={deleteError} className="mb-6" />
      <ErrorAlert error={reorderError} className="mb-6" />

      <Toolbar>
        <Field
          label="Status"
          as="select"
          value={status}
          onChange={setStatus}
          options={[['', 'All statuses'], ...FEATURE_STATUSES]}
          inputClassName="w-auto"
        />
        <Field
          label="Priority"
          as="select"
          value={priority}
          onChange={setPriority}
          options={[['', 'All priorities'], ...FEATURE_PRIORITIES]}
          inputClassName="w-auto"
        />
        <Button variant="ghost" onClick={() => { setStatus(''); setPriority('') }}>Clear</Button>
      </Toolbar>

      <DataTable
        columns={columns}
        rows={rows}
        rowKey={(feature) => feature.id}
        actions={actions}
        empty="No features match these filters."
        loading={loading}
        caption="Roadmap features"
      />

      <ConfirmModal
        open={!!pendingDelete}
        title="Delete feature"
        message={pendingDelete ? `Delete “${pendingDelete.title}”? This cannot be undone.` : ''}
        confirmText="Delete"
        tone="danger"
        onConfirm={confirmDelete}
        onCancel={() => setPendingDelete(null)}
      />
    </Page>
  )
}
