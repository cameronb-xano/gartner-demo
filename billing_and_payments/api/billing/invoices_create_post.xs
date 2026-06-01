query "invoices" verb=POST {
  api_group = "billing"
  description = "Create an invoice. Called by Tickets & Claims when a claim is approved (direction=inbound, payout to customer) or by other systems for premiums (direction=outbound)."
  input {
    int customer_id
    text claim_ref? filters=trim|upper
    enum direction?="inbound" {
      values = ["outbound", "inbound"]
    }
    decimal amount filters=min:0
    text currency?="USD" filters=trim|upper
    text description? filters=trim
    int due_in_days?=14 filters=min:0|max:365
  }
  stack {
    var $due_at { value = now|transform_timestamp:("+" ~ ($input.due_in_days|to_text) ~ " days") }

    db.add "invoice" {
      data = {
        customer_id: $input.customer_id,
        claim_ref: $input.claim_ref,
        direction: $input.direction,
        amount: $input.amount,
        currency: $input.currency,
        status: "issued",
        description: $input.description,
        due_at: $due_at,
        created_at: now
      }
    } as $invoice
  }
  response = $invoice
  guid = "jtaRrVlznMiLzFcinuenW1s-G2o"
}
