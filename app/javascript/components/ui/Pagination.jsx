import React from 'react'
import { Button } from './Button'

/** Prev / next pager. Stacks on mobile so the buttons stay tappable. */
export function Pagination({ page, totalPages, total, onChange, className = '' }) {
  if (!totalPages || totalPages <= 1) return null
  return (
    <nav className={`card mt-6 flex flex-col sm:flex-row items-center justify-between gap-3 ${className}`} aria-label="Pagination">
      <Button variant="secondary" size="sm" disabled={page <= 1} onClick={() => onChange(page - 1)} className="w-full sm:w-auto">
        ← Previous
      </Button>
      <p className="text-sm text-ink-muted order-first sm:order-none">
        Page {page} of {totalPages}
        {typeof total === 'number' ? ` · ${total} total` : ''}
      </p>
      <Button variant="secondary" size="sm" disabled={page >= totalPages} onClick={() => onChange(page + 1)} className="w-full sm:w-auto">
        Next →
      </Button>
    </nav>
  )
}
