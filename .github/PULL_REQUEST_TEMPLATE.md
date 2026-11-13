## What changed

<!-- One or two sentences. Link the issue if there is one. -->

## Checks run

<!-- Paste the commands you actually ran and their result. Remove lines that do not apply. -->

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `npm run db:test` (when `supabase/**` changed)
- [ ] `git diff --check`

## Safety review

- [ ] No invented restaurant, menu, order, or customer data added outside tests or a clearly
      labelled local development fixture.
- [ ] No secrets, tokens, keys, `config/dev.json`, or `supabase/.temp/` contents committed.
- [ ] Migrations and RLS policies, if touched, include pgTAP coverage and keep existing
      assertions passing.
- [ ] Prices, totals, order status, and permissions are still decided by the database, not the
      Flutter client.
