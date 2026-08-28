import React from 'react'
import { LoadingBlock } from './Spinner'

/**
 * The admin's one list primitive, built mobile-first.
 *
 * On `md` and up it renders a real <table>. Below that a table is unusable on a
 * phone, so each row becomes a stacked card: the column marked `primary` is the
 * card's heading, the rest become label/value pairs, and row actions move to a
 * footer. Defining columns as data (rather than hand-writing <td>s per page) is
 * what makes that switch possible at all.
 *
 *   <DataTable
 *     columns={[
 *       { key: 'title', header: 'Title', primary: true, render: (row) => <Link .../> },
 *       { key: 'author', header: 'Author' },
 *       { key: 'published', header: 'Status', render: (row) => <BoolBadge value={row.published} /> },
 *     ]}
 *     rows={posts}
 *     rowKey={(row) => row.id}
 *     actions={(row) => <Button size="sm" variant="ghost">Edit</Button>}
 *     empty="No articles yet."
 *   />
 */
export function DataTable({
  columns,
  rows,
  rowKey = (row, index) => row.id ?? index,
  actions,
  empty = 'Nothing here yet.',
  loading = false,
  caption,
}) {
  const cell = (column, row) => (column.render ? column.render(row) : row[column.key])
  const primary = columns.find((column) => column.primary) ?? columns[0]
  const secondary = columns.filter((column) => column !== primary)

  if (loading && !rows.length) {
    return (
      <div className="card-flush">
        <LoadingBlock />
      </div>
    )
  }

  if (!rows.length) {
    return (
      <div className="card-flush">
        <p className="empty-state">{empty}</p>
      </div>
    )
  }

  return (
    <>
      {/* Desktop / tablet: a real table */}
      <div className="card-flush overflow-x-auto hidden md:block">
        <table className="admin-table">
          {caption ? <caption className="sr-only">{caption}</caption> : null}
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column.key} className={column.headerClassName}>{column.header}</th>
              ))}
              {actions ? <th><span className="sr-only">Actions</span></th> : null}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, index) => (
              <tr key={rowKey(row, index)}>
                {columns.map((column) => (
                  <td key={column.key} className={column.className}>{cell(column, row)}</td>
                ))}
                {actions ? (
                  <td>
                    <div className="flex justify-end gap-1 whitespace-nowrap">{actions(row)}</div>
                  </td>
                ) : null}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile: one card per row */}
      <ul className="md:hidden space-y-3">
        {rows.map((row, index) => (
          <li key={rowKey(row, index)} className="card space-y-3">
            <div className="font-display font-bold text-ink break-words">{cell(primary, row)}</div>

            {secondary.length ? (
              <dl className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
                {secondary.map((column) => {
                  const value = cell(column, row)
                  if (value === null || value === undefined || value === '') return null
                  return (
                    <div key={column.key} className={column.wide ? 'col-span-2 min-w-0' : 'min-w-0'}>
                      <dt className="text-xs uppercase tracking-wide text-ink-muted">{column.header}</dt>
                      <dd className="text-ink break-words">{value}</dd>
                    </div>
                  )
                })}
              </dl>
            ) : null}

            {actions ? (
              <div className="flex flex-wrap gap-2 pt-1 border-t border-line -mx-6 px-6 pt-3">
                {actions(row)}
              </div>
            ) : null}
          </li>
        ))}
      </ul>
    </>
  )
}
