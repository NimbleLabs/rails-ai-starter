import React from 'react'

const TONES = {
  brand: 'badge-brand',
  gray: 'badge-gray',
  green: 'badge-green',
  red: 'badge-red',
  amber: 'badge-amber',
  blue: 'badge-blue',
}

export function Badge({ tone = 'gray', children, className = '' }) {
  return <span className={`${TONES[tone] ?? TONES.gray} ${className}`}>{children}</span>
}

/** Yes/no column helper used across the admin lists. */
export function BoolBadge({ value, yes = 'Yes', no = 'No' }) {
  return <Badge tone={value ? 'green' : 'gray'}>{value ? yes : no}</Badge>
}
