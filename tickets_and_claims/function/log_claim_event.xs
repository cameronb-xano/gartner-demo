function "log_claim_event" {
  description = "Append an event row to a claim's timeline"
  input {
    int claim_id { table = "claim" }
    int actor_id? { table = "user" }
    text event_type
    text message? filters=trim
    json payload?
  }
  stack {
    db.add "claim_event" {
      data = {
        claim_id: $input.claim_id,
        actor_id: $input.actor_id,
        event_type: $input.event_type,
        message: $input.message,
        payload: $input.payload,
        created_at: now
      }
    } as $event
  }
  response = $event
  guid = "ikOlS4ErUo6tNANOw837cruqOZo"
}
