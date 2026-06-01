function "create_payout_invoice" {
  description = "Cross-workspace call to Billing & Payments workspace to create an inbound (payout) invoice when a claim is approved. Failures are swallowed."
  input {
    int customer_id
    text claim_ref filters=trim|upper
    decimal amount filters=min:0
    text description? filters=trim
  }
  stack {
    var $result { value = null }
    try_catch {
      try {
        api.request {
          url = "https://x5oh-bynb-yevw.n7d.xano.io/api:gartner-billing/invoices"
          method = "POST"
          params = {
            customer_id: $input.customer_id,
            claim_ref: $input.claim_ref,
            direction: "inbound",
            amount: $input.amount,
            currency: "USD",
            description: $input.description ?? ("Claim payout for " ~ $input.claim_ref),
            due_in_days: 14
          }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $api_result
        var.update $result { value = $api_result.response.result }
      }
      catch {
        debug.log { value = "create_payout_invoice failed (non-fatal): " ~ ($error.message ?? "unknown") }
      }
    }
  }
  response = $result
  guid = "DOEO9SI1OG5eMfrGwCNMsBA5rCs"
}
