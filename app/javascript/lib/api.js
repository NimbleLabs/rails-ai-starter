/**
 * Thin fetch wrapper around the Rails JSON API.
 *
 * Replaces the old superagent-based RestService. Differences that matter:
 *  - never blindly JSON.parse()s a response, so a 500 that returns an HTML
 *    error page rejects cleanly instead of throwing inside a callback;
 *  - sends the CSRF token from the <meta> tag on every mutating request;
 *  - supports FormData for file uploads (multipart) without hand-rolling it.
 *
 *   const users = await api.get('/api/v1/users.json')
 *   await api.post('/articles.json', { article: {...} })
 *   await api.post('/articles.json', toFormData('article', {...}))   // multipart
 */

export class ApiError extends Error {
  constructor(message, status, body) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.body = body
  }

  /** Field errors from the Rails `{ errors: { field: [msg] } }` envelope. */
  get fieldErrors() {
    const errors = this.body?.errors ?? this.body
    if (!errors || typeof errors !== 'object' || Array.isArray(errors)) return {}
    return errors
  }

  /** Flat, human-readable list suitable for an alert box. */
  get messages() {
    const errors = this.fieldErrors
    const list = Object.entries(errors).map(([field, messages]) => {
      const text = Array.isArray(messages) ? messages.join(', ') : String(messages)
      return field === 'base' ? text : `${field.replace(/_/g, ' ')} ${text}`
    })
    return list.length ? list : [this.message]
  }
}

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content ?? ''
}

function safeParse(text) {
  if (!text) return null
  try {
    return JSON.parse(text)
  } catch {
    return text
  }
}

function messageFrom(body, status) {
  if (body && typeof body === 'object') {
    if (typeof body.error === 'string') return body.error
    if (body.errors && typeof body.errors === 'object') {
      const first = Object.entries(body.errors)[0]
      if (first) {
        const [field, messages] = first
        const text = Array.isArray(messages) ? messages[0] : String(messages)
        return `${field.replace(/_/g, ' ')} ${text}`
      }
    }
  }
  return `Request failed (${status})`
}

async function request(method, path, body, options = {}) {
  const isForm = typeof FormData !== 'undefined' && body instanceof FormData

  const headers = {
    Accept: 'application/json',
    ...(body !== undefined && !isForm ? { 'Content-Type': 'application/json' } : {}),
    ...(method !== 'GET' ? { 'X-CSRF-Token': csrfToken() } : {}),
    ...(options.headers ?? {}),
  }

  const response = await fetch(path, {
    method,
    headers,
    credentials: 'same-origin',
    signal: options.signal,
    body: body === undefined ? undefined : isForm ? body : JSON.stringify(body),
  })

  if (response.status === 204) return null

  const text = await response.text()
  const parsed = safeParse(text)

  if (!response.ok) {
    throw new ApiError(messageFrom(parsed, response.status), response.status, parsed)
  }
  return parsed
}

/** Cache-buster: several admin endpoints are hit right after a mutation. */
function bust(path) {
  const separator = path.includes('?') ? '&' : '?'
  return `${path}${separator}t=${Date.now()}`
}

export const api = {
  get: (path, options) => request('GET', bust(path), undefined, options),
  post: (path, body, options) => request('POST', path, body, options),
  put: (path, body, options) => request('PUT', path, body, options),
  patch: (path, body, options) => request('PATCH', path, body, options),
  delete: (path, options) => request('DELETE', path, undefined, options),
}

/**
 * Build a Rails-shaped FormData payload: toFormData('article', { title, featured_image })
 * produces article[title], article[featured_image], and handles File/array values.
 */
export function toFormData(modelName, attributes) {
  const data = new FormData()
  Object.entries(attributes ?? {}).forEach(([key, value]) => {
    if (value === undefined || value === null) return
    if (Array.isArray(value) || value instanceof FileList) {
      Array.from(value).forEach((item) => data.append(`${modelName}[${key}][]`, item))
    } else {
      data.append(`${modelName}[${key}]`, value)
    }
  })
  return data
}

/**
 * A REST resource helper, so pages don't repeat URL building.
 *
 *   const articles = resource('/articles')
 *   await articles.list()            // GET  /articles.json
 *   await articles.get(slug)         // GET  /articles/:id.json
 *   await articles.create(payload)   // POST /articles.json
 */
export function resource(basePath) {
  const url = (id) => (id === undefined ? `${basePath}.json` : `${basePath}/${id}.json`)
  return {
    url,
    list: (query = '', options) => api.get(query ? `${url()}?${query}` : url(), options),
    get: (id, options) => api.get(url(id), options),
    create: (payload, options) => api.post(url(), payload, options),
    update: (id, payload, options) => api.put(url(id), payload, options),
    patch: (id, payload, options) => api.patch(url(id), payload, options),
    remove: (id, options) => api.delete(url(id), options),
  }
}
