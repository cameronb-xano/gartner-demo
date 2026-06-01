function "record_customer_event" {
  description = "Cross-workspace call to Customer Profiling workspace to record a behavior event for a customer. Failures are swallowed."
  input {
    int customer_id
    text event_type filters=trim
    json payload?
  }
  stack {
    var $result { value = null }
    try_catch {
      try {
        api.request {
          url = "https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-profiling/events"
          method = "POST"
          params = {
            customer_id: $input.customer_id,
            source: "tickets",
            event_type: $input.event_type,
            payload: $input.payload
          }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $api_result
        var.update $result { value = $api_result.response.result }
      }
      catch {
        debug.log { value = "record_customer_event failed (non-fatal): " ~ ($error.message ?? "unknown") }
      }
    }
  }
  response = $result
  guid = "f3H2d_TwXO3mV1FaOM6OsfPIfr4"
}
