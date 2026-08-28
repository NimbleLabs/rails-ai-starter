import React, { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'

import { resource } from '~/lib/api'
import { useMutation, useResource, useTitle } from '~/lib/hooks'
import { Button, Card, ErrorAlert, Field, LoadingBlock, Page, PageHeader } from '~/components/ui'
import { FEATURE_PRIORITIES, FEATURE_STATUSES } from './FeaturesList'

const features = resource('/features')

const BLANK = {
  title: '',
  description: '',
  status: 'backlog',
  priority: 'medium',
  area: '',
  acceptance_criteria: '',
  plan: '',
  implementation_notes: '',
  started_at: '',
  completed_at: '',
}

/** ISO timestamp from Rails → the `YYYY-MM-DD` a date input wants. */
function toDateInput(value) {
  return value ? String(value).slice(0, 10) : ''
}

export function FeatureForm() {
  const { id } = useParams()
  const navigate = useNavigate()
  const editing = !!id
  useTitle(editing ? 'Edit feature' : 'New feature')

  const [form, setForm] = useState(BLANK)
  const set = (key) => (value) => setForm((current) => ({ ...current, [key]: value }))

  const { data, loading, error } = useResource(
    ({ signal }) => (id ? features.get(id, { signal }) : Promise.resolve(null)),
    [id]
  )

  useEffect(() => {
    if (!data) return
    setForm({
      title: data.title ?? '',
      description: data.description ?? '',
      status: data.status ?? 'backlog',
      priority: data.priority ?? 'medium',
      area: data.area ?? '',
      acceptance_criteria: data.acceptance_criteria ?? '',
      plan: data.plan ?? '',
      implementation_notes: data.implementation_notes ?? '',
      started_at: toDateInput(data.started_at),
      completed_at: toDateInput(data.completed_at),
    })
  }, [data])

  const { run: save, pending, error: saveError } = useMutation((payload) =>
    editing ? features.update(id, payload) : features.create(payload)
  )

  const fieldErrors = saveError?.fieldErrors ?? {}
  const fieldError = (key) => {
    const messages = fieldErrors[key]
    if (!messages) return undefined
    return Array.isArray(messages) ? messages.join(', ') : String(messages)
  }

  const submit = async (event) => {
    event.preventDefault()
    const result = await save({
      feature: {
        ...form,
        started_at: form.started_at || null,
        completed_at: form.completed_at || null,
      },
    })
    if (result !== null) navigate('/features')
  }

  return (
    <Page width="max-w-3xl">
      <PageHeader
        title={editing ? 'Edit feature' : 'New feature'}
        subtitle="Describe the work, set its status and priority, and capture the plan."
        backTo="/features"
        backLabel="Back to features"
      />

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={saveError} className="mb-6" />

      {editing && loading && !data ? (
        <Card><LoadingBlock label="Loading feature…" /></Card>
      ) : (
        <form onSubmit={submit} className="space-y-6">
          <Card>
            <h2 className="section-title mb-4">Details</h2>
            <div className="space-y-4">
              <Field
                label="Title"
                value={form.title}
                onChange={set('title')}
                placeholder="e.g. Add user authentication"
                error={fieldError('title')}
                required
              />
              <Field
                label="Description"
                as="textarea"
                rows={3}
                value={form.description}
                onChange={set('description')}
                placeholder="Brief description of the feature"
                error={fieldError('description')}
              />
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Field
                  label="Status"
                  as="select"
                  value={form.status}
                  onChange={set('status')}
                  options={FEATURE_STATUSES}
                  error={fieldError('status')}
                />
                <Field
                  label="Priority"
                  as="select"
                  value={form.priority}
                  onChange={set('priority')}
                  options={FEATURE_PRIORITIES}
                  error={fieldError('priority')}
                />
              </div>
              <Field
                label="Area"
                value={form.area}
                onChange={set('area')}
                placeholder="e.g. Backend, Frontend, API, Infrastructure"
                error={fieldError('area')}
              />
            </div>
          </Card>

          <Card>
            <h2 className="section-title mb-4">Planning</h2>
            <div className="space-y-4">
              <Field
                label="Acceptance criteria"
                as="textarea"
                rows={4}
                value={form.acceptance_criteria}
                onChange={set('acceptance_criteria')}
                placeholder={'- Criteria 1\n- Criteria 2'}
                error={fieldError('acceptance_criteria')}
              />
              <Field
                label="Implementation plan"
                as="textarea"
                rows={4}
                value={form.plan}
                onChange={set('plan')}
                placeholder="High-level plan for implementing this feature"
                error={fieldError('plan')}
              />
              <Field
                label="Implementation notes"
                as="textarea"
                rows={4}
                value={form.implementation_notes}
                onChange={set('implementation_notes')}
                placeholder="Technical notes, decisions made, etc."
                error={fieldError('implementation_notes')}
              />
            </div>
          </Card>

          <Card>
            <h2 className="section-title mb-4">Timeline</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field
                label="Started"
                type="date"
                value={form.started_at}
                onChange={set('started_at')}
                error={fieldError('started_at')}
              />
              <Field
                label="Completed"
                type="date"
                value={form.completed_at}
                onChange={set('completed_at')}
                error={fieldError('completed_at')}
              />
            </div>
          </Card>

          <div className="flex flex-col-reverse sm:flex-row sm:justify-end gap-3">
            <Button variant="secondary" to="/features">Cancel</Button>
            <Button type="submit" loading={pending}>{editing ? 'Update feature' : 'Create feature'}</Button>
          </div>
        </form>
      )}
    </Page>
  )
}
