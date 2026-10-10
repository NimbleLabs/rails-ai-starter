/**
 * The app's name and brand-mark initials from config/app.yml. The Rails host
 * page puts them on window.__app (see AppConfig), so neither SPA hard-codes them.
 */
export const app = window.__app ?? { name: 'App', shortName: 'A' }
