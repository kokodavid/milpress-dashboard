# create_admin_user (Supabase Edge Function)

Creates or reuses a Supabase Auth user and upserts a matching row in `admin_profiles` with the same id. Supports two strategies:

- `auto` (default): Auto-confirm the user by creating with a random temp password and `email_confirm: true`.
- `invite`: Sends an invite email (optionally with `redirectTo`) and upserts profile.

It also verifies the caller is a `super_admin` (by reading the caller's profile) and logs an activity event.

## Inputs

POST body (JSON):

```
{
  "email": "newadmin@example.com",
  "name": "Jane Admin",
  "role": "admin" | "super_admin",
  "isActive": true,
  "strategy": "auto" | "invite" | "temp_password",   // default "auto"
  "redirectTo": "https://app.example.com/auth/callback" // for invite flow
}
```

## Outputs

- 200 OK: `{ userId: string, created: boolean, invited: boolean, recoveryLink?: string }`
- 4xx/5xx: `{ error: string, details?: string }`

## Environment variables

Set these in your Edge Function environment (do NOT expose service key to clients):

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY`

Optional (to email temporary passwords when using `strategy = "temp_password"`):

- `RESEND_API_KEY` and `MAIL_FROM` (uses Resend)
- or `SENDGRID_API_KEY` and `MAIL_FROM` (uses SendGrid)
- `APP_LOGIN_URL` (login link to include in the email)
- `APP_NAME` (branding in the email)

## Deploy (via Supabase CLI)

PowerShell (Windows):

```powershell
# From the project root
supabase functions deploy create_admin_user
supabase secrets set SUPABASE_URL="<your-url>"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="<your-service-role-key>"
supabase secrets set SUPABASE_ANON_KEY="<your-anon-key>"
```

Local test:

```powershell
supabase functions serve create_admin_user
```

## Client usage (Flutter)

Call the function instead of directly inserting into `admin_profiles`:

```dart
final supabase = Supabase.instance.client;
final res = await supabase.functions.invoke('create_admin_user', body: {
  'email': email,
  'name': name,
  'role': role, // 'admin' or 'super_admin'
  'isActive': isActive,
  // Choose one:
  // 'strategy': 'invite',        // user gets invite or recovery link
  // 'strategy': 'temp_password', // user gets a temp password (emailed if provider configured)
});
// res.data => { userId, created, invited }
```

## Notes

- The function checks the caller is `super_admin` using their `admin_profiles` row.
- For existing users by email, it reuses the Auth user and only upserts the profile.
- Add a DB constraint if desired: `ALTER TABLE admin_profiles ADD CONSTRAINT admin_profiles_email_unique UNIQUE (email);`
- If you want to always send a password reset after `auto`, you can trigger it with the Admin API (optional enhancement).
