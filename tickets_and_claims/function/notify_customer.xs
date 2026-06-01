function "notify_customer" {
  description = "Cross-workspace call to Notifications & Communications workspace to send a templated message. Failures are swallowed so they don't break the parent claim flow."
  input {
    int customer_id
    text recipient filters=trim
    text template_name filters=trim
    enum channel?="email" {
      values = ["email", "sms", "push", "inapp"]
    }
    json vars?
  }
  stack {
    var $result { value = null }
    try_catch {
      try {
        api.request {
          url = "https://x5oh-bynb-yevw.n7d.xano.io/api:gartner-notify/send"
          method = "POST"
          params = {
            customer_id: $input.customer_id,
            recipient: $input.recipient,
            template_name: $input.template_name,
            channel: $input.channel,
            vars: $input.vars,
            source: "tickets"
          }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $api_result
        var.update $result { value = $api_result.response.result }
      }
      catch {
        debug.log { value = "notify_customer failed (non-fatal): " ~ ($error.message ?? "unknown") }
      }
    }
  }
  response = $result
  guid = "3ConOtQqiHqThqe0Lg5kUp3WVTk"
}
