import React from 'react'
import { useParams } from 'react-router-dom'

import { resource } from '~/lib/api'
import { useResource, useTitle } from '~/lib/hooks'
import {
  Badge, BoolBadge, Button, Card, DetailList, EmptyState, ErrorAlert, LoadingBlock, Page, PageHeader,
} from '~/components/ui'

const articles = resource('/articles')

function formatDate(value) {
  if (!value) return null
  return new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

export function PostDetails() {
  // `:id` is the article slug — Article uses friendly_id with :finders.
  const { id } = useParams()
  const { data: article, loading, error } = useResource(({ signal }) => articles.get(id, { signal }), [id])

  useTitle(article?.title ?? 'Article')

  // A deleted or renamed slug 404s; that is a normal outcome here, not an error banner.
  const missing = !article && !loading && (!error || error.status === 404)

  return (
    <Page width="max-w-5xl">
      <PageHeader title={article?.title ?? 'Article'} backTo="/articles" backLabel="Back to articles">
        {article ? <Button to={`/articles/${article.slug}/edit`}>Edit</Button> : null}
      </PageHeader>

      {missing ? null : <ErrorAlert error={error} className="mb-6" />}

      {loading && !article ? (
        <Card><LoadingBlock label="Loading article…" /></Card>
      ) : article ? (
        <div className="space-y-6">
          <Card>
            <div className="flex flex-wrap items-center gap-2 mb-6">
              <BoolBadge value={article.published} yes="Published" no="Draft" />
              {article.featured ? <Badge tone="amber">Featured</Badge> : null}
              {article.category ? <Badge tone="brand">{article.category}</Badge> : null}
            </div>

            <DetailList
              items={[
                { label: 'Description', value: article.description, wide: true },
                { label: 'Author', value: article.author },
                { label: 'Category', value: article.category },
                { label: 'Slug', value: article.slug },
                { label: 'Published at', value: formatDate(article.published_at) },
                { label: 'Created', value: formatDate(article.created_at) },
                { label: 'Last updated', value: formatDate(article.updated_at) },
              ]}
            />
          </Card>

          <Card>
            <h2 className="section-title mb-4">Content</h2>
            {article.content ? (
              // Trusted HTML: this is our own Action Text field, written by an admin
              // in the Trix editor on this very app — not user-submitted content.
              <div
                className="rich-text trix-content prose max-w-none text-ink"
                dangerouslySetInnerHTML={{ __html: article.content }}
              />
            ) : (
              <p className="text-sm text-ink-muted">No content yet.</p>
            )}
          </Card>
        </div>
      ) : missing ? (
        <EmptyState title="Article not found">
          No article matches “{id}”. It may have been deleted or renamed.
        </EmptyState>
      ) : null}
    </Page>
  )
}
