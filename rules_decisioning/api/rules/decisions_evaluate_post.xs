query "decisions/evaluate" verb=POST {
  api_group = "rules"
  description = "Evaluate claim approval and routing rules from claim, policy, and fraud context."
  input {
    int claim_id?
    text claim_type filters=trim|lower
    decimal amount_requested filters=min:0
    text policy_status filters=trim|lower
    int policy_age_months
    bool fraud_flag
    text summary? filters=trim|lower
    text coverage_tier? filters=trim|lower
  }
  stack {
    var $claim_under_5000 { value = $input.amount_requested < 5000 }
    var $policy_active_over_1_year { value = $input.policy_status == "active" && $input.policy_age_months > 12 }
    var $no_fraud_flag { value = $input.fraud_flag == false }
    var $auto_approved { value = $claim_under_5000 && $policy_active_over_1_year && $no_fraud_flag }

    var $assigned_queue { value = "general_review" }
    conditional {
      if ($input.claim_type == "auto") {
        var.update $assigned_queue { value = "auto_specialist" }
      }
      elseif ($input.claim_type == "property") {
        var.update $assigned_queue { value = "property_specialist" }
      }
      elseif ($input.claim_type == "liability") {
        var.update $assigned_queue { value = "liability_specialist" }
      }
      elseif ($input.claim_type == "health" || $input.claim_type == "travel") {
        var.update $assigned_queue { value = "complex_claims" }
      }
    }

    var $priority { value = "high" }
    conditional {
      if ($input.amount_requested >= 25000 || $input.fraud_flag == true) {
        var.update $priority { value = "urgent" }
      }
      elseif ($auto_approved == true) {
        var.update $priority { value = "low" }
      }
    }

    var $decision { value = "escalate" }
    conditional {
      if ($auto_approved == true) {
        var.update $decision { value = "auto_approve" }
      }
    }

    var $reason { value = "Claim does not meet auto-approval criteria; route to specialist review." }
    conditional {
      if ($auto_approved == true) {
        var.update $reason { value = "Claim meets all auto-approval criteria." }
      }
      elseif ($input.fraud_flag == true) {
        var.update $reason { value = "Fraud flag requires specialist review." }
      }
      elseif ($input.policy_status != "active" || $input.policy_age_months <= 12) {
        var.update $reason { value = "Policy eligibility requires specialist review." }
      }
      elseif ($input.amount_requested >= 5000) {
        var.update $reason { value = "Requested amount exceeds auto-approval threshold." }
      }
    }
  }
  response = {
    rule_workspace: "Rules & Decisioning",
    rule_version: "2026.05",
    claim_id: $input.claim_id,
    decision: $decision,
    auto_approved: $auto_approved,
    assigned_queue: $assigned_queue,
    priority: $priority,
    reason: $reason,
    checks: {
      claim_under_5000: $claim_under_5000,
      policy_active_over_1_year: $policy_active_over_1_year,
      no_fraud_flag: $no_fraud_flag
    }
  }
  guid = "P9SajMW3mV5Ra4JHrs0dDk7g5fs"
}
