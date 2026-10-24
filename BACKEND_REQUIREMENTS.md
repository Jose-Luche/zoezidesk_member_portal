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

## B2. Idempotency keys ✅ (Feature 6)

Commit `78df8ae` on `mobile-api`. `App\Http\Middleware\IdempotentRequest` plus
the additive migration `2026_10_23_000001_create_api_idempotency_keys_table`
(**run `php artisan migrate` when deploying**). Attached to class book and
cancel; reusable on any member write.

- A write with an `Idempotency-Key` header stores its response; a repeat
  with the same key and same request gets the stored response back
  (`Idempotent-Replayed: true`) and does not run again.
- Same key, different request: `422`. Same key while the first is still
  running: `409`. `5xx` responses are not stored, so they can be retried.
- Keys are per member and expire after 24 hours.

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

**✅ Prompt interpreter fixed** (commit `fc329ea`). It never worked: it used a
class from a package that was not installed, read the key with `env()`
(null once `config:cache` runs), called the retired
`claude-3-5-sonnet-20241022`, and read `content[0]`. Now:

- the official `anthropic-ai/sdk` (v1.2) with `Anthropic\Client`
- model `claude-opus-5-5` by default, changeable with `ANTHROPIC_WORKOUT_MODEL`
- structured output (JSON schema), `effort: low`, server-side refusal fallback
- result clamped to values the builder accepts; clear error when the key is missing

**The app does not offer "Describe it" for now** (removed to avoid API costs). The backend stays ready; re-adding it in the app is a small change.

**To switch it on:** set `ANTHROPIC_API_KEY` in the server's `.env`, then run
`php artisan config:clear` (or `config:cache`). Until then "Describe it"
falls back to the step-by-step form, as it does today. Each use is billed
by Anthropic to the key's account. See the cost note in the Feature 5
summary.

`shareTemplate` was broken (a link to a missing route); fixed in `fd78fd3`.

## B3b. Attendance ✅ (Feature 7)

Commit `93451b3` on `mobile-api`. `GET /api/member/attendance?page=`
(`Api\Member\AttendanceController`, tests in `AttendanceTest.php`): the
member's own check-ins, newest first, 20 per page, with `meta` (pages,
total) and `summary` (`this_month`, `last_visit`). Read-only: check-ins are
still recorded only by the front-desk QR scan.

## B4. Classes ✅ (Feature 6)

Commit `78df8ae` on `mobile-api` (`Api\Member\ClassesController`, tests in
`ClassesTest.php`, 15 tests).

- `GET /api/member/classes?from=Y-m-d&days=7` (days 1–14). Original fields
  unchanged; adds `description`, `date_iso`, `starts_at`, `ends_at` (ISO with
  offset), `my_booking`, `status`, `updated_at`, and top-level `from` / `to` /
  `generated_at`.
- `POST /api/member/classes/{id}/book` and `/cancel`, idempotent (B2).
  Errors are `422` with a `code`: `unavailable`, `started`, `no_membership`,
  `full`, plus `404 not_found` for another gym's class.

Rules follow the web `ClassTimetable` (active membership, class scheduled,
capacity, no cancelling after the start) with a row lock against
overbooking and the same WhatsApp and push confirmations. Differences, each
needed for queued offline bookings or fixing a web bug:

| Rule | Web | API |
|---|---|---|
| Book a class that has already started | allowed | refused (`started`): a queued booking can arrive late |
| Membership past its end date but still marked active | can book | refused (`no_membership`), as the front-desk scanner refuses it |
| Book an already-booked class / cancel twice | error | success with `already_booked` / `already_cancelled` (safe retries) |
| Rebook after cancelling | **fails** (unique index on class + member) | works: the cancelled row is reused |

The web rebooking failure was fixed in `6b48f55`.

## B5. Payments ✅ (Feature 8, commit `a00e2f2`)

Read-only, as on the web `PaymentHistory` page (members pay at the front desk).

- `GET /api/member/payments?page=`: every payment of the member (completed,
  pending, failed), ordered by `paid_at` desc then `id` desc, 10 per page.
  Items: `id`, `amount` (whole KES), `method`, `status`, `receipt` (M-Pesa
  receipt), `plan`, `paid_at` and `created_at` (ISO 8601, `paid_at` null while
  pending), `has_receipt_pdf` (completed only). Also `meta`
  (`current_page`, `last_page`, `per_page`, `total`), `total_paid` (sum of
  completed payments across all pages) and `generated_at`.
- `POST /api/member/payments/{id}/receipt-link`: returns `{url, expires_at}`,
  a temporary signed URL valid for 10 minutes. 404 if the payment is not the
  member's, 422 if it is not completed.
- `GET /api/member/receipts/{payment}` (route `api.member.receipt-pdf`):
  `signed` middleware, no token, so the phone's browser can open it. Streams
  the PDF from the existing `ReceiptPdfService` inline with
  `Cache-Control: private, no-store`. Tampered or expired links get 403.

Why a signed link instead of the planned `GET /payments/{id}/receipt`: the app
hands the PDF to the browser, which cannot send the bearer token, and the
token must never appear in a URL. The web keeps its own `member.receipt`
route; it is unchanged.

The app caches the history in the `Payments` table (schema v4, additive)
with amount, receipt, plan and method encrypted. Receipt links are online
only and fetched fresh on every tap.

## B7. Member checkout by M-Pesa STK push ✅ (Feature 9, commit `5bddb23`)

Reuses the front-desk flow (`Admin\Memberships\InitiatePayment`) unchanged:
`MembershipService::initiate` creates a pending membership and payment,
`MpesaService::stkPush` sends the prompt, and the existing web route
`POST /mpesa/callback/{gym}` completes the payment and activates the
membership (extending from the current expiry on an early renewal). The
callback, `MpesaService` and `MembershipService` are not modified.

- `GET /api/member/payments/plans`: `mpesa_enabled` (the gym has shortcode,
  passkey, consumer key and secret), `phone` (registered number), `current`
  (`plan_id`, `plan_name`, `expires_at`), `plans` (`id`, `name`,
  `description`, `price`, `duration_days`, `duration_label`) and
  `pending_payment_id` (a prompt sent in the last 2 minutes, still pending).
- `POST /api/member/payments/stk` `{plan_id, phone}` with `Idempotency-Key`:
  `201 {payment_id, status: pending, amount, phone, message}`.
  - 422 `errors.phone`: not a Safaricom number (2547… / 2541…).
  - 422 `errors.plan_id`: the plan cannot be bought in the app.
  - 422 `code: mpesa_unavailable`: the gym has no M-Pesa credentials.
  - 422 `code: mpesa_rejected`: Daraja refused the push; the payment is
    recorded as failed and its membership cancelled. 422 rather than 5xx so
    the client's retry logic never re-sends it.
  - 409 `code: pending_exists, payment_id`: a prompt from the last 2 minutes
    is still pending; the app resumes watching it.
  - 429: more than 5 pushes in an hour for this member.
- `GET /api/member/payments/{id}/status`: `status`, `amount`, `plan`,
  `receipt`, `failure_reason` (failed only), `paid_at`, and `membership`
  (`starts_at`, `expires_at`) once completed. 404 for other members' payments.

Business rules (decided for Feature 9; change them here if the gym disagrees):

1. The prompt goes to the registered phone by default; the member may enter
   another Safaricom number, as the front desk can.
2. Members can buy active `standard` plans, plus the plan they are on now
   (any category), so student, corporate and family plans stay with the
   front desk, which can check eligibility. Early renewal is allowed and
   starts the day after the current membership ends.
3. The app checks the status every 5 seconds for 2 minutes. After that it
   says it is still waiting rather than marking the payment failed: only the
   callback decides. A second push is refused while one from the last
   2 minutes is pending, so a member is never prompted twice at once.

Production needs: a reachable `APP_URL` for the callback, each gym's Daraja
credentials in M-Pesa settings, and `MPESA_ENV=live`. `MPESA_BASE_URL`
(new, optional) points `MpesaService` at a fake Daraja for local testing;
leave it unset in production.

Not handled (as on the web): a pending payment whose callback never arrives
stays pending. An STK status query (`/mpesa/stkpushquery/v1/query`) on a
schedule would settle these; it needs a change to `MpesaService`, so it is
left for you to decide.

## B8. Workout logging ✅ (Feature 10, commits `ba3984b`, `50adec3`)

New controller `Api\Member\WorkoutsController`, matching the web
WorkoutDashboard, WorkoutSession, WorkoutHistory and ExercisePRHistory pages.
The older closure routes (`/workout-sessions/*`, `/exercise-prs/*`) are left
as they were.

- `GET /api/member/workouts/exercises`: the gym's whole active library (gym
  and global exercises), with `last` = the member's sets for that exercise
  the last time (within 180 days), to prefill new sets offline.
- `GET /api/member/workouts?page=`: every session newest first, 20 per page:
  `id`, `client_id`, `day_type`, `muscle_group`, `session_date`,
  `started_at`, `ended_at`, `duration_minutes`, `status`, `rating`,
  `exercise_count`, `total_sets`, `total_volume`, `updated_at`.
- `GET /api/member/workouts/{id}`: one session with exercises and sets, each
  set with `pr_types`.
- `PUT /api/member/workouts/sync/{client_id}`: the whole session as one
  document (exercises and sets, each with an app-generated `client_id`).
  The server creates, updates or removes rows to match, so sending the same
  document twice changes nothing. PR detection (`PRDetectionService`) and
  goal updates run once, for new sets, oldest first; PRs are dated when the
  set was lifted. Returns the document plus `new_prs`. 422 when an exercise
  is not available at the member's gym, or when an id belongs to another
  member's session.
- `DELETE /api/member/workouts/sync/{client_id}`: discard; repeating it is
  fine.
- `GET /api/member/workouts/prs`: totals plus records grouped by exercise.

Migration `2026_10_24_000001_add_client_uuid_to_workout_tables`: nullable,
unique `client_uuid` on `workout_sessions`, `workout_exercises` and
`workout_sets` (additive). Rows made on the web get one the first time the
app reads them.

Times arrive from the app in UTC and are stored in the app timezone, as
`now()` stores them.

Rules that differ from the web (decided for Feature 10):

- "Repeat" copies the exercises but not the sets; the last time's numbers
  prefill each new set instead. The web copies the old sets as if done.
- A "Legs" workout offers quads, hamstrings, glutes and calves exercises,
  as the web now does too (`05e4022`).
- Only workouts in progress are edited in the app; finished ones are
  read-only there.
- If the same in-progress session were edited on the web and in the app at
  once, the app's latest document wins for that session.

Not in the app yet: history filters, workout analytics and muscle progress.

## B6. `changes_since` ⏳

An optional `?since=<ISO8601>` on list endpoints where it is cheap, so the
app can fetch only changed rows.

## ✅ Fixed: `Member::activeMembership()` hid active memberships

Commit `d551e29` on `mobile-api` (shared model, fixed with your approval;
tests in `tests/Feature/MemberActiveMembershipTest.php`).

`->where('status', 'active')->latestOfMany()` took `MAX(id)` over all
memberships before filtering, so any newer non-active row (pending renewal,
expired, cancelled, suspended) made the relation null. The web and app
dashboards then showed "No active membership", and the front-desk scanner
refused check-in. It now uses
`->ofMany(['id' => 'max'], fn ($q) => $q->where('status', 'active'))`, the
newest *active* membership. Eager loading and `whereHas` are covered by tests.

## Open questions ❓

- **Duplicate notes routes:** `PUT`/`DELETE /api/member/notes/{id}` are each
  defined twice in `routes/api.php` (closures, then `ProgressController`); the
  later definition wins. Which behaviour is intended?
- **Refresh tokens:** Sanctum tokens never expire (`sanctum.expiration` is
  null). The app treats any `401` as logout. Short-lived access tokens with
  refresh tokens are possible later if you want them.
- **Offline logout:** if the member logs out without a connection, the app
  wipes local data but the server token stays valid until it is revoked.

## Web bugs fixed (2026-10-24, on `mobile-api`)

Fixed at your request, one commit each, with tests:

| Bug | Fix | Commit |
|---|---|---|
| Class timetable at `/member/member/classes` (doubled prefix); push and service-worker links to `/member/classes` were 404 | Now `/member/classes`; the old URL redirects (301) | `106b80c` |
| `/member/workouts/history` caught by `/member/workouts/{session}` (404) | Registered first; session ids must be numeric | `106b80c` |
| Rebooking a cancelled class failed (unique booking per member and class) | Reuses the cancelled row, as the API does | `6b48f55` |
| `shareTemplate` linked to a route that does not exist, so it always failed | Returns the code only; keeps an existing code; templates only | `fd78fd3` |
| The Legs workout picker was empty | Shows quads, hamstrings, glutes and calves | `05e4022` |

Correction: the earlier note that `Exercise::scopeSearch` leaks other gyms'
exercises was wrong. Laravel wraps a local scope's conditions in brackets
when they contain `orWhere`, so the gym filter still applies. Nothing was
changed there.

Still failing, not caused by this work: `WorkoutWorkflowTest` asks for the
old exercise category `push_day`, which a migration renamed; the Breeze
auth tests (login, registration, password reset) expect routes this app
does not have.

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
