query "policies" verb=GET {
  api_group = "policy"
  description = "List demo policy records for the recorded insurance claims workspace."
  input {
  }
  stack {
    var $policies {
      value = {
        items: [
          {
            id: 2048,
            customer_id: 77,
            customer_name: "Maya Chen",
            policy_number: "POL-PROP-2048",
            policy_type: "property",
            status: "active",
            age_months: 28,
            coverage_tier: "homeowners_plus",
            deductible: 500
          },
          {
            id: 2049,
            customer_id: 78,
            customer_name: "Andre Wilson",
            policy_number: "POL-AUTO-2049",
            policy_type: "auto",
            status: "active",
            age_months: 19,
            coverage_tier: "comprehensive",
            deductible: 750
          }
        ],
        itemsTotal: 2,
        curPage: 1,
        pageTotal: 1
      }
    }
  }
  response = $policies
  guid = "l_a9fY3lkDWSq3-i_MEULr3DGvQ"
}
