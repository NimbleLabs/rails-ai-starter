import React, { useState } from 'react'

import { api } from '~/lib/api'
import { useResource, useTitle } from '~/lib/hooks'
import { Button, Card, ErrorAlert, Field, LoadingBlock, Page, PageHeader, StatTile, Toolbar } from '~/components/ui'

/**
 * GET /api/v1/funnels/metrics.json returns:
 *   { funnels: [{ id, name, slug }],                       // active funnels, for the filter
 *     metrics: { lead_page, book_call_page,
 *                order_page, order_completed_page },       // ahoy funnel_page_view counts
 *     conversion_rates: { lead_to_book_call, book_call_to_order,
 *                         order_to_completed, overall },   // percentages, 2dp, 0 when the
 *                                                          // denominator is 0
 *     filters: { funnel_slug, start_date, end_date } }
 *
 * The server can't distinguish "0% converted" from "nothing to divide by", so
 * every rate below is re-guarded against its own denominator and rendered as —.
 */

const EMPTY_METRICS = { lead_page: 0, book_call_page: 0, order_page: 0, order_completed_page: 0 }

const STAGES = [
  { key: 'lead_page', label: 'Lead page' },
  { key: 'book_call_page', label: 'Book call page' },
  { key: 'order_page', label: 'Order page' },
  { key: 'order_completed_page', label: 'Order completed' },
]

const RATES = [
  { key: 'lead_to_book_call', label: 'Lead → Book call', denominator: 'lead_page' },
  { key: 'book_call_to_order', label: 'Book call → Order', denominator: 'book_call_page' },
  { key: 'order_to_completed', label: 'Order → Completed', denominator: 'order_page' },
  { key: 'overall', label: 'Lead → Order completed', denominator: 'lead_page' },
]

function percentOf(part, whole) {
  if (!whole) return null
  return (part / whole) * 100
}

export function FunnelMetrics() {
  useTitle('Funnel metrics')

  const [funnelSlug, setFunnelSlug] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')

  const { data, loading, error } = useResource(({ signal }) => {
    const params = new URLSearchParams()
    if (funnelSlug) params.set('funnel_slug', funnelSlug)
    if (startDate) params.set('start_date', startDate)
    if (endDate) params.set('end_date', endDate)
    const query = params.toString()
    return api.get(`/api/v1/funnels/metrics.json${query ? `?${query}` : ''}`, { signal })
  }, [funnelSlug, startDate, endDate])

  const metrics = data?.metrics ?? EMPTY_METRICS
  const rates = data?.conversion_rates ?? {}
  const funnels = data?.funnels ?? []
  const leads = metrics.lead_page ?? 0

  const clearFilters = () => {
    setFunnelSlug('')
    setStartDate('')
    setEndDate('')
  }

  const hasFilters = !!(funnelSlug || startDate || endDate)

  return (
    <Page>
      <PageHeader
        title="Funnel metrics"
        subtitle="Page views at each stage and how many visitors move on."
        backTo="/funnels"
        backLabel="Back to funnels"
      />

      <Toolbar>
        <Field
          label="Funnel"
          as="select"
          value={funnelSlug}
          onChange={setFunnelSlug}
          options={[['', 'All funnels'], ...funnels.map((funnel) => [funnel.slug, funnel.name])]}
          className="min-w-0 flex-1 sm:flex-none"
          inputClassName="sm:w-auto"
        />
        <Field label="Start date" type="date" value={startDate} onChange={setStartDate} className="min-w-0 flex-1 sm:flex-none" />
        <Field label="End date" type="date" value={endDate} onChange={setEndDate} className="min-w-0 flex-1 sm:flex-none" />
        {hasFilters ? <Button variant="ghost" onClick={clearFilters}>Clear</Button> : null}
      </Toolbar>

      <ErrorAlert error={error} className="mb-6" />

      {loading && !data ? (
        <Card><LoadingBlock label="Loading metrics…" /></Card>
      ) : (
        <div className="space-y-6">
          <div className="grid gap-4 grid-cols-2 lg:grid-cols-4">
            {STAGES.map((stage) => {
              const share = percentOf(metrics[stage.key] ?? 0, leads)
              return (
                <StatTile
                  key={stage.key}
                  label={stage.label}
                  value={metrics[stage.key] ?? 0}
                  hint={stage.key === 'lead_page' || share === null ? undefined : `${Math.round(share)}% of leads`}
                />
              )
            })}
          </div>

          <Card>
            <h2 className="section-title mb-4">Conversion rates</h2>
            <ul className="space-y-3">
              {RATES.map((rate) => {
                // 0 views at the previous stage means the rate is undefined, not 0%.
                const measurable = (metrics[rate.denominator] ?? 0) > 0
                const value = Number(rates[rate.key] ?? 0)
                const width = measurable ? Math.min(100, Math.max(0, value)) : 0
                return (
                  <li key={rate.key}>
                    <div className="flex items-baseline justify-between gap-3 mb-1">
                      <span className="text-sm text-ink truncate min-w-0">{rate.label}</span>
                      <span className="text-sm font-medium text-ink-muted shrink-0 tabular-nums">
                        {measurable ? `${value}%` : '—'}
                      </span>
                    </div>
                    <div className="h-1.5 rounded-full bg-surface-muted overflow-hidden">
                      <div className="h-full rounded-full bg-primary" style={{ width: `${width}%` }} />
                    </div>
                  </li>
                )
              })}
            </ul>
            {!leads ? (
              <p className="text-sm text-ink-muted mt-4">
                No funnel page views recorded for this selection yet.
              </p>
            ) : null}
          </Card>
        </div>
      )}
    </Page>
  )
}
