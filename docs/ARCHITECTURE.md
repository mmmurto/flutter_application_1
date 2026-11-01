# Architecture

## Client boundaries

- `/` is the public customer entry.
- `/r/:restaurantSlug/table/:qrToken` is the public table-session entry.
- `/owner` is an authenticated restaurant-management surface.
- `/kitchen` is an authenticated kitchen surface.
- Platform administration will use a separate authenticated route tree.

Customer, restaurant, kitchen, and platform-admin access must never be exposed through a shared unauthenticated navigation shell.

## Source layout

```text
lib/
  app/                 application setup and routing
  core/                configuration, theme, errors, shared widgets
  features/            customer, menu, ordering, owner, kitchen, auth
  main.dart            environment initialization only
```

## Backend rules

- Supabase PostgreSQL is the system of record.
- Flutter uses only the publishable client key.
- The service-role key is server-side only.
- RLS enforces restaurant tenancy and staff roles.
- Anonymous customers never insert arbitrary order or payment rows directly.
- A transactional RPC or Edge Function validates QR tokens, loads authoritative prices, calculates totals, and creates orders idempotently.
- Payment success is accepted only from a verified provider webhook.

## Environments

Use separate development, staging, and production projects before pilot data is loaded. Local configuration files remain untracked.
