table "claim_event" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    int claim_id {
      table = "claim"
    }
    int actor_id? {
      description = "User who performed the action; null/0 for system events"
    }
    enum event_type {
      values = [
        "created",
        "status_changed",
        "assigned",
        "escalated",
        "observability_logged",
        "auto_approval_evaluated",
        "amount_updated",
        "note_added",
        "ticket_added",
        "attachment_added",
        "closed"
      ]
    }
    text message? filters=trim
    json payload?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "claim_id"}, {name: "created_at", op: "desc"}]}
    {type: "btree", field: [{name: "event_type"}]}
  ]
  guid = "boLNwV6Tlso5kstjEmAb3VZKn4c"
}
