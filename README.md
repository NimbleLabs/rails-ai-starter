# Rails AI Starter

An opinionated Rails 8 starter optimized for building AI-accelerated products with
[Claude Code](https://github.com/anthropics/claude-code). Ships with auth, an admin
SPA, LLM integration, transactional email, payments, and a feature-tracking workflow
so you can get from `clone` to shipping in an afternoon.

Built and maintained by [Nimble Labs](https://www.nimblelabs.com).

---

## What's included

- **Auth** — Devise with sign-in / register / logout, optional
  [Sign in with Google](#setting-up-sign-in-with-google), FriendlyId slugs, role
  enum (user / admin), API-token authentication for mobile clients.
- **Bot protection** — optional
  [reCAPTCHA Enterprise](#setting-up-recaptcha-enterprise) on sign-up and the
  contact form, off until you configure it.
- **Analytics** — Ahoy, in your own Postgres, powering the admin dashboard. No
  third-party analytics SDK.
- **Error tracking** — an internal `Log` model with an admin UI at `/admin/logs`
  and email/Slack notification rules. No Rollbar or Sentry.
- **Two React 19 SPAs** — a customer-facing app at `/app/*` and an admin app at
  `/admin/*`, both served via `vite_rails`.
- **AI** — [`ruby_llm`](https://github.com/crmne/ruby_llm) wired up for OpenAI +
  Anthropic, with `acts_as_chat` / `acts_as_message` models that track tokens
  and tool calls.
- **Email** — `bootstrap-email` for responsive HTML, Ahoy for open/click tracking,
  Mailkick for unsubscribe management, and an `EmailTemplate` model with Action
  Text rich content.
- **Payments** — Stripe (subscriptions + one-time), wired through a single
  `payments_controller`.
- **Marketing funnels** — `/f/:slug` landing pages (lead → book-call → order →
  thank-you) backed by a `Funnel` model with a metrics endpoint.
- **Feature workflow** — `bin/feature` (rake task wrapper) creates branches,
  tracks status, and creates PRs against your features API.
- **Background jobs / cache / Action Cable** — Solid Queue, Solid Cache, Solid
  Cable. No Redis required.
- **Deployment** — Kamal config + Dockerfile + Thruster, GitHub Actions for
  Brakeman, RuboCop, and tests.
- **Rich text + uploads** — Action Text with Trix, Active Storage with
  `image_processing` variants.

## Tech stack

| Layer | Choice |
| --- | --- |
| Language | Ruby 3.4.7 |
| Framework | Rails 8.1 |
| Database | PostgreSQL |
| Frontend | React 19 + Vite + react-router (admin + user SPAs) |
| Styling | Tailwind CSS 4 |
| Auth | Devise + Google OAuth + token auth for mobile |
| Bot protection | reCAPTCHA Enterprise (optional) |
| Analytics | Ahoy (self-hosted, in Postgres) |
| Error tracking | Internal `Log` model (no third-party service) |
| LLM | ruby_llm (OpenAI + Anthropic) |
| Jobs / cache / cable | Solid Queue / Cache / Cable |
| Deployment | Kamal + Docker + Thruster |
| Email | Action Mailer + Ahoy + Mailkick + Bootstrap Email |

---

## Quick start (Mac)

Fresh Mac? One script installs the toolchain, then `bin/setup` finishes the app.

```bash
git clone https://github.com/NimbleLabs/rails-ai-starter.git
cd rails-ai-starter
bin/install-mac-deps           # Homebrew, Ruby, Postgres 17, Node, Yarn
bin/setup                      # bundle, db:prepare, then bin/dev
```

`bin/install-mac-deps` is idempotent — safe to re-run if something breaks.

**Building a Rails + mobile product?** Use the
[Nimble Labs dev bootstrap](https://github.com/NimbleLabs/dev-bootstrap) instead.
It scaffolds a parent directory containing this Rails starter alongside an Expo
mobile app, with a shared `CLAUDE.md` so Claude Code can work across both.

## Requirements

- macOS (or Linux — adapt `bin/install-mac-deps` accordingly)
- Ruby 3.4.7 (see `.ruby-version`)
- PostgreSQL 17
- Node 20+ and Yarn 1.x
- An [Anthropic API key](https://console.anthropic.com) and/or
  [OpenAI API key](https://platform.openai.com) for AI features

## Environment variables

Create a `.env` in the project root (loaded by `dotenv-rails` in development).
`.env.example` documents every variable; copy it with `cp .env.example .env`.

```bash
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
STRIPE_SECRET_KEY=sk_test_...        # optional, payments
STRIPE_PUBLISHABLE_KEY=pk_test_...
STARTER_API_TOKEN=...                # optional, feature workflow

SLACK_WEBHOOK_URL=                   # optional, error-log notifications
MAIL_FROM=                           # from address for outgoing mail
APP_NAME=Starter                     # shown in log alerts

RECAPTCHA_SITE_KEY=                  # optional, bot protection
RECAPTCHA_ENTERPRISE_API_KEY=
RECAPTCHA_ENTERPRISE_PROJECT_ID=

GOOGLE_CLIENT_ID=                    # optional, Sign in with Google
GOOGLE_CLIENT_SECRET=
```

`DATABASE_URL` is auto-configured by `config/database.yml` for development.

**Everything optional is genuinely optional.** Leave the reCAPTCHA and Google
variables blank and those features switch themselves off — no widget is
rendered, no verification runs, and the "Continue with Google" button does not
appear. A fresh clone signs up and runs its test suite without a Google Cloud
account. Set them when you want them; see the two sections below.

---

## Running locally

```bash
bin/dev                        # starts Rails, Vite, and Tailwind CSS together
bin/rails server               # Rails only (port 3000)
bin/vite dev                   # Vite dev server only
```

Visit <http://localhost:3000>.

## Testing

```bash
bin/rails test                 # all tests
bin/rails test:system          # system (browser) tests only
bin/rails test test/models/user_test.rb
```

## Code quality

```bash
bin/rubocop                    # lint (omakase style)
bin/rubocop -a                 # auto-fix
bin/brakeman                   # security scan
bin/importmap audit            # JS dependency audit
bin/rails annotaterb:annotate  # refresh model schema comments
```

---

## Project structure

```
app/
  controllers/
    api/v1/               # JSON API for mobile clients
    payments_controller.rb
    landing_pages_controller.rb
  javascript/
    app/                  # customer React SPA (/app/*)
    admin/                # admin React SPA (/admin/*)
    components/ui/        # shared React component kit (both SPAs)
    lib/                  # api client + data hooks
    entrypoints/          # Vite entrypoints
  models/
    user.rb               # Devise + roles + API tokens + Mailkick subs
    article.rb            # Action Text + Active Storage + FriendlyId
    funnel.rb             # marketing funnels
    chat.rb / message.rb  # ruby_llm acts_as_chat
config/
  routes.rb               # Devise + REST + namespaced API + funnel paths
  deploy.yml              # Kamal
.kamal/                   # secrets + deploy hooks
bin/
  setup                   # idempotent app setup
  install-mac-deps        # idempotent toolchain installer
  dev                     # foreman-style dev server
  feature                 # feature-workflow CLI
```

## Authentication for mobile clients

Users have an `auth_token` column. To call the API from a mobile app:

```http
GET /api/v1/users/current HTTP/1.1
x-api-token: <user.auth_token>
```

`ApplicationController` exposes:
- `authenticate_with_token` — token-only (best for API-only endpoints)
- `authenticate_user_or_token` — token OR Devise session (for hybrid endpoints)

Both populate `current_user` the same way Devise does.

## Setting up Sign in with Google

Optional. Leave `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` unset and the button
never appears.

You need a Google Cloud project. Everything below happens in the
[Google Cloud Console](https://console.cloud.google.com/) — pick or create your
project in the picker at the top first, since every link is project-scoped.

> Google reorganizes this part of the console periodically. The consent screen
> now lives under **Google Auth Platform**; older guides call it
> *APIs & Services → OAuth consent screen*, which redirects there. If a link
> below lands somewhere unexpected, search the console for the page name.

**1. Configure the consent screen** — [Google Auth Platform → Branding](https://console.cloud.google.com/auth/branding)

This is what users see on Google's own permission page. Set an app name, a
support email, and your logo. Choose **External** as the user type unless
everyone signing in is inside your Google Workspace org.

While you are only testing, the app stays in *Testing* mode and you must add
each tester under [Audience](https://console.cloud.google.com/auth/audience) —
sign-in fails for anyone not on that list. Publishing removes the limit. Because
we only request `email` and `profile` (both non-sensitive), publishing does
**not** require Google's verification review.

**2. Create the OAuth client** — [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)

*Create credentials → OAuth client ID → Web application.*

| Field | Value |
| --- | --- |
| Authorized JavaScript origins | `http://localhost:3000` |
| Authorized redirect URIs | `http://localhost:3000/users/auth/google_oauth2/callback` |

Add your real origin and callback for production too:
`https://your-domain.com/users/auth/google_oauth2/callback`.

The callback path is fixed by Devise's OmniAuth routing — it is
`/users/auth/<provider>/callback`, so for this app:

```
/users/auth/google_oauth2/callback
```

Confirm it any time with `bin/rails routes | grep google`. It must match what
you enter in the console **exactly** — scheme, host, port and path. A mismatch
is the single most common failure here, and Google reports it as
`redirect_uri_mismatch`.

**3. Put the credentials in `.env`**

```bash
GOOGLE_CLIENT_ID=1234567890-abcdefg.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-...
```

Restart `bin/dev` — the OmniAuth strategy is registered at boot, so a running
server will not pick up new credentials.

**4. Check it**

Visit `/users/sign-in`. "Continue with Google" should now be there. Sign in with
a Google account and you should land back on the site signed in.

Notes worth knowing:

- The button is a **POST**, not a link. `omniauth-rails_csrf_protection` rejects
  a GET request phase because it is cross-site forgeable
  ([CVE-2015-9284](https://nvd.nist.gov/vuln/detail/CVE-2015-9284)). If you add
  your own Google button anywhere, use `button_to`.
- An account is only linked to an existing local user when Google reports the
  email as **verified**. See "Sign in with Google" in `CLAUDE.md` for the full
  trust rules.
- Google accounts get a random password so Devise's `:validatable` is satisfied;
  users can set a real one later through password reset.

## Setting up reCAPTCHA Enterprise

Optional. Leave the three `RECAPTCHA_*` variables unset and no widget renders and
no verification runs. It protects sign-up and the contact form.

**1. Enable the API** —
[Enable reCAPTCHA Enterprise](https://console.cloud.google.com/apis/library/recaptchaenterprise.googleapis.com)

Same project as above is fine. The API must be enabled before a key will verify
anything.

**2. Create a site key** — [Security → reCAPTCHA](https://console.cloud.google.com/security/recaptcha)

*Create key*, platform **Website**.

| Field | Value |
| --- | --- |
| Domains | `localhost` for development, plus your production domain |
| Type | **Score-based (no interaction)** |

Score-based is the right choice: this app uses the invisible v3-style flow, which
scores the request rather than showing a checkbox. The value you get is
`RECAPTCHA_SITE_KEY` — it is public and rendered into the page.

**3. Create an API key** — [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)

*Create credentials → API key.* This one is secret; the server uses it to create
assessments. Restrict it — *Edit API key → API restrictions → Restrict key →
reCAPTCHA Enterprise API* — so a leak can't be used against your other Google
services.

**4. Put all three in `.env`**

```bash
RECAPTCHA_SITE_KEY=6Lc...                    # public, rendered in the page
RECAPTCHA_ENTERPRISE_API_KEY=AIza...         # secret, server-side assessments
RECAPTCHA_ENTERPRISE_PROJECT_ID=my-project   # the project ID, not its name
```

`RECAPTCHA_ENTERPRISE_PROJECT_ID` is the project **ID** (e.g. `my-app-42817`),
which is not always the display name — the picker in the console shows both.

Restart `bin/dev`, then load `/users/register`. You should see the "Protected by
reCAPTCHA" notice under the form, and Google's badge in the corner.

Notes worth knowing:

- All three variables are required. Set only some and the feature stays off, on
  purpose, rather than half-working.
- The default pass mark is a score of **0.5** (Google's suggested starting
  point). Tune it once you have real traffic — the right threshold depends
  heavily on your audience. See `RecaptchaProtection::DEFAULT_MINIMUM_SCORE`.
- If Google is unreachable, requests are let through rather than blocked: an
  outage at Google should not stop people signing up. A genuine low score is
  still rejected.
- The test suite never calls Google. The gem skips verification in the test
  environment, so you don't need keys to run `bin/rails test`.
- To protect another form, see "Bot protection" in `CLAUDE.md` — it is a concern
  include, one guard line in the controller, and one partial in the view.

## Deployment notes for these features

Both features are configured per environment, so production needs its own setup:

- **Google** — add the production callback to the same OAuth client under
  *Authorized redirect URIs*: `https://your-domain.com/users/auth/google_oauth2/callback`.
  One client can hold several URIs, so localhost and production can coexist. Set
  `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` on the server. If your consent
  screen is still in *Testing*, publish it or real users cannot sign in.
- **reCAPTCHA** — add your production domain to the site key's domain list, and
  set the three `RECAPTCHA_*` variables on the server. The same key works for
  both environments once `localhost` and the real domain are both listed.
- Neither feature blocks a deploy: with the variables unset, the app runs
  exactly as it does today, minus the button and the widget.

If you deploy with `bin/bootstrap-droplet`, pass these through with `--push-env`
or set them later with `dokku config:set`.

## Deployment

The app deploys via [Kamal 2](https://kamal-deploy.org/):

```bash
bin/kamal setup                # first time only
bin/kamal deploy
```

Secrets live in `.kamal/secrets`. The `Dockerfile` is production-ready;
Thruster handles HTTP caching + compression in front of Puma.

---

## Working with Claude Code

This repo is designed for Claude Code as a pair programmer. See
[`CLAUDE.md`](./CLAUDE.md) for the orientation file Claude reads on startup —
it documents the architecture, conventions, and common workflows.

A few prompts to try after `claude` starts:

- "Explain how the two React SPAs share state with Rails."
- "Add a new model `Project` with FriendlyId slugs and a `/projects` REST resource."
- "Wire up a new `/api/v1/projects` endpoint that authenticates by token."

See [`PROMPTS.md`](./PROMPTS.md) for a longer set of starter prompts.

## License

MIT.
