# Restaurant Platform Engineering Rules

This repository is a production startup, not a demo application.

- Never invent or publish restaurant names, menus, ratings, reviews, locations, sales, or customer data.
- Synthetic fixtures are allowed only in tests or explicitly development-only preview code.
- Never commit `config/dev.json`, database passwords, service-role keys, payment credentials, SSH private keys, or production personal data.
- The Flutter client is not authoritative for prices, totals, order status, payments, refunds, roles, or tenant access.
- Database migrations, RLS policies, authentication, ordering, payments, and secret handling require focused review and tests.
- Keep customer, restaurant-owner, kitchen, and platform-admin surfaces behind separate routes and authorization boundaries.
- Prefer small, reviewed commits. Do not let multiple agents edit the same file concurrently.
- Before handing off code, run formatting, `flutter analyze`, and `flutter test`.
