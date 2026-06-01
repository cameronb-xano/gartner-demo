query "claims/{claim_id}/escalate" verb=POST {
  api_group = "claims"
  description = "Route a claim using Snowflake context, Rules & Decisioning, and Datadog observability without hardcoding business policy in Customer Claims."
  auth = "user"
  input {
    int claim_id { table = "claim" }
    text reason? filters=trim
  }
  stack {
    db.get "claim" {
      field_name = "id"
      field_value = $input.claim_id
    } as $claim

    precondition ($claim != null) {
      error_type = "notfound"
      error = "Claim not found"
    }

    db.get "customer" {
      field_name = "id"
      field_value = $claim.customer_id
    } as $customer

    var $policy_context {
      value = {
        claim_id: $input.claim_id,
        customer_id: $claim.customer_id,
        customer_name: "Maya Chen",
        policy_number: "POL-PROP-2048",
        policy_status: "active",
        policy_age_months: 28,
        coverage_tier: "homeowners_plus",
        deductible: 500,
        coverage_valid: true,
        source: "demo_fallback"
      }
    }

    try_catch {
      try {
        db.external.snowflake.direct_query {
          sql = "select customer_id, customer_name, policy_number, policy_status, policy_age_months, coverage_tier, deductible, coverage_valid, summary from XANO_DEMO.CLAIMS_DEMO.CLAIM_POLICY_CONTEXT where claim_id = {{ $input.claim_id|sql_esc }}"
          parser = "template_engine"
          response_type = "single"
          connection_string = "snowflake://XANO_DEMO_USER:-----BEGIN%20PRIVATE%20KEY-----%0AMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCR3eCGn%2FIYuk0S%0A1NG0qUCSabDYNDrPBuE9Yaxj0SFXclXT3QOuY%2FBZdg%2BYg%2FhgdgQ05vA9DfkYCuKm%0Atx7J6E0l5lwTVDvPHEA3OTHRhCqDkzGNbswOzYFIYNT69TNfKhPx%2By1lN8H3pBWe%0AvwPyK0s2IcZH54cCtAXfpLbbDO2CG%2FHl4TLXAwnJ74JXst6uJa1L4xV%2BrZh%2F0eRY%0Ae3HCHF8SMnj5dbcTNRijnpUKT4VOtDcmZ%2BMqL3u4ytpCPocIhEjKf5LsA6lAOhR2%0Abz2450Rc4h4l%2B2qG0ecxSWit69XW5GlTD9OiQvEfk7z3vrfHpKErD%2F%2FaR5EWKGvx%0AkJWfa9DBAgMBAAECggEAAw%2BcLhVFSO05P9ROB2ID3tI9vxO9gqKQYVptiErslM3P%0ACWIvx0%2FMzMoGEPtUbilUu5npQ3iCpoACpQuJCwijw5dXOE4stnaksasWUES%2BzolC%0AfeOzDfrpsjppFN5xK7PnEc1lgvm%2FnsdcxI%2F9Re5swwNu%2FCfamGQ0ZAQeBnAyn4RC%0AYs%2Flx4XeuCbFzze44UxsptuNnZ7KqFlvcdQeO6qTxFnTjBKKfhA4r3UxUt%2BiXg6i%0Ahcqo0kI4FuC%2BfTzvMDL6EwVcgGm6MZH1ZQ%2BQsqMKsxBzov58pbdCB05CCA1wVdFX%0AbXPie48p8M3LDszU2NhOVTMpQP78sxGMVL6sTh%2BVSQKBgQDEUIt2f9XCuFkKItuc%0AfRWmQEPfZs%2FXIQmT3350CeBHri5GH3Gp4Ei96B1uabFuJNb2MeP6eBQXq9tkXSqI%0A5XR2HPBTDcbh%2B7IFfBSVWBPuOwcF5Gl904RRoNnX3q%2Fr%2BPqW1S1u8EDxnLz6MzXg%0AdSeiG1XaHTAeHQfiuRdJZ%2Fc6tQKBgQC%2BNuWLzX7TYuyG9HhuUHbcWwQAxaDgNoGe%0ALhhKhgrJMUZUcD%2By3lfLysKPJ96WAYBnlVnxhZR5ktB%2BBCBvzgu%2F0NXluSbwNJZ7%0AGntXBs%2Bs0HjrAI05V%2F8MRWBvgRmxukZ0qWJL%2BsiaiKtVDKJjSl9y9K%2BGbpZCeOPC%0ACHqXZ7KpXQKBgHE88KVC6d%2BvDJU%2FNCRZNqK2UTBNErhJ80db1IpEpB1UyJZkTuEp%0AYWxBtrBYwSMClwheEN4KY7SfyiZjY0Sh7oKvAKU3vi%2FeSnrFbu4SZzS00cFBVuRg%0AnOOk%2F%2BN4LUvVS16zyshCR4PW4F8GKR63FUx5rhTpXzcPkdvi3h7WnJI9AoGAH%2F1%2F%0AkYmYANksSm4nKvZhZyHvhGm4ar0AA6hg8XelrLyaxWyzadO3FFEfc5ATAUtzWvhl%0AThdXJzMn2Wm8QtF2bGYk8yO2hsNxY3bKs5Izry7Ih01qcvB3toqcc2RU%2B%2B0GGGy8%0AWWbuAf9mQUGEtgo2D1FTi9phbwCB3Yorg%2FcutwkCgYEAj6Sx%2Fnpm5IJt7Ab3HyxG%0AtxFI33ReF87A9NoyzUtxwMIyLEQA4UqA7%2BQXwtFxS8KWIFE4mMaiKRuobFAzW07T%0A1rfdUSZDQDk6YNarjACEgcTLvzLDTZf4IDL92FfxkL89FZwB0E6m2DdUTvNXcc3S%0AWl5kk%2BnNSCdJhPav34wX5ag%3D%0A-----END%20PRIVATE%20KEY-----%0A@VJSKWGT-CO19189:443/XANO_DEMO?schema=CLAIMS_DEMO&warehouse=COMPUTE_WH&role=XANO_DEMO_ROLE"
        } as $policy_snowflake_row
        conditional {
          if ($policy_snowflake_row != null) {
            var.update $policy_context {
              value = {
                claim_id: $input.claim_id,
                customer_id: $policy_snowflake_row.CUSTOMER_ID,
                customer_name: $policy_snowflake_row.CUSTOMER_NAME,
                policy_number: $policy_snowflake_row.POLICY_NUMBER,
                policy_status: $policy_snowflake_row.POLICY_STATUS,
                policy_age_months: $policy_snowflake_row.POLICY_AGE_MONTHS,
                coverage_tier: $policy_snowflake_row.COVERAGE_TIER,
                deductible: $policy_snowflake_row.DEDUCTIBLE,
                coverage_valid: $policy_snowflake_row.COVERAGE_VALID,
                summary: $policy_snowflake_row.SUMMARY,
                source: "snowflake"
              }
            }
          }
        }
      }
      catch {
        debug.log { value = "Snowflake policy context lookup unavailable; using demo fallback data." }
      }
    }

    var $claim_history {
      value = {
        customer_id: $claim.customer_id,
        prior_claim_count: 2,
        prior_claim_total: 12400,
        fraud_flag: false,
        last_claim_at: "2025-11-18T15:30:00Z",
        source: "demo_fallback"
      }
    }

    try_catch {
      try {
        db.external.snowflake.direct_query {
          sql = "select customer_id, prior_claim_count, prior_claim_total, fraud_flag, last_claim_at from XANO_DEMO.CLAIMS_DEMO.CUSTOMER_CLAIM_HISTORY where customer_id = {{ $claim.customer_id|sql_esc }}"
          parser = "template_engine"
          response_type = "single"
          connection_string = "snowflake://XANO_DEMO_USER:-----BEGIN%20PRIVATE%20KEY-----%0AMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCR3eCGn%2FIYuk0S%0A1NG0qUCSabDYNDrPBuE9Yaxj0SFXclXT3QOuY%2FBZdg%2BYg%2FhgdgQ05vA9DfkYCuKm%0Atx7J6E0l5lwTVDvPHEA3OTHRhCqDkzGNbswOzYFIYNT69TNfKhPx%2By1lN8H3pBWe%0AvwPyK0s2IcZH54cCtAXfpLbbDO2CG%2FHl4TLXAwnJ74JXst6uJa1L4xV%2BrZh%2F0eRY%0Ae3HCHF8SMnj5dbcTNRijnpUKT4VOtDcmZ%2BMqL3u4ytpCPocIhEjKf5LsA6lAOhR2%0Abz2450Rc4h4l%2B2qG0ecxSWit69XW5GlTD9OiQvEfk7z3vrfHpKErD%2F%2FaR5EWKGvx%0AkJWfa9DBAgMBAAECggEAAw%2BcLhVFSO05P9ROB2ID3tI9vxO9gqKQYVptiErslM3P%0ACWIvx0%2FMzMoGEPtUbilUu5npQ3iCpoACpQuJCwijw5dXOE4stnaksasWUES%2BzolC%0AfeOzDfrpsjppFN5xK7PnEc1lgvm%2FnsdcxI%2F9Re5swwNu%2FCfamGQ0ZAQeBnAyn4RC%0AYs%2Flx4XeuCbFzze44UxsptuNnZ7KqFlvcdQeO6qTxFnTjBKKfhA4r3UxUt%2BiXg6i%0Ahcqo0kI4FuC%2BfTzvMDL6EwVcgGm6MZH1ZQ%2BQsqMKsxBzov58pbdCB05CCA1wVdFX%0AbXPie48p8M3LDszU2NhOVTMpQP78sxGMVL6sTh%2BVSQKBgQDEUIt2f9XCuFkKItuc%0AfRWmQEPfZs%2FXIQmT3350CeBHri5GH3Gp4Ei96B1uabFuJNb2MeP6eBQXq9tkXSqI%0A5XR2HPBTDcbh%2B7IFfBSVWBPuOwcF5Gl904RRoNnX3q%2Fr%2BPqW1S1u8EDxnLz6MzXg%0AdSeiG1XaHTAeHQfiuRdJZ%2Fc6tQKBgQC%2BNuWLzX7TYuyG9HhuUHbcWwQAxaDgNoGe%0ALhhKhgrJMUZUcD%2By3lfLysKPJ96WAYBnlVnxhZR5ktB%2BBCBvzgu%2F0NXluSbwNJZ7%0AGntXBs%2Bs0HjrAI05V%2F8MRWBvgRmxukZ0qWJL%2BsiaiKtVDKJjSl9y9K%2BGbpZCeOPC%0ACHqXZ7KpXQKBgHE88KVC6d%2BvDJU%2FNCRZNqK2UTBNErhJ80db1IpEpB1UyJZkTuEp%0AYWxBtrBYwSMClwheEN4KY7SfyiZjY0Sh7oKvAKU3vi%2FeSnrFbu4SZzS00cFBVuRg%0AnOOk%2F%2BN4LUvVS16zyshCR4PW4F8GKR63FUx5rhTpXzcPkdvi3h7WnJI9AoGAH%2F1%2F%0AkYmYANksSm4nKvZhZyHvhGm4ar0AA6hg8XelrLyaxWyzadO3FFEfc5ATAUtzWvhl%0AThdXJzMn2Wm8QtF2bGYk8yO2hsNxY3bKs5Izry7Ih01qcvB3toqcc2RU%2B%2B0GGGy8%0AWWbuAf9mQUGEtgo2D1FTi9phbwCB3Yorg%2FcutwkCgYEAj6Sx%2Fnpm5IJt7Ab3HyxG%0AtxFI33ReF87A9NoyzUtxwMIyLEQA4UqA7%2BQXwtFxS8KWIFE4mMaiKRuobFAzW07T%0A1rfdUSZDQDk6YNarjACEgcTLvzLDTZf4IDL92FfxkL89FZwB0E6m2DdUTvNXcc3S%0AWl5kk%2BnNSCdJhPav34wX5ag%3D%0A-----END%20PRIVATE%20KEY-----%0A@VJSKWGT-CO19189:443/XANO_DEMO?schema=CLAIMS_DEMO&warehouse=COMPUTE_WH&role=XANO_DEMO_ROLE"
        } as $history_snowflake_row
        conditional {
          if ($history_snowflake_row != null) {
            var.update $claim_history {
              value = {
                customer_id: $history_snowflake_row.CUSTOMER_ID,
                prior_claim_count: $history_snowflake_row.PRIOR_CLAIM_COUNT,
                prior_claim_total: $history_snowflake_row.PRIOR_CLAIM_TOTAL,
                fraud_flag: $history_snowflake_row.FRAUD_FLAG,
                last_claim_at: $history_snowflake_row.LAST_CLAIM_AT,
                source: "snowflake"
              }
            }
          }
        }
      }
      catch {
        debug.log { value = "Snowflake claim history lookup unavailable; using demo fallback data." }
      }
    }

    var $rules_decision {
      value = {
        rule_workspace: "Rules & Decisioning",
        rule_version: "fallback",
        decision: "escalate",
        auto_approved: false,
        assigned_queue: "general_review",
        priority: "high",
        reason: "Rules workspace unavailable; route to general review.",
        checks: {}
      }
    }

    try_catch {
      try {
        api.request {
          url = "https://x5oh-bynb-yevw.n7d.xano.io/api:gartner-rules-decisioning/decisions/evaluate"
          method = "POST"
          params = {
            claim_id: $claim.id,
            claim_type: $claim.claim_type,
            amount_requested: $claim.amount_requested,
            policy_status: $policy_context.policy_status,
            policy_age_months: $policy_context.policy_age_months,
            fraud_flag: $claim_history.fraud_flag,
            summary: ($policy_context.summary ?? $claim.summary),
            coverage_tier: $policy_context.coverage_tier
          }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $rules_result
        var.update $rules_decision { value = $rules_result.response.result }
      }
      catch {
        debug.log { value = "Rules & Decisioning workspace unavailable; using fallback routing." }
      }
    }

    function.run "log_claim_event" {
      input = {
        claim_id: $input.claim_id,
        actor_id: $auth.id,
        event_type: "auto_approval_evaluated",
        message: $rules_decision.reason,
        payload: $rules_decision
      }
    }

    var $assigned_queue { value = $rules_decision.assigned_queue }
    var $priority { value = $rules_decision.priority }

    datadog.log {
      message = "claim.escalated"
      service = "northstar-claims"
      tags = [
        ("claim_id:" ~ $claim.id),
        ("claim_number:" ~ $claim.claim_number),
        ("claim_type:" ~ $claim.claim_type),
        ("route:" ~ $assigned_queue),
        ("priority:" ~ $priority)
      ]
      attributes = {
        claim_id: $claim.id,
        claim_number: $claim.claim_number,
        claim_type: $claim.claim_type,
        route: $assigned_queue,
        priority: $priority,
        rules_decision: $rules_decision
      }
    }

    datadog.metric {
      metric = "claims.escalations.routed"
      value = 1
      type = "gauge"
      tags = [
        ("claim_type:" ~ $claim.claim_type),
        ("route:" ~ $assigned_queue),
        ("priority:" ~ $priority)
      ]
    }

    var $datadog_event {
      value = {
        provider: "datadog",
        type: "claim.escalated",
        payload: {
          claim_id: $claim.id,
          claim_number: $claim.claim_number,
          claim_type: $claim.claim_type,
          route: $assigned_queue,
          priority: $priority,
          rules_decision: $rules_decision
        },
        accepted: true,
        recorded_at: now
      }
    }

    var $datadog_metric {
      value = {
        provider: "datadog",
        name: "claims.escalations.routed",
        value: 1,
        tags: {
          claim_type: $claim.claim_type,
          route: $assigned_queue,
          priority: $priority
        },
        accepted: true,
        recorded_at: now
      }
    }

    var $escalation_record { value = null }
    try_catch {
      try {
        api.request {
          url = "https://x5oh-bynb-yevw.n7d.xano.io/api:gartner-escalation-payouts/events"
          method = "POST"
          params = {
            claim_id: $claim.id,
            claim_number: $claim.claim_number,
            route: $assigned_queue,
            priority: $priority,
            payload: {
              rules_decision: $rules_decision,
              datadog_event: $datadog_event,
              datadog_metric: $datadog_metric
            }
          }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $escalation_result
        var.update $escalation_record { value = $escalation_result.response.result }
      }
      catch {
        debug.log { value = "Escalation & Payouts event failed (non-fatal)." }
      }
    }

    db.patch "claim" {
      field_name = "id"
      field_value = $input.claim_id
      data = {
        priority: $priority,
        status: "in_review",
        assigned_queue: $assigned_queue,
        sla_due_at: now|transform_timestamp:"+4 hours"
      }
    } as $updated

    function.run "log_claim_event" {
      input = {
        claim_id: $input.claim_id,
        actor_id: $auth.id,
        event_type: "escalated",
        message: ("Routed to " ~ $assigned_queue ~ ($input.reason != null ? (": " ~ $input.reason) : "")),
        payload: {
          from_priority: $claim.priority,
          to_priority: $priority,
          from_queue: $claim.assigned_queue,
          to_queue: $assigned_queue,
          reason: $input.reason,
          snowflake_policy_context: $policy_context,
          snowflake_claim_history: $claim_history,
          rules_decision: $rules_decision,
          escalation_record: $escalation_record
        }
      }
    }

    function.run "log_claim_event" {
      input = {
        claim_id: $input.claim_id,
        actor_id: $auth.id,
        event_type: "observability_logged",
        message: "Datadog escalation event and metric recorded",
        payload: {
          event: $datadog_event,
          metric: $datadog_metric
        }
      }
    }

    function.run "record_customer_event" {
      input = {
        customer_id: $claim.customer_id,
        event_type: "claim_escalated",
        payload: {
          claim_id: $claim.id,
          claim_number: $claim.claim_number,
          route: $assigned_queue,
          priority: $priority,
          reason: $input.reason
        }
      }
    }

    conditional {
      if ($customer != null) {
        function.run "notify_customer" {
          input = {
            customer_id: $claim.customer_id,
            recipient: $customer.email,
            template_name: "claim_escalated",
            channel: "email",
            vars: {
              claim_number: $claim.claim_number,
              customer_name: $customer.first_name,
              route: $assigned_queue,
              reason: ($input.reason ?? "additional review needed")
            }
          }
        }
      }
    }
  }
  response = {
    claim: $updated,
    rules_decision: $rules_decision,
    route: $assigned_queue,
    priority: $priority,
    snowflake: {
      customer_data: $policy_context,
      claim_history: $claim_history
    },
    datadog: {
      event: $datadog_event,
      metric: $datadog_metric
    },
    escalation_record: $escalation_record,
    escalated_at: now,
    sla_due_at: $updated.sla_due_at
  }
  guid = "OULB0fwvMAicse_z33h0PUuf5T8"
}
