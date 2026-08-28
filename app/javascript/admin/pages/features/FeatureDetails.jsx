import React from 'react'
import { useParams } from 'react-router-dom'

import { resource } from '~/lib/api'
import { useResource, useTitle } from '~/lib/hooks'
import { Button, Card, DetailList, EmptyState, ErrorAlert, LoadingBlock, Page, PageHeader } from '~/components/ui'
import { PriorityBadge, StatusBadge } from './FeaturesList'

const features = resource('/features')

function formatDate(value) {
  if (!value) return null
  return new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

/** A long free-text field. Rendered only when there is something to show. */
function TextSection({ title, body }) {
  if (!body) return null
  return (
    <Card>
      <h2 className="section-title mb-3">{title}</h2>
      <p className="text-sm text-ink whitespace-pre-line break-words">{body}</p>
    </Card>
  )
}

export function FeatureDetails() {
  const { id } = useParams()
  const { data: feature, loading, error } = useResource(({ signal }) => features.get(id, { signal }), [id])
  useTitle(feature?.title ?? 'Feature')

  return (
    <Page width="max-w-5xl">
      <PageHeader
        title={feature?.title ?? 'Feature'}
        subtitle={feature?.description || 'Roadmap item'}
        backTo="/features"
        backLabel="Back to features"
      >
        {feature ? <Button to={`/features/${feature.slug}/edit`}>Edit</Button> : null}
      </PageHeader>

      <ErrorAlert error={error} className="mb-6" />

      {loading && !feature ? (
        <Card><LoadingBlock label="Loading feature…" /></Card>
      ) : feature ? (
        <div className="space-y-6">
          <Card>
            <h2 className="section-title mb-4">Overview</h2>
            <DetailList
              items={[
                { label: 'Status', value: <StatusBadge status={feature.status} /> },
                { label: 'Priority', value: <PriorityBadge priority={feature.priority} /> },
                { label: 'Area', value: feature.area || '—' },
                { label: 'Order', value: feature.position ?? '—' },
                { label: 'Owner', value: feature.user?.name || feature.user?.email || 'Unknown' },
                { label: 'Slug', value: feature.slug },
                { label: 'Started', value: formatDate(feature.started_at) },
                { label: 'Completed', value: formatDate(feature.completed_at) },
                { label: 'Created', value: formatDate(feature.created_at) },
                { label: 'Updated', value: formatDate(feature.updated_at) },
              ]}
            />
          </Card>

          <TextSection title="Description" body={feature.description} />
          <TextSection title="Acceptance criteria" body={feature.acceptance_criteria} />
          <TextSection title="Plan" body={feature.plan} />
          <TextSection title="Implementation notes" body={feature.implementation_notes} />
        </div>
      ) : !error ? (
        <EmptyState title="Not found">That feature no longer exists.</EmptyState>
      ) : null}
    </Page>
  )
}
