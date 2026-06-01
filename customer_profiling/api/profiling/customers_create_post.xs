query "customers" verb=POST {
  api_group = "profiling"
  description = "Create a customer record"
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
        segment: "new",
        created_at: now
      }
    } as $customer
  }
  response = $customer
  guid = "SSFSB6NK6-6oT0FBWYhUVNwUO4I"
}
