import React, { useState } from 'react'
import { useParams } from 'react-router-dom'

import { api } from '~/lib/api'
import { useResource, useTitle } from '~/lib/hooks'
import { Alert, Badge, Button, Card, DetailList, EmptyState, ErrorAlert, LoadingBlock, Page, PageHeader } from '~/components/ui'

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

function formatDateTime(value) {
  if (!value) return null
  return new Date(value).toLocaleString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric', hour: 'numeric', minute: '2-digit',
  })
}

/** The API token, with a copy button. Mirrors the header mobile clients send. */
function ApiTokenPanel({ token }) {
  const [copied, setCopied] = useState(false)
  const [copyError, setCopyError] = useState(null)

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(token)
      setCopyError(null)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      setCopyError('Could not copy to the clipboard. Select the token and copy it manually.')
    }
  }

  return (
    <div className="pt-6 border-t border-line">
      <h2 className="section-title mb-2">API token</h2>
      <div className="flex flex-col sm:flex-row sm:items-center gap-2">
        <code className="flex-1 min-w-0 break-all bg-surface-muted px-3 py-2 rounded-xl text-sm font-mono text-ink select-all">
          {token || 'No token generated'}
        </code>
        {token ? (
          <Button variant="secondary" size="sm" onClick={copy} className="shrink-0">
            {copied ? 'Copied!' : 'Copy'}
          </Button>
        ) : null}
      </div>
      <p className="form-hint mt-2">
        Sent as the <code className="font-mono">x-api-token</code> header by mobile clients.
      </p>
      {copyError ? <Alert tone="error" className="mt-3" onDismiss={() => setCopyError(null)}>{copyError}</Alert> : null}
    </div>
  )
}

export function UserDetails() {
  const { id } = useParams()
  const { data: user, loading, error } = useResource(
    ({ signal }) => api.get(`/api/v1/users/${encodeURIComponent(id)}.json`, { signal }),
    [id]
  )
  useTitle(user?.name || 'User')

  const notFound = error?.status === 404

  return (
    <Page width="max-w-5xl">
      <PageHeader
        title={user?.name || 'User'}
        subtitle="Account information and API access."
        backTo="/users"
        backLabel="Back to users"
      />

      {notFound ? null : <ErrorAlert error={error} className="mb-6" />}

      {loading && !user ? (
        <Card><LoadingBlock label="Loading user…" /></Card>
      ) : notFound ? (
        <EmptyState title="User not found">
          No user matches “{id}”. It may have been deleted, or the link may be out of date.
        </EmptyState>
      ) : user ? (
        <Card className="space-y-6">
          <div className="flex items-center gap-4">
            <div
              className="w-14 h-14 shrink-0 rounded-full bg-primary/10 text-primary flex items-center justify-center"
              aria-hidden="true"
            >
              <span className="font-display font-bold text-xl">{initials(user.name)}</span>
            </div>
            <div className="min-w-0">
              <h2 className="font-display text-lg font-bold text-ink break-words">{user.name || '—'}</h2>
              <p className="text-sm text-ink-muted break-words">{user.email}</p>
            </div>
          </div>

          <div className="pt-6 border-t border-line">
            <DetailList
              items={[
                {
                  label: 'Role',
                  value: <Badge tone={user.role === 'admin' ? 'brand' : 'gray'}>{user.role || 'user'}</Badge>,
                },
                { label: 'User ID', value: user.id },
                { label: 'Slug', value: user.slug },
                { label: 'Sign-ins', value: user.sign_in_count ?? 0 },
                { label: 'Current sign-in', value: formatDateTime(user.current_sign_in_at) },
                { label: 'Previous sign-in', value: formatDateTime(user.last_sign_in_at) },
                { label: 'Current sign-in IP', value: user.current_sign_in_ip },
                { label: 'Previous sign-in IP', value: user.last_sign_in_ip },
                { label: 'Joined', value: formatDate(user.created_at) },
                { label: 'Last updated', value: formatDate(user.updated_at) },
              ]}
            />
          </div>

          <ApiTokenPanel token={user.auth_token} />
        </Card>
      ) : null}
    </Page>
  )
}
