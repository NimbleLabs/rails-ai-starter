import React, { useState } from 'react'

import { api } from '~/lib/api'
import { useResource, useTitle } from '~/lib/hooks'
import {
  Alert, Badge, Button, Card, DataTable, EmptyState, ErrorAlert, LoadingBlock, Page, PageHeader, StatTile,
} from '~/components/ui'

/** Check status → badge tone and glyph. Status is never color alone. */
const STATUS = {
  pass: { tone: 'green', glyph: '✓', label: 'Pass' },
  warn: { tone: 'amber', glyph: '!', label: 'Check' },
  fail: { tone: 'red', glyph: '✗', label: 'Fail' },
}

const FILES_SHOWN = 10

function formatDate(value, withTime = true) {
  if (!value) return '—'
  const options = withTime
    ? { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }
    : { month: 'short', day: 'numeric' }
  return new Date(value).toLocaleString('en-US', options)
}

/** One decimal, matching the check details the report's Ruby side writes ("83.0%"). */
function pct(value) {
  return value === null || value === undefined ? '—' : `${Number(value).toFixed(1)}%`
}

function StatusBadge({ status }) {
  const { tone, glyph, label } = STATUS[status] ?? STATUS.warn
  return <Badge tone={tone}><span aria-hidden="true" className="mr-1">{glyph}</span>{label}</Badge>
}

/** One ratio against its limits: a track, a fill, and hairlines at the minimum and target. */
function Meter({ value, minimum, target, label }) {
  const clamp = (n) => Math.max(0, Math.min(100, n ?? 0))
  return (
    <div
      className="relative h-2 rounded-full bg-surface-muted"
      role="meter"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={value ?? 0}
    >
      <div className="h-full rounded-full bg-primary" style={{ width: `${clamp(value)}%` }} />
      {[minimum, target].filter((mark) => mark !== undefined).map((mark) => (
        <div key={mark} className="absolute -top-1 -bottom-1 w-px bg-ink-muted" style={{ left: `${clamp(mark)}%` }} />
      ))}
    </div>
  )
}

function Banner({ report, onlyFailing }) {
  const tests = report.tests
  if (report.status === 'failing') {
    return (
      <Alert tone="error">
        <strong><span aria-hidden="true">✗ </span>Failing.</strong>{' '}
        {onlyFailing.map((check) => check.label).join(', ')} {onlyFailing.length === 1 ? 'needs' : 'need'} attention.
      </Alert>
    )
  }
  if (report.status === 'stale') {
    return (
      <Alert tone="warning">
        <strong><span aria-hidden="true">! </span>Out of date.</strong>{' '}
        The suite passed, but {report.changed_count} source {report.changed_count === 1 ? 'file has' : 'files have'} changed
        since it ran, so this report no longer describes the running code.
      </Alert>
    )
  }
  return (
    <Alert tone="success">
      <strong><span aria-hidden="true">✓ </span>All green.</strong>{' '}
      {tests?.count} tests pass with {pct(report.coverage?.line)} line coverage, and the report matches the running code.
    </Alert>
  )
}

function Checks({ checks }) {
  return (
    <Card>
      <h2 className="section-title mb-4">Checks</h2>
      <ul className="divide-y divide-line -my-3">
        {checks.map((check) => (
          <li key={check.key} className="py-3 flex items-start gap-3">
            <div className="shrink-0 pt-0.5"><StatusBadge status={check.status} /></div>
            <div className="min-w-0">
              <p className="font-medium text-ink">{check.label}</p>
              <p className="text-sm text-ink-muted break-words">{check.detail}</p>
            </div>
          </li>
        ))}
      </ul>
    </Card>
  )
}

function Coverage({ coverage, thresholds }) {
  const groups = coverage.groups ?? []
  return (
    <Card>
      <h2 className="section-title mb-1">Line coverage</h2>
      <p className="text-sm text-ink-muted mb-4">
        Marks at the {thresholds.minimum_line_coverage}% minimum and the {thresholds.target_line_coverage}% target.
      </p>
      <div className="flex items-baseline justify-between gap-3 mb-2">
        <span className="font-display text-3xl font-extrabold text-ink">{pct(coverage.line)}</span>
        <span className="text-sm text-ink-muted text-right">
          {coverage.lines ? `${coverage.lines.covered} of ${coverage.lines.total} lines` : null}
        </span>
      </div>
      <Meter
        value={coverage.line}
        minimum={thresholds.minimum_line_coverage}
        target={thresholds.target_line_coverage}
        label="Line coverage"
      />

      {groups.length ? (
        <ul className="space-y-3 mt-6">
          {groups.map((group) => (
            <li key={group.name}>
              <div className="flex items-baseline justify-between gap-3 mb-1">
                <span className="text-sm text-ink truncate min-w-0">
                  {group.name} <span className="text-ink-muted">· {group.files} {group.files === 1 ? 'file' : 'files'}</span>
                </span>
                <span className="text-sm font-medium text-ink-muted shrink-0 tabular-nums">{pct(group.line)}</span>
              </div>
              <Meter value={group.line} label={`${group.name} line coverage`} />
            </li>
          ))}
        </ul>
      ) : null}
    </Card>
  )
}

function Problems({ problems }) {
  if (!problems?.length) return null
  return (
    <Card>
      <h2 className="section-title mb-4">Failing and skipped tests</h2>
      <ul className="space-y-4">
        {problems.map((problem) => (
          <li key={`${problem.name}-${problem.location}`} className="min-w-0">
            <div className="flex flex-wrap items-center gap-2 mb-1">
              <Badge tone={problem.kind === 'skip' ? 'amber' : 'red'}>{problem.kind}</Badge>
              <span className="font-medium text-ink break-all">{problem.name}</span>
            </div>
            <p className="text-xs text-ink-muted break-all mb-2">{problem.location}</p>
            <pre className="panel-muted text-xs text-ink whitespace-pre-wrap break-words">{problem.message}</pre>
          </li>
        ))}
      </ul>
    </Card>
  )
}

function ChangedFiles({ changes, total }) {
  const rows = [
    ...changes.modified.map((path) => ({ path, change: 'modified' })),
    ...changes.added.map((path) => ({ path, change: 'added' })),
    ...changes.removed.map((path) => ({ path, change: 'removed' })),
  ]
  if (!rows.length) return null
  return (
    <Card>
      <h2 className="section-title mb-1">Changed since this run</h2>
      <p className="text-sm text-ink-muted mb-4">
        {total > rows.length ? `The first ${rows.length} of ${total} files. ` : ''}
        These differ from the files the suite ran against.
      </p>
      <ul className="space-y-2">
        {rows.map((row) => (
          <li key={row.path} className="flex items-center gap-2 min-w-0">
            <Badge tone={row.change === 'removed' ? 'red' : row.change === 'added' ? 'blue' : 'amber'}>{row.change}</Badge>
            <code className="text-sm text-ink break-all">{row.path}</code>
          </li>
        ))}
      </ul>
    </Card>
  )
}

function Files({ files, minimum }) {
  const [showAll, setShowAll] = useState(false)
  const sorted = [...files].sort((a, b) => (a.line ?? 0) - (b.line ?? 0) || b.missed - a.missed)
  const rows = showAll ? sorted : sorted.slice(0, FILES_SHOWN)

  return (
    <section>
      <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-2 mb-3">
        <div>
          <h2 className="section-title">Least-covered files</h2>
          <p className="text-sm text-ink-muted">Where a new test would do the most good.</p>
        </div>
        {files.length > FILES_SHOWN ? (
          <Button size="sm" variant="ghost" onClick={() => setShowAll(!showAll)}>
            {showAll ? 'Show fewer' : `Show all ${files.length} files`}
          </Button>
        ) : null}
      </div>
      <DataTable
        caption="Coverage by file"
        rowKey={(row) => row.path}
        rows={rows}
        empty="No files were measured."
        columns={[
          { key: 'path', header: 'File', primary: true, render: (row) => <code className="text-sm break-all">{row.path}</code> },
          {
            key: 'line',
            header: 'Lines',
            render: (row) => (
              <div className="flex items-center gap-2 min-w-32">
                <span className={`tabular-nums w-14 shrink-0 ${row.line < minimum ? 'font-semibold text-ink' : 'text-ink-muted'}`}>{pct(row.line)}</span>
                <div className="flex-1"><Meter value={row.line} label={`${row.path} line coverage`} /></div>
              </div>
            ),
          },
          { key: 'branch', header: 'Branches', render: (row) => <span className="tabular-nums">{pct(row.branch)}</span> },
          { key: 'missed', header: 'Untested lines', render: (row) => <span className="tabular-nums">{row.missed} of {row.lines}</span> },
        ]}
      />
    </section>
  )
}

function TestsByType({ byType }) {
  const rows = Object.entries(byType ?? {}).sort((a, b) => b[1] - a[1])
  const max = Math.max(1, ...rows.map(([, count]) => count))
  return (
    <Card>
      <h2 className="section-title mb-4">Tests by type</h2>
      {rows.length ? (
        <ul className="space-y-3">
          {rows.map(([type, count]) => (
            <li key={type}>
              <div className="flex items-baseline justify-between gap-3 mb-1">
                <span className="text-sm text-ink capitalize">{type}</span>
                <span className="text-sm font-medium text-ink-muted tabular-nums">{count}</span>
              </div>
              <div className="h-1.5 rounded-full bg-surface-muted overflow-hidden">
                <div className="h-full rounded-full bg-primary" style={{ width: `${(count / max) * 100}%` }} />
              </div>
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-sm text-ink-muted">No tests recorded.</p>
      )}
    </Card>
  )
}

function SlowestTests({ slowest }) {
  return (
    <Card>
      <h2 className="section-title mb-4">Slowest tests</h2>
      {slowest?.length ? (
        <ul className="divide-y divide-line -my-3">
          {slowest.map((test) => (
            <li key={`${test.name}-${test.location}`} className="py-3 flex items-start justify-between gap-3">
              <div className="min-w-0">
                <p className="text-sm text-ink break-all">{test.name}</p>
                <p className="text-xs text-ink-muted break-all">{test.location}</p>
              </div>
              <span className="text-sm font-medium text-ink-muted tabular-nums shrink-0">{test.time}s</span>
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-sm text-ink-muted">No timings recorded.</p>
      )}
    </Card>
  )
}

/** Line coverage of each committed report, oldest first, ending with this one. */
function History({ report }) {
  const points = [
    ...[...(report.history ?? [])].reverse(),
    { commit: 'this report', committed_at: report.generated_at, tests: report.tests?.count, line: report.coverage?.line, status: report.status },
  ].filter((point) => point.line !== null && point.line !== undefined)

  if (points.length < 2) {
    return (
      <Card>
        <h2 className="section-title mb-1">History</h2>
        <p className="text-sm text-ink-muted">
          Each committed report adds a point here, so a trend appears from the second commit on.
        </p>
      </Card>
    )
  }

  const first = points[0]
  const last = points[points.length - 1]
  return (
    <Card>
      <h2 className="section-title mb-1">History</h2>
      <p className="text-sm text-ink-muted mb-4">
        Line coverage across the last {points.length} reports: {pct(first.line)} → {pct(last.line)},
        and {first.tests ?? '—'} → {last.tests ?? '—'} tests.
      </p>
      <div className="flex items-end justify-between gap-0.5 h-32" role="img" aria-label={`Line coverage from ${pct(first.line)} to ${pct(last.line)}`}>
        {points.map((point, index) => (
          <div
            key={`${point.commit}-${index}`}
            className="flex-1 min-w-px max-w-6 bg-primary/70 hover:bg-primary rounded-t-sm transition-colors"
            style={{ height: `${Math.max(2, point.line)}%` }}
            title={`${point.commit} · ${formatDate(point.committed_at, false)}: ${pct(point.line)} of lines, ${point.tests ?? '—'} tests`}
          />
        ))}
      </div>
      <div className="flex justify-between text-xs text-ink-muted mt-2">
        <span>{formatDate(first.committed_at, false)}</span>
        <span>{formatDate(last.committed_at, false)}</span>
      </div>
    </Card>
  )
}

/** RuboCop offenses and Brakeman warnings, when there are any to list. */
function Findings({ title, items, describe }) {
  if (!items?.length) return null
  return (
    <Card>
      <h2 className="section-title mb-4">{title}</h2>
      <ul className="space-y-3">
        {items.map((item, index) => (
          <li key={index} className="min-w-0">
            <p className="text-sm text-ink break-words">{describe(item)}</p>
            <p className="text-xs text-ink-muted break-all">{item.path}{item.line ? `:${item.line}` : ''}</p>
          </li>
        ))}
      </ul>
    </Card>
  )
}

function NoReport({ command, path }) {
  return (
    <EmptyState title="No report yet">
      <p className="mb-3">
        Run <code className="text-ink">{command}</code> on your machine. It runs every test with coverage, plus
        RuboCop and Brakeman, and writes <code className="text-ink">{path}</code>.
      </p>
      <p>Commit that file with your change. It deploys with the code it tested, and this page reads it.</p>
    </EmptyState>
  )
}

export function Quality() {
  useTitle('Quality')
  const { data, loading, error } = useResource(({ signal }) => api.get('/quality.json', { signal }))
  const report = data?.report

  return (
    <Page>
      <PageHeader
        title="Quality"
        subtitle={report ? `From the ${data.command} run on ${formatDate(report.generated_at)}.` : 'How well tested this app is.'}
      />

      <ErrorAlert error={error ?? data?.error} className="mb-6" />

      {loading && !data ? (
        <Card><LoadingBlock label="Loading the report…" /></Card>
      ) : report ? (
        <div className="space-y-6">
          <Banner report={report} onlyFailing={report.checks.filter((check) => check.status === 'fail')} />

          <div className="grid gap-4 grid-cols-2 lg:grid-cols-4">
            <StatTile label="Tests" value={report.tests?.count ?? '—'} hint={report.tests ? `${report.tests.assertions} assertions · ${report.tests.duration}s` : null} />
            <StatTile
              label="Failing"
              value={report.tests ? report.tests.failures + report.tests.errors : '—'}
              tone="alert"
              hint={report.tests ? `${report.tests.skips} skipped` : null}
            />
            <StatTile label="Line coverage" value={pct(report.coverage?.line)} hint={`Target ${report.thresholds.target_line_coverage}%`} />
            <StatTile
              label="Branch coverage"
              value={pct(report.coverage?.branch)}
              hint={report.coverage?.branches ? `${report.coverage.branches.covered} of ${report.coverage.branches.total} branches` : null}
            />
          </div>

          <div className="grid gap-6 lg:grid-cols-2 items-start">
            <Checks checks={report.checks} />
            <div className="space-y-6">
              {report.coverage ? <Coverage coverage={report.coverage} thresholds={report.thresholds} /> : null}
              <TestsByType byType={report.tests?.by_type} />
            </div>
          </div>

          <Problems problems={report.tests?.problems} />
          <ChangedFiles changes={report.changes} total={report.changed_count} />
          <Findings
            title="RuboCop offenses"
            items={report.lint?.listed}
            describe={(offense) => `${offense.cop}: ${offense.message}`}
          />
          <Findings
            title="Brakeman warnings"
            items={report.security?.listed}
            describe={(warning) => `${warning.type} (${warning.confidence}): ${warning.message}`}
          />

          {report.coverage?.files ? <Files files={report.coverage.files} minimum={report.thresholds.minimum_line_coverage} /> : null}

          <div className="grid gap-6 lg:grid-cols-2 items-start">
            <History report={report} />
            <SlowestTests slowest={report.tests?.slowest} />
          </div>
        </div>
      ) : data ? (
        <NoReport command={data.command} path={data.path} />
      ) : null}
    </Page>
  )
}
