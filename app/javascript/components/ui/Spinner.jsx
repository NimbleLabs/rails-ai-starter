import React from 'react'

export function Spinner({ className = 'w-5 h-5' }) {
  return (
    <span
      role="status"
      aria-label="Loading"
      className={`inline-block rounded-full border-2 border-primary border-r-transparent animate-spin ${className}`}
    />
  )
}

/** Full-page overlay used while the admin boots or saves. */
export function LoadingOverlay({ show }) {
  if (!show) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-canvas/60 backdrop-blur-sm" role="status" aria-live="polite">
      <Spinner className="w-10 h-10" />
      <span className="sr-only">Loading</span>
    </div>
  )
}

/** Inline block used inside a card/table while data loads. */
export function LoadingBlock({ label = 'Loading…' }) {
  return (
    <div className="flex items-center justify-center gap-3 py-12 text-ink-muted">
      <Spinner />
      <span>{label}</span>
    </div>
  )
}
