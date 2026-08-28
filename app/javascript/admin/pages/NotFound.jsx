import React from 'react'
import { Button, Page, PageHeader, EmptyState } from '~/components/ui'

export function NotFound() {
  return (
    <Page width="max-w-3xl">
      <PageHeader title="Page not found" subtitle="That admin page doesn't exist." />
      <EmptyState>
        <Button to="/">Back to dashboard</Button>
      </EmptyState>
    </Page>
  )
}
