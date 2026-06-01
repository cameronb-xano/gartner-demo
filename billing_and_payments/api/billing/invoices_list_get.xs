query "invoices" verb=GET {
  api_group = "billing"
  description = "List invoices, optionally filtered by customer or claim reference"
  input {
    int customer_id?
    text claim_ref? filters=trim|upper
    text status? filters=trim|lower
    text direction? filters=trim|lower
    int page?=1 filters=min:1
    int per_page?=25 filters=min:1|max:100
  }
  stack {
    db.query "invoice" {
      where = $db.invoice.customer_id ==? $input.customer_id && $db.invoice.claim_ref ==? $input.claim_ref && $db.invoice.status ==? $input.status && $db.invoice.direction ==? $input.direction
      sort = { created_at: "desc" }
      return = {
        type: "list",
        paging: { page: $input.page, per_page: $input.per_page, totals: true }
      }
    } as $invoices
  }
  response = $invoices
  guid = "NgwbHll7s4BWZGnJ2b1GcZvvfLg"
}
