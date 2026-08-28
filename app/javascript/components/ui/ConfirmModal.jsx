import React, { useEffect, useRef } from 'react'
import { Button } from './Button'

/**
 * Destructive-action confirmation. Traps focus loosely (focuses the cancel
 * button), closes on Escape and on backdrop click, and locks body scroll —
 * which matters on mobile, where a scrolling background behind a modal is
 * disorienting.
 */
export function ConfirmModal({
  open = true,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  tone = 'primary',
  onConfirm,
  onCancel,
}) {
  const cancelRef = useRef(null)

  useEffect(() => {
    if (!open) return undefined
    cancelRef.current?.focus()
    const onKey = (event) => { if (event.key === 'Escape') onCancel?.() }
    document.addEventListener('keydown', onKey)
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = previousOverflow
    }
  }, [open, onCancel])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto" role="dialog" aria-modal="true" aria-labelledby="confirm-title">
      <div className="fixed inset-0 bg-ink/50" onClick={onCancel} aria-hidden="true" />
      <div className="relative flex min-h-full items-end sm:items-center justify-center p-4">
        <div className="card-flush w-full sm:max-w-lg relative">
          <div className="p-6">
            <div className="flex items-start gap-4">
              <div
                className={`shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${
                  tone === 'danger' ? 'bg-red-100 text-red-600' : 'bg-primary/10 text-primary'
                }`}
                aria-hidden="true"
              >
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
                </svg>
              </div>
              <div className="min-w-0">
                <h3 id="confirm-title" className="section-title">{title}</h3>
                {message ? <p className="text-sm text-ink-muted mt-1">{message}</p> : null}
              </div>
            </div>
          </div>
          <div className="bg-surface-muted border-t border-line px-6 py-4 flex flex-col-reverse sm:flex-row sm:justify-end gap-3">
            <Button ref={cancelRef} variant="secondary" onClick={onCancel} className="w-full sm:w-auto">{cancelText}</Button>
            <Button variant={tone === 'danger' ? 'danger' : 'primary'} onClick={onConfirm} className="w-full sm:w-auto">{confirmText}</Button>
          </div>
        </div>
      </div>
    </div>
  )
}
