import React, { useEffect, useId, useRef } from 'react'
import 'trix'

/**
 * React wrapper around the Trix rich-text editor.
 *
 * Trix is a custom element that edits a hidden <input> and emits `trix-change`.
 * The listeners are scoped to this element (the Vue version listened on
 * `document`, so two editors on one page fought over each other).
 *
 * Attachments are disabled: uploading them needs a server endpoint to POST
 * files to, and this app has none. Re-enable by handling `trix-attachment-add`
 * and calling `attachment.setAttributes({ url, href })` once uploaded.
 */
export function TrixEditor({ value = '', onChange, placeholder, className = '', id }) {
  const generatedId = useId().replace(/:/g, '')
  const inputId = id ?? `trix-input-${generatedId}`
  const inputRef = useRef(null)
  const editorRef = useRef(null)
  // Tracks what we last pushed in, so echoing our own change back doesn't
  // reset the cursor to the start of the document on every keystroke.
  const lastValue = useRef(value)

  useEffect(() => {
    const editor = editorRef.current
    if (!editor) return undefined

    const handleChange = () => {
      const html = inputRef.current?.value ?? ''
      lastValue.current = html
      onChange?.(html)
    }

    const rejectAttachment = (event) => {
      // No upload endpoint — remove it rather than leaving a broken placeholder.
      event.attachment.remove()
    }

    editor.addEventListener('trix-change', handleChange)
    editor.addEventListener('trix-attachment-add', rejectAttachment)
    return () => {
      editor.removeEventListener('trix-change', handleChange)
      editor.removeEventListener('trix-attachment-add', rejectAttachment)
    }
  }, [onChange])

  // Load external changes (e.g. a record arriving from the API) into the editor.
  useEffect(() => {
    const editor = editorRef.current
    if (!editor?.editor) return
    if (value === lastValue.current) return
    lastValue.current = value
    editor.editor.loadHTML(value ?? '')
  }, [value])

  return (
    <div className={`richText ${className}`}>
      <input id={inputId} type="hidden" defaultValue={value} ref={inputRef} />
      <trix-editor
        ref={editorRef}
        input={inputId}
        placeholder={placeholder}
        class="trix-content min-h-[300px] max-h-[600px] overflow-y-auto rounded-xl border border-line bg-surface px-4 py-2.5 text-ink focus:border-primary focus:outline-none"
      />
    </div>
  )
}
