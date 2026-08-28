import { useCallback, useEffect, useRef, useState } from 'react'

/**
 * Load data on mount (and whenever `deps` change) with loading/error state.
 *
 *   const { data, loading, error, reload } = useResource(() => api.get('/users.json'), [])
 *
 * Aborts in-flight work on unmount so a slow response can't set state on an
 * unmounted component or clobber a newer request.
 */
export function useResource(loader, deps = [], { initial = null } = {}) {
  const [data, setData] = useState(initial)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [nonce, setNonce] = useState(0)
  const loaderRef = useRef(loader)
  loaderRef.current = loader

  useEffect(() => {
    let cancelled = false
    const controller = new AbortController()
    setLoading(true)
    setError(null)

    Promise.resolve(loaderRef.current({ signal: controller.signal }))
      .then((result) => { if (!cancelled) { setData(result); setError(null) } })
      .catch((e) => { if (!cancelled && e?.name !== 'AbortError') setError(e) })
      .finally(() => { if (!cancelled) setLoading(false) })

    return () => { cancelled = true; controller.abort() }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, nonce])

  const reload = useCallback(() => setNonce((n) => n + 1), [])
  return { data, loading, error, reload, setData }
}

/**
 * Wrap a mutation (save/delete) with pending + error state.
 *
 *   const { run, pending, error } = useMutation((payload) => api.post(url, payload))
 *   await run(payload)   // resolves to the result, or null if it failed
 */
export function useMutation(fn) {
  const [pending, setPending] = useState(false)
  const [error, setError] = useState(null)

  const run = useCallback(async (...args) => {
    setPending(true)
    setError(null)
    try {
      return await fn(...args)
    } catch (e) {
      setError(e)
      return null
    } finally {
      setPending(false)
    }
  }, [fn])

  return { run, pending, error, setError }
}

/** A transient success/error banner that clears itself. */
export function useFlash(timeout = 5000) {
  const [flash, setFlash] = useState(null)
  useEffect(() => {
    if (!flash) return undefined
    const timer = setTimeout(() => setFlash(null), timeout)
    return () => clearTimeout(timer)
  }, [flash, timeout])
  return [flash, setFlash]
}

/** Sets document.title for the current admin page. */
export function useTitle(title) {
  useEffect(() => {
    if (!title) return
    const previous = document.title
    document.title = `${title} · Admin`
    return () => { document.title = previous }
  }, [title])
}
