import React, { useState } from 'react'
import { Link } from 'react-router-dom'

import { resource } from '~/lib/api'
import { useFlash, useMutation, useResource, useTitle } from '~/lib/hooks'
import { Alert, BoolBadge, Button, ConfirmModal, DataTable, ErrorAlert, Page, PageHeader } from '~/components/ui'

const funnels = resource('/api/v1/funnels')

/** FriendlyId: the controller finds by slug or id, so prefer the slug. */
const funnelId = (funnel) => funnel.slug ?? funnel.id

export function FunnelsList() {
  useTitle('Funnels')

  const { data, loading, error, reload } = useResource(({ signal }) => funnels.list('', { signal }), [])
  const [flash, setFlash] = useFlash()
  const [toDelete, setToDelete] = useState(null)

  const { run: destroy, error: deleteError } = useMutation(async (funnel) => {
    await funnels.remove(funnelId(funnel))
    return true
  })

  const rows = data ?? []

  const confirmDelete = async () => {
    const funnel = toDelete
    setToDelete(null)
    if (await destroy(funnel)) {
      setFlash({ tone: 'success', message: `Deleted “${funnel.name}”.` })
      reload()
    }
  }

  return (
    <Page>
      <PageHeader title="Funnels" subtitle="Landing-page sequences that turn visitors into orders.">
        <Button variant="secondary" to="/funnel-metrics">View metrics</Button>
        <Button to="/funnels/new">New funnel</Button>
      </PageHeader>

      {flash ? <Alert tone={flash.tone} className="mb-6" onDismiss={() => setFlash(null)}>{flash.message}</Alert> : null}
      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={deleteError} className="mb-6" />

      <DataTable
        columns={[
          {
            key: 'name',
            header: 'Name',
            primary: true,
            render: (row) => <Link to={`/funnels/${funnelId(row)}/edit`} className="table-link">{row.name}</Link>,
          },
          {
            key: 'slug',
            header: 'Slug',
            render: (row) => <span className="font-mono text-xs text-ink-muted break-words">{row.slug}</span>,
          },
          { key: 'description', header: 'Description', wide: true },
          {
            key: 'active',
            header: 'Status',
            render: (row) => <BoolBadge value={row.active} yes="Active" no="Inactive" />,
          },
        ]}
        rows={rows}
        rowKey={(row) => row.id}
        actions={(row) => (
          <>
            <Button size="sm" variant="ghost" to={`/funnels/${funnelId(row)}/edit`}>Edit</Button>
            <Button size="sm" variant="ghost" href={`/f/${row.slug}/lead`} target="_blank" rel="noreferrer">Preview</Button>
            <Button size="sm" variant="ghost" className="text-red-600" onClick={() => setToDelete(row)}>Delete</Button>
          </>
        )}
        empty="No funnels yet."
        loading={loading}
        caption="Funnels"
      />

      <ConfirmModal
        open={!!toDelete}
        title="Delete funnel"
        message={`“${toDelete?.name ?? ''}” and its landing pages will stop responding. This cannot be undone.`}
        confirmText="Delete"
        tone="danger"
        onConfirm={confirmDelete}
        onCancel={() => setToDelete(null)}
      />
    </Page>
  )
}
