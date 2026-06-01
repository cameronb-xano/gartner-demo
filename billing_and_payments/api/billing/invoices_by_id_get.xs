query "invoices/{invoice_id}" verb=GET {
  api_group = "billing"
  description = "Get a single invoice with its payment history"
  input {
    int invoice_id { table = "invoice" }
  }
  stack {
    db.get "invoice" {
      field_name = "id"
      field_value = $input.invoice_id
    } as $invoice

    precondition ($invoice != null) {
      error_type = "notfound"
      error = "Invoice not found"
    }

    db.query "payment" {
      where = $db.payment.invoice_id == $input.invoice_id
      sort = { created_at: "desc" }
      return = { type: "list" }
    } as $payments
  }
  response = { invoice: $invoice, payments: $payments }
  guid = "aFO8OYlCRcA_V8f6QwpEX3pmSYI"
}
