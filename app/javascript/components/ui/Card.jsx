import React from 'react'
import { Link } from 'react-router-dom'

export function Card({ className = '', children, ...props }) {
  return <div className={`card ${className}`} {...props}>{children}</div>
}

/** Card with no padding — for wrapping tables. */
export function CardFlush({ className = '', children, ...props }) {
  return <div className={`card-flush ${className}`} {...props}>{children}</div>
}

/**
 * A single dashboard number. Pass `to` to make the whole tile a link, and
 * tone="alert" to turn a non-zero value red (used for unresolved errors).
 */
export function StatTile({ label, value, hint, to, tone = 'default' }) {
  const isAlert = tone === 'alert' && Number(value) > 0
  const body = (
    <>
      <p className="stat-label">{label}</p>
      <p className={isAlert ? 'stat-value text-red-600' : 'stat-value'}>{value}</p>
      {hint ? <p className="text-xs text-ink-muted mt-1">{hint}</p> : null}
    </>
  )

  if (to) {
    return (
      <Link to={to} className="stat-tile block transition-colors hover:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40">
        {body}
      </Link>
    )
  }
  return <div className="stat-tile">{body}</div>
}
