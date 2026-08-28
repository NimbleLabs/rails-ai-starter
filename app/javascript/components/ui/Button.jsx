import React from 'react'
import { Link } from 'react-router-dom'

const VARIANTS = {
  primary: 'btn-primary',
  secondary: 'btn-secondary',
  outline: 'btn-outline',
  danger: 'btn-danger',
  ghost: 'btn-ghost',
}

const SIZES = { sm: 'btn-sm', md: '', lg: 'btn-lg' }

/**
 * One button, three shapes: a real <button>, a react-router <Link> (pass `to`),
 * or an <a> (pass `href`). Styling comes from the shared component classes in
 * app/assets/tailwind/application.css.
 */
export function Button({
  variant = 'primary',
  size = 'md',
  to,
  href,
  loading = false,
  disabled = false,
  className = '',
  children,
  ...props
}) {
  const classes = [VARIANTS[variant] ?? VARIANTS.primary, SIZES[size] ?? '', className]
    .filter(Boolean)
    .join(' ')

  const content = loading ? (
    <>
      <span className="inline-block w-4 h-4 rounded-full border-2 border-current border-r-transparent animate-spin" aria-hidden="true" />
      <span>Working…</span>
    </>
  ) : (
    children
  )

  if (to) return <Link to={to} className={classes} {...props}>{content}</Link>
  if (href) return <a href={href} className={classes} {...props}>{content}</a>

  return (
    <button className={classes} disabled={disabled || loading} {...props}>
      {content}
    </button>
  )
}
