# Prompts Log

## Marketing Funnel Tracking System

**Date:** 2026-01-15

**Prompt:**
I want to create a system that allows me to track various marketing funnels. Here is the idea. We need to create a Funnel model that has a name (include a Friendly ID slug based on the name). We also need a LandingPage controller with four pages named lead_page, book_call_page, order_page and order_completed_page. When each of these pages is viewed we need to track an event (using Ahoy Events). All of these pages will include the Funnel slug in the URL so we can track them. To manage Funnels we need to be able to create, update and delete them in the Admin Vue app. Lastly please include a Funnel metrics page in the Admin app that will allow viewing metrics for all funnels or an individual funnel.

## Fix Database Migration Conflicts

**Date:** 2026-01-23

**Prompt:**
I am having trouble running rake db:migrate and getting the database in a good state because it always says that the chats relation already exists... please do whatever is necessary to get the database in a good state

## Theme System Overhaul

**Date:** 2026-02-16

**Prompt:**
Replace the old 5-color theme picker (purple/orange/blue/green/amber) with a full theme system that applies all properties from JSON theme definitions in lib/themes/. The new system supports dark/light mode per theme, dynamically loads Google Fonts, and applies 7 color tokens (primary/secondary/accent/background/surface/text/textMuted) plus typography, border-radius, and shadow via CSS custom properties. A Rails ThemeHelper reads theme JSON files, injects them as window.__themes, and Alpine.js applies the selected theme at runtime. Any new theme JSON added to lib/themes/ is automatically picked up.

## Starter Audit & Cleanup

**Date:** 2026-06-02

**Prompt:**
Please review this and let me know your thoughts — followed by: I dont see .env in github and it is in .gitignore. We need to confirm that is really an issue before doing anything. Everything else please fix.

Scope covered (cross-repo, from parent starter dir): added rack-cors gem + config/initializers/cors.rb gated on CORS_ORIGINS, created .env.example listing required keys, fixed bin/dev default PORT 3001 → 3000. Mobile side: signOut now calls DELETE /api/v1/sessions before clearing local token; users/current handler stopped accepting two shapes and asserts { user }; README rewritten from stock Expo boilerplate to starter-specific docs. Parent CLAUDE.md typo fixed (cd ails-ai-starter).

## bin/new-app — one-command fork of the starter

**Date:** 2026-06-02

**Prompt:**
The goal of this setup is to make it lightning fast to clone and create new applications so that my clients can use AI agents to build applications themselves. (After scoping discussion:) build bin/new-app first but do not do this piece: Second layer: generators that scaffold the full vertical for common patterns.

Built rails-ai-starter/bin/new-app: Ruby script (stdlib only) that rewrites RailsAiStarter / rails-ai-starter / rails_ai_starter / "Rails AI Starter" placeholders across the Rails repo and the sibling mobile-app-starter, patches app.json (name/slug/scheme/ios.bundleIdentifier/android.package), removes config/credentials.yml.enc + master.key so credentials:edit can regenerate, resets PROMPTS.md, and optionally nukes .git for a fresh history. Flags: --name --slug --module --bundle-id --github-org --fresh-git --skip-mobile --non-interactive. Verified end-to-end on copies in /tmp: 13 Rails files + 4 mobile files rewritten, app.json correctly structured, idempotent on re-run, fresh-git produces single Initial commit on both repos.

## bin/bootstrap-droplet — DO + Dokku provisioning

**Date:** 2026-06-02

**Prompt:**
Ok... do the droplet piece next

Built rails-ai-starter/bin/bootstrap-droplet: Ruby (stdlib only — Net::HTTP + Socket + system ssh). Validates a DO API token, auto-discovers the latest marketplace Dokku image (falls back to ubuntu-24-04-x64 with confirmation), picks an SSH key from the user's DO account (lists if multiple), shows a cost-aware plan + confirmation, creates the droplet, polls until active + reachable, waits for the Dokku CLI to finish first-boot setup, then runs idempotent dokku commands over ssh: apps:create, postgres plugin install + service + link, ensures the cache/cable databases the Rails 8 multi-db config expects (docker exec into the postgres container), sets RAILS_MASTER_KEY (read from local config/master.key) + RAILS_LOG_TO_STDOUT + RAILS_SERVE_STATIC_FILES + CORS_ORIGINS, installs letsencrypt plugin + domain + cron if --domain, adds a `dokku` git remote locally, optionally `git push dokku main` at the end. Flags: --token --app --droplet-name --region --size --image --ssh-key --domain --email --push-env --deploy --non-interactive --yes.

Notes: lib/tasks/deploy.rake is the older approach (hardcoded app name, password-auth Net::SSH, adds Heroku buildpacks despite the Dockerfile) and is superseded by this — left in place, didn't delete unprompted. Not run end-to-end yet since spinning up a real droplet costs money; verified syntax, --help, default_app_name derivation (RailsAiStarter → rails-ai-starter), abort path when token missing. Dokku CLI calls audited (replaced fictional postgres:exists/postgres:linked checks with postgres:info / config:get DATABASE_URL).

## scripts/testflight-init.js — Expo → TestFlight bootstrap

**Date:** 2026-06-02

**Prompt:**
Ok... go ahead with the TestFlight piece next

Built mobile-app-starter/scripts/testflight-init.js (Node, stdlib only). Leans entirely on eas-cli for the slow/hard parts (codesigning, bundle-id registration with Apple, ASC app record creation, IPA upload) and acts as config glue. Steps: verifies eas-cli installed (offers to npm install -g), runs eas whoami (or eas login), reads app.json bundle id and refuses if it's still the com.example.* placeholder, prompts for Apple Team ID + ASC API key Issuer/Key IDs + path to .p8, copies the .p8 into ./credentials/ (chmod 600) and adds credentials/ to .gitignore, writes eas.json (preserves existing custom config via shallow merge — verified by adding env block and re-running), runs eas init if no projectId, then triggers `eas build --platform ios --profile production --auto-submit`. Flags: --apple-team-id, --ascapi-issuer-id, --ascapi-key-id, --ascapi-key-path, --sku (default: bundle id), --language (default: en-US), --skip-build, --non-interactive, --yes. Also added `npm run testflight:init` alias in package.json.

Caught one bug during local testing: in --non-interactive mode the SKU prompt still blocked because the default-fallback path called prompt() unconditionally. Fixed by defaulting SKU to bundle id silently (`opts.sku ||= bundleId`).

## launch-starter — non-technical client onboarding via Claude Code

**Date:** 2026-06-02

**Prompt:**
If I was to offer this as a service to clients what would the best user experience be for them assuming they are not technical but they were part of my coaching program and would have access to me and the community if they needed help. ... build it as siblings

Built /Users/harris/Dev/starter/launch-starter/ as a third sibling repo to rails-ai-starter and mobile-app-starter. Layout: README.md (client-facing onboarding — install Claude Code, open in claude, type /launch), CLAUDE.md (behavioral primer — one question at a time, surface every spending decision, never improvise, never run scripts without confirmation), LAUNCH.md (the 10-phase workflow Claude follows: greet → name app → detect current state for resumability → clone the two starters as siblings → install-mac-deps → bin/new-app → bin/setup → verify Rails boots → mobile npm install → optional droplet deploy → optional TestFlight → wrap up), and .claude/commands/launch.md (the /launch slash command, points at LAUNCH.md).

Also added preflight scripts: rails-ai-starter/bin/preflight (bash, prints homebrew/ruby/node/postgres/gems/master_key/env_file/renamed/dev_db/dokku_remote as key=value lines) and mobile-app-starter/scripts/preflight.js (node, prints node/npm/eas_cli/node_modules/env_file/eas_json/app_slug/bundle_id/renamed/eas_linked/bundle_placeholder/asc_key). Both read-only, exit 0 always, designed for Claude to parse on /launch invocation to resume mid-flow rather than restart. Also added `npm run preflight` alias in mobile package.json.

## Shared design system, Ahoy analytics, and an internal Logs system (replacing Rollbar)

**Date:** 2026-08-27

**Prompt:**
The rails-ai-starter and the mobile-app-starter applications need to be updated to have styling like that which is found in ../FitnessHQ (Rails and mobile). We also need to make it clear that ahoy analytics is the preferred metrics/analytics tool for these applications. We also need a very simple logs system (logs model) that we use for logging exceptions and there needs to be an Admin view for logs and a way to send and manage notifications for logs. I am tired of paying for Rollbar which is total crap. Also update the claude.md file in the rails application with notes about this and that any future development needs to surgically post exceptions and errors to our internal logs system. We do not want spam in there. Rollbar does not work for me because is logs so much crap.

**Styling.** Ported FitnessHQ's design system into both repos so the two halves of a project read as one product: warm neutrals (cream `#fffaf0` canvas, warm-black `#1c1410` ink), soft rounded surfaces, low-opacity shadows, Outfit typeface, purple `#7c3aed` brand. On Rails this became a token layer in `app/assets/tailwind/application.css` — `--theme-*` runtime vars (still driven by the existing Alpine theme switcher, plus a new `lib/themes/starter-theme.json` that is now the default) bridged into Tailwind 4 `@theme` colors, plus semantic component classes (`.btn-*`, `.card`, `.admin-table`, `.badge-*`, `.alert-*`, `.stat-tile`, `.nav-link`, `.form-*`). Gotcha worth remembering: Tailwind 4 cannot `@apply` a class defined in `@layer components`, so the composable bases (`btn`, `badge`, `alert`) are `@utility` instead. Swept every ERB view, Devise page, admin Vue page and the admin shell off `gray-*`/`purple-*`/`sky-*` literals onto the tokens. The admin/app SPA host pages now load Outfit and serialize the current user into `window.__currentUser`, replacing a commented-out boot fetch.

On mobile, replaced the 5-token Expo template theme with the full FitnessHQ token set (`Colors` light/dark, `Brand` ramp, `Spacing`, `Radii`, `Shadows`, `FontWeightFamily`), loaded Outfit via `@expo-google-fonts/outfit`, and — unlike FitnessHQ, which never extracted them — pulled the repeated recipes into real primitives under `src/components/ui/` (`Button`, `Card`, `TextField`, `Screen`, `Section`). Added `src/constants/branding.ts` as the single rename point. Deleted the duplicate ungated `src/app/index.tsx` / `explore.tsx` routes that shadowed the `(authed)` ones, renamed the Explore tab to Profile (with sign-out, which the starter had defined but never called), and installed the missing `expo-secure-store` that `auth-storage.ts` had been importing without it being in package.json.

**Ahoy.** Turned on `Ahoy.api`, added an `Ahoy::Store` that stamps `user_id` and stops ahoy's bot filter discarding native-app traffic, and added `app/services/analytics.rb` as the tracking helper. Mobile posts to a new `POST /api/v1/events` with an allow-list (`Analytics::CLIENT_REPORTABLE`) so the server drops anything already recorded server-side rather than double-counting; `src/lib/visit.ts` mints `Ahoy-Visitor`/`Ahoy-Visit` headers so anonymous activity stitches to the user at sign-in.

**Logs.** New `Log` model (level/source/message/error_class/backtrace/context/fingerprint/occurrences/resolved_at) and `LogSubscription` (email or Slack, `min_level`, `throttle_minutes`). The key design decision, given the complaint about Rollbar noise: capture is *narrow by default*. `LogErrorSubscriber` hooks Rails' own error reporter, which in Rails 8 already means only unhandled 500s (`rescue_responses` filters out 404/400/422 before we ever see them) and Active Job failures *after* retries are exhausted — plus an explicit `IGNORED` list as a second gate. Same-fingerprint failures roll up into one row with an `occurrences` counter inside a 24h window, where the fingerprint normalizes numbers/UUIDs/hex out of the message and drops the line number from the first app frame, so `id=42` and `id=43` are one problem and the row survives code drift. Admin UI at `/admin/logs` (filter by status/level/source/search, paginate, resolve/reopen, bulk resolve, delete resolved) and `/admin/log-notifications` (CRUD plus a "Test" button that sends a real notification).

Two real bugs fell out of writing the smoke tests, both worth recording. First: `Log.sanitize_context` originally called `to_json` on arbitrary context values, and a Rails routing object — an Enumerable whose JSON serialization recurses — blew the stack *inside the error handler*, turning a plain template error into a `SystemStackError`. Fixed by coercing every value to a JSON primitive with depth/entry/size caps and never calling `to_json` on an unknown object (`to_s` is overridden far more safely than `to_json` is implemented), and by widening the rescue to `Exception` (re-raising signals) since `SystemStackError`/`NoMemoryError` are not `StandardError`. A logger that can crash the request it is logging is worse than no logger. Second: `Contact` had `belongs_to :company, optional: true` with no `Company` model and a string `company` column, which meant the contact form had never rendered — the test suite had been broken since before this work (empty `users.yml` fixtures collided on the unique email index and `static_controller_test.rb` referenced route helpers that don't exist), so nothing had ever exercised it. Fixed the fixtures, the static tests, added Devise/ActiveJob test helpers, and the suite went from 6 errors to 88 passing tests / 222 assertions.

Also removed the one dead `Rollbar.error(e)` call (the gem was never actually installed) along with the unrouted `ContactsController#create_action_plan` that referenced five undefined constants, and wrote a real `SlackService` — it was referenced in three places but had never existed, so those call sites would have raised `NameError`.

Still open: production SMTP is commented out in `config/environments/production.rb`, so email log notifications won't deliver until that's configured (Slack works without it). `Contact#first_name` returns `name.split[1]` — the second word, not the first — left alone as out of scope.
