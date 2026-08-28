# Rails AI Starter

An opinionated Rails 8 starter optimized for building AI-accelerated products with
[Claude Code](https://github.com/anthropics/claude-code). Ships with auth, an admin
SPA, LLM integration, transactional email, payments, and a feature-tracking workflow
so you can get from `clone` to shipping in an afternoon.

Built and maintained by [Nimble Labs](https://www.nimblelabs.com).

---

## What's included

- **Auth** — Devise with sign-in / register / logout, FriendlyId slugs, role enum
  (user / admin), API-token authentication for mobile clients.
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
| Auth | Devise + token auth for mobile |
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

Create a `.env` in the project root (loaded by `dotenv-rails` in development):

```bash
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
STRIPE_SECRET_KEY=sk_test_...        # optional, payments
STRIPE_PUBLISHABLE_KEY=pk_test_...
STARTER_API_TOKEN=...                # optional, feature workflow
```

`DATABASE_URL` is auto-configured by `config/database.yml` for development.

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
