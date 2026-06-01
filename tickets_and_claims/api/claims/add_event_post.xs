query "claims/{claim_id}/events" verb=POST {
  api_group = "claims"
  description = "Append a custom event (typically a note or attachment marker) to a claim's timeline"
  auth = "user"
  input {
    int claim_id { table = "claim" }
    enum event_type {
      values = ["note_added", "attachment_added", "ticket_added"]
    }
    text message? filters=trim
    json payload?
  }
  stack {
    db.has "claim" {
      field_name = "id"
      field_value = $input.claim_id
    } as $exists

    precondition ($exists) {
      error_type = "notfound"
      error = "Claim not found"
    }

    function.run "log_claim_event" {
      input = {
        claim_id: $input.claim_id,
        actor_id: $auth.id,
        event_type: $input.event_type,
        message: $input.message,
        payload: $input.payload
      }
    } as $event
  }
  response = $event
  guid = "c8D8kTKBLIl7w39lHYsuFouDJWQ"
}
