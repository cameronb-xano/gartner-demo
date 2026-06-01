query "events" verb=POST {
  api_group = "profiling"
  description = "Ingest a behavior event for a customer. Called by other workspaces (Tickets, Billing, Notifications) to track activity."
  input {
    int customer_id { table = "customer" }
    text source filters=trim
    text event_type filters=trim
    json payload?
  }
  stack {
    db.has "customer" {
      field_name = "id"
      field_value = $input.customer_id
    } as $exists

    precondition ($exists) {
      error_type = "notfound"
      error = "Customer not found"
    }

    db.add "behavior_event" {
      data = {
        customer_id: $input.customer_id,
        source: $input.source,
        event_type: $input.event_type,
        payload: $input.payload,
        created_at: now
      }
    } as $event

    var $score_delta { value = 0 }
    var $ltv_delta { value = 0 }
    conditional {
      if ($input.event_type == "claim_opened") {
        var.update $score_delta { value = 5 }
      }
      elseif ($input.event_type == "claim_denied") {
        var.update $score_delta { value = 10 }
      }
      elseif ($input.event_type == "claim_paid") {
        var.update $ltv_delta { value = ($input.payload|get:"amount":0)|to_decimal }
      }
      elseif ($input.event_type == "payment_received") {
        var.update $ltv_delta { value = ($input.payload|get:"amount":0)|to_decimal }
      }
    }

    db.get "customer" {
      field_name = "id"
      field_value = $input.customer_id
    } as $customer

    var $new_score { value = ($customer.risk_score + $score_delta) }
    conditional {
      if ($new_score > 100) {
        var.update $new_score { value = 100 }
      }
    }
    var $new_ltv { value = $customer.lifetime_value + $ltv_delta }
    var $new_segment { value = $customer.segment }
    conditional {
      if ($new_score >= 70) {
        var.update $new_segment { value = "at_risk" }
      }
      elseif ($new_ltv >= 10000) {
        var.update $new_segment { value = "high_value" }
      }
      elseif ($customer.segment == "new") {
        var.update $new_segment { value = "standard" }
      }
    }

    db.edit "customer" {
      field_name = "id"
      field_value = $input.customer_id
      data = {
        risk_score: $new_score,
        lifetime_value: $new_ltv,
        segment: $new_segment,
        last_event_at: now
      }
    } as $updated_customer
  }
  response = { event: $event, customer: $updated_customer }
  guid = "zmrR-kDvg2Q4pdIm3fkMvsryKKc"
}
