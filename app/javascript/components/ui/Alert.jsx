import React from 'react'

const TONES = {
  info: 'alert-info',
  success: 'alert-success',
  warning: 'alert-warning',
  error: 'alert-error',
}

export function Alert({ tone = 'info', children, className = '', onDismiss }) {
  if (!children) return null
  return (
    <div className={`${TONES[tone] ?? TONES.info} ${className} flex items-start gap-3`} role={tone === 'error' ? 'alert' : 'status'}>
      <div className="flex-1 min-w-0">{children}</div>
      {onDismiss ? (
        <button type="button" onClick={onDismiss} className="shrink-0 opacity-60 hover:opacity-100" aria-label="Dismiss">×</button>
      ) : null}
    </div>
  )
}

/** Renders an ApiError's messages (or any string/array) as an error alert. */
export function ErrorAlert({ error, className = '' }) {
  if (!error) return null
  const messages = Array.isArray(error) ? error : (error.messages ?? [error.message ?? String(error)])
  return (
    <Alert tone="error" className={className}>
      {messages.length === 1 ? (
        messages[0]
      ) : (
        <ul className="list-disc list-inside space-y-0.5">
          {messages.map((message, index) => <li key={index}>{message}</li>)}
        </ul>
      )}
    </Alert>
  )
}
