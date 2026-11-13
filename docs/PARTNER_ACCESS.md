# Partner access

Two independent decisions: access to the **GitHub repository** and access to the **hosted
Supabase project**. A partner may need one, both, or neither. Local development needs only
GitHub access, because the database runs in the partner's own Docker.

Rule for both: each person uses their own account, own SSH key, and own credentials. Never send
a password, access token, SSH private key, `.env` file, or `config/dev.json`.

## 1. GitHub repository access

The repository `mmmurto/flutter_application_1` is private. Cloning fails with "Repository not
found" until the invitation is accepted.

Owner steps (GitHub website):

1. Open the repository, then **Settings → Collaborators and teams → Add people**.
2. Enter the partner's GitHub username or the email tied to their account.
3. Choose the least role that fits the work:
   - **Write** — normal development: push feature branches and open pull requests. This is the
     usual choice for a developer.
   - **Read** — review, reading, and running the project locally without pushing. This is
     enough for a reviewer, designer, or advisor.
4. Send the invitation. The partner accepts it from the notification or the repository URL.

Partner steps:

```powershell
ssh -T git@github.com          # confirms their own SSH key is registered with GitHub
git clone git@github.com:mmmurto/flutter_application_1.git
```

If `ssh -T` reports a permission error, the partner adds their own public key under
**GitHub → Settings → SSH and GPG keys**. The key belongs to the partner's account, never to the
repository.

No repository secrets or GitHub Actions secrets are required today. Both workflows use only the
automatic `GITHUB_TOKEN` with `contents: read`.

Do not grant **Admin**. Nobody needs it to contribute, and it allows destructive repository and
billing changes.

## 2. Hosted Supabase access

Access to `restaurant-qr-platform-dev` is separate and usually unnecessary. The partner can run
the full local stack (`npm run db:start`, `npm run db:test`) without it. Grant it only when the
agreed work requires the hosted project — for example the open hosted pgTAP task in
[`HANDOFF_HOSTED_PGTAP.md`](HANDOFF_HOSTED_PGTAP.md).

Owner steps:

1. Sign in to the Supabase dashboard and open the organization that owns
   `restaurant-qr-platform-dev`.
2. **Organization → Team → Invite member**, using the partner's own email address.
3. Choose the least role that works:
   - **Read-only** — inspect the project, read the SQL editor, review migrations and logs. Start
     here for documentation, review, or Flutter-only work.
   - **Developer** — run hosted SQL and the hosted test runner. Use this only for the specific
     database task, and downgrade afterwards if the partner no longer needs it.
   - **Owner/Administrator** — billing, project deletion, member management. Nobody outside the
     owner needs this.
4. Tell the partner which project is in scope. Do not invite them to unrelated projects.

Partner steps: accept the email invitation, then authenticate the CLI with their own account
(`npx supabase login`). Connection strings and keys are visible to them in the dashboard under
**Project Settings → Database**; they copy them themselves.

The local stack prints its own throwaway keys (`sb_publishable_...`, `sb_secret_...`) on every
machine. Those are not shared credentials and must not be reused for hosted work.

## What never changes hands

- Database password, connection strings containing passwords, service-role or secret keys.
- Supabase access tokens, GitHub personal access tokens, SSH private keys, `.env` files.
- `config/dev.json` contents, `supabase/.temp/` contents (project link and local secrets).
- Payment-provider credentials and merchant onboarding details.
- Restaurant owner contact data or anything a restaurant has not agreed to publish.

If any of these was already sent through chat, email, or a ticket, rotate it: Supabase
**Project Settings → Database → Reset database password**, Supabase account tokens, and the
affected GitHub/SSH credentials.

## Shared hosted development database

The hosted development project is shared, has no production data, and both migrations are
already applied there.

- Coordinate before `npx supabase db push`. One person applies migrations at a time.
- Never run `supabase db reset --linked` or any destructive command against it.
- Never edit applied migrations; add a new one.
- Treat hosted test runs as shared events: they create and drop test objects, so avoid running
  them while someone else is diagnosing the same database.
- Keep production and staging out of scope until the owner creates them.

## Owner checklist

- [ ] Partner's GitHub username (or account email) recorded.
- [ ] GitHub invitation sent with the smallest sufficient role, accepted by the partner.
- [ ] Decision recorded: does this partner need hosted Supabase access at all?
- [ ] If yes: Supabase invitation sent as **Read-only** or **Developer**, project scope stated.
- [ ] Partner confirmed they will use their own credentials and will not share secrets.
- [ ] No secrets, tokens, keys, or machine-specific config were sent with the invitation.
- [ ] Optional: Figma file shared as **can view** if design references are needed.
- [ ] Optional: Android Studio / Play Console / App Store access deferred until release work.
