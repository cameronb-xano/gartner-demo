query "claims/{claim_id}/timeline" verb=GET {
  api_group = "claims"
  description = "Return the full timeline of events for a claim"
  auth = "user"
  input {
    int claim_id { table = "claim" }
    int page?=1 filters=min:1
    int per_page?=50 filters=min:1|max:200
  }
  stack {
    db.query "claim_event" {
      where = $db.claim_event.claim_id == $input.claim_id
      sort = { created_at: "desc" }
      return = {
        type: "list",
        paging: { page: $input.page, per_page: $input.per_page }
      }
    } as $events
  }
  response = $events
  guid = "mITyXVCfU-ecB4K5_QtEO1RIV7c"
}
