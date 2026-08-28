import React, { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'

import { api } from '~/lib/api'
import { useResource, useTitle } from '~/lib/hooks'
import { Card, EmptyState, ErrorAlert, Field, LoadingBlock, Page, PageHeader, Toolbar } from '~/components/ui'

/** "Ada Lovelace" → "AL". Falls back to "?" so the avatar is never blank. */
function initials(name) {
  const parts = String(name ?? '').trim().split(/\s+/).filter(Boolean)
  if (!parts.length) return '?'
  if (parts.length === 1) return parts[0].charAt(0).toUpperCase()
  return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase()
}

function formatDate(value) {
  if (!value) return null
  return new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

export function UsersList() {
  useTitle('Users')
  const [query, setQuery] = useState('')
  const { data, loading, error } = useResource(({ signal }) => api.get('/api/v1/users.json', { signal }), [])

  const users = useMemo(() => (Array.isArray(data) ? data : []), [data])

  // The index endpoint takes no search param, so filter the loaded array.
  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase()
    if (!needle) return users
    return users.filter((user) =>
      `${user.name ?? ''} ${user.email ?? ''}`.toLowerCase().includes(needle)
    )
  }, [users, query])

  return (
    <Page>
      <PageHeader title="Users" subtitle="Everyone with an account, including admins." />

      <ErrorAlert error={error} className="mb-6" />

      <Toolbar>
        <Field
          label="Search"
          type="search"
          value={query}
          onChange={setQuery}
          placeholder="Name or email"
          className="w-full sm:w-auto sm:flex-1"
        />
        <p className="text-sm text-ink-muted pb-2">
          {filtered.length === users.length
            ? `${users.length} ${users.length === 1 ? 'user' : 'users'}`
            : `${filtered.length} of ${users.length}`}
        </p>
      </Toolbar>

      {loading && !users.length ? (
        <Card><LoadingBlock label="Loading users…" /></Card>
      ) : filtered.length ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.map((user) => {
            const lastSeen = formatDate(user.current_sign_in_at ?? user.last_sign_in_at)
            return (
              <Card key={user.id} className="flex items-center gap-4">
                <div
                  className="w-12 h-12 shrink-0 rounded-full bg-primary/10 text-primary flex items-center justify-center"
                  aria-hidden="true"
                >
                  <span className="font-display font-bold text-lg">{initials(user.name)}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <h2 className="font-display text-base font-bold truncate">
                    <Link to={`/users/${user.slug ?? user.id}`} className="table-link">
                      {user.name || user.email}
                    </Link>
                  </h2>
                  <p className="text-sm text-ink-muted truncate" title={user.email}>{user.email}</p>
                  <p className="text-xs text-ink-muted truncate">
                    {lastSeen ? `Last seen ${lastSeen}` : 'Never signed in'}
                  </p>
                </div>
              </Card>
            )
          })}
        </div>
      ) : users.length ? (
        <EmptyState title="No matches">
          No user matches “{query}”. Try a different name or email.
        </EmptyState>
      ) : error ? null : (
        <EmptyState title="No users found">
          Users will appear here once they have registered an account.
        </EmptyState>
      )}
    </Page>
  )
}
