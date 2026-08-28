import React, { useId } from 'react'

/**
 * Labelled form control. Wraps an input/select/textarea so every form in the
 * admin gets the same label, hint and error treatment without repeating markup.
 *
 *   <Field label="Title" value={title} onChange={setTitle} />
 *   <Field label="Status" as="select" value={s} onChange={setS} options={[...]} />
 *   <Field label="Body" as="textarea" rows={5} value={b} onChange={setB} />
 */
export function Field({
  label,
  as = 'input',
  type = 'text',
  value,
  onChange,
  hint,
  error,
  options,
  className = '',
  inputClassName = '',
  children,
  ...props
}) {
  const id = useId()
  const describedBy = [hint ? `${id}-hint` : null, error ? `${id}-error` : null].filter(Boolean).join(' ') || undefined
  const handle = (event) => onChange?.(as === 'input' && type === 'checkbox' ? event.target.checked : event.target.value)

  if (type === 'checkbox') {
    return (
      <div className={className}>
        <label htmlFor={id} className="flex items-center gap-2 text-sm text-ink cursor-pointer">
          <input id={id} type="checkbox" className="form-checkbox" checked={!!value} onChange={handle} aria-describedby={describedBy} {...props} />
          {label}
        </label>
        {hint ? <p id={`${id}-hint`} className="form-hint">{hint}</p> : null}
        {error ? <p id={`${id}-error`} className="form-hint text-red-600">{error}</p> : null}
      </div>
    )
  }

  const shared = {
    id,
    value: value ?? '',
    onChange: handle,
    className: `input-form-field ${inputClassName}`,
    'aria-describedby': describedBy,
    'aria-invalid': error ? true : undefined,
    ...props,
  }

  return (
    <div className={className}>
      {label ? <label htmlFor={id} className="form-label">{label}</label> : null}
      {as === 'select' ? (
        <select {...shared}>
          {children ?? options?.map((option) => {
            const [optionValue, optionLabel] = Array.isArray(option) ? option : [option, option]
            return <option key={optionValue} value={optionValue}>{optionLabel}</option>
          })}
        </select>
      ) : as === 'textarea' ? (
        <textarea {...shared} />
      ) : (
        <input type={type} {...shared} />
      )}
      {hint ? <p id={`${id}-hint`} className="form-hint">{hint}</p> : null}
      {error ? <p id={`${id}-error`} className="form-hint text-red-600">{error}</p> : null}
    </div>
  )
}

/** Filter/toolbar row above a list. Wraps and stays tappable on mobile. */
export function Toolbar({ children, className = '' }) {
  return <div className={`card flex flex-wrap items-end gap-3 sm:gap-4 mb-6 ${className}`}>{children}</div>
}

/** Definition list used on detail pages; single column on mobile. */
export function DetailList({ items }) {
  return (
    <dl className="grid gap-x-6 gap-y-4 sm:grid-cols-2 text-sm">
      {items.filter(Boolean).map((item) => (
        <div key={item.label} className={item.wide ? 'sm:col-span-2 min-w-0' : 'min-w-0'}>
          <dt className="text-ink-muted">{item.label}</dt>
          <dd className="font-medium text-ink break-words">{item.value ?? '—'}</dd>
        </div>
      ))}
    </dl>
  )
}
