import React from 'react'
import { Card, Page, PageHeader } from '~/components/ui'

export function Home({ currentUser }) {
  return (
    <Page width="max-w-5xl">
      <PageHeader
        title={currentUser?.name ? `Welcome, ${currentUser.name}` : 'Welcome'}
        subtitle="This is the user-facing React app. Start building here."
      />
      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <h2 className="section-title mb-2">Where things live</h2>
          <p className="text-sm text-ink-muted">
            Screens go in <code className="text-primary">app/javascript/app/pages</code>, routed from{' '}
            <code className="text-primary">app/javascript/app/UserApp.jsx</code>.
          </p>
        </Card>
        <Card>
          <h2 className="section-title mb-2">Shared building blocks</h2>
          <p className="text-sm text-ink-muted">
            Import from <code className="text-primary">~/components/ui</code> and fetch with{' '}
            <code className="text-primary">~/lib/api</code> — the same kit the admin uses.
          </p>
        </Card>
      </div>
    </Page>
  )
}
