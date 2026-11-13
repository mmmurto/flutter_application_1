# Handoff: hosted pgTAP verification

Status: **open**. The security migration is applied to the hosted development project, but the
pgTAP suite has never executed a single assertion there. This page records what has been
observed, what is still unknown, and the exact next steps. It is the task referenced by
"Where to continue" in the root `README.md`.

Project: `restaurant-qr-platform-dev` (linked ref recorded in `supabase/.temp/linked-project.json`).
Local stack: Supabase CLI `2.122.0` (pinned in `package.json`), Postgres 17, Docker Desktop.

## Completion criteria

A hosted run that prints `Files=1, Tests=22` and `Result: PASS`, with the temporary `DIAG`
notice showing where pgTAP lives in that session, and with both migrations and all access
policies unchanged.

## Last observed results

Hosted, owner-run (`npx supabase test db --linked`):

```text
extension "pgtap" already exists, skipping
... failed at select plan(22);
function plan(integer) does not exist
Tests=0
```

Local, reproduced today on this machine:

```text
Connecting to local database...
psql:.../security_foundation_rls_test.sql:3: NOTICE:  extension "pgtap" already exists, skipping
psql:.../security_foundation_rls_test.sql:43: NOTICE:  DIAG role=postgres search_path=public, extensions \
  pgtap_schema=extensions pgtap_version=1.3.3 extensions_usage=true \
  plan_qualified=plan(integer) plan_unqualified=plan(integer)
Files=1, Tests=22
Result: PASS
```

The same 22 assertions passed both before and after a clean `npx supabase db reset --local
--network-id local-network`, so the local baseline is reproducible from the migrations alone.

## What changed in the harness, and what is committed

- `26b232a` "Fix hosted database test schema" is the last commit touching the test file. It
  added `set local search_path = public, extensions;` before `select plan(22);`.
- The working tree still has uncommitted changes on top of that commit:
  1. the fixed search path was replaced by a `set_config(...)` that discovers the pgTAP schema
     from `pg_extension` / `pg_namespace`;
  2. a temporary `do $$ ... raise notice 'DIAG ...' ... $$;` block was added before
     `select plan(22);` so a failing hosted run still reports the session facts.
- Both changes are additive to the harness only. No migration, policy, grant, or assertion was
  touched, and no hosted change was made while preparing this page.

## Evidence established locally

1. **`test db` runs a containerized `pg_prove`.** `npx supabase test db --local` (without the
   project's network flag) fails with `network supabase_network_flutter_application_1 not
   found`, and the CLI binary contains the `supabase/pg_prove:3.36` image reference. That is
   why the npm scripts always pass `--network-id local-network`.
2. **The CLI manages the pgTAP extension itself.** The same binary embeds
   `create extension if not exists pgtap with schema extensions` and
   `drop extension if exists pgtap` next to the `pg_prove` image reference. So the runner
   installs pgTAP for the run rather than relying on the migration or the dashboard.
3. **A local pass cannot validate the `search_path` fix.** With no `set local` at all, a local
   test session reports `role=postgres`, `search_path="$user", public, extensions`, and both
   `plan(integer)` and `extensions.plan(integer)` resolve. The local role already finds pgTAP,
   so the earlier "local passes, hosted fails" contrast says nothing about whether the new
   `set_config` line works.
4. **`set_config` is a no-op when pgTAP is absent.** The dynamic statement is
   `select set_config(...) from pg_extension ... where extname = 'pgtap'`. If that extension
   row does not exist, the statement returns zero rows, no error is raised, and the search path
   is left untouched — the next statement then fails exactly as the hosted run did.

## Why the dashboard result cannot settle this

After the failed run the owner ran a read-only query in the hosted SQL editor and found
`current_user = postgres`, a search path containing `public` and `extensions`, and `NULL` for
both the pgTAP extension and any `plan` function.

That query ran in a **separate session, after the CLI run had finished**. Given point 2 above,
the runner may have dropped pgTAP again during cleanup, so "no extension and no `plan`" is a
plausible post-run state and is not evidence of what the failing session saw. Equally, it may
mean pgTAP was never installed in the database the runner used. The dashboard result cannot
distinguish those cases; only a diagnostic emitted **inside** the test session can.

## Still unknown

- Whether pgTAP exists in the database the hosted runner connects to, and in which schema.
- The effective role and `search_path` of the hosted test session, and whether the `set_config`
  call actually changed it.
- Whether the runner's own `create extension` committed, was rolled back, or targeted a
  different database.
- Whether the hosted run used the direct database connection or a pooler. There is no
  `supabase/.temp/pooler-url` on this machine, which suggests the direct connection, but that is
  an inference from a missing file, not proof.

## Next steps (in order)

Everything below is owner-run or owner-approved because it touches the hosted project. Run from
the repository root in PowerShell.

### 1. Capture one hosted run with the DIAG block

```powershell
npx supabase test db --linked 2>&1 | Tee-Object -FilePath .\hosted-test.log
```

`hosted-test.log` stays out of Git. The run still fails at `plan(22)`, but the `DIAG` notice is
emitted before that statement, so it will appear in the output even though the TAP output never
starts.

### 2. Read the DIAG line

| DIAG shows | Meaning | Next action |
| --- | --- | --- |
| `pgtap_schema=NONE` | No pgTAP in the session's database. The `set_config` statement matched zero rows, so the unqualified `plan` call cannot resolve. | Confirm the runner's `create extension` target, then install pgTAP in the hosted development database (owner, see step 3) and rerun. |
| `pgtap_schema=extensions` and `search_path` without `extensions` | The extension is present but the search-path change did not reach the statement. | Check whether the runner executes each statement on a separate connection; if so, call pgTAP functions schema-qualified instead of relying on `search_path`. |
| `plan_qualified=` a signature but `plan_unqualified=NONE` while `search_path` contains `extensions` | Search path is fine but resolution is blocked (privilege or extension state). | Check `extensions_usage`; if `false`, request the narrow `grant usage on schema extensions` (owner-reviewed) instead of broad grants. |
| `extensions_usage=false` | The session role cannot use the `extensions` schema even for a qualified call. | Narrow, owner-reviewed schema-usage grant for that role only. |
| `pgtap_version` differs between local and hosted | Version mismatch is a separate variable. | Record it; upgrade/downgrade only with owner approval. |

### 3. If pgTAP has to be installed on hosted development

Only with owner review, and only in the development project. In the dashboard SQL editor:

```sql
create extension if not exists pgtap with schema extensions;
```

Effect: adds the pgTAP test functions to the `extensions` schema. It does not create, alter, or
grant anything in `public`, does not touch product data, and does not change any policy. It can
be reverted with `drop extension pgtap;`. This is the same statement the CLI already runs, so it
does not widen the trust boundary — it only makes the state explicit.

### 4. Fix the harness only after the DIAG line explains the failure

If step 2 shows the extension is missing, the smallest possible harness change is to make the
missing extension loud instead of silent, for example:

```sql
select set_config('search_path', format('public, %I', n.nspname), true)
from pg_extension e join pg_namespace n on n.oid = e.extnamespace
where e.extname = 'pgtap';

do $$
begin
  if to_regprocedure('plan(integer)') is null then
    raise exception 'pgTAP is not resolvable in this session';
  end if;
end $$;
```

Do not change the 22 assertions, do not touch the migrations, and do not add broad grants to
make the runner work.

### 5. Rerun both suites

```powershell
npm run db:test
npx supabase test db --linked
```

Local must stay at `Tests=22`, `Result: PASS`. Hosted success is the completion criterion at the
top of this page.

### 6. Clean up

Once hosted passes, remove the temporary `DIAG` block from
`supabase/tests/security_foundation_rls_test.sql`, rerun `npm run db:test`, and let the owner
decide on commit, push, and whether the harness keeps the schema-aware `search_path` or returns
to the simpler committed form.

## Guard rails

- Preserve both applied migrations and every RLS policy. This is a test-tooling problem.
- No `supabase db reset --linked`, no destructive hosted commands, no changes to product data.
- No broad `grant all` on tables, schemas, or functions.
- Hosted configuration changes need owner review, with the exact command and its effect stated
  first.
- Never print or commit the database password, access tokens, `supabase/.temp/` contents,
  `config/dev.json`, or SSH keys.
- If the cause is only visible from a separate dashboard session, label it as such rather than
  presenting it as evidence from the failing session.
