function "datadog_log_event" {
  description = "Structured Datadog log event for claim escalation observability."
  input {
    text type filters=trim
    json payload?
  }
  stack {
    datadog.log {
      message = $input.type
      service = "northstar-claims"
      tags = [
        ("claim_id:" ~ ($input.payload.claim_id ?? "")),
        ("claim_number:" ~ ($input.payload.claim_number ?? "")),
        ("claim_type:" ~ ($input.payload.claim_type ?? "")),
        ("route:" ~ ($input.payload.route ?? "")),
        ("priority:" ~ ($input.payload.priority ?? ""))
      ]
      attributes = ($input.payload ?? {})
    }

    var $event {
      value = {
        provider: "datadog",
        type: $input.type,
        payload: $input.payload,
        accepted: true,
        recorded_at: now
      }
    }
  }
  response = $event
  guid = "uwGP14RzjFxywE7mfM3FjT9CZEg"
}
