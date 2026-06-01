query "customers" verb=GET {
  api_group = "profiling"
  description = "List customers with optional segment filter"
  input {
    text segment? filters=trim|lower
    text search? filters=trim|lower
    int page?=1 filters=min:1
    int per_page?=25 filters=min:1|max:100
  }
  stack {
    db.query "customer" {
      where = $db.customer.segment ==? $input.segment && ($db.customer.email includes? $input.search || $db.customer.last_name includes? $input.search || $db.customer.policy_number includes? $input.search)
      sort = { created_at: "desc" }
      return = {
        type: "list",
        paging: { page: $input.page, per_page: $input.per_page, totals: true }
      }
    } as $customers
  }
  response = $customers
  guid = "f-xjvEjT135eCw9QAlYitMDeE9c"
}
