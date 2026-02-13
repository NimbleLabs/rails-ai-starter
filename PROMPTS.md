# Prompts Log

## Marketing Funnel Tracking System

**Date:** 2026-01-15

**Prompt:**
I want to create a system that allows me to track various marketing funnels. Here is the idea. We need to create a Funnel model that has a name (include a Friendly ID slug based on the name). We also need a LandingPage controller with four pages named lead_page, book_call_page, order_page and order_completed_page. When each of these pages is viewed we need to track an event (using Ahoy Events). All of these pages will include the Funnel slug in the URL so we can track them. To manage Funnels we need to be able to create, update and delete them in the Admin Vue app. Lastly please include a Funnel metrics page in the Admin app that will allow viewing metrics for all funnels or an individual funnel.

## Fix Database Migration Conflicts

**Date:** 2026-01-23

**Prompt:**
I am having trouble running rake db:migrate and getting the database in a good state because it always says that the chats relation already exists... please do whatever is necessary to get the database in a good state

## Integrate assistant-ui for AI Chat

**Date:** 2026-02-12

**Prompt:**
Implement the plan to integrate assistant-ui for AI Chat. This includes: Rails backend with Chat CRUD API endpoints and SSE streaming completions controller using ActionController::Live and ruby_llm, React frontend using @assistant-ui/react with LocalRuntime + RemoteThreadListAdapter for multi-thread chat support, thread sidebar with create/delete, message streaming via SSE, and message history loading. Uses the existing Chat/Message/ToolCall models with acts_as_chat/acts_as_message from ruby_llm gem.
