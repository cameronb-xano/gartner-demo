function "snowflake_get_customer_data" {
  description = "Snowflake lookup for claim, customer, and policy context. Uses db.external.snowflake.direct_query with deterministic fallback data."
  input {
    int claim_id
  }
  stack {
    var $context {
      value = {
        claim_id: $input.claim_id,
        customer_id: 77,
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
        } as $snowflake_row
        conditional {
          if ($snowflake_row != null) {
            var.update $context {
              value = {
                claim_id: $input.claim_id,
                customer_id: $snowflake_row.CUSTOMER_ID,
                customer_name: $snowflake_row.CUSTOMER_NAME,
                policy_number: $snowflake_row.POLICY_NUMBER,
                policy_status: $snowflake_row.POLICY_STATUS,
                policy_age_months: $snowflake_row.POLICY_AGE_MONTHS,
                coverage_tier: $snowflake_row.COVERAGE_TIER,
                deductible: $snowflake_row.DEDUCTIBLE,
                coverage_valid: $snowflake_row.COVERAGE_VALID,
                summary: $snowflake_row.SUMMARY,
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
  }
  response = $context
  guid = "Ha3dF3xWqytimxN7cK3RUZ2S1mA"
}
