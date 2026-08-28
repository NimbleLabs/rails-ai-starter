import React, { useEffect, useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { Sidebar } from './Sidebar'

/**
 * Admin shell. The sidebar is permanent from `lg` up and an off-canvas drawer
 * below it, behind a sticky top bar — on a phone a fixed 16rem sidebar would
 * eat most of the viewport.
 */
export function AdminLayout({ currentUser }) {
  const [menuOpen, setMenuOpen] = useState(false)
  const { pathname } = useLocation()

  // Close the drawer on navigation and lock background scroll while it's open.
  useEffect(() => { setMenuOpen(false) }, [pathname])
  useEffect(() => {
    if (!menuOpen) return undefined
    const onKey = (event) => { if (event.key === 'Escape') setMenuOpen(false) }
    document.addEventListener('keydown', onKey)
    const previous = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = previous
    }
  }, [menuOpen])

  return (
    <div className="min-h-screen bg-canvas">
      {/* Mobile top bar */}
      <header className="lg:hidden sticky top-0 z-30 flex items-center justify-between gap-3 px-4 h-14 bg-surface/90 backdrop-blur border-b border-line">
        <a href="/" className="flex items-center gap-2 min-w-0">
          <span className="brand-mark w-7 h-7 text-[10px]">ST</span>
          <span className="font-display font-extrabold tracking-tight text-ink truncate">Starter</span>
        </a>
        <button
          type="button"
          onClick={() => setMenuOpen(true)}
          className="p-2 -mr-2 rounded-xl text-ink-muted hover:text-primary focus:outline-none focus:ring-2 focus:ring-primary/40"
          aria-label="Open navigation"
          aria-expanded={menuOpen}
        >
          <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor" aria-hidden="true">
            <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
          </svg>
        </button>
      </header>

      {/* Mobile drawer */}
      {menuOpen ? (
        <div className="relative z-50 lg:hidden" role="dialog" aria-modal="true" aria-label="Navigation">
          <div className="fixed inset-0 bg-ink/50" onClick={() => setMenuOpen(false)} aria-hidden="true" />
          <div className="fixed inset-y-0 left-0 flex max-w-[85%]">
            <Sidebar onNavigate={() => setMenuOpen(false)} currentUser={currentUser} />
            <button
              type="button"
              onClick={() => setMenuOpen(false)}
              className="absolute top-3 -right-12 p-2 text-white/90 hover:text-white focus:outline-none"
              aria-label="Close navigation"
            >
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor" aria-hidden="true">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      ) : null}

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:flex-col">
        <Sidebar currentUser={currentUser} />
      </div>

      <main className="lg:pl-64">
        <Outlet />
      </main>
    </div>
  )
}
