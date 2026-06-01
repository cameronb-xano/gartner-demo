function "get_customer_notifications" {
  description = "Cross-workspace GET to Notifications & Communications — fetch notification delivery log for a customer. Returns empty list on failure."
  input {
    int customer_id
    int per_page?=20 filters=min:1|max:100
  }
  stack {
    var $notifications { value = [] }
    try_catch {
      try {
        api.request {
          url = "https://x5oh-bynb-yevw.n7d.xano.io/api:gartner-notify/notifications"
          method = "GET"
          params = { customer_id: $input.customer_id, per_page: $input.per_page }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $api_result
        conditional {
          if ($api_result.response.status == 200) {
            var.update $notifications { value = ($api_result.response.result.items ?? []) }
          }
        }
      }
      catch {
        debug.log { value = "get_customer_notifications failed (non-fatal): " ~ ($error.message ?? "unknown") }
      }
    }
  }
  response = $notifications
  guid = "CYKaTEnscNbNbmSmDxV9uW4jbE8"
}
