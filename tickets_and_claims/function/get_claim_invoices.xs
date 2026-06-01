function "get_claim_invoices" {
  description = "Cross-workspace GET to Billing & Payments — fetch all invoices issued for a given claim reference. Returns empty list on failure."
  input {
    text claim_ref filters=trim|upper
  }
  stack {
    var $invoices { value = [] }
    try_catch {
      try {
        api.request {
          url = "https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-billing/invoices"
          method = "GET"
          params = { claim_ref: $input.claim_ref }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $api_result
        conditional {
          if ($api_result.response.status == 200) {
            var.update $invoices { value = ($api_result.response.result.items ?? []) }
          }
        }
      }
      catch {
        debug.log { value = "get_claim_invoices failed (non-fatal): " ~ ($error.message ?? "unknown") }
      }
    }
  }
  response = $invoices
  guid = "z3Tl0sr97XQa27T-YUhTjo7BLTk"
}
