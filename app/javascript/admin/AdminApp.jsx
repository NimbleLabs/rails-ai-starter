import React from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'

import { AdminLayout } from './layout/AdminLayout'
import { Dashboard } from './pages/Dashboard'
import { UsersList } from './pages/users/UsersList'
import { UserDetails } from './pages/users/UserDetails'
import { ContactsList } from './pages/contacts/ContactsList'
import { EmailTemplates } from './pages/email/EmailTemplates'
import { EmailForm } from './pages/email/EmailForm'
import { PostsList } from './pages/articles/PostsList'
import { PostForm } from './pages/articles/PostForm'
import { PostDetails } from './pages/articles/PostDetails'
import { FunnelsList } from './pages/funnels/FunnelsList'
import { FunnelForm } from './pages/funnels/FunnelForm'
import { FunnelMetrics } from './pages/funnels/FunnelMetrics'
import { FeaturesList } from './pages/features/FeaturesList'
import { FeatureForm } from './pages/features/FeatureForm'
import { FeatureDetails } from './pages/features/FeatureDetails'
import { LogsList } from './pages/logs/LogsList'
import { LogDetails } from './pages/logs/LogDetails'
import { LogSubscriptions } from './pages/logs/LogSubscriptions'
import { NotFound } from './pages/NotFound'

/**
 * The admin SPA. Rails mounts this at /admin and has a catch-all route
 * (`get "admin/*other"`) so deep links and refreshes work.
 */
export default function AdminApp() {
  const currentUser = window.__currentUser ?? null

  return (
    <BrowserRouter basename="/admin">
      <Routes>
        <Route element={<AdminLayout currentUser={currentUser} />}>
          <Route index element={<Dashboard />} />

          <Route path="users" element={<UsersList />} />
          <Route path="users/:id" element={<UserDetails />} />

          <Route path="contacts" element={<ContactsList />} />

          <Route path="email-templates" element={<EmailTemplates />} />
          <Route path="emails/new" element={<EmailForm />} />
          <Route path="emails/:id/edit" element={<EmailForm />} />

          <Route path="articles" element={<PostsList />} />
          <Route path="articles/new" element={<PostForm />} />
          <Route path="articles/:id/edit" element={<PostForm />} />
          <Route path="articles/:id" element={<PostDetails />} />

          <Route path="funnels" element={<FunnelsList />} />
          <Route path="funnels/new" element={<FunnelForm />} />
          <Route path="funnels/:id/edit" element={<FunnelForm />} />
          <Route path="funnel-metrics" element={<FunnelMetrics />} />

          <Route path="features" element={<FeaturesList />} />
          <Route path="features/new" element={<FeatureForm />} />
          <Route path="features/:id/edit" element={<FeatureForm />} />
          <Route path="features/:id" element={<FeatureDetails />} />

          <Route path="logs" element={<LogsList />} />
          <Route path="logs/:id" element={<LogDetails />} />
          <Route path="log-notifications" element={<LogSubscriptions />} />

          {/* Old Vue-era URLs */}
          <Route path="home" element={<Navigate to="/" replace />} />
          <Route path="posts" element={<Navigate to="/articles" replace />} />

          <Route path="*" element={<NotFound />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
