# Deployment and payments

Two decisions the owner keeps asking about: **do we need to buy a server**, and **how do we take
Apple Pay / Google Pay**. This page records what is true today, what the pilot actually needs,
and what only the owner can do.

## 1. Hosting: no server purchase needed for the pilot

The Flutter app is a static web build, and the database, auth, storage, and functions already run
on the hosted Supabase project. That means the pilot needs **static hosting plus the existing
Supabase project** — not a VPS.

What is needed:

| Piece | Pilot choice | Notes |
| --- | --- | --- |
| Web hosting | Cloudflare Pages, Vercel, or Netlify (free tier) | Serves `build/web` over HTTPS. |
| Domain | One domain or subdomain, e.g. `app.<domain>` | QR codes must be stable and HTTPS. |
| Database/auth | Existing `restaurant-qr-platform-dev` | Promote to a separate production project before real data. |
| Server | None | Add one only if a later requirement cannot be met with Supabase Edge Functions. |

Build command for a static host (values are public client configuration, not secrets):

```text
flutter build web --release \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-or-anon-key>
```

Output directory: `build/web`. Pin the Flutter version in the host's build settings (the repo is
developed on Flutter 3.47.x) so a host upgrade never changes the build silently.

Rules that matter:

- The **publishable/anon** key is designed to ship in a browser bundle; RLS is what protects
  data. The **service-role/secret** key must never appear in the app, the bundle, or Git.
- `config/dev.json` stays local. Hosted builds get their values from the host's environment
  variables, not from a committed file.
- Flutter web currently uses hash URLs (`/#/r/<slug>/table/<token>`). Clean paths
  (`/r/<slug>/table/<token>`) need `usePathUrlStrategy` **and** a host rewrite of every path to
  `index.html`; if that rewrite is missing, printed QR links break. Decide once, before printing
  QR codes for a restaurant.
- Before real pilot data: create a separate production Supabase project, apply the reviewed
  migrations, and keep development and production credentials apart.

Owner actions: choose the host and domain, create the production Supabase project, then send the
partner the hosting account or deploy access. Nothing needs to be purchased to keep building.

## 2. Payments: provider first, code second

Apple Pay and Google Pay are **wallets**, not merchant accounts. In Azerbaijan they are reached
through a licensed acquirer or payment service provider (PSP). The provider decides whether the
wallet methods are enabled for a specific merchant, at what fee, and with what settlement and
refund terms.

Local providers that publicly document wallet support include:

- **Epoint** — documents Apple Pay and Google Pay support, with a token payment widget embedded
  by iframe or webview: <https://www.epoint.az/en/free-business/pays>,
  <https://developer.epoint.az/en/token-payment>.
- **Payriff** — its hosted checkout documentation lists Apple Pay and Google Pay among the
  methods presented on one payment page: <https://docs.payriff.com/docs/payment-methods>.

Treat those pages as a starting point, not as an offer. Confirm current support, pricing,
settlement currency, refund handling, and required documents directly with the provider's
merchant team.

### What the owner must do before any payment code is written

1. Choose one PSP and request merchant onboarding for the company entity.
2. Sign the merchant agreement; agree fees, settlement timing, refund and chargeback rules.
3. Ask explicitly: *"Are Apple Pay and Google Pay enabled for web checkout on this merchant
   account, and what is required to turn them on?"*
4. Obtain sandbox credentials: merchant identifier, API keys, and the callback/webhook URL
   format.
5. Decide **when** money is taken: on order placement, after the meal, or both. This changes the
   order state machine, not just the checkout screen.

### What the code will need (not built yet)

- A `payment_attempts` table with an idempotency key, amount, currency (`AZN`), provider
  reference, and status — amounts always recalculated on the server.
- A server-side checkout session created by a reviewed function; the client only receives a
  hosted-checkout URL.
- A verified, idempotent webhook that marks an order paid only after the provider signature or
  callback secret checks out.
- Refund and reconciliation paths, plus receipts that match the merchant agreement.
- Apple Pay on the web also requires hosting an Apple domain-association file on the final
  domain; Google Pay requires a merchant ID from the Google Pay Business Console. Both require
  HTTPS on the domain you actually print in QR codes.

Until a provider is contracted, the app must not fake a payment, show "paid", or collect card
details. The product rule in `AGENTS.md` stands: prices, totals, and payment state are
server-authoritative.

## 3. Checks before a public pilot

- [ ] Production Supabase project created; migrations applied and pgTAP verified there.
- [ ] Hosted pgTAP verification green (`Tests=22`, `Result=pass`) — see
      [`HANDOFF_HOSTED_PGTAP.md`](HANDOFF_HOSTED_PGTAP.md).
- [ ] Email sign-up policy decided in Supabase Auth; staff accounts created only by the owner.
- [ ] Domain + HTTPS + URL strategy decided; one test QR code printed and scanned from a phone.
- [ ] Backups and restore tested on the production project.
- [ ] PSP agreement signed and sandbox credentials stored outside Git.
- [ ] One consenting restaurant onboarded with its approved data only.
