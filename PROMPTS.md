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
