import React, { useState } from 'react'
import { Link } from 'react-router-dom'

import { api } from '~/lib/api'
import { useResource, useTitle } from '~/lib/hooks'
import { Card, ErrorAlert, Field, LoadingBlock, Page, PageHeader, StatTile } from '~/components/ui'

const RANGES = [
  ['7', 'Last 7 days'],
  ['30', 'Last 30 days'],
  ['90', 'Last 90 days'],
]

function percent(part, whole) {
  if (!whole) return '—'
  return `${Math.round((part / whole) * 100)}%`
}

/** Horizontal bar list — used for events, pages, referrers and devices. */
function BreakdownList({ title, rows, labelKey, emptyText }) {
  const max = Math.max(1, ...rows.map((row) => row.count))
  return (
    <Card>
      <h2 className="section-title mb-4">{title}</h2>
      {rows.length ? (
        <ul className="space-y-3">
          {rows.map((row) => (
            <li key={row[labelKey]}>
              <div className="flex items-baseline justify-between gap-3 mb-1">
                <span className="text-sm text-ink truncate min-w-0" title={String(row[labelKey])}>{row[labelKey]}</span>
                <span className="text-sm font-medium text-ink-muted shrink-0 tabular-nums">{row.count}</span>
              </div>
              <div className="h-1.5 rounded-full bg-surface-muted overflow-hidden">
                <div className="h-full rounded-full bg-primary" style={{ width: `${(row.count / max) * 100}%` }} />
              </div>
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-sm text-ink-muted">{emptyText}</p>
      )}
    </Card>
  )
}

/** Visits per day. A plain flex chart — no charting library for one sparkline. */
function VisitsChart({ series }) {
  const max = Math.max(1, ...series.map((point) => point.count))
  const format = (iso) => new Date(`${iso}T00:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })

  return (
    <Card>
      <h2 className="section-title mb-1">Visits per day</h2>
      <p className="text-sm text-ink-muted mb-4">Peak {max} on a single day.</p>
      <div className="flex items-end gap-px h-32 overflow-hidden" role="img" aria-label={`Visits per day, peak ${max}`}>
        {series.map((point) => (
          <div
            key={point.date}
            className="flex-1 min-w-px bg-primary/70 hover:bg-primary rounded-t-sm transition-colors"
            style={{ height: `${Math.max(2, (point.count / max) * 100)}%` }}
            title={`${format(point.date)}: ${point.count} visit${point.count === 1 ? '' : 's'}`}
          />
        ))}
      </div>
      {series.length ? (
        <div className="flex justify-between text-xs text-ink-muted mt-2">
          <span>{format(series[0].date)}</span>
          <span>{format(series[series.length - 1].date)}</span>
        </div>
      ) : null}
    </Card>
  )
}

export function Dashboard() {
  useTitle('Dashboard')
  const [days, setDays] = useState('30')
  const { data, loading, error } = useResource(
    ({ signal }) => api.get(`/dashboard/metrics.json?days=${days}`, { signal }),
    [days]
  )

  const totals = data?.totals
  const logs = data?.logs

  return (
    <Page>
      <PageHeader title="Dashboard" subtitle="Traffic and activity, straight from Ahoy.">
        <Field
          as="select"
          value={days}
          onChange={setDays}
          options={RANGES}
          inputClassName="w-auto"
          aria-label="Date range"
        />
      </PageHeader>

      <ErrorAlert error={error} className="mb-6" />

      {loading && !data ? (
        <Card><LoadingBlock label="Loading metrics…" /></Card>
      ) : totals ? (
        <div className="space-y-6">
          <div className="grid gap-4 grid-cols-2 lg:grid-cols-4">
            <StatTile label="Visits" value={totals.visits} hint={`${totals.visits_today} today`} />
            <StatTile label="Unique visitors" value={totals.visitors} />
            <StatTile label="Events" value={totals.events} hint={`${percent(totals.engaged_visits, totals.visits)} of visits engaged`} />
            <StatTile label="New users" value={totals.signups} hint={`${totals.total_users} total`} to="/users" />
          </div>

          {logs?.unresolved > 0 ? (
            <Link to="/logs" className="alert-error flex items-center justify-between gap-3 hover:opacity-90">
              <span>
                <strong>{logs.unresolved}</strong> unresolved {logs.unresolved === 1 ? 'log' : 'logs'}
                {logs.errors_24h > 0 ? ` · ${logs.errors_24h} error-level in the last 24h` : ''}
              </span>
              <span aria-hidden="true">→</span>
            </Link>
          ) : null}

          <VisitsChart series={data.visits_by_day ?? []} />

          <div className="grid gap-6 lg:grid-cols-2">
            <BreakdownList title="Top events" rows={data.top_events ?? []} labelKey="name" emptyText="No events recorded yet. Track one with Analytics.track." />
            <BreakdownList title="Top landing pages" rows={data.top_landing_pages ?? []} labelKey="page" emptyText="No visits recorded yet." />
            <BreakdownList title="Top referrers" rows={data.top_referrers ?? []} labelKey="domain" emptyText="No external referrers yet." />
            <BreakdownList title="Devices" rows={data.device_types ?? []} labelKey="type" emptyText="No visits recorded yet." />
          </div>

          <Card>
            <h2 className="section-title mb-4">Recent sign-ups</h2>
            {data.recent_signups?.length ? (
              <ul className="divide-y divide-line -my-2">
                {data.recent_signups.map((user) => (
                  <li key={user.id} className="py-3 flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <Link to={`/users/${user.slug ?? user.id}`} className="table-link block truncate">{user.name || user.email}</Link>
                      <p className="text-xs text-ink-muted truncate">{user.email}</p>
                    </div>
                    <time className="text-xs text-ink-muted shrink-0" dateTime={user.created_at}>
                      {new Date(user.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                    </time>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-ink-muted">Nobody has signed up in this period.</p>
            )}
          </Card>
        </div>
      ) : null}
    </Page>
  )
}
