function "datadog_record_metric" {
  description = "Datadog custom metric recorder for escalation routing telemetry."
  input {
    text name filters=trim
    decimal value
    json tags?
  }
  stack {
    datadog.metric {
      metric = $input.name
      value = $input.value
      type = "gauge"
      tags = [
        ("claim_type:" ~ ($input.tags.claim_type ?? "")),
        ("route:" ~ ($input.tags.route ?? "")),
        ("priority:" ~ ($input.tags.priority ?? ""))
      ]
    }

    var $metric {
      value = {
        provider: "datadog",
        name: $input.name,
        value: $input.value,
        tags: $input.tags,
        accepted: true,
        recorded_at: now
      }
    }
  }
  response = $metric
  guid = "lsPIiGJ4L2YJVGZqly00gJF9imw"
}
