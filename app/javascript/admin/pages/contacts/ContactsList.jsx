import React, { useMemo, useState } from 'react'

import { api } from '~/lib/api'
import { useResource, useTitle } from '~/lib/hooks'
import { DataTable, ErrorAlert, Field, Page, PageHeader, Toolbar } from '~/components/ui'

function formatDate(value) {
  if (!value) return '—'
  return new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

export function ContactsList() {
  useTitle('Contacts')
  const [query, setQuery] = useState('')
  const { data, loading, error } = useResource(({ signal }) => api.get('/contacts.json', { signal }), [])

  const contacts = useMemo(() => (Array.isArray(data) ? data : []), [data])

  // /contacts.json takes no search param, so filter the loaded array.
  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase()
    if (!needle) return contacts
    return contacts.filter((contact) =>
      ['name', 'email', 'phone', 'company', 'message']
        .map((key) => contact[key] ?? '')
        .join(' ')
        .toLowerCase()
        .includes(needle)
    )
  }, [contacts, query])

  return (
    <Page>
      <PageHeader title="Contacts" subtitle="Leads and newsletter sign-ups captured from the site." />

      <ErrorAlert error={error} className="mb-6" />

      <Toolbar>
        <Field
          label="Search"
          type="search"
          value={query}
          onChange={setQuery}
          placeholder="Name, email, company or message"
          className="w-full sm:w-auto sm:flex-1"
        />
        <p className="text-sm text-ink-muted pb-2">
          {filtered.length === contacts.length
            ? `${contacts.length} ${contacts.length === 1 ? 'contact' : 'contacts'}`
            : `${filtered.length} of ${contacts.length}`}
        </p>
      </Toolbar>

      <DataTable
        columns={[
          { key: 'name', header: 'Name', primary: true, render: (row) => row.name || '—' },
          {
            key: 'email',
            header: 'Email',
            render: (row) =>
              row.email ? <a href={`mailto:${row.email}`} className="table-link break-words">{row.email}</a> : '—',
          },
          {
            key: 'phone',
            header: 'Phone',
            render: (row) =>
              row.phone ? <a href={`tel:${row.phone}`} className="table-link whitespace-nowrap">{row.phone}</a> : '—',
          },
          { key: 'company', header: 'Company', render: (row) => row.company || '—' },
          { key: 'budget_range', header: 'Budget', render: (row) => row.budget_range || '—' },
          { key: 'created_at', header: 'Received', render: (row) => formatDate(row.created_at) },
          {
            key: 'message',
            header: 'Message',
            wide: true,
            render: (row) =>
              row.message ? (
                <span className="block break-words line-clamp-2" title={row.message}>{row.message}</span>
              ) : (
                '—'
              ),
          },
        ]}
        rows={filtered}
        rowKey={(row) => row.id}
        empty={query ? `No contact matches “${query}”.` : 'No contacts yet.'}
        loading={loading}
        caption="Contacts submitted through the site"
      />
    </Page>
  )
}
