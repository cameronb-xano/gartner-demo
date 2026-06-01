query "claims/stats" verb=GET {
  api_group = "claims"
  description = "Aggregate claim counts and total dollar amounts grouped by status. Built live via the sandbox-push workflow during the Gartner demo."
  auth = "user"
  input {
  }
  stack {
    db.query "claim" {
      return = { type: "list" }
    } as $all_claims

    var $stats { value = {
      total_count: ($all_claims|count),
      total_amount_requested: 0,
      total_amount_approved: 0,
      by_status: {}
    } }

    foreach ($all_claims) {
      each as $c {
        var.update $stats { value = $stats|set:"total_amount_requested":(($stats|get:"total_amount_requested") + ($c.amount_requested ?? 0)) }
        var.update $stats { value = $stats|set:"total_amount_approved":(($stats|get:"total_amount_approved") + ($c.amount_approved ?? 0)) }

        var $status_bucket { value = ($stats|get:"by_status")|get:$c.status:{ count: 0, amount_requested: 0, amount_approved: 0 } }
        var.update $status_bucket { value = $status_bucket|set:"count":(($status_bucket|get:"count") + 1) }
        var.update $status_bucket { value = $status_bucket|set:"amount_requested":(($status_bucket|get:"amount_requested") + ($c.amount_requested ?? 0)) }
        var.update $status_bucket { value = $status_bucket|set:"amount_approved":(($status_bucket|get:"amount_approved") + ($c.amount_approved ?? 0)) }

        var $by_status { value = ($stats|get:"by_status")|set:$c.status:$status_bucket }
        var.update $stats { value = $stats|set:"by_status":$by_status }
      }
    }
  }
  response = $stats
  guid = "95I1ax-LeRPV_NIilshWW3t7wQc"
}
