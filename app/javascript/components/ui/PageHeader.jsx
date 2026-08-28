import React from 'react'
import { Link } from 'react-router-dom'

/** Page title + optional subtitle and actions. Actions wrap below on mobile. */
export function PageHeader({ title, subtitle, backTo, backLabel = 'Back', children }) {
  return (
    <>
      {backTo ? (
        <Link to={backTo} className="inline-block text-sm text-ink-muted hover:text-primary mb-4">
          ← {backLabel}
        </Link>
      ) : null}
      <div className="page-header">
        <div className="min-w-0">
          <h1 className="page-title break-words">{title}</h1>
          {subtitle ? <p className="page-subtitle">{subtitle}</p> : null}
        </div>
        {children ? <div className="flex flex-wrap gap-2">{children}</div> : null}
      </div>
    </>
  )
}

/** Page shell: consistent padding and max width across every admin page. */
export function Page({ width = 'max-w-7xl', children }) {
  return <div className={`p-4 sm:p-6 lg:p-10 ${width} mx-auto`}>{children}</div>
}

export function EmptyState({ title, children }) {
  return (
    <div className="card text-center py-12">
      {title ? <h3 className="section-title mb-2">{title}</h3> : null}
      <div className="text-ink-muted max-w-md mx-auto">{children}</div>
    </div>
  )
}
