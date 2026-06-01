query "customers/{customer_id}" verb=GET {
  api_group = "profiling"
  description = "Get a customer's full profile including recent behavior events and computed totals"
  input {
    int customer_id { table = "customer" }
  }
  stack {
    db.get "customer" {
      field_name = "id"
      field_value = $input.customer_id
    } as $customer

    precondition ($customer != null) {
      error_type = "notfound"
      error = "Customer not found"
    }

    db.query "behavior_event" {
      where = $db.behavior_event.customer_id == $input.customer_id
      sort = { created_at: "desc" }
      return = { type: "list", paging: { page: 1, per_page: 20 } }
    } as $events

    db.query "behavior_event" {
      where = $db.behavior_event.customer_id == $input.customer_id
      return = { type: "count" }
    } as $event_count
  }
  response = {
    customer: $customer,
    recent_events: $events.items ?? $events,
    total_events: $event_count
  }
  guid = "tdwBltfNRwTdhV6jk6D9CJjRAxQ"
}
