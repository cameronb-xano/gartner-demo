query "claims/demo/reset" verb=POST {
  api_group = "claims"
  description = "Reset the recorded demo claim to a clean baseline state."
  input {
    text confirm filters=trim
    int claim_id?=99
  }
  stack {
    precondition ($input.confirm == "RESET_CLAIM_99") {
      error_type = "accessdenied"
      error = "Reset confirmation token is required."
    }

    db.get "claim" {
      field_name = "id"
      field_value = $input.claim_id
    } as $existing

    precondition ($existing != null) {
      error_type = "notfound"
      error = "Demo claim not found."
    }

    db.edit "claim" {
      field_name = "id"
      field_value = $input.claim_id
      data = {
        status: "new",
        priority: "high",
        assigned_agent_id: 0,
        assigned_queue: "unassigned",
        amount_approved: 0,
        closed_at: 0,
        sla_due_at: 0,
        summary: "Storm and roof damage requiring specialist routing"
      }
    } as $claim

    db.bulk.delete "claim_event" {
      where = $db.claim_event.claim_id == $input.claim_id
    } as $deleted_events

    function.run "log_claim_event" {
      input = {
        claim_id: $input.claim_id,
        actor_id: null,
        event_type: "created",
        message: "Demo reset: claim returned to baseline before catastrophe routing change.",
        payload: {
          reset_for: "catastrophe_routing_demo",
          deleted_events: $deleted_events
        }
      }
    } as $reset_event
  }
  response = {
    claim: $claim,
    deleted_events: $deleted_events,
    reset_event: $reset_event
  }
  guid = "Ea7a7S1I1hyetKj7p0nlMf2FlZk"
}
