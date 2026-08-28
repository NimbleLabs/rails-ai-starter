# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

- **Backend**: Rails 8.1.1 with PostgreSQL
- **Frontend**: React 19 with Vite, served via vite_rails. **React is the standard for
  every SPA in this app — do not add Vue, Svelte or another framework.**
- **Styling**: Tailwind CSS 4.x, CSS-first config. Design tokens and the shared
  component classes live in `app/assets/tailwind/application.css` — see "Design system".
- **Authentication**: Devise, plus "Sign in with Google" (omniauth-google-oauth2)
- **Bot protection**: reCAPTCHA Enterprise (`recaptcha` gem)
- **LLM Integration**: ruby_llm gem (~> 1.9.1) for OpenAI/Anthropic APIs
- **Email**: bootstrap-email, ahoy_email (tracking), mailkick (unsubscribe management)
- **Analytics/Metrics**: Ahoy (`ahoy_matey`) — the one and only analytics tool here. See "Analytics (Ahoy)".
- **Error tracking**: our own `Log` model. No Rollbar, no Sentry. See "Error logging (internal Logs)".
- **Background Jobs**: Solid Queue (Rails 8 default)
- **Caching**: Solid Cache
- **Action Cable**: Solid Cable
- **Rich Text**: Action Text with Trix editor
- **File Storage**: Active Storage
- **URL Slugs**: FriendlyId

## Development Commands

### Setup
```bash
bin/setup              # Install dependencies, prepare DB, start server
bin/setup --skip-server # Setup without starting server
```

### Running the Application
```bash
bin/dev                # Start all services (Rails, Vite, Tailwind CSS)
bin/rails server       # Rails server only (port 3000)
bin/vite dev           # Vite dev server only
```

### Database
```bash
bin/rails db:prepare   # Create/migrate/seed database
bin/rails db:migrate   # Run pending migrations
bin/rails db:test:prepare # Prepare test database
```

### Testing
```bash
bin/rails test                    # Run all tests
bin/rails test:system             # Run system tests only
bin/rails test test/models/user_test.rb  # Run single test file
bin/rails test test/models/log_test.rb   # Internal logging system
npx vite build                           # Type-free build check for the React apps
```

### Code Quality
```bash
bin/rubocop           # Run linter (omakase style)
bin/rubocop -a        # Auto-fix linter issues
bin/brakeman          # Security vulnerability scan
bin/importmap audit   # JavaScript security scan
bin/rails annotaterb:annotate # Update model schema annotations
```

## Architecture

### Two React Applications

The project has **two React 19 SPAs**, both mounted on a `#app` div by a bare Rails
view and both sharing one component kit:

1. **User App** (`/app/*`)
   - Entrypoint: `app/javascript/entrypoints/application.jsx`
   - Root: `app/javascript/app/UserApp.jsx` (react-router, `basename="/app"`)
   - Host page: `app/views/static/app.html.erb`
   - Deliberately minimal — the starting point for a real product UI.

2. **Admin App** (`/admin/*`)
   - Entrypoint: `app/javascript/entrypoints/admin.jsx`
   - Root: `app/javascript/admin/AdminApp.jsx` (react-router, `basename="/admin"`)
   - Host page: `app/views/static/admin.html.erb`
   - Layout: `app/javascript/admin/layout/` — permanent sidebar at `lg+`, off-canvas
     drawer below it. Nav items are data in `layout/navItems.js`.
   - Pages: `app/javascript/admin/pages/` — dashboard, users, contacts, email
     templates, articles, funnels, metrics, features, logs.

Both host pages serialize the signed-in user into `window.__currentUser`, so the SPAs
boot without a round trip. Rails catch-all routes (`get "admin/*other"`) make deep
links and refreshes work.

### Shared frontend building blocks

Import with the `~` alias (= `app/javascript`).

- **`~/lib/api`** — `api.get/post/put/patch/delete`, plus `resource(basePath)` and
  `toFormData(model, attrs)` for multipart. Sends the CSRF token, never blindly
  `JSON.parse`s a response, and throws `ApiError` (which exposes `.fieldErrors` and
  `.messages` from the Rails error envelope).
- **`~/lib/hooks`** — `useResource` (load + loading/error, aborts on unmount),
  `useMutation` (pending/error around a save), `useFlash`, `useTitle`.
- **`~/components/ui`** — `Page`, `PageHeader`, `Card`, `DataTable`, `Button`, `Badge`,
  `Field`, `Toolbar`, `DetailList`, `Pagination`, `ConfirmModal`, `Alert`/`ErrorAlert`,
  `StatTile`, `EmptyState`, `Spinner`.
- **`~/components/TrixEditor`** — Action Text rich-text editing. Attachments are
  disabled (there is no upload endpoint in this app).

**`DataTable` is how every list is built.** It renders a real `<table>` at `md+` and
**stacked cards below `md`** — a table is unusable on a phone. Because of that, columns
are declared as data (`{ key, header, primary, render, wide }`) rather than hand-written
`<td>`s. Mark exactly one column `primary`; it becomes the card heading on mobile.

### Mobile

Every React screen must work on a phone: no fixed pixel widths, no horizontal page
scroll, tap targets at least 40px, grids that start at one column, form action rows
that stack (`flex-col-reverse sm:flex-row`), and long values that `truncate` or
`break-words`. Use `DataTable` rather than a bare `<table>`.

### Rails Routes Structure

- Static pages: Root `/`, About, Privacy, Terms
- Devise auth: `/sign-in`, `/register`, `/logout`
- Resources: `/articles`, `/contacts`, `/email-templates`, `/features`, `/logs`, `/log-subscriptions`
  (the last three are JSON-only, consumed by the React admin)
- API: `/api/v1/users/*`, `/api/v1/sessions`, `/api/v1/registrations` (JSON format)
- Mobile ingestion: `POST /api/v1/logs` (errors), `POST /api/v1/events` (Ahoy analytics)
- Ahoy JS/native endpoints: `/ahoy/visits`, `/ahoy/events`
- Admin dashboard metrics: `GET /dashboard/metrics.json?days=N`
- React SPAs: `/app/*` and `/admin/*` (catch-all routes to the respective apps)

### Key Models

**User**
- Uses Devise for authentication, optionally via Google (`provider`, `uid`, `avatar_url`)
- FriendlyId slugs based on name
- Has `role` enum (user: 0, admin: 1)
- Mailkick subscriptions (`has_subscriptions`)
- After create: sends welcome email, subscribes to newsletter

**Article**
- FriendlyId slugs based on title
- Action Text rich content (`has_rich_text :content`)
- Active Storage featured image (`has_one_attached :featured_image`)
- Fields: title, description, author, category, published, featured, published_at

**Contact**
- FriendlyId slugs based on name
- Mailkick subscriptions
- Email validation with URI::MailTo::EMAIL_REGEXP
- Tracks Ahoy messages for email campaign tracking
- After create: subscribes to newsletter

**Log**
- The internal exception/error log — this app's replacement for Rollbar
- `level` enum (info/warn/error/fatal), `source` (web/job/mobile/console/app)
- Repeats of the same problem roll up into one row (`occurrences`, `last_seen_at`) via a `fingerprint`
- `resolved_at` for triage; admin UI at `/admin/logs`
- See "Error logging (internal Logs)" before writing anything that touches it

**LogSubscription**
- A notification rule: channel (email/slack), destination, `min_level`, `throttle_minutes`
- Managed in the admin at `/admin/log-notifications`

**Chat/Message System**
- Uses ruby_llm gem: `acts_as_chat` and `acts_as_message`
- Messages track tokens (input/output), role, model_id
- ToolCall model for function calling support

### Email Architecture

**Template System**
- `EmailTemplate` model with `has_rich_text :content` for HTML emails
- `SendEmailTemplateJob` for bulk sending to contacts
- Bootstrap-email for responsive email styling
- Ahoy Email for open/click tracking
- Mailkick for unsubscribe management

**User Journey**
- Welcome email sent 2 seconds after user creation
- Auto-subscribe to "Newsletter" on signup
- Contacts track "first outreach email" with custom queries

### Environment Configuration

Required environment variables (use .env in development via dotenv-rails):
- `OPENAI_API_KEY` - for ruby_llm OpenAI integration
- `ANTHROPIC_API_KEY` - for ruby_llm Anthropic integration
- `DATABASE_URL` - PostgreSQL connection (auto-configured in database.yml)
- `SLACK_WEBHOOK_URL` - incoming webhook for `SlackService` system alerts (optional)
- `MAIL_FROM` - from address for outgoing mail, including log alerts
- `APP_NAME` - shown in log notification subjects and Slack messages
- `CORS_ORIGINS` - comma-separated allowed origins for `/api/v1/*` and `/ahoy/*`
- `RECAPTCHA_SITE_KEY`, `RECAPTCHA_ENTERPRISE_API_KEY`, `RECAPTCHA_ENTERPRISE_PROJECT_ID` -
  bot protection; all three unset disables it (see "Bot protection")
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` - "Sign in with Google"; unset disables it

### Deployment

- Docker support via Dockerfile
- Kamal deploy configuration in .kamal/ and config/deploy.yml
- Thruster for HTTP caching/compression
- CI via GitHub Actions: brakeman, importmap audit, rubocop, tests


## Design system

The look is shared deliberately with `mobile-app-starter` (and with FitnessHQ,
which it was ported from) so both halves of a project read as one product: warm
neutrals, soft rounded surfaces, low-opacity shadows, Outfit as the typeface, and
a purple brand accent (`#7c3aed`).

**All tokens live in `app/assets/tailwind/application.css`** (Tailwind 4 is
CSS-first — there is no `tailwind.config.js`). The `--theme-*` custom properties
are the runtime layer: the marketing layout's Alpine theme switcher overrides
them per theme from `lib/themes/*-theme.json`, and `.dark` redefines them for
dark mode. `@theme` bridges them to Tailwind color utilities.

Use the semantic classes, never literal palette utilities:

| Instead of | Use |
| --- | --- |
| `bg-white`, `bg-gray-50` | `bg-surface`, `bg-surface-muted`, `bg-canvas` |
| `text-gray-900`, `text-gray-500` | `text-ink`, `text-ink-muted` |
| `border-gray-200` | `border-line` |
| `bg-purple-600` | `bg-primary` (hover `bg-primary-hover`), tints `bg-primary/10` |

Component classes: `.btn-primary` `.btn-secondary` `.btn-outline` `.btn-danger`
`.btn-ghost` (+ `.btn-sm` `.btn-lg`), `.card` `.card-flush` `.panel-muted`,
`.stat-tile`/`.stat-label`/`.stat-value`, `.admin-table` `.table-link`
`.empty-state`, `.form-label` `.input-form-field` `.form-hint` `.form-checkbox`,
`.badge-brand|gray|green|red|amber|blue`, `.alert-info|success|warning|error`,
`.page-header` `.page-title` `.page-subtitle` `.section-title` `.eyebrow`,
`.nav-link`/`.nav-link-active`, `.brand-mark`.

Rules: no hex colors in `.erb` or `.jsx` files; add a token here rather than a
one-off utility; `.btn`, `.badge` and `.alert` are `@utility` (not `@layer
components`) precisely so the variants can `@apply` them — Tailwind 4 cannot
`@apply` a plain component class. Rebuild with `bin/rails tailwindcss:build`
(`bin/dev` watches).

## Analytics (Ahoy)

The admin dashboard at `/admin` is built entirely on Ahoy: `DashboardMetrics`
(`app/services/dashboard_metrics.rb`) turns `ahoy_visits` / `ahoy_events` into visit
counts, a dense per-day series, top events/pages/referrers, device split and recent
sign-ups, served by `GET /dashboard/metrics.json?days=N`. That page is the argument for
keeping analytics in our own Postgres: it is one request, plain SQL, and it joins
straight against `users`.


**Ahoy is the analytics and metrics tool for this app. Do not add a third-party
analytics SDK** (Google Analytics as a product-metrics source, Segment, Mixpanel,
Amplitude, PostHog, Heap, …). Events are `Ahoy::Event` rows in our own Postgres,
which means funnel numbers join directly against `users`, `articles`, `funnels`
and everything else with plain SQL, cost nothing per event, and never leave our
database.

Everything is already wired:

- `config/initializers/ahoy.rb` — `Ahoy.api = true` (so `/ahoy/visits` and
  `/ahoy/events` are mounted for ahoy.js and for native clients),
  `visit_duration = 30.minutes`, and an `Ahoy::Store` that stamps `user_id` onto
  visits/events and stops ahoy's bot filter from discarding native-app traffic.
- `app/services/analytics.rb` — the helper you should actually call.
- Web pages load ahoy.js from the marketing layout and call `ahoy.trackView()`.
- Mobile posts to `POST /api/v1/events` (`Api::V1::EventsController`).

### Tracking an event

```ruby
Analytics.track(Analytics::SIGN_UP, user: user, controller: self)
Analytics.track("article_read", user: current_user, controller: self,
                properties: { slug: @article.slug })
```

`Analytics.track` never raises outside the test environment — analytics must not
be able to break a sign-up.

### Rules

1. **Track server-side, at the point the thing actually happened.** A dropped
   request, a crash on the way out, or an ad-blocker cannot deflate a number
   recorded in the controller/model that did the work — and a client cannot
   inflate it.
2. **The client may only report what the server genuinely cannot see** (e.g. a
   push notification being opened). Those names must be added to
   `Analytics::CLIENT_REPORTABLE`; `POST /api/v1/events` silently drops anything
   else, on purpose, so an event recorded on both sides can't double-count.
3. **Name events as past-tense facts** (`sign_up`, `challenge_started`), declare
   them as constants in `Analytics`, and keep `properties` small and scalar.
4. Mobile sends `Ahoy-Visitor` / `Ahoy-Visit` headers on every API request
   (`mobile-app-starter/src/lib/visit.ts`) so anonymous activity stitches to the
   user as soon as they sign in. Don't break that by tracking without the
   request.

## Error logging (internal Logs)

**We do not use Rollbar or any hosted error tracker.** Exceptions go into our own
`Log` model, visible in the admin at `/admin/logs`, with notification rules at
`/admin/log-notifications`.

The whole point of this system is that it stays *readable*. Rollbar was abandoned
precisely because it logged so much noise that nobody looked at it. A log nobody
reads is worse than no log at all, because it feels like monitoring while
silently failing to be monitoring.

### The rule for all future development

> **Post to the internal Logs system surgically. Every row must be something a
> human would want to be interrupted about. If a human wouldn't act on it, it
> does not belong in Logs.**

This means:

- **DO NOT** add `Log.record` / `Rails.error.report` calls "for visibility",
  for tracing, for progress, or inside a loop that runs per-record.
- **DO NOT** log expected, handled outcomes: validation failures, a 401 from an
  expired token, a 404, a user cancelling something, an empty result set, a
  retryable network blip that the retry then fixed.
- **DO NOT** log the same failure at several layers as it bubbles up. Log it once,
  at the layer that actually knows it's a problem.
- **DO** use `Rails.logger.info/debug` for anything you merely want to see in
  the server log. That is what it is for.
- **DO** use Ahoy for anything you want to *count*. A metric is not an error.

### What already reports itself — don't duplicate it

`LogErrorSubscriber` (wired in `config/initializers/error_reporting.rb`) is
subscribed to Rails' own error reporter, so these are captured with **no code
from you**:

- unhandled exceptions from web requests (500s only — Rails' `rescue_responses`
  means `RecordNotFound`, `ParameterMissing`, `InvalidAuthenticityToken`,
  `RoutingError` etc. never arrive, and `LogErrorSubscriber::IGNORED` blocks them
  a second time even if something reports one explicitly);
- Active Job failures, but only once retries are exhausted or the job is
  discarded — a job that fails and then succeeds on retry is not an incident;
- anything passed to `Rails.error.report`.

So: **do not wrap a controller action or a job in `begin/rescue` just to log it.**
It is already covered, and doing so usually makes the report worse by discarding
the original backtrace.

### When to write an explicit call

Only where the failure is genuinely invisible to the machinery above *and* a
human needs to act. The shape to use:

```ruby
# A third-party call we swallowed on purpose, but that means a customer
# silently didn't get something.
rescue Stripe::APIError => e
  Log.error(e, source: "web", context: { user_id: user.id, invoice_id: invoice.id })
  # ...degrade gracefully...
end

# A "this should be impossible" branch.
Log.warn("Subscription active with no plan", source: "job",
         context: { subscription_id: subscription.id })
```

`Log.record` (and its `Log.info/warn/error/fatal` shorthands) never raises — not
even on `SystemStackError` — and never propagates. Context is coerced to JSON
primitives with depth/size caps, so passing it an arbitrary object is safe.

### Deduplication

Same-fingerprint failures inside `Log::DEDUPE_WINDOW` (24h) roll up into one row
with an `occurrences` counter rather than creating new rows. The fingerprint is
`error class + message with numbers/UUIDs/hex normalized out + first app frame`,
so `id=42` and `id=43` are one problem, and the row survives line-number drift.
This is a safety net, not a licence to log in a loop.

### Notifications

`LogSubscription` rows decide who hears about a log. Each has a channel (email
via `LogMailer`, or Slack via an incoming webhook), a `min_level`, and a
`throttle_minutes` gap so a recurring error re-notifies at most that often.
`LogNotificationJob` fans a log out on create and on roll-up; resolving one never
notifies. A failing channel is logged to `Rails.logger` and never re-reported,
so a broken webhook cannot cause a notification loop.

Set `SLACK_WEBHOOK_URL` (system alerts via `SlackService`), `MAIL_FROM` and
`APP_NAME` in `.env`. **Email notifications need outgoing mail configured** —
`config/environments/production.rb` still has SMTP commented out.

### Mobile

`POST /api/v1/logs` (`Api::V1::LogsController`) accepts reports from the Expo
app, authenticated or not (a crash before sign-in still matters). The client
(`mobile-app-starter/src/lib/logger.ts`) applies the same policy on its side and
dedupes locally. A client cannot forge a server-side `source`.

## Bot protection (reCAPTCHA Enterprise)

Public forms — sign-up and the contact form — are protected with **reCAPTCHA
Enterprise** via the `recaptcha` gem.

```
RECAPTCHA_SITE_KEY               public key rendered into the page
RECAPTCHA_ENTERPRISE_API_KEY     Google Cloud API key used to create assessments
RECAPTCHA_ENTERPRISE_PROJECT_ID  Google Cloud project the key belongs to
```

**It is off unless all three are set.** With no keys the widget is not rendered
and verification is skipped, so a fresh clone can sign up without anyone
provisioning Google Cloud first. `RecaptchaProtection#recaptcha_enabled?` is the
single source of truth and is exposed to views, so the form and the controller
can never disagree about whether a token should be present.

### Protecting another form

```ruby
class ThingsController < ApplicationController
  include RecaptchaProtection

  def create
    @thing = Thing.new(thing_params)
    return render :new, status: :unprocessable_entity unless
      check_recaptcha(action: "thing", model: @thing)
    # ...
  end
end
```

```erb
<%= render "shared/recaptcha", action: "thing" %>
```

The `action` in the view and the controller **must match** — Enterprise treats a
mismatched assessment as invalid, and that is what stops a token minted on a
cheap form being replayed against an expensive one. Failures are added to the
model's errors, so they render with the rest of the form's validation messages.

Notes: the default minimum score is `RecaptchaProtection::DEFAULT_MINIMUM_SCORE`
(0.5, Google's suggested starting point — tune per action with real traffic).
`handle_timeouts_gracefully` is on, so an outage at Google lets requests through
rather than blocking sign-ups; a genuine low score still rejects. Google requires
the badge or a text disclosure, which the shared partial renders. The gem omits
its `<script>` entirely in the test environment (`skip_verify_env`), so tests
never load Google's JS.

## Sign in with Google

Devise `:omniauthable` with `omniauth-google-oauth2`.

```
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
```

**Off unless both are set** — the strategy is not registered and
`google_oauth_enabled?` keeps the button off the sign-in and sign-up pages.
Authorized redirect URI: `https://<host>/users/auth/google_oauth2/callback`.

`omniauth-rails_csrf_protection` is a hard requirement, not a nicety: a GET
request phase is cross-site forgeable (CVE-2015-9284). **Every "Sign in with
Google" control must be a `button_to` (POST), never a `link_to`.**

### The trust rules, in `User.from_omniauth`

1. Known `provider` + `uid` → sign in.
2. A local account already uses this email → link them, **but only if Google
   says it verified the address**. Linking on an unverified email would let
   anyone who can put an address on a Google profile take over the matching
   local account. An account already linked to a different Google `uid` is never
   moved.
3. Otherwise create the account — again only when the email is verified.

New records get a random password because `:validatable` requires one; the user
can set a real one later through password reset. The email is never updated from
Google on later sign-ins: it is the account's identity here, and letting a
Google-side change reassign it would be a takeover vector. Two gotchas worth
knowing: OmniAuth's `InfoHash#name` silently falls back to the email when the
provider sends no name (hence `User.omniauth_name`), and Google reports
verification as either a boolean or the string `"true"`.

Rejections are deliberately vague to the user — spelling out whether an email is
unverified or already linked would tell an attacker whether an account exists.

## Important Patterns

### FriendlyId Usage
Most models use FriendlyId with `use: [:slugged, :finders]`. This means:
- URLs use slugs instead of IDs (e.g., `/articles/my-article-title`)
- Finders work with both slugs and IDs
- Models need a `slug` column (string, indexed)

### Ruby LLM Integration
Configure in `config/initializers/ruby_llm.rb`. Models using `acts_as_chat` and `acts_as_message` automatically get chat functionality with token tracking and tool calling support.

### Vite + Rails Integration
- Vite config base path: `/app/` (see vite.config.js); the only plugins are
  `vite-plugin-ruby` and `@vitejs/plugin-react`.
- Entrypoints are `.jsx`, so the host pages must name the extension:
  `vite_javascript_tag 'admin.jsx'`. Development also needs
  `vite_react_refresh_tag` alongside `vite_client_tag` or Fast Refresh breaks.

### Schema Annotations
Models are annotated with schema info via annotaterb. Run `bin/rails annotaterb:annotate` after migrations to keep comments up to date.


## Feature Workflow

Pull features from the production yourdomainhere.com Features API to manage development workflow.

**Setup:**
1. Get your API token from: Production Admin → Users → Your User → Copy API Token
2. Add to `.env`: `STARTER_API_TOKEN=<your-token>`

**Commands:**
```bash
# Rake tasks
rake feature:list                    # List planned features from production
rake feature:show[slug]              # Show details for a specific feature
rake feature:start[slug]             # Create branch, update status to in_progress
rake feature:complete                # Complete current feature (detects from branch)
rake feature:current                 # Show current feature being worked on

# Shell wrappers (quick access)
bin/feature list                     # Alias for rake feature:list
bin/feature start <slug>             # Alias for rake feature:start
bin/feature complete                 # Alias for rake feature:complete
bin/feature current                  # Alias for rake feature:current
```

**Workflow:**
1. `rake feature:list` - See available features
2. `rake feature:start[slug]` - Creates `feature/<slug>` branch, marks as in_progress
3. Work on the feature, commit changes
4. `rake feature:complete` - Marks as completed, optionally creates PR

## API Token Authentication

Users have an `auth_token` column for stateless API authentication.

**ApplicationController Methods:**
- `authenticate_with_token` - Token-only auth via `x-api-token` header
- `authenticate_user_or_token` - Token OR Devise session auth
- Both set `@current_user` and work with `current_user` helper

**Usage in controllers:**
```ruby
before_action :authenticate_with_token      # Token only
before_action :authenticate_user_or_token   # Token or session
```

**User model:**
```ruby
user.auth_token                  # Get token
user.regenerate_auth_token       # Generate new token
User.find_by_auth_token(token)   # Find by token
```

### Final Points
- Write every prompt that you are given to a PROMPTS.md file so we can keep track of them over time.

