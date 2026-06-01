query "customers/{customer_id}/insights" verb=GET {
  api_group = "claims"
  description = "Customer insights — fetches the unified profile, risk score, segment, and recent behavior events from the Customer Profiling workspace via cross-workspace HTTP."
  auth = "user"
  input {
    int customer_id { table = "customer" }
  }
  stack {
    db.get "customer" {
      field_name = "id"
      field_value = $input.customer_id
    } as $local_customer

    precondition ($local_customer != null) {
      error_type = "notfound"
      error = "Customer not found"
    }

    function.run "get_customer_profile" {
      input = { customer_id: $input.customer_id }
    } as $profile

    function.run "get_customer_notifications" {
      input = { customer_id: $input.customer_id, per_page: 10 }
    } as $recent_notifications

    db.query "claim" {
      where = $db.claim.customer_id == $input.customer_id
      sort = { opened_at: "desc" }
      return = { type: "list", paging: { page: 1, per_page: 20 } }
    } as $local_claims
  }
  response = {
    customer: $local_customer,
    profile: {
      _source: "gartner-profiling",
      data: $profile
    },
    recent_notifications: {
      _source: "gartner-notify",
      items: $recent_notifications
    },
    open_claims: {
      _source: "local",
      items: ($local_claims.items ?? $local_claims)
    }
  }
  guid = "sY1Fgf7ywIiwVZdP8jMOrLmZBMg"
}
