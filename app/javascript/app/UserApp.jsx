import React from 'react'
import { BrowserRouter, Route, Routes } from 'react-router-dom'

import { AppLayout } from './layout/AppLayout'
import { Home } from './pages/Home'

/**
 * The signed-in user-facing SPA, mounted by Rails at /app.
 *
 * Deliberately minimal — this is the starting point for a real product UI. It
 * shares the design tokens and the `~/components/ui` kit with the admin, so
 * anything built here matches the admin and the mobile app out of the box.
 */
export default function UserApp() {
  const currentUser = window.__currentUser ?? null

  return (
    <BrowserRouter basename="/app">
      <Routes>
        <Route element={<AppLayout currentUser={currentUser} />}>
          <Route index element={<Home currentUser={currentUser} />} />
          <Route path="*" element={<Home currentUser={currentUser} />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
