function "evaluate_auto_approval" {
  description = "Core customer-claims business rule: auto-approve only when the claim is under $5K, the policy has been active over one year, and no fraud flag exists. This rule is intentionally not changed during the demo."
  input {
    decimal amount_requested
    text policy_status filters=trim|lower
    int policy_age_months
    bool fraud_flag
  }
  stack {
    var $approved {
      value = $input.amount_requested < 5000 && $input.policy_status == "active" && $input.policy_age_months > 12 && $input.fraud_flag == false
    }
    var $decision {
      value = {
        auto_approved: $approved,
        rule_name: "Customer Claims Auto-Approval",
        rule_description: "Approve if claim under $5K, policy active over 1 year, and no fraud flag.",
        checks: {
          claim_under_5000: $input.amount_requested < 5000,
          policy_active_over_1_year: $input.policy_status == "active" && $input.policy_age_months > 12,
          no_fraud_flag: $input.fraud_flag == false
        }
      }
    }
  }
  response = $decision
  guid = "NupRuCa5GgR9h9HETKfEsTcFrMo"
}
