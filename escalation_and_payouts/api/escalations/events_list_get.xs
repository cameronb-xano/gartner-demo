query "events" verb=GET {
  api_group = "escalations"
  description = "List demo escalation and observability events."
  input {
  }
  stack {
    var $events {
      value = {
        items: [
          {
            id: 1042,
            claim_id: 1042,
            claim_number: "CLM-2026-01042",
            route: "property_specialist",
            priority: "high",
            status: "recorded",
            datadog_event: "claim.escalated",
            datadog_metric: "claims.escalations.routed",
            created_at: now
          }
        ],
        itemsTotal: 1,
        curPage: 1,
        pageTotal: 1
      }
    }
  }
  response = $events
  guid = "V9oW3iP6hCT-xjkHK-_UuuFnUmw"
}
