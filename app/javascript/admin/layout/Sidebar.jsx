import React from 'react'
import { NavLink, useLocation } from 'react-router-dom'
import { NAV_ITEMS } from './navItems'

function isActive(item, pathname) {
  if (item.exact) return pathname === item.to
  if (pathname.startsWith(item.to)) return true
  return (item.match ?? []).some((prefix) => pathname.startsWith(prefix))
}

export function Sidebar({ onNavigate, currentUser }) {
  const { pathname } = useLocation()

  return (
    <div className="w-64 h-full bg-surface border-r border-line flex flex-col">
      <div className="px-4 pt-5 pb-4">
        <a href="/" className="flex items-center gap-2">
          <span className="brand-mark w-8 h-8 text-xs">ST</span>
          <span className="font-display text-lg font-extrabold tracking-tight text-ink">Starter</span>
        </a>
      </div>

      <nav className="flex-1 px-2 space-y-1 overflow-y-auto pb-4" aria-label="Admin">
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            onClick={onNavigate}
            end={item.exact}
            className={`nav-link ${isActive(item, pathname) ? 'nav-link-active' : ''}`}
          >
            <svg className="h-4 w-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path strokeLinecap="round" strokeLinejoin="round" d={item.icon} />
            </svg>
            {item.label}
          </NavLink>
        ))}
      </nav>

      <div className="px-2 py-3 border-t border-line space-y-1">
        {currentUser?.email ? (
          <p className="px-3 py-1 text-xs text-ink-muted truncate" title={currentUser.email}>
            {currentUser.name || currentUser.email}
          </p>
        ) : null}
        <a href="/app" className="nav-link">
          <svg className="h-4 w-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" aria-hidden="true">
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 15 3 9m0 0 6-6M3 9h12a6 6 0 0 1 0 12h-3" />
          </svg>
          Back to app
        </a>
      </div>
    </div>
  )
}
