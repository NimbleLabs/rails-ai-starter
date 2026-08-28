import React, { useState } from 'react'
import { Link } from 'react-router-dom'

import { api, resource } from '~/lib/api'
import { useFlash, useMutation, useResource, useTitle } from '~/lib/hooks'
import { Alert, Badge, Button, ConfirmModal, DataTable, ErrorAlert, Page, PageHeader } from '~/components/ui'

const emailTemplates = resource('/email-templates')

/** FriendlyId: the controller finds by slug or id, so prefer the slug. */
const templateId = (template) => template.slug ?? template.id

function formatDate(value) {
  if (!value) return '—'
  return new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

export function EmailTemplates() {
  useTitle('Emails')

  const { data, loading, error, reload } = useResource(({ signal }) => emailTemplates.list('', { signal }), [])
  const [flash, setFlash] = useFlash()

  // Two independent confirmations: deleting a template, and blasting it to a
  // list. Sending is irreversible (it enqueues a job that mails every
  // subscriber), so it never happens on a single click.
  const [toDelete, setToDelete] = useState(null)
  const [toSend, setToSend] = useState(null)

  const { run: destroy, error: deleteError } = useMutation(async (template) => {
    await emailTemplates.remove(templateId(template))
    return true
  })

  const { run: send, error: sendError } = useMutation((template) =>
    api.post(`/email-templates/${templateId(template)}/send`)
  )

  const rows = data ?? []

  const confirmDelete = async () => {
    const template = toDelete
    setToDelete(null)
    if (await destroy(template)) {
      setFlash({ tone: 'success', message: `Deleted “${template.subject}”.` })
      reload()
    }
  }

  const confirmSend = async () => {
    const template = toSend
    setToSend(null)
    const result = await send(template)
    if (result) {
      setFlash({ tone: 'success', message: result.message ?? 'Email queued for sending.' })
    }
  }

  return (
    <Page>
      <PageHeader title="Emails" subtitle="Templates you can send to a subscriber list.">
        <Button to="/emails/new">New template</Button>
      </PageHeader>

      {flash ? <Alert tone={flash.tone} className="mb-6" onDismiss={() => setFlash(null)}>{flash.message}</Alert> : null}
      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={deleteError} className="mb-6" />
      <ErrorAlert error={sendError} className="mb-6" />

      <DataTable
        columns={[
          {
            key: 'subject',
            header: 'Subject',
            primary: true,
            render: (row) => (
              <Link to={`/emails/${templateId(row)}/edit`} className="table-link">{row.subject || 'Untitled'}</Link>
            ),
          },
          {
            key: 'send_group',
            header: 'List',
            render: (row) => (row.send_group ? <Badge tone="brand">{row.send_group}</Badge> : '—'),
          },
          { key: 'created_at', header: 'Created', render: (row) => formatDate(row.created_at) },
        ]}
        rows={rows}
        rowKey={(row) => row.id}
        actions={(row) => (
          <>
            <Button size="sm" variant="ghost" to={`/emails/${templateId(row)}/edit`}>Edit</Button>
            <Button size="sm" variant="ghost" onClick={() => setToSend(row)}>Send</Button>
            <Button size="sm" variant="ghost" className="text-red-600" onClick={() => setToDelete(row)}>Delete</Button>
          </>
        )}
        empty="No emails yet."
        loading={loading}
        caption="Email templates"
      />

      <ConfirmModal
        open={!!toSend}
        title="Send this email?"
        message={`This emails every subscriber on the ${toSend?.send_group || 'selected'} list. It happens immediately and cannot be undone.`}
        confirmText="Send to list"
        tone="danger"
        onConfirm={confirmSend}
        onCancel={() => setToSend(null)}
      />

      <ConfirmModal
        open={!!toDelete}
        title="Delete email template"
        message={`“${toDelete?.subject ?? ''}” will be permanently removed.`}
        confirmText="Delete"
        tone="danger"
        onConfirm={confirmDelete}
        onCancel={() => setToDelete(null)}
      />
    </Page>
  )
}
