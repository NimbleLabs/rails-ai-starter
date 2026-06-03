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
