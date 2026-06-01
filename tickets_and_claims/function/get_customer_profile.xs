function "get_customer_profile" {
  description = "Cross-workspace GET to Customer Profiling — fetch a customer's full profile (risk score, LTV, segment, recent events). Returns null on failure."
  input {
    int customer_id
  }
  stack {
    var $result { value = null }
    try_catch {
      try {
        api.request {
          url = ("https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-profiling/customers/" ~ ($input.customer_id|to_text))
          method = "GET"
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $api_result
        conditional {
          if ($api_result.response.status == 200) {
            var.update $result { value = $api_result.response.result }
          }
        }
      }
      catch {
        debug.log { value = "get_customer_profile failed (non-fatal): " ~ ($error.message ?? "unknown") }
      }
    }
  }
  response = $result
  guid = "1m3II0ghUuNz36cu_1X-kRdQ4Aw"
}
