query "events" verb=POST {
  api_group = "escalations"
  description = "Record an escalation event and mocked Datadog telemetry receipt."
  input {
    int claim_id
    text claim_number? filters=trim|upper
    text route filters=trim|lower
    text priority filters=trim|lower
    json payload?
  }
  stack {
    var $event {
      value = {
        id: $input.claim_id,
        claim_id: $input.claim_id,
        claim_number: $input.claim_number,
        route: $input.route,
        priority: $input.priority,
        status: "recorded",
        datadog: {
          event_type: "claim.escalated",
          metric_name: "claims.escalations.routed",
          accepted: true
        },
        payload: $input.payload,
        created_at: now
      }
    }
    debug.log { value = $event }
  }
  response = $event
  guid = "Mik1AjT7cZGxpGDQDfStNM-Tg1U"
}
