query "claims/{claim_id}/360" verb=GET {
  api_group = "claims"
  description = "360-degree view of a claim with customer, policy, decisioning, payout, and communication context for the recorded insurance claims story."
  auth = "user"
  input {
    int claim_id { table = "claim" }
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
    } as $local_customer

    db.query "claim_event" {
      where = $db.claim_event.claim_id == $input.claim_id
      sort = { created_at: "desc" }
      return = { type: "list", paging: { page: 1, per_page: 50 } }
    } as $timeline

    function.run "get_customer_profile" {
      input = { customer_id: $claim.customer_id }
    } as $profiling_view

    function.run "get_claim_invoices" {
      input = { claim_ref: $claim.claim_number }
    } as $billing_view

    function.run "get_customer_notifications" {
      input = { customer_id: $claim.customer_id, per_page: 20 }
    } as $notifications_view

    var $policy_view {
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
            var.update $policy_view {
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

    var $claim_history_view {
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
            var.update $claim_history_view {
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

    var $rules_view { value = null }
    try_catch {
      try {
        api.request {
          url = "https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-rules-decisioning/decisions/evaluate"
          method = "POST"
          params = {
            claim_id: $claim.id,
            claim_type: $claim.claim_type,
            amount_requested: $claim.amount_requested,
            policy_status: $policy_view.policy_status,
            policy_age_months: $policy_view.policy_age_months,
            fraud_flag: $claim_history_view.fraud_flag,
            summary: ($policy_view.summary ?? $claim.summary),
            coverage_tier: $policy_view.coverage_tier
          }
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $rules_result
        var.update $rules_view { value = $rules_result.response.result }
      }
      catch {
        debug.log { value = "Rules & Decisioning read failed (non-fatal)." }
      }
    }

    var $payout_view { value = null }
    try_catch {
      try {
        api.request {
          url = ("https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-escalation-payouts/payouts?claim_ref=" ~ $claim.claim_number)
          method = "GET"
          headers = ["Content-Type: application/json"]
          timeout = 10
        } as $payout_result
        var.update $payout_view { value = $payout_result.response.result }
      }
      catch {
        debug.log { value = "Escalation & Payouts read failed (non-fatal)." }
      }
    }

    var $assigned_agent { value = null }
    conditional {
      if ($claim.assigned_agent_id != null && $claim.assigned_agent_id > 0) {
        db.get "user" {
          field_name = "id"
          field_value = $claim.assigned_agent_id
        } as $agent
        var.update $assigned_agent { value = { id: $agent.id, name: $agent.name, email: $agent.email, role: $agent.role } }
      }
    }
  }
  response = {
    claim: $claim,
    customer_local: $local_customer,
    assigned_agent: $assigned_agent,
    timeline: ($timeline.items ?? $timeline),
    profiling: {
      _source: "gartner-profiling",
      data: $profiling_view
    },
    billing: {
      _source: "gartner-billing",
      invoices: $billing_view
    },
    notifications: {
      _source: "gartner-notify",
      sent: $notifications_view
    },
    policy_data: {
      _source: "gartner-policy-data",
      customer_data: $policy_view,
      claim_history: $claim_history_view
    },
    rules_decisioning: {
      _source: "gartner-rules-decisioning",
      decision: $rules_view
    },
    escalation_payouts: {
      _source: "gartner-escalation-payouts",
      payouts: $payout_view
    }
  }
  guid = "_9cmWe-t6LlgNynvofMj8lbTEkI"
}
