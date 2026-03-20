# Project Instructions

## Maintenance Rule

- The core process we confirm in chat must be written to this file.
- If the process changes later, this file must be updated in the same turn.
- Versioning rule for HTML files: always create a new file, `vx -> vx+1`; do not overwrite the previous version.

## Current Relevant Files

- Current deploy entry: `index.html` (copied from `world01-spike-v19-glow-supabase.html`)
- Previous deploy entry backup: `index-pre-v19-backup.html`
- Main auth prototype: `world01-spike-v4-supabase-auth.html`
- Debug/fix prototype: `world01-spike-v5-supabase-auth-debug.html`
- Storage debug prototype: `world01-spike-v6-supabase-storage-debug.html`
- Magic-link prototype: `world01-spike-v7-supabase-magic-link.html`
- Clean magic-link prototype: `world01-spike-v8-supabase-magic-link-clean.html`
- Final UI + auth/storage merge: `world01-spike-v19-glow-supabase.html`
- Previous auth version: `world01-spike-v3-supabase邮箱登录.html`
- Supabase SQL schema: `supabase-schema-v1.sql`

## Product Flow Confirmed

- Users open the HTML page from `localhost`, not `file://`.
- Users log in with email only.
- Login method is Supabase email OTP, not password login.
- After login, the user's rejection data is loaded from Supabase.
- When the user adds rejection entries or seals a jar, the state is saved back to Supabase.
- The same email should restore the same user data on the next visit.

## Supabase Implementation Notes

### Frontend auth flow

- Use `supabase.auth.signInWithOtp({ email })` to send the email code.
- Use `supabase.auth.verifyOtp({ email, token, type: 'email' })` to verify the 6-digit code.
- The HTML page contains placeholders for:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`

### Data model

- Table name: `public.user_rejection_state`
- Primary key: `user_id`, referencing `auth.users.id`
- Stored fields:
  - `email`
  - `active_entries` as `jsonb`
  - `jars` as `jsonb`
  - `round_started_at`
  - `updated_at`

### SQL and RLS

- Schema file: `supabase-schema-v1.sql`
- RLS is enabled.
- Policies allow authenticated users to:
  - read their own row
  - insert their own row
  - update their own row

## Supabase Email Template Rule

- The older OTP flow used `{{ .Token }}`.
- The new preferred flow is magic-link login.
- For the magic-link version, the Supabase email template must use `{{ .ConfirmationURL }}`.
- Do not use `{{ .Token }}` in the magic-link version.

### Recommended magic-link template body

```html
<h2>登录 1000 Rejections</h2>
<p>点击下面的链接完成登录：</p>
<p><a href="{{ .ConfirmationURL }}">Log in</a></p>
<p>如果这不是你本人操作，请忽略这封邮件。</p>
```

## Local Preview Rule

- A local server was started so the HTML can be opened from localhost.
- Current preview URL:
  - `http://localhost:8000/world01-spike-v7-supabase-magic-link.html`

## Resend SMTP Decision

- Domain available for email sending: `100worlds.com`
- Recommended sending subdomain: `auth.100worlds.com`
- Recommended sender email: `noreply@auth.100worlds.com`
- Recommended sender name: `1000 Rejections`

### Resend SMTP values for Supabase

- Host: `smtp.resend.com`
- Port: `465`
- Username: `resend`
- Password: Resend API key

## Resend Domain Verification State

- Resend domain added: `auth.100worlds.com`
- Current status discussed in chat: `Verified`
- Provider shown in Resend: `Vercel`

### DNS records provided by Resend

#### Required

- TXT
  - Host/Name: `resend._domainkey.auth`
  - Value: `p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgkebPSOdqlTosdb1mEw6VDxwZ7+F8vNb2sqtgWGuIhz5Fruwz6n6R+7jpzon0vzeN2ue8Fur8Gl9ocX3iMpXjbXRoGRlUQcq4hVetV1S1YcLKIHxYbeNuOsqNOKmq/E4QLIgDYCVspCxgRDwFqAy9ycZ5hSzoIindK7t3nVfQwQIDAQAB`

- MX
  - Host/Name: `send.auth`
  - Value: `feedback-smtp.us-east-1.amazonses.com`
  - Priority: `10`

- TXT
  - Host/Name: `send.auth`
  - Value: `v=spf1 include:amazonses.com ~all`

#### Recommended

- TXT
  - Host/Name: `_dmarc`
  - Value: `v=DMARC1; p=none;`

## Next Operational Step

- `auth.100worlds.com` verification is complete in Resend.
- Supabase SMTP settings have been filled with the Resend SMTP credentials.
- `world01-spike-v4-supabase-auth.html` hit a runtime error because local code declared `let supabase`, which conflicts with the global Supabase SDK symbol.
- The fix version renames the local client variable to `supabaseClient` in `world01-spike-v5-supabase-auth-debug.html`.
- `world01-spike-v6-supabase-storage-debug.html` adds a visible storage debug panel showing session, sync state, last error, and the last row loaded/saved from Supabase.
- Next: test saving again from `world01-spike-v6-supabase-storage-debug.html`.
- After OTP verification succeeds, confirm that:
  - the user appears in Supabase Authentication Users
  - a row is created in `public.user_rejection_state`

## How To Verify History Storage

### In the product

- Open `world01-spike-v5-supabase-auth-debug.html` from localhost.
- Log in with email OTP.
- Add one or more rejection entries.
- Refresh the page.
- Log in again if needed.
- Success condition:
  - the count restores
  - hovering stars still shows saved rejection text
  - previously sealed jars still exist in the shelf

### In Supabase

- Check `Authentication > Users`:
  - the email user should exist after successful OTP login
- Check `Table Editor > public.user_rejection_state`:
  - there should be one row for the user
  - `active_entries` should contain the current unsaved-in-jar rejection texts
  - `jars` should contain sealed jar history
  - `updated_at` should move forward after saving changes

### Strong verification sequence

- Log in
- Add 2 rejection entries
- Refresh
- Confirm the count returns as `2`
- Seal the jar
- Refresh
- Confirm the shelf still shows the jar
- Confirm `jars` in `public.user_rejection_state` is not empty

## Current Debug Findings

- Browser extension errors such as `chrome-extension://... userReportLinkedCandidate.json` are unrelated to the product.
- The current blocking issue is Supabase OTP verification:
  - request URL: `/auth/v1/verify`
  - HTTP status: `403`
  - error: `AuthApiError: Token has expired or is invalid`

### Meaning of this error

- Supabase received the OTP verification request.
- The code being submitted is not accepted.
- This is not a storage-layer issue yet; login must succeed before storage can be verified end-to-end.

### Most likely causes

- An older OTP email was used after requesting a newer code.
- The code expired before verification.
- The email used to request the code does not exactly match the email used to verify it.
- Too many repeated send attempts caused confusion about which OTP is the latest valid one.

### Current status

- OTP verification proved unreliable in the current setup.
- The preferred path is now magic-link login instead of 6-digit OTP.
- Storage verification should continue on top of the magic-link flow.
- `world01-spike-v8-supabase-magic-link-clean.html` removes the on-page storage debug panel while keeping the working magic-link auth and Supabase persistence flow.
- `world01-spike-v19-glow-supabase.html` uses `world01-spike-v18-glow.html` as the UI base and merges in magic-link auth plus Supabase persistence.
- In the merged version:
  - `active_entries` stores current unsealed star-clusters, including `category`
  - `jars` stores the archived galaxy `planets` objects for the glow UI
