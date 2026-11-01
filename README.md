# Restaurant Platform

Production foundation for a verified restaurant discovery, QR-menu, ordering, and kitchen platform for Azerbaijan.

## Current status

- Flutter targets: Android, iOS, web, Windows, macOS, and Linux.
- Supabase development project connected through compile-time configuration.
- Initial empty database schema is versioned under `supabase/migrations/`.
- Public customer, restaurant-owner, and kitchen routes are separated.
- Staff routes fail closed until authentication and restaurant permissions are implemented.
- No invented restaurant, menu, rating, review, order, or sales data is present in the active application.

## Local configuration

Copy `config/dev.example.json` to `config/dev.json` and add only the Supabase project URL and publishable key. The local file is ignored by Git.

```powershell
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Never place database passwords, service-role keys, payment credentials, SSH private keys, or production personal data in Flutter source or Git.

## Verification

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Documentation

- `docs/PRODUCT_FOUNDATION.md`
- `docs/ARCHITECTURE.md`
- `docs/THREAT_MODEL.md`

## Next security milestone

Design and review versioned migrations for identity, restaurant memberships, RLS policies, server-authoritative order creation, audit events, and payment state. Anonymous Flutter clients must not write arbitrary order or payment records directly.
