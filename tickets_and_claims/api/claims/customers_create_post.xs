query "customers" verb=POST {
  api_group = "claims"
  description = "Create a customer record locally and mirror it to the Customer Profiling workspace so cross-workspace events can be attributed."
  auth = "user"
  input {
    text first_name filters=trim
    text last_name filters=trim
    email email filters=trim|lower
    text phone? filters=trim
    text policy_number? filters=trim|upper
    json address?
  }
  stack {
    db.has "customer" {
      field_name = "email"
      field_value = $input.email
    } as $exists

    precondition (!$exists) {
      error_type = "inputerror"
      error = "A customer with that email already exists"
    }

    db.add "customer" {
      data = {
        first_name: $input.first_name,
        last_name: $input.last_name,
        email: $input.email,
        phone: $input.phone,
        policy_number: $input.policy_number,
        address: $input.address,
        created_at: now
      }
    } as $customer

    try_catch {
      try {
        api.request {
          url = "https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-profiling/customers"
          method = "POST"
          params = {
            first_name: $input.first_name,
            last_name: $input.last_name,
            email: $input.email,
            phone: $input.phone,
            policy_number: $input.policy_number,
            address: $input.address
          }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $profiling_result
      }
      catch {
        debug.log { value = "profiling sync failed (non-fatal): " ~ ($error.message ?? "unknown") }
      }
    }
  }
  response = $customer
  guid = "z4wOLMr_nnm3vgVAs6ypNQ6WGW8"
}
