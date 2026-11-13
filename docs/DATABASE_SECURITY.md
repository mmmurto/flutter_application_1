# Database Security Foundation

## Current state

The initial schema is installed in the development Supabase project. Its tables
have Row Level Security enabled, so they fail closed while no policies exist.

Migration `202611010001_security_foundation.sql` prepares the first production
authorization boundary:

- every new account starts as a customer;
- platform administration is separate from restaurant membership;
- restaurant roles are scoped to one restaurant;
- only reviewed, published restaurants and active menu content are public;
- table QR credentials and order records are never publicly selectable;
- clients have no direct write access to restaurants, menus, memberships,
  tables, orders, or order items;
- user profiles are created automatically from Supabase Auth;
- modification timestamps are maintained by database triggers.

The pgTAP suite in `supabase/tests/security_foundation_rls_test.sql` defines the
allow and deny cases for anonymous users, outsiders, restaurant owners, kitchen
staff, and platform administrators. It passes against a local Supabase stack.
Both migrations are already applied to the hosted development project, but the
hosted test runner has not yet executed these assertions there; that open task is
documented in `docs/HANDOFF_HOSTED_PGTAP.md`.

## Deliberately deferred

Do not grant direct client writes to make a screen work. The following require
separate reviewed migrations and server-authoritative functions:

1. platform-controlled restaurant onboarding;
2. staff invitations and role changes;
3. validated menu management with audit events;
4. revocable QR table-session exchange;
5. idempotent order creation with server-calculated prices and totals;
6. valid order-status transitions and history;
7. payment attempts, verified webhooks, refunds, and reconciliation.

## Release rule

Apply migrations to the development project first. Verify anonymous, customer,
restaurant-owner, kitchen, and platform-admin access independently before the
same migration is promoted to staging or production.
