query "invoices/{invoice_id}/pay" verb=POST {
  api_group = "billing"
  description = "Record a payment against an invoice and mark it paid"
  input {
    int invoice_id { table = "invoice" }
    decimal amount? filters=min:0
    enum method?="manual" {
      values = ["card", "ach", "wire", "check", "credit", "manual"]
    }
    text transaction_ref? filters=trim
    json provider_payload?
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

    precondition ($invoice.status != "paid") {
      error_type = "inputerror"
      error = "Invoice is already paid"
    }

    var $pay_amount { value = $invoice.amount }
    conditional {
      if ($input.amount != null && $input.amount > 0) {
        var.update $pay_amount { value = $input.amount }
      }
    }

    security.create_uuid as $uuid
    var $tx_ref { value = ("PAY-" ~ ($input.invoice_id|to_text) ~ "-" ~ $uuid) }
    conditional {
      if ($input.transaction_ref != null && $input.transaction_ref != "") {
        var.update $tx_ref { value = $input.transaction_ref }
      }
    }

    db.add "payment" {
      data = {
        invoice_id: $input.invoice_id,
        amount: $pay_amount,
        currency: $invoice.currency,
        method: $input.method,
        transaction_ref: $tx_ref,
        status: "succeeded",
        provider_payload: $input.provider_payload,
        created_at: now
      }
    } as $payment

    db.edit "invoice" {
      field_name = "id"
      field_value = $input.invoice_id
      data = { status: "paid", paid_at: now }
    } as $updated_invoice
  }
  response = { invoice: $updated_invoice, payment: $payment }
  guid = "RkFGnHfF5xysLMlxdBmsd6yOQys"
}
