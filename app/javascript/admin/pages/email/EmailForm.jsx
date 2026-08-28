import React, { useCallback, useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'

import { resource } from '~/lib/api'
import { useMutation, useResource, useTitle } from '~/lib/hooks'
import { Button, Card, ErrorAlert, Field, LoadingBlock, Page, PageHeader } from '~/components/ui'
import { TrixEditor } from '~/components/TrixEditor'

const emailTemplates = resource('/email-templates')

// The only subscriber list the app maintains (User/Contact both subscribe to
// "Newsletter" via mailkick, and SendEmailTemplateJob resolves recipients with
// User.subscribed(send_group)).
const SEND_GROUPS = ['Newsletter']

const EMPTY = { subject: '', send_group: SEND_GROUPS[0], body: '' }

/** Create and edit share one component; `useParams().id` decides which. */
export function EmailForm() {
  const { id } = useParams()
  const navigate = useNavigate()
  const isEditing = !!id
  useTitle(isEditing ? 'Edit email' : 'New email')

  const { data, loading, error } = useResource(
    ({ signal }) => (id ? emailTemplates.get(id, { signal }) : Promise.resolve(null)),
    [id]
  )

  const [form, setForm] = useState(EMPTY)

  useEffect(() => {
    if (!data) return
    setForm({
      subject: data.subject ?? '',
      send_group: data.send_group ?? SEND_GROUPS[0],
      body: data.body ?? '',
    })
  }, [data])

  const set = (field) => (value) => setForm((current) => ({ ...current, [field]: value }))
  // Stable identity so TrixEditor doesn't re-bind its listeners every keystroke.
  const setBody = useCallback((body) => setForm((current) => ({ ...current, body })), [])

  const { run: save, pending, error: saveError } = useMutation((payload) =>
    isEditing ? emailTemplates.update(id, payload) : emailTemplates.create(payload)
  )

  const fieldErrors = saveError?.fieldErrors ?? {}
  const fieldError = (field) => {
    const messages = fieldErrors[field]
    return Array.isArray(messages) ? messages.join(', ') : messages
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    const saved = await save({ email_template: form })
    if (saved) navigate('/email-templates')
  }

  return (
    <Page width="max-w-3xl">
      <PageHeader
        title={isEditing ? 'Edit email' : 'New email'}
        subtitle="Write the message, then send it to a list from the Emails page."
        backTo="/email-templates"
        backLabel="Back to emails"
      />

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={saveError} className="mb-6" />

      {loading && isEditing && !data ? (
        <Card><LoadingBlock label="Loading email…" /></Card>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-6">
          <Card className="space-y-4">
            <Field
              label="Subject"
              value={form.subject}
              onChange={set('subject')}
              placeholder="Enter email subject"
              error={fieldError('subject')}
              required
            />

            <Field
              label="Send to"
              as="select"
              value={form.send_group}
              onChange={set('send_group')}
              options={SEND_GROUPS}
              hint="The subscriber list this email will go to."
              error={fieldError('send_group')}
              required
            />

            <div>
              <span className="form-label">Body</span>
              <TrixEditor value={form.body} onChange={setBody} placeholder="Write the email…" />
              {fieldError('body') ? <p className="form-hint text-red-600">{fieldError('body')}</p> : null}
            </div>
          </Card>

          <div className="flex flex-col-reverse sm:flex-row sm:justify-end gap-3">
            <Button variant="secondary" to="/email-templates">Cancel</Button>
            <Button type="submit" loading={pending}>{isEditing ? 'Update email' : 'Create email'}</Button>
          </div>
        </form>
      )}
    </Page>
  )
}
