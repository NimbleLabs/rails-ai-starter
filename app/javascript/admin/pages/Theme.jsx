import React, { useEffect, useMemo, useState } from 'react'

import { api } from '~/lib/api'
import { useMutation, useResource, useTitle } from '~/lib/hooks'
import { Alert, Button, Card, ErrorAlert, Field, LoadingBlock, Page, PageHeader } from '~/components/ui'

const HEX = /^#[0-9a-f]{6}$/i
const CATEGORY_LABELS = { sans: 'Sans serif', serif: 'Serif' }
const CORNER_LABELS = { sharp: 'Sharp', soft: 'Soft', round: 'Round' }

const sameTheme = (a, b) =>
  ['display_font', 'body_font', 'primary', 'secondary', 'corners']
    .every((key) => String(a?.[key] ?? '').toLowerCase() === String(b?.[key] ?? '').toLowerCase())

/** Loads the Google Fonts the preview needs, replacing the previous request. */
function usePreviewFonts(url) {
  useEffect(() => {
    if (!url) return
    let link = document.getElementById('theme-preview-fonts')
    if (!link) {
      link = document.createElement('link')
      link.id = 'theme-preview-fonts'
      link.rel = 'stylesheet'
      document.head.appendChild(link)
    }
    link.href = url
  }, [url])
}

/** Asks the server to derive the tokens for a draft (Ruby owns the color math), debounced. */
function usePreview(draft, initial) {
  const [preview, setPreview] = useState(initial)
  const [lastGood, setLastGood] = useState(initial)

  // The saved theme's preview arrives with the page data, after the first render.
  useEffect(() => {
    if (!initial) return
    setPreview(initial)
    setLastGood(initial)
  }, [initial])

  useEffect(() => {
    if (!draft) return undefined
    const controller = new AbortController()
    const timer = setTimeout(async () => {
      try {
        const result = await api.post('/theme/preview.json', { config: draft }, { signal: controller.signal })
        setPreview(result)
        if (result.css_variables) setLastGood(result)
      } catch (error) {
        if (error.name !== 'AbortError') setPreview((current) => ({ ...current, errors: [error.message] }))
      }
    }, 200)
    return () => { clearTimeout(timer); controller.abort() }
  }, [draft])

  return { preview, lastGood }
}

function PresetCard({ preset, selected, onSelect }) {
  const { theme } = preset
  return (
    <button
      type="button"
      onClick={() => onSelect(theme)}
      aria-pressed={selected}
      className={`card text-left p-4 transition-colors hover:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40 ${selected ? 'border-primary ring-2 ring-primary/30' : ''}`}
    >
      <div className="flex items-center gap-2 mb-2">
        <span className="h-5 w-5 rounded-full border border-line" style={{ backgroundColor: theme.primary }} />
        <span className="h-5 w-5 rounded-full border border-line" style={{ backgroundColor: theme.secondary }} />
        <span className="font-semibold text-ink truncate">{preset.name}</span>
      </div>
      <p className="text-xs text-ink-muted mb-1">{theme.display_font} / {theme.body_font} · {CORNER_LABELS[theme.corners] ?? theme.corners}</p>
      {preset.description ? <p className="text-sm text-ink-muted line-clamp-2">{preset.description}</p> : null}
    </button>
  )
}

function FontSelect({ label, value, onChange, fonts, bodyOnly = false, hint }) {
  const groups = Object.entries(CATEGORY_LABELS).map(([category, groupLabel]) => ({
    label: groupLabel,
    fonts: fonts.filter((font) => font.category === category && !(bodyOnly && font.display_only)),
  }))
  return (
    <Field label={label} as="select" value={value} onChange={onChange} hint={hint}>
      {groups.map((group) => (
        <optgroup key={group.label} label={group.label}>
          {group.fonts.map((font) => (
            <option key={font.family} value={font.family}>
              {font.family}{!bodyOnly && font.display_only ? ' (headings only)' : ''}
            </option>
          ))}
        </optgroup>
      ))}
    </Field>
  )
}

function ColorField({ label, value, onChange, hint }) {
  return (
    <div>
      <span className="form-label">{label}</span>
      <div className="flex items-center gap-3">
        <input
          type="color"
          value={HEX.test(value) ? value : '#000000'}
          onChange={(event) => onChange(event.target.value)}
          className="h-10 w-12 shrink-0 cursor-pointer rounded-field border border-line bg-surface p-1"
          aria-label={`${label} picker`}
        />
        <Field value={value} onChange={onChange} className="flex-1 min-w-0" aria-label={`${label} hex`} spellCheck={false} />
      </div>
      {hint ? <p className="form-hint">{hint}</p> : null}
    </div>
  )
}

function CornerChoice({ corners, value, onChange }) {
  return (
    <fieldset>
      <legend className="form-label">Corners</legend>
      <div className="grid grid-cols-3 gap-2">
        {corners.map((corner) => (
          <label
            key={corner}
            className={`flex min-h-10 cursor-pointer items-center justify-center gap-2 border px-3 py-2 text-sm font-medium transition-colors ${value === corner ? 'border-primary bg-primary/10 text-primary' : 'border-line text-ink-muted hover:bg-primary/5'}`}
            style={{ borderRadius: corner === 'sharp' ? '0.375rem' : corner === 'soft' ? '0.75rem' : '9999px' }}
          >
            <input type="radio" name="corners" value={corner} checked={value === corner} onChange={() => onChange(corner)} className="sr-only" />
            {CORNER_LABELS[corner] ?? corner}
          </label>
        ))}
      </div>
    </fieldset>
  )
}

/**
 * Tailwind resolves its --color-* / --font-* / --radius-* aliases once, at the
 * page root, so setting --theme-* on an element alone changes nothing under it.
 * Re-declaring the aliases here makes them resolve against this element's
 * variables (and, in the dark sample, the .dark neutrals).
 */
const ALIASES = {
  '--color-primary': 'var(--theme-primary)',
  '--color-primary-hover': 'var(--theme-primary-hover)',
  '--color-on-primary': 'var(--theme-on-primary)',
  '--color-secondary': 'var(--theme-secondary)',
  '--color-canvas': 'var(--theme-background)',
  '--color-surface': 'var(--theme-surface)',
  '--color-surface-muted': 'var(--theme-surface-muted)',
  '--color-ink': 'var(--theme-text)',
  '--color-ink-muted': 'var(--theme-text-muted)',
  '--color-line': 'var(--theme-line)',
  '--font-display': 'var(--theme-display-font)',
  '--font-sans': 'var(--theme-body-font)',
  '--radius-card': 'var(--theme-border-radius)',
  '--radius-control': 'var(--theme-control-radius)',
  '--radius-field': 'var(--theme-field-radius)',
  fontFamily: 'var(--theme-body-font)',
}

/** Real component classes under the draft's variables, in light or dark mode. */
function Sample({ variables, dark, config }) {
  const style = { ...variables.light, ...(dark ? variables.dark : {}), ...ALIASES }
  return (
    <div className={`${dark ? 'dark ' : ''}bg-canvas border border-line rounded-card p-5 space-y-4 min-w-0`} style={style} aria-hidden="true">
      <div className="flex items-center gap-2 min-w-0">
        <span className="brand-mark w-8 h-8 text-xs">{config.short_name || '?'}</span>
        <span className="font-display font-extrabold text-lg text-ink truncate">{config.name || 'Your app'}</span>
      </div>
      <h2 className="font-display text-2xl text-ink break-words">Headings set in {config.theme.display_font}</h2>
      <p className="text-sm text-ink-muted">
        Body text set in {config.theme.body_font}. {config.tagline}
      </p>
      <div className="flex flex-wrap gap-2">
        <span className="btn-primary">Primary</span>
        <span className="btn-secondary">Secondary</span>
        <span className="btn-outline">Outline</span>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <span className="badge-brand">Badge</span>
        <span className="table-link">A link</span>
      </div>
      <div className="input-form-field text-ink-muted">A form field</div>
      <div className="alert-info">Messages and highlights use the primary.</div>
      <div className="h-2 rounded-full bg-gradient-to-r from-primary to-secondary" />
    </div>
  )
}

export function Theme() {
  useTitle('Theme')
  const { data, loading, error } = useResource(({ signal }) => api.get('/theme.json', { signal }))
  const [draft, setDraft] = useState(null)
  const [copied, setCopied] = useState(false)

  useEffect(() => { if (data) setDraft(data.config) }, [data])

  const { preview, lastGood } = usePreview(draft, data?.preview)
  usePreviewFonts(lastGood?.fonts_url)

  const save = useMutation((config) => api.put('/theme.json', { config }))

  const dirty = useMemo(() => data && draft && JSON.stringify(draft) !== JSON.stringify(data.config), [data, draft])
  const errors = preview?.errors ?? []

  const set = (key) => (value) => setDraft((current) => ({ ...current, [key]: value }))
  const setTheme = (key) => (value) => setDraft((current) => ({ ...current, theme: { ...current.theme, [key]: value } }))

  const onSave = async () => {
    // Every page renders the theme server-side, so reload to see it everywhere.
    if (await save.run(draft)) window.location.reload()
  }

  const onCopy = async () => {
    try {
      await navigator.clipboard.writeText(preview.yaml)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      document.getElementById('theme-yaml')?.setAttribute('open', '')
    }
  }

  if (loading && !data) return <Page><Card><LoadingBlock label="Loading the theme…" /></Card></Page>
  if (!draft) return <Page><ErrorAlert error={error} /></Page>

  const contrast = preview?.contrast

  return (
    <Page>
      <PageHeader title="Theme" subtitle={`How ${data.config.name} looks across the site, this admin, email and the mobile app.`}>
        {dirty ? <Button variant="ghost" onClick={() => setDraft(data.config)}>Reset</Button> : null}
        <Button variant="secondary" onClick={onCopy}>{copied ? 'Copied' : 'Copy YAML'}</Button>
        {data.can_save ? (
          <Button onClick={onSave} loading={save.pending} disabled={!dirty || errors.length > 0}>Save</Button>
        ) : null}
      </PageHeader>

      {data.can_save ? null : (
        <Alert tone="info" className="mb-6">
          Previewing only. Saving works in development, where it writes <code>{data.path}</code> for you to commit and
          deploy. To keep a change made here, copy the YAML into that file.
        </Alert>
      )}
      <ErrorAlert error={save.error} className="mb-6" />
      {errors.length ? <ErrorAlert error={errors} className="mb-6" /> : null}

      <section className="mb-8">
        <h2 className="section-title mb-1">Start from a preset</h2>
        <p className="text-sm text-ink-muted mb-4">Picks fonts, colors and corners together. Adjust anything after.</p>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {data.presets.map((preset) => (
            <PresetCard
              key={preset.slug}
              preset={preset}
              selected={sameTheme(preset.theme, draft.theme)}
              onSelect={(theme) => setDraft((current) => ({ ...current, theme: { ...theme } }))}
            />
          ))}
        </div>
      </section>

      <div className="grid gap-6 lg:grid-cols-2 items-start">
        <div className="space-y-6 min-w-0">
          <Card className="space-y-4">
            <h2 className="section-title">Fonts</h2>
            <FontSelect label="Headings" value={draft.theme.display_font} onChange={setTheme('display_font')} fonts={data.fonts} />
            <FontSelect label="Body text" value={draft.theme.body_font} onChange={setTheme('body_font')} fonts={data.fonts} bodyOnly />
          </Card>

          <Card className="space-y-4">
            <h2 className="section-title">Colors</h2>
            <ColorField
              label="Primary"
              value={draft.theme.primary}
              onChange={setTheme('primary')}
              hint={contrast
                ? `${contrast.primary_on_white}:1 on white (needs 3:1; 4.5:1 reads well as small text). ${contrast.dark_primary_on_surface}:1 in dark mode.`
                : 'Buttons, links and highlights.'}
            />
            <ColorField label="Secondary" value={draft.theme.secondary} onChange={setTheme('secondary')} hint="Accents and gradients." />
          </Card>

          <Card>
            <CornerChoice corners={data.corners} value={draft.theme.corners} onChange={setTheme('corners')} />
          </Card>

          <Card className="space-y-4">
            <h2 className="section-title">Identity</h2>
            <div className="grid gap-4 sm:grid-cols-[minmax(0,1fr)_8rem]">
              <Field label="Name" value={draft.name} onChange={set('name')} />
              <Field label="Initials" value={draft.short_name} onChange={set('short_name')} maxLength={3} hint="The brand mark." />
            </div>
            <Field label="Tagline" value={draft.tagline} onChange={set('tagline')} hint="Footer and default page description." />
            <Field label="Support email" type="email" value={draft.support_email} onChange={set('support_email')} hint="Shown in the footer when set." />
          </Card>
        </div>

        <div className="space-y-4 min-w-0 lg:sticky lg:top-6">
          <h2 className="section-title">Preview</h2>
          {lastGood?.css_variables ? (
            <>
              <p className="text-sm text-ink-muted">Light</p>
              <Sample variables={lastGood.css_variables} config={draft} />
              <p className="text-sm text-ink-muted">Dark</p>
              <Sample variables={lastGood.css_variables} config={draft} dark />
            </>
          ) : null}
          <details id="theme-yaml" className="card">
            <summary className="cursor-pointer font-medium text-ink">{data.path}</summary>
            <pre className="mt-4 text-xs text-ink whitespace-pre-wrap break-words">{preview?.yaml}</pre>
          </details>
        </div>
      </div>
    </Page>
  )
}
