query "auto-approval" verb=GET {
  api_group = "rules"
  description = "Readable customer claims auto-approval rule for PM and engineering review."
  input {
  }
  stack {
    var $rule {
      value = {
        id: "customer_claims_auto_approval",
        version: "2026.05",
        description: "Approve if claim under $5K, policy active over 1 year, and no fraud flag.",
        conditions: [
          { key: "claim_under_5000", label: "Claim amount is under $5,000" },
          { key: "policy_active_over_1_year", label: "Policy is active for more than one year" },
          { key: "no_fraud_flag", label: "Customer has no fraud flag" }
        ],
        owner: "Claims Operations",
        last_reviewed: "2026-05-20"
      }
    }
  }
  response = $rule
  guid = "nNl2YkiL8qjW7mV73DeyoRJl3DI"
}
