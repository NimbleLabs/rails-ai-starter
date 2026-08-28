import React, { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'

import { resource } from '~/lib/api'
import { useMutation, useResource, useTitle } from '~/lib/hooks'
import { Button, Card, ErrorAlert, Field, LoadingBlock, Page, PageHeader } from '~/components/ui'

const funnels = resource('/api/v1/funnels')

const EMPTY = { name: '', description: '', active: true }

const STAGES = ['lead', 'book-call', 'order', 'order-completed']

/** Create and edit share one component; `useParams().id` decides which. */
export function FunnelForm() {
  const { id } = useParams()
  const navigate = useNavigate()
  const isEditing = !!id
  useTitle(isEditing ? 'Edit funnel' : 'New funnel')

  const { data, loading, error } = useResource(
    ({ signal }) => (id ? funnels.get(id, { signal }) : Promise.resolve(null)),
    [id]
  )

  const [form, setForm] = useState(EMPTY)

  useEffect(() => {
    if (!data) return
    setForm({
      name: data.name ?? '',
      description: data.description ?? '',
      active: !!data.active,
    })
  }, [data])

  const set = (field) => (value) => setForm((current) => ({ ...current, [field]: value }))

  const { run: save, pending, error: saveError } = useMutation((payload) =>
    isEditing ? funnels.update(id, payload) : funnels.create(payload)
  )

  const fieldErrors = saveError?.fieldErrors ?? {}
  const fieldError = (field) => {
    const messages = fieldErrors[field]
    return Array.isArray(messages) ? messages.join(', ') : messages
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    const saved = await save({ funnel: form })
    if (saved) navigate('/funnels')
  }

  const slug = data?.slug

  return (
    <Page width="max-w-3xl">
      <PageHeader
        title={isEditing ? 'Edit funnel' : 'New funnel'}
        subtitle="Name the funnel and toggle whether its pages are live."
        backTo="/funnels"
        backLabel="Back to funnels"
      />

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={saveError} className="mb-6" />

      {loading && isEditing && !data ? (
        <Card><LoadingBlock label="Loading funnel…" /></Card>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-6">
          <Card className="space-y-4">
            <Field
              label="Name"
              value={form.name}
              onChange={set('name')}
              placeholder="e.g. Summer Sale 2025"
              error={fieldError('name')}
              required
            />

            <Field
              label="Description"
              as="textarea"
              rows={3}
              value={form.description}
              onChange={set('description')}
              placeholder="Optional description for internal reference"
              error={fieldError('description')}
            />

            <Field
              label="Active"
              type="checkbox"
              value={form.active}
              onChange={set('active')}
              hint="Inactive funnels return a not-found page for visitors."
              error={fieldError('active')}
            />
          </Card>

          {slug ? (
            <div className="panel-muted">
              <p className="eyebrow mb-2">Landing page URLs</p>
              <ul className="text-sm font-mono space-y-1">
                {STAGES.map((stage) => (
                  <li key={stage} className="break-words">
                    <a href={`/f/${slug}/${stage}`} target="_blank" rel="noreferrer" className="table-link">
                      /f/{slug}/{stage}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ) : null}

          <div className="flex flex-col-reverse sm:flex-row sm:justify-end gap-3">
            <Button variant="secondary" to="/funnels">Cancel</Button>
            <Button type="submit" loading={pending}>{isEditing ? 'Update funnel' : 'Create funnel'}</Button>
          </div>
        </form>
      )}
    </Page>
  )
}
