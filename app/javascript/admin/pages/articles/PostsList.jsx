import React, { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'

import { api, resource } from '~/lib/api'
import { useResource, useMutation, useTitle } from '~/lib/hooks'
import {
  Badge, BoolBadge, Button, ConfirmModal, DataTable, ErrorAlert, Field, Page, PageHeader, Toolbar,
} from '~/components/ui'

const articles = resource('/articles')

function formatDate(value) {
  if (!value) return '—'
  return new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

/** Distinct, sorted values of one field across the loaded rows. */
function optionsFor(rows, key) {
  return [...new Set(rows.map((row) => row[key]).filter(Boolean))].sort()
}

export function PostsList() {
  useTitle('Articles')

  const { data, loading, error, reload } = useResource(({ signal }) => api.get('/articles.json', { signal }), [])
  const posts = data ?? []

  const [category, setCategory] = useState('')
  const [author, setAuthor] = useState('')
  const [pendingDelete, setPendingDelete] = useState(null)

  // DELETE returns 204, which api.delete resolves to `null` — the same value useMutation
  // uses for "failed". Return the post so success stays distinguishable.
  const { run: destroy, error: deleteError } = useMutation(async (post) => {
    await articles.remove(post.slug)
    return post
  })

  // Filter choices come from the data that is actually on screen. The Vue app read
  // them from a hardcoded list in model.js, which went stale the moment someone
  // added a category through the admin.
  const categories = useMemo(() => optionsFor(posts, 'category'), [posts])
  const authors = useMemo(() => optionsFor(posts, 'author'), [posts])

  const rows = useMemo(
    () => posts.filter((post) => (!category || post.category === category) && (!author || post.author === author)),
    [posts, category, author]
  )

  const confirmDelete = async () => {
    const post = pendingDelete
    setPendingDelete(null)
    if (await destroy(post)) reload()
  }

  return (
    <Page>
      <PageHeader title="Articles" subtitle="Blog posts and long-form content for the marketing site.">
        <Button to="/articles/new">New article</Button>
      </PageHeader>

      <ErrorAlert error={error} className="mb-6" />
      <ErrorAlert error={deleteError} className="mb-6" />

      <Toolbar>
        <Field
          label="Category"
          as="select"
          value={category}
          onChange={setCategory}
          options={[['', 'All categories'], ...categories]}
          className="w-full sm:w-auto"
        />
        <Field
          label="Author"
          as="select"
          value={author}
          onChange={setAuthor}
          options={[['', 'All authors'], ...authors]}
          className="w-full sm:w-auto"
        />
        <Button
          variant="secondary"
          onClick={() => { setCategory(''); setAuthor('') }}
          disabled={!category && !author}
        >
          Clear
        </Button>
      </Toolbar>

      <DataTable
        columns={[
          {
            key: 'title',
            header: 'Title',
            primary: true,
            render: (post) => <Link to={`/articles/${post.slug}`} className="table-link">{post.title}</Link>,
          },
          { key: 'author', header: 'Author' },
          {
            key: 'category',
            header: 'Category',
            render: (post) => (post.category ? <Badge tone="brand">{post.category}</Badge> : '—'),
          },
          {
            key: 'published',
            header: 'Status',
            render: (post) => <BoolBadge value={post.published} yes="Published" no="Draft" />,
          },
          {
            key: 'featured',
            header: 'Featured',
            render: (post) => (post.featured ? <Badge tone="amber">Featured</Badge> : '—'),
          },
          { key: 'published_at', header: 'Published', render: (post) => formatDate(post.published_at) },
        ]}
        rows={rows}
        rowKey={(post) => post.id}
        actions={(post) => (
          <>
            <Button size="sm" variant="ghost" to={`/articles/${post.slug}`}>View</Button>
            <Button size="sm" variant="ghost" to={`/articles/${post.slug}/edit`}>Edit</Button>
            <Button size="sm" variant="ghost" onClick={() => setPendingDelete(post)}>Delete</Button>
          </>
        )}
        empty={posts.length ? 'No articles match these filters.' : 'No articles yet.'}
        loading={loading}
        caption="Articles"
      />

      <ConfirmModal
        open={!!pendingDelete}
        title="Delete this article?"
        message={pendingDelete ? `“${pendingDelete.title}” will be permanently removed.` : ''}
        confirmText="Delete"
        tone="danger"
        onConfirm={confirmDelete}
        onCancel={() => setPendingDelete(null)}
      />
    </Page>
  )
}
