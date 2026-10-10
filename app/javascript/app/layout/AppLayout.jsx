import React from 'react'
import { Outlet } from 'react-router-dom'
import { app } from '~/lib/app'

/**
 * User app shell: a simple top bar rather than the admin's sidebar, since a
 * product UI usually wants the full width — especially on a phone.
 */
export function AppLayout({ currentUser }) {
  return (
    <div className="min-h-screen bg-canvas">
      <header className="sticky top-0 z-30 border-b border-line bg-surface/90 backdrop-blur">
        <div className="max-w-5xl mx-auto flex items-center justify-between gap-3 px-4 sm:px-6 h-14">
          <a href="/" className="flex items-center gap-2 min-w-0">
            <span className="brand-mark w-7 h-7 text-[10px]" aria-hidden="true">{app.shortName}</span>
            <span className="font-display font-extrabold tracking-tight text-ink truncate">{app.name}</span>
          </a>
          <div className="flex items-center gap-3 text-sm">
            {currentUser?.admin ? <a href="/admin" className="text-ink-muted hover:text-primary">Admin</a> : null}
            <a href="/users/logout" data-turbo="false" className="text-ink-muted hover:text-primary">Sign out</a>
          </div>
        </div>
      </header>
      <main>
        <Outlet />
      </main>
    </div>
  )
}
