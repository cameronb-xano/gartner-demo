# Recorded Demo Script - Insurance Claims Platform

This is now a media-project script, not a live demo runbook. Capture clean screen
recordings first, then add voiceover. The story is: Xano lets enterprise teams
understand, change, and govern real backend logic across existing systems.

## Setup Slide

Use four workspaces:

| Workspace | One-line description |
|---|---|
| Customer Claims | Intake, status, history, and claim decision orchestration. |
| Policy Data | Policy lookup, coverage checks, and eligibility context. |
| Rules & Decisioning | Auto-approval and specialist routing decisions outside the claims service. |
| Escalation & Payouts | Exception routing, supervisor review, and approved disbursements. |

Keep this slide shallow. The only workspace we go deep on is Customer Claims.

## Built-In Integration Blocks

These should already exist before the AI/editor build moment:

- `db.external.snowflake.direct_query` - pulls policy, customer, prior-claim, and fraud context.
- `datadog.log` - records the structured escalation event.
- `datadog.metric` - records the routing metric.
- `evaluate_auto_approval(...)` - unchanged core business rule.

The Snowflake calls do not need to reach a live warehouse during recording. The
endpoint has deterministic fallback data so the stack shows the enterprise
integration shape without risking a failed take.

## Core Rule We Do Not Touch

Show the Customer Claims screen and highlight the auto-approval card:

> Approve if claim is under $5K, policy is active for more than one year, and
> there is no fraud flag.

Voiceover:

> "This is the business rule the team already trusts. It is readable enough for
> a PM and an engineer to review together, and we are not changing it. The new
> work only handles claims that fall out of this rule."

## Existing Escalation Path

`POST /claims/{claim_id}/escalate` should already exist in the default Customer
Claims workspace. Show it behaving normally before the prompted rules change.

The endpoint should:

1. Load the claim.
2. Pull customer and policy context from Snowflake.
3. Pull claim history and fraud indicators from Snowflake.
4. Ask Rules & Decisioning for the auto-approval and specialist routing decision.
5. Log the escalation event and metric to Datadog.
6. Patch the claim with `status = in_review`, priority, SLA, and assigned queue.
7. Write timeline events so the app visibly changes after the call.

## Prompted Change We Make

The prompted build moment changes routing policy in Rules & Decisioning, not the
Customer Claims orchestration endpoint. The escalation endpoint keeps the same
top-level Snowflake and Datadog blocks; only the Rules response changes from
baseline specialist routing to catastrophe routing for weather-related property
claims.

## Recording Shot List

### Shot 1 - Platform Setup

Record the Systems page or a slide with the four workspace names. Keep the shot
slow enough to read the descriptions.

Voiceover:

> "For the recording, think of this as four insurance backends: customer claims,
> policy data, rules and decisioning, and escalation plus payouts. We are only going
> deep on customer claims, but the business process depends on all four."

### Shot 2 - The Untouched Rule

Record the Claims page with the auto-approval rule card visible.

Voiceover:

> "The rule running the business is intentionally visible. Claims under five
> thousand dollars, with an active policy older than one year and no fraud flag,
> can be auto-approved. That rule stays exactly as-is."

### Shot 3 - The Existing Escalation Flow

Record Cursor on:

`tickets_and_claims/api/claims/escalate_post.xs`

Pan through the stack lines that use:

- `db.external.snowflake.direct_query`
- `POST /api:gartner-rules-decisioning/decisions/evaluate`
- `datadog.log`
- `datadog.metric`
- `db.patch "claim"` with `assigned_queue`

Voiceover:

> "The exception path is already running. When a claim does not meet auto-approval,
> the endpoint pulls enterprise context from Snowflake, chooses the right
> specialist queue, logs the event to Datadog, and updates the claim record."

### Shot 4 - Normal Behavior

Record the app before and after pressing **Escalate claim** in the default state.
Claim 99 should route to `property_specialist` under baseline Rules &
Decisioning.

### Shot 5 - Prompted Rules Change

Prompt for weather-related property claims to route to catastrophe review. This
change is made in Rules & Decisioning and pushed through sandbox review before
promotion. After promotion, the same live escalation endpoint routes claim 99 to
`catastrophe_review` with `urgent` priority.

### Shot 6 - Optional CLI Governance

If we still want the engineering governance beat, record:

```bash
./demo/scripts/push-rules-sandbox.sh --dry-run
./demo/scripts/push-rules-sandbox.sh
```

Voiceover:

> "Because this is backend code, it can still move through the normal review
> path: preview the change, push it to a sandbox, inspect it visually in Xano,
> then promote when the team is ready."

This is optional. For a tighter media edit, use only the editor and Xano visual
flow shots.

### Shot 7 - Visual Stack In Xano

Record the endpoint flow in Xano. Show the Snowflake connector, Datadog blocks,
routing branch, and claim patch.

Voiceover:

> "The same logic is visible as a Xano stack. An engineer can work in the
> editor, while a PM, architect, or operations lead can still inspect the flow
> visually."

### Shot 8 - Result In The App

Record the app before and after pressing **Escalate claim**. The desired visible
result is:

- Claim status moves to `in_review`.
- Priority moves to high or urgent.
- Before the prompted change, assigned queue becomes `property_specialist`.
- After the prompted change, assigned queue becomes `catastrophe_review`.
- Timeline shows auto-approval evaluation, escalation, and observability events.

Voiceover:

> "Now the record tells the story: this claim did not fit the auto-approval
> rule, so the platform routed it to the right specialist queue and recorded
> the operational telemetry enterprises expect."

## Fallback Notes

- If Snowflake is unavailable, the endpoint returns deterministic demo data and
  logs a fallback message.
- The Datadog blocks are top-level components; the response includes
  deterministic acknowledgement objects for the demo UI.
- If sandbox push gets noisy, skip the CLI shot and keep the recording focused
  on editor, Xano visual stack, and app result.
- If the live app data is awkward, record the endpoint in Xano run/debug and
  then capture the app after refresh.
