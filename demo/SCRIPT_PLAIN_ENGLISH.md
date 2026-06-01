# Demo Briefing - Plain English

## What the demo is now

This is no longer a live demo. It is a recorded screen sequence with voiceover,
so we should optimize for clarity, pacing, and clean visuals instead of live
recovery paths.

The story is an insurance claims platform made of four workspaces:

- **Customer Claims** - intake, status, history, and decision orchestration.
- **Policy Data** - policy lookup, coverage checks, and eligibility context.
- **Rules & Decisioning** - auto-approval and specialist routing decisions outside the claims service.
- **Escalation & Payouts** - exception routing, supervisor review, and payouts.

We only go deep on Customer Claims.

## The main message

Xano can run business-critical backend logic in a way both business and
engineering teams can understand. The unchanged auto-approval rule is visible
and readable, and the new exception path integrates with enterprise tools like
Snowflake and Datadog.

## What we show

First, show the setup: four insurance workspaces and their roles. Do not spend
time explaining every endpoint.

Second, show the existing auto-approval rule:

> Approve if the claim is under $5K, the policy has been active more than one
> year, and there is no fraud flag.

This rule is the anchor. The point is that a PM and an engineer can look at the
same backend logic together and understand it.

Third, show the existing escalation endpoint. When a claim does not meet
auto-approval, it:

- Pulls customer and policy context from Snowflake.
- Pulls claim history and fraud indicators from Snowflake.
- Calls Rules & Decisioning to decide whether to auto-approve or route to a specialist queue.
- Logs a structured event and metric to Datadog.
- Updates the claim with status, priority, SLA, and assigned queue.

Snowflake does not need to be live. The endpoint uses the top-level Snowflake
connector shape for `db.external.snowflake.direct_query`, then falls back to
deterministic demo data. Datadog uses top-level `datadog.log` and
`datadog.metric` blocks directly in the endpoint.

Then show the prompted change in Rules & Decisioning. The Customer Claims
endpoint stays the same; only the routing policy response changes, so the same
Escalate button moves from normal specialist routing to catastrophe review for
the weather-related property claim.

## Why this works better as a recording

The original version leaned hard on live CLI push, sandbox review, and promote.
That is still useful, but it is no longer the whole story. In the recorded
version, the strongest moments are:

- A clean setup slide.
- A readable business rule.
- A focused Rules & Decisioning change.
- A visual Xano stack.
- A final app state that proves the claim was routed.

The governance/CLI beat can be included as a short supporting shot if there is
room, but it should not steal focus from the insurance workflow.

## Suggested voiceover arc

> "This claims platform is split across four workspaces. Customer Claims owns
> the claim record and decision flow. Policy Data provides Snowflake-backed
> coverage context. Rules & Decisioning owns approval and routing policy.
> Escalation & Payouts handles exceptions and downstream disbursement."

> "The key business rule is intentionally visible: under five thousand dollars,
> policy active over a year, and no fraud flag. That rule is not changing."

> "The escalation path already handles claims that fall out of that rule. It
> routes to the correct specialist queue, using Snowflake context and Datadog
> observability, then updates the claim record."

> "Now we change one piece of policy: weather-related property claims should go
> to catastrophe review with urgent priority. The orchestration endpoint stays
> the same, with Snowflake and Datadog visible as top-level blocks."

> "An engineer can work on this in Cursor and the CLI, while the same logic is
> still inspectable as a Xano flow. That is the enterprise story: speed,
> governance, and shared understanding."

## What to build before recording

- Reskin the visible app and setup copy to the four insurance workspaces.
- Use top-level Snowflake connector blocks with `db.external.snowflake.direct_query`.
- Use top-level Datadog blocks with `datadog.log` and `datadog.metric`.
- Add the untouched auto-approval rule as a visible function/UI artifact.
- Keep the escalation endpoint live in the default state.
- Update Rules & Decisioning during the prompt so weather-related property claims route to catastrophe review.
- Make the claim screen show the assigned queue and timeline events.

## What can go wrong

If Snowflake is not configured, the demo still works because the endpoint has
fallback data.

If Datadog is not configured, the endpoint still returns deterministic
acknowledgement objects for the demo response.

If the sandbox/promotion path is too noisy for recording, skip it. The media
story still works with editor, Xano visual flow, and app verification.
