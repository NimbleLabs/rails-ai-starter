import React, { useState } from 'react'

import { api, resource } from '~/lib/api'
import { useFlash, useMutation, useResource, useTitle } from '~/lib/hooks'
import {
  Alert, Badge, BoolBadge, Button, Card, ConfirmModal, DataTable, ErrorAlert, Field, Page, PageHeader,
} from '~/components/ui'

const subscriptions = resource('/log-subscriptions')

/** LogSubscription::CHANNELS. */
const CHANNELS = [['email', 'Email'], ['slack', 'Slack']]

/** Log::LEVELS — the notification fires at this level or above. */
const LEVELS = [['info', 'Info'], ['warn', 'Warn'], ['error', 'Error'], ['fatal', 'Fatal']]

const BLANK = {
  id: null,
  name: '',
  channel: 'email',
  destination: '',
  min_level: 'error',
  throttle_minutes: 60,
  active: true,
}

export function LogSubscriptions() {
  useTitle('Log notifications')

  const [editing, setEditing] = useState(null)
  const [pendingDelete, setPendingDelete] = useState(null)
  const [flash, setFlash] = useFlash()

  const { data, loading, error, reload } = useResource(({ signal }) => subscriptions.list('', { signal }), [])
  const rows = data ?? []

  const { run: save, pending: saving, error: saveError, setError: setSaveError } = useMutation((subscription) => {
    const payload = {
      log_subscription: {
        name: subscription.name,
        channel: subscription.channel,
        destination: subscription.destination,
        min_level: subscription.min_level,
        throttle_minutes: subscription.throttle_minutes,
        active: subscription.active,
      },
    }
    return subscription.id ? subscriptions.update(subscription.id, payload) : subscriptions.create(payload)
  })
  const { run: destroy, error: deleteError } = useMutation((subscription) => subscriptions.remove(subscription.id))
  const { run: sendTest, pending: testing, error: testError, setError: setTestError } = useMutation((subscription) =>
    api.post(`/log-subscriptions/${subscription.id}/test.json`)
  )

  const fieldErrors = saveError?.fieldErrors ?? {}
  const fieldError = (key) => {
    const messages = fieldErrors[key]
    if (!messages) return undefined
    return Array.isArray(messages) ? messages.join(', ') : String(messages)
  }

  const set = (key) => (value) => setEditing((current) => ({ ...current, [key]: value }))

  const startNew = () => { setSaveError(null); setEditing({ ...BLANK }) }
  const startEdit = (subscription) => { setSaveError(null); setEditing({ ...BLANK, ...subscription }) }

  const submit = async (event) => {
    event.preventDefault()
    const result = await save(editing)
    if (result === null) return
    setEditing(null)
    setFlash({ tone: 'success', message: 'Notification saved.' })
    reload()
  }

  const onDelete = async () => {
    const target = pendingDelete
    setPendingDelete(null)
    if ((await destroy(target)) === null) return
    setFlash({ tone: 'success', message: 'Notification deleted.' })
    reload()
  }

  const onTest = async (subscription) => {
    setTestError(null)
    const result = await sendTest(subscription)
    if (result === null) return
    setFlash({ tone: 'success', message: result.message || 'Test notification sent.' })
    reload()
  }

  const slack = editing?.channel === 'slack'

  const columns = [
    {
      key: 'name',
      header: 'Name',
      primary: true,
      render: (row) => row.name || row.display_name || '—',
    },
    { key: 'channel', header: 'Channel', render: (row) => <Badge tone="brand">{row.channel}</Badge> },
    { key: 'destination', header: 'Destination', wide: true, render: (row) => <span className="break-all">{row.destination}</span> },
    { key: 'min_level', header: 'Level', render: (row) => <Badge tone="gray">{`${row.min_level}+`}</Badge> },
    { key: 'throttle_minutes', header: 'Throttle', render: (row) => `${row.throttle_minutes}m` },
    { key: 'active', header: 'Status', render: (row) => <BoolBadge value={row.active} yes="Active" no="Paused" /> },
  ]

  return (
    <Page width="max-w-5xl">
      <PageHeader
        title="Log notifications"
        subtitle="Who gets told when something lands in the log, and how."
        backTo="/logs"
        backLabel="Back to logs"
      >
        <Button onClick={startNew}>New notification</Button>
      </PageHeader>

      {flash ? (
        <Alert tone={flash.tone} className="mb-6" onDismiss={() => setFlash(null)}>{flash.message}</Alert>
      ) : null}

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={testError} className="mb-6" />
      <ErrorAlert error={deleteError} className="mb-6" />

      {editing ? (
        <Card className="mb-6">
          <form onSubmit={submit}>
            <h2 className="section-title mb-4">{editing.id ? 'Edit notification' : 'New notification'}</h2>

            <ErrorAlert error={saveError} className="mb-4" />

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field
                label="Name"
                value={editing.name ?? ''}
                onChange={set('name')}
                placeholder="Ops on-call"
                hint="Optional label so you can tell rules apart."
                error={fieldError('name')}
              />
              <Field
                label="Channel"
                as="select"
                value={editing.channel}
                onChange={set('channel')}
                options={CHANNELS}
                error={fieldError('channel')}
              />
              <Field
                className="sm:col-span-2"
                label="Destination"
                value={editing.destination ?? ''}
                onChange={set('destination')}
                placeholder={slack ? 'https://hooks.slack.com/services/…' : 'ops@example.com'}
                hint={slack
                  ? 'A Slack incoming-webhook URL — it must start with https://hooks.slack.com/.'
                  : 'An email address. Requires outgoing mail to be configured.'}
                error={fieldError('destination')}
              />
              <Field
                label="Notify at or above"
                as="select"
                value={editing.min_level}
                onChange={set('min_level')}
                options={LEVELS}
                hint="Error is the sensible default. Info will be noisy."
                error={fieldError('min_level')}
              />
              <Field
                label="Throttle (minutes)"
                type="number"
                min="0"
                max="10080"
                value={editing.throttle_minutes ?? 0}
                onChange={(value) => set('throttle_minutes')(value === '' ? '' : Number(value))}
                hint="Minimum gap before the same recurring problem notifies again."
                error={fieldError('throttle_minutes')}
              />
              <Field
                className="sm:col-span-2"
                label="Active"
                type="checkbox"
                value={editing.active}
                onChange={set('active')}
                hint="Paused rules stay configured but never notify."
              />
            </div>

            <div className="flex flex-col-reverse sm:flex-row sm:justify-end gap-3 mt-6">
              <Button variant="secondary" type="button" onClick={() => setEditing(null)}>Cancel</Button>
              <Button type="submit" loading={saving}>Save</Button>
            </div>
          </form>
        </Card>
      ) : null}

      <DataTable
        columns={columns}
        rows={rows}
        rowKey={(row) => row.id}
        actions={(row) => (
          <>
            <Button size="sm" variant="ghost" disabled={testing} onClick={() => onTest(row)} title="Send a test notification">
              Test
            </Button>
            <Button size="sm" variant="ghost" onClick={() => startEdit(row)}>Edit</Button>
            <Button size="sm" variant="ghost" className="text-red-600" onClick={() => setPendingDelete(row)}>Delete</Button>
          </>
        )}
        empty="No notifications yet. Add one so errors reach a human."
        loading={loading}
        caption="Log notification rules"
      />

      <ConfirmModal
        open={!!pendingDelete}
        title="Delete this notification?"
        message="Nobody will be notified through this channel any more."
        confirmText="Delete"
        tone="danger"
        onConfirm={onDelete}
        onCancel={() => setPendingDelete(null)}
      />
    </Page>
  )
}
