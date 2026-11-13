# Restaurant Platform — Azerbaijan

A restaurant discovery and table-ordering platform for Azerbaijan. Customers find approved
restaurants, browse approved menus and prices in AZN, filter by budget per person, and open
directions in Google Maps or Waze. At the table, a printed QR code opens the menu in a phone
browser with no app install; the planned flow sends the order to the kitchen and later accepts
payment through an approved provider. Restaurants get menu, table, QR, staff, and order tools.
Platform staff approve a restaurant before anything about it becomes public.

This repository is a production foundation, not a demo. Nothing about a restaurant may be
published without that owner's approval, and made-up restaurants, menus, ratings, or sales must
not appear in the public product. Synthetic data belongs only in tests or explicitly
development-only previews (see `AGENTS.md`).

## Status

### Working and verified

- One Flutter project for web, Android, iOS, Windows, macOS, and Linux, split into
  `app/`, `core/`, and `features/` layers with a router rather than widget-embedded navigation.
- Public routes: `/` (customer entry), `/r/<restaurantSlug>/table/<qrToken>` (table menu entry),
  `/owner`, `/kitchen`.
- Owner and kitchen routes stop at an access boundary instead of exposing staff tooling, and the
  customer entry exposes no staff navigation. Both are covered by widget tests.
- The QR route reads the restaurant-approved published menu (categories, items, descriptions,
  AZN prices) through the anon role, so the database decides what is public. It fails closed
  with distinct states for missing configuration, an unpublished or empty menu, a failed read
  with retry, and loading.
- Parsing of the public menu is covered by model tests against a response captured from the
  local PostgREST API, plus widget tests for the loaded, empty, and error states.
- Supabase configuration is read at startup from `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY`; the app still starts without them, with database features
  unavailable.
- Two versioned migrations create the schema (profiles, restaurants, restaurant memberships,
  tables, menu categories, menu items, orders, order items) and the security foundation
  (RLS, public/private visibility rules, tenant-scoped staff access, automatic profiles,
  maintained `updated_at`).
- 22 pgTAP security assertions pass against the local Supabase stack.
- CI: Flutter format/analyze/test on every push and pull request; database tests when
  `supabase/**` or the npm files change.

### Partially built — scaffolding only

- The Supabase client is initialized at startup, but no screen reads or writes real data yet.
- `/owner` and `/kitchen` are placeholders for an authorization boundary, not real sign-in.
- Both migrations are applied to the hosted development project
  (`restaurant-qr-platform-dev`). Hosted pgTAP verification is still blocked; see
  [Where to continue](#where-to-continue).
- The table menu route accepts a restaurant slug and table token but has no data layer for the
  table itself: the QR token is not yet exchanged for a table session, and there is no cart or
  ordering.

### Not started

Authentication and staff invitations; restaurant onboarding and platform approval; menu
drafting and publishing; discovery search, AZN budget filter, and maps/waze links; QR
generation and revocation; cart and server-validated order creation; kitchen queue and order
status transitions with audit history; payments and provider webhooks; the admin interface;
AZ/EN/RU localization; Android and iOS release builds; subscriptions and reporting.

## Repository layout

```text
lib/
  main.dart                     environment setup only
  app/                          MaterialApp, router, route table
  core/                         configuration, theme, shared widgets
  features/                     customer, menu, staff presentation screens
supabase/
  config.toml                   local stack configuration (ports, seed, auth)
  migrations/                   versioned schema and security migrations
  seed.sql                      intentionally empty; no production-like seed data
  tests/                        pgTAP security suite (22 assertions)
test/                           Flutter widget tests
docs/                           product, architecture, security, and handoff docs
config/dev.example.json         template for local Supabase values
.github/workflows/              Flutter CI and Database CI
```

## Windows quick start

Run every command from the repository root in PowerShell. Git commands must be run there too,
not from `C:\flutter`.

### Prerequisites

- **Git** with an SSH key registered on your own GitHub account. The repository is private, so
  you need an invitation first — see [`docs/PARTNER_ACCESS.md`](docs/PARTNER_ACCESS.md).
- **Flutter stable** with Dart (last verified: Flutter 3.47.5 / Dart 3.13.4, SDK at
  `C:\flutter`; `C:\flutter\bin` must be on `PATH` so `flutter` and `dart` resolve).
- **Node.js 24 and npm** (last verified: Node v24.21.0, npm 11.19.0). CI pins Node 24.
- **Docker Desktop with WSL 2** for the local Supabase stack. Start Docker Desktop before
  any database command.
- **Chrome** for the web target.
- **Android Studio** only when you work on Android builds. Not needed for web, docs, or
  database work.

### 1. Clone

```powershell
git clone git@github.com:mmmurto/flutter_application_1.git
Set-Location .\flutter_application_1
```

### 2. Install dependencies

```powershell
flutter pub get
npm ci
```

`npm ci` installs the Supabase CLI pinned in `package.json` (`2.122.0`) from
`package-lock.json`. Keep using the pinned version; do not run `npm install -g supabase` or
upgrade the CLI as part of unrelated work. The CLI prints an update notice because a newer
major version exists — that notice is expected and not an error.

### 3. Start local Supabase

Docker Desktop must be running. The project scripts pin the Docker network name
`local-network`; create it once on a new machine if it is missing:

```powershell
docker network ls --format "{{.Name}}"
docker network create local-network   # only when the line above does not list it
```

```powershell
npm run db:start     # supabase start --network-id local-network
npm run db:test      # supabase test db --network-id local-network
npm run db:stop      # supabase stop --network-id local-network
```

Always use these npm scripts. Running `npx supabase test db` directly on Windows fails with
`network supabase_network_flutter_application_1 not found` because the generated network name
is not the one the local stack uses.

`db:start` applies both migrations and the intentionally empty `supabase/seed.sql`, then prints
the local URLs and keys. The local API is `http://127.0.0.1:54321` and the database listens on
port `54322`. Local keys are throwaway values for your own machine.

Useful extras:

```powershell
npx supabase status                                  # print local URLs and keys again
npx supabase db reset --local --network-id local-network   # reapply migrations; wipes local data
```

`db reset` only touches your local stack. Never run a reset against the hosted project.

### 4. Configure the Flutter app

Create your own config file from the checked-in template:

```powershell
Copy-Item .\config\dev.example.json .\config\dev.json
```

Fill in the two values from `npm run db:start` (or `npx supabase status`):

```json
{
  "SUPABASE_URL": "http://127.0.0.1:54321",
  "SUPABASE_PUBLISHABLE_KEY": "<local publishable key printed by the CLI>"
}
```

`config/dev.json` is ignored by Git. Never commit it, a database password, a service-role or
secret key, a payment credential, or an SSH private key. The app uses only the publishable key.

### 5. Run the app

```powershell
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Without `--dart-define-from-file`, the app still starts but treats the backend as
unconfigured, so `/r/<slug>/table/<token>` shows "Service is not configured". That is the
expected fail-closed behaviour.

## Verification

Run these before opening a pull request. They are the same checks CI runs.

| Command | Success looks like |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | `Formatted N files (0 changed)` |
| `flutter analyze` | `No issues found!` |
| `flutter test` | `+8: All tests passed!` |
| `npm run db:test` | `Files=1, Tests=22` and `Result: PASS` |
| `git diff --check` | No output |

A passing `npm run db:test` also prints two notices: `extension "pgtap" already exists,
skipping` and a `DIAG ...` line describing the test session. Both are informational. The
`DIAG` notice is temporary diagnostic output added while the hosted pgTAP problem is open.

CI results live in the **Actions** tab of the GitHub repository:

- **Flutter CI** runs on every push and pull request.
- **Database CI** runs when `supabase/**`, `package.json`, `package-lock.json`, or its own
  workflow file change. It starts its own throwaway stack (`npx supabase start`), so it does
  not depend on the `local-network` workaround.

## Contributor workflow

1. Create a branch from an up-to-date `main`: `git switch -c feat/short-description`.
2. Make one focused change. Keep migrations, policies, and docs separate from refactors.
3. Run the checks that match the change: Flutter checks for `lib/` and `test/`, database tests
   for `supabase/`, and `git diff --check` for everything.
4. Commit with a short imperative message, push the branch, and open a pull request into
   `main`. Describe what changed and paste the observed command results.
5. Wait for review and green CI before merging. Do not push directly to `main`.

Do not commit `config/dev.json`, `.env*` files, `supabase/.temp/`, build output, secrets, or
customer/restaurant personal data. Do not add invented restaurants, menus, prices, ratings, or
orders to make a screen look complete.

## Partner access

Two separate decisions: GitHub repository access, and hosted Supabase access. Steps,
recommended roles, and the list of things never to hand over are in
[`docs/PARTNER_ACCESS.md`](docs/PARTNER_ACCESS.md). Every person uses their own GitHub account,
SSH key, and Supabase login.

## Documentation map

- [`docs/PRODUCT_FOUNDATION.md`](docs/PRODUCT_FOUNDATION.md) — product objective, pilot scope,
  non-goals.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — client boundaries, source layout, backend
  rules, environments.
- [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) — protected assets, threats, required controls.
- [`docs/DATABASE_SECURITY.md`](docs/DATABASE_SECURITY.md) — what the security migration does,
  what is deliberately deferred, release rules.
- [`docs/HANDOFF_HOSTED_PGTAP.md`](docs/HANDOFF_HOSTED_PGTAP.md) — the open hosted pgTAP
  investigation, evidence so far, and the exact next steps.
- [`docs/PARTNER_ACCESS.md`](docs/PARTNER_ACCESS.md) — inviting a partner to GitHub and Supabase.
- `AGENTS.md` — engineering rules every contributor and AI assistant must follow.

## Where to continue

**Next task: make the hosted pgTAP suite run.** The security migration is applied to hosted
development, but the runner stops before any assertion, so the access rules are not yet verified
there.

- Relevant files: `supabase/tests/security_foundation_rls_test.sql`, `supabase/config.toml`,
  [`docs/HANDOFF_HOSTED_PGTAP.md`](docs/HANDOFF_HOSTED_PGTAP.md).
- Last observed hosted result: `extension "pgtap" already exists, skipping`, then failure at
  `select plan(22);` with `function plan(integer) does not exist`, and `Tests=0`.
- Local result on the same file: `Files=1, Tests=22`, `Result: PASS`.
- Current working tree: the test harness has uncommitted changes (schema-aware `search_path`
  plus a temporary `DIAG` notice). The last commit touching the file is `26b232a`.
- Completion: a hosted run of `npx supabase test db --linked` that reports `Tests=22` and
  `Result: PASS`, with the `DIAG` notice showing where pgTAP actually lives in that session.

`docs/HANDOFF_HOSTED_PGTAP.md` lists the evidence already gathered, why the earlier dashboard
query cannot settle the question, and the exact next diagnostic step. Hosted database changes
need owner review, and the applied migrations and access policies must not be altered to make
tests pass.

After that: authentication and onboarding, then menu and discovery, QR ordering, kitchen
operations, and payments, in that order. See `docs/PRODUCT_FOUNDATION.md` for scope.
