import React, { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'

import { ApiError, resource, toFormData } from '~/lib/api'
import { useMutation, useResource, useTitle } from '~/lib/hooks'
import { TrixEditor } from '~/components/TrixEditor'
import { Button, Card, ErrorAlert, Field, LoadingBlock, Page, PageHeader } from '~/components/ui'

const articles = resource('/articles')

/** `published_at` comes back as an ISO timestamp; <input type="date"> wants YYYY-MM-DD. */
function toDateInput(value) {
  if (!value) return ''
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '' : date.toISOString().slice(0, 10)
}

export function PostForm() {
  // `:id` is the article slug — Article uses friendly_id with :finders.
  const { id } = useParams()
  const isEdit = !!id
  const navigate = useNavigate()
  useTitle(isEdit ? 'Edit article' : 'New article')

  const [form, setForm] = useState({
    title: '',
    description: '',
    author: '',
    category: '',
    published: false,
    featured: false,
    published_at: '',
  })
  const [content, setContent] = useState('')
  const [featuredImage, setFeaturedImage] = useState(null)

  const { data, loading, error } = useResource(
    ({ signal }) => (isEdit ? articles.get(id, { signal }) : null),
    [id]
  )

  // Copy the loaded record into local state once; the form is controlled from here on.
  useEffect(() => {
    if (!data) return
    setForm({
      title: data.title ?? '',
      description: data.description ?? '',
      author: data.author ?? '',
      category: data.category ?? '',
      published: !!data.published,
      featured: !!data.featured,
      published_at: toDateInput(data.published_at),
    })
    setContent(data.content ?? '')
  }, [data])

  const update = (key) => (value) => setForm((current) => ({ ...current, [key]: value }))

  // The controller does params.require(:article), so everything is nested under
  // `article[...]`. multipart, because featured_image is an Active Storage
  // attachment and a File cannot ride along in JSON.
  const { run: save, pending, error: saveError } = useMutation((payload) =>
    isEdit ? articles.update(id, payload) : articles.create(payload)
  )

  const fieldError = (name) => {
    if (!(saveError instanceof ApiError)) return undefined
    const messages = saveError.fieldErrors[name]
    if (!messages) return undefined
    return Array.isArray(messages) ? messages.join(', ') : String(messages)
  }

  const onSubmit = async (event) => {
    event.preventDefault()
    const payload = toFormData('article', {
      ...form,
      content,
      ...(featuredImage ? { featured_image: featuredImage } : {}),
    })
    if (await save(payload) !== null) navigate('/articles')
  }

  return (
    <Page width="max-w-3xl">
      <PageHeader
        title={isEdit ? 'Edit article' : 'New article'}
        subtitle="Blog posts and long-form content for the marketing site."
        backTo="/articles"
        backLabel="Back to articles"
      />

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={saveError} className="mb-6" />

      {loading && isEdit && !data ? (
        <Card><LoadingBlock label="Loading article…" /></Card>
      ) : (
        <form onSubmit={onSubmit} className="space-y-6">
          <Card>
            <h2 className="section-title mb-4">Details</h2>
            <div className="space-y-4">
              <Field
                label="Title"
                value={form.title}
                onChange={update('title')}
                error={fieldError('title')}
                required
              />
              <Field
                label="Description"
                value={form.description}
                onChange={update('description')}
                hint="Short summary shown in listings and previews."
                error={fieldError('description')}
              />
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Field label="Author" value={form.author} onChange={update('author')} error={fieldError('author')} />
                <Field
                  label="Category"
                  value={form.category}
                  onChange={update('category')}
                  hint="Free text — e.g. AI, Engineering."
                  error={fieldError('category')}
                />
              </div>
              <Field
                label="Published at"
                type="date"
                value={form.published_at}
                onChange={update('published_at')}
                error={fieldError('published_at')}
              />
              <div className="flex flex-wrap gap-6">
                <Field label="Published" type="checkbox" value={form.published} onChange={update('published')} />
                <Field label="Featured" type="checkbox" value={form.featured} onChange={update('featured')} />
              </div>
            </div>
          </Card>

          <Card>
            <h2 className="section-title mb-4">Content</h2>
            <TrixEditor value={content} onChange={setContent} placeholder="Write the article…" />
          </Card>

          <Card>
            <h2 className="section-title mb-1">Featured image</h2>
            <p className="text-sm text-ink-muted mb-4">
              Optional. Uploading a new file replaces the current attachment.
            </p>
            <input
              type="file"
              accept="image/*"
              onChange={(event) => setFeaturedImage(event.target.files?.[0] ?? null)}
              className="block w-full text-sm text-ink file:mr-4 file:rounded-full file:border-0 file:bg-primary/10 file:px-4 file:py-2 file:text-sm file:font-medium file:text-primary"
              aria-label="Featured image"
            />
          </Card>

          <div className="flex flex-col-reverse sm:flex-row sm:justify-end gap-3">
            <Button variant="secondary" to="/articles">Cancel</Button>
            <Button type="submit" loading={pending}>Save</Button>
          </div>
        </form>
      )}
    </Page>
  )
}
