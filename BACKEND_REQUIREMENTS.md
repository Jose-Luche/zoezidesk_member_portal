# Backend requirements for the members app

The mobile app talks only to the mobile API in `routes/api.php` of the
Laravel project (`zoezi_erp`). The web members portal uses Livewire with the
`member` session guard and never calls `/api`, so these changes do not
touch it. Work happens on the `mobile-api` branch; nothing is deployed until
you deploy.

Status: ✅ done on `mobile-api` · ⏳ planned (feature it ships with) · ❓ needs a decision

## B1. OTP login hardening ✅ (Feature 2)

Commit `a446cc4` on `mobile-api`. Controller:
`app/Http/Controllers/Api/Member/OtpAuthController.php`. Tests:
`tests/Feature/Api/Member/OtpAuthTest.php` (12 tests).

| Before | After |
|---|---|
| `otp/verify` matched the **code only**: any member's unused code logged in whoever sent it | Code must match the phone it was sent to |
| No rate limit on verify | 5 attempts / 5 min per phone, 10 per IP; `429` with `retry_after` |
| `otp/request` returned `404` for unknown numbers | Same `200` response for known and unknown numbers |
| Suspended members could request codes | Suspended members get no code (as on the web) |
| Older unused codes stayed valid | A new request invalidates older codes |

Contract (unchanged field names; `status` added to `member`):

```
POST /api/member/otp/request   {phone}
  200 {success: true, message, debug_code: string|null}   debug_code only when APP_ENV=local
  422 validation · 429 {success:false, message, retry_after}

POST /api/member/otp/verify    {phone, code, device_name?}
  200 {success: true, token, member: {id, name, member_number, phone, email, gym_name, status}}
  422 {success:false, message} wrong/expired/used code · 429 as above

POST /api/member/logout        (Bearer)   200 {success: true}
```

The web `OtpLogin::verifyOtp` also looks codes up without the phone. It is
rate-limited per IP, so the risk is lower, but the same fix applies. Not
changed, because the web portal is out of scope.

## B1b. Dashboard fields ✅ (Feature 3)

Commit `36a64c8` on `mobile-api`. `GET /api/member/dashboard` moved to
`Api\Member\DashboardController`; tests in
`tests/Feature/Api/Member/DashboardTest.php`. Every original field is
unchanged. Added fields:

| Field | Why |
|---|---|
| `member.status` | Show suspended or inactive members correctly |
| `membership.starts_at_iso`, `expires_at_iso` | Dates the app can parse (`d M Y` strings stay) |
| `membership.days_remaining` | Whole days. The original `days_left` is a float on Carbon 3 (e.g. `12.208`) |
| `membership.expiry_percent` | Progress bar, same formula as the web dashboard |
| `membership.state` | `active` / `expiring` (≤ 7 days) / `expired` (by date, even if the daily expiry job has not run) |
| `recent_payments[].date_iso` | Parseable payment time |
| `total_paid` | Shown on the web dashboard |
| `generated_at` | Server time of the snapshot |

The app also reads the original response, so it works before this is deployed.

The web dashboard prints `$daysLeft` from the same float calculation, so it
can show values like "12.208333 days remaining". Not changed (web is out of
scope).

## B2. Idempotency keys ⏳ (Feature 6)

Middleware honouring an `Idempotency-Key` header on member write endpoints.
It stores key, member, route and response for 24 h and replays the stored
response on a repeat. Needs an additive `api_idempotency_keys` table.

## B3a. Profile ✅ (Feature 4)

Commits `6c6917e` and `7b67fa2` on `mobile-api`
(`Api\Member\ProfileController`, tests in `ProfileTest.php`).

`GET /api/member/profile` returns `member` (name, number, phone, email,
gender, date_of_birth, emergency contact, absolute `photo_url`, status,
member_since, updated_at), `gym` (name, phone, email, address, town),
`memberships` (last 20, newest first, with `status` and a date-based
`lapsed` flag) and `generated_at`.

`PATCH /api/member/profile` lets a member edit their own:

| Editable from the app | Front desk only |
|---|---|
| email, gender, date_of_birth (`Y-m-d`, in the past), emergency_contact_name, emergency_contact_phone | name, phone (the OTP login identity), photo, status, and every staff-only column |

Only the fields sent change, and `null` clears one. Last write wins (server
wins in the app). Returns the same body as `GET`; `422` carries per-field
errors. Unknown or protected fields in the request are ignored; a test
enforces this. Each change is logged with the field names, not the values.

Staff-only columns (`notes`, `id_number`, `group_id`) and the QR payload are
never exposed.

**Business rule to confirm:** I chose which fields are editable. Phone stays
with the front desk because changing it changes how the member logs in.
Name and photo stay because staff use them to identify members at
check-in.

## B3c. Workout builder ✅ (Feature 5)

Commit `fb4f8f8` on `mobile-api` (`Member\GuidedWorkoutController`, which only
`routes/api.php` uses; tests in `GuidedWorkoutTest.php`, 12 tests).

**Fixed.** These returned 500 for app (token) requests:

| Problem | Effect | Fix |
|---|---|---|
| `$this->authorize()`, but the Laravel 12 base `Controller` has no `AuthorizesRequests` | swap, remove, reorder, save-template, start-session, share all crashed | add the trait |
| `auth('member')->user()` (web session guard) | null member on token requests: start-session, templates, 4-week plan, import, save/copy plan | use `$request->user()` |
| start-session not transactional, accepted an empty workout | half-created sessions | transaction plus the web's "add at least one exercise" rule (422) |

**Added** (all original response fields unchanged):

- `GET /api/member/guided-workout/options`: the web form's choices and labels,
  the member's last answers, and needs-attention muscles from their logs.
- `GET /api/member/guided-workout/{id}`: one workout with its exercises.
- `GET /api/member/guided-workout/{id}/exercises/{guidedExerciseId}/alternatives`:
  swap candidates (the web results page has them; the API did not).
- `generate` and `swap-exercise` responses gain `plateau`, `order`, `status`,
  `template_name` and `session_id`.

**⚠️ Prompt interpreter model is retired.** `WorkoutPromptInterpreterService`
calls Anthropic with `claude-3-5-sonnet-20241022`, which is no longer
available, so "Describe it" fails on both the web and the app. The app shows
"Could not understand that description. Try the step-by-step form." The
service is shared with the web, so it is not changed; it needs a current
model ID and `ANTHROPIC_API_KEY` set.

**Also noticed, not changed:** `shareTemplate` builds a URL with
`route('member.workout-templates.import')`, which does not exist, so it
throws. Nothing uses it (the web has no share UI).

## B3b. Attendance ⏳ (Feature 7)

- `GET /api/member/attendance?page=`: check-ins, newest first, paginated.

## B4. Classes ⏳ (Feature 6)

- `GET /api/member/classes?from=&to=` adds `my_booking`, ISO `date_iso` and
  `updated_at`. The current fields and the 7-day default are kept.
- `POST /api/member/classes/{id}/book` and `/cancel`, idempotent, with the
  rules copied from `Livewire/Member/ClassTimetable::book/cancel` and a row
  lock against overbooking.

## B5. Payments ⏳ (Feature 8)

- `GET /api/member/payments?page=`: 10 per page, same query as the web
  `PaymentHistory`.
- `GET /api/member/payments/{id}/receipt`: PDF via `ReceiptPdfService`.

## B6. `changes_since` ⏳

An optional `?since=<ISO8601>` on list endpoints where it is cheap, so the
app can fetch only changed rows.

## ⚠️ Bug found: `Member::activeMembership()` can hide an active membership

`app/Models/Member.php` defines

```php
return $this->hasOne(Membership::class)->where('status', 'active')->latestOfMany();
```

`latestOfMany()` picks `MAX(id)` across **all** of the member's memberships
first, and only then applies `status = 'active'`. If the newest row is not
active (a pending renewal, a suspended or cancelled one, or a back-dated
import), the relation returns `null` even though an active membership exists.
I reproduced it on `zoezi_testing` (active membership id 6, expired id 7:
`activeMembership` was null).

Effects, web and app alike:

- Web dashboard and mobile dashboard: "No active membership".
- Front-desk scanner (`QrCodeService::validateScan`): "No active membership.
  Renewal required.", so **check-in is refused**.

Suggested fix (one line, shared model, so not changed without your go-ahead):

```php
return $this->hasOne(Membership::class)
    ->ofMany(['id' => 'max'], fn ($q) => $q->where('status', 'active'));
```

## Open questions ❓

- **Duplicate notes routes:** `PUT`/`DELETE /api/member/notes/{id}` are each
  defined twice in `routes/api.php` (closures, then `ProgressController`); the
  later definition wins. Which behaviour is intended?
- **Member payments:** the web portal has no member payment flow ("visit the
  front desk to renew"). Feature 9 needs a decision and an STK-push endpoint.
- **Refresh tokens:** Sanctum tokens never expire (`sanctum.expiration` is
  null). The app treats any `401` as logout. Short-lived access tokens with
  refresh tokens are possible later if you want them.
- **Offline logout:** if the member logs out without a connection, the app
  wipes local data but the server token stays valid until it is revoked.

## Web-only issues noticed (not changed)

- `/member/member/classes`: the route has a doubled `member` prefix.
- `/member/workouts/history` is registered after `/member/workouts/{session}`
  and is shadowed by it.

## Running the backend tests

The default `phpunit.xml` uses in-memory SQLite, and two migrations use
MySQL-only `MODIFY` statements, so most tests fail there. Run against a MySQL
test database instead (never your dev database):

```sh
mysql -u root -e "CREATE DATABASE IF NOT EXISTS zoezi_testing"
DB_CONNECTION=mysql DB_DATABASE=zoezi_testing php artisan test
```

Baseline on `main`: 8 failures that were already there (Jetstream auth
scaffolding tests and `WorkoutWorkflowTest`). The `mobile-api` branch adds no
new failures.
