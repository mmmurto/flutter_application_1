# Initial Threat Model

## Protected assets

- Restaurant tenancy and staff permissions
- Menu prices and availability
- Table QR credentials
- Orders, totals, and status history
- Payment and refund state
- Customer and merchant personal data
- Secrets, signing keys, and webhook credentials

## Primary threats

- A restaurant reading or changing another restaurant's data
- A customer opening owner or kitchen functionality
- Forged or copied table QR tokens
- Client-side price or quantity manipulation
- Duplicate orders caused by retries
- Invalid order-status transitions
- Forged payment-success callbacks
- Leaked service-role, payment, database, or signing credentials
- Automated abuse of anonymous ordering endpoints

## Required controls before pilot

- Reviewed RLS policies and tenant-isolation tests
- Server-authoritative order creation and totals
- Idempotency keys for order/payment operations
- Revocable QR tokens
- Verified, idempotent payment webhooks
- Staff invitations and least-privilege roles
- Audit events for privileged changes and order transitions
- Rate limiting, monitoring, backups, and restore testing
- No production secrets or personal data in AI tools, logs, or Git
