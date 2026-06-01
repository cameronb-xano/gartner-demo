query "payouts" verb=GET {
  api_group = "escalations"
  description = "List demo payout and disbursement records tied to escalated claims."
  input {
    text claim_ref? filters=trim|upper
  }
  stack {
    var $payouts {
      value = {
        items: [
          {
            id: 3001,
            claim_ref: "CLM-2026-01042",
            customer_id: 77,
            direction: "inbound",
            amount: 18420,
            currency: "USD",
            status: "pending_review",
            description: "Potential payout pending specialist review",
            due_at: now|transform_timestamp:"+5 days"
          },
          {
            id: 3002,
            claim_ref: "CLM-2026-01040",
            customer_id: 78,
            direction: "inbound",
            amount: 4200,
            currency: "USD",
            status: "approved",
            description: "Auto-approved payout",
            due_at: now|transform_timestamp:"+2 days"
          }
        ],
        itemsTotal: 2,
        curPage: 1,
        pageTotal: 1
      }
    }
  }
  response = $payouts
  guid = "pRMHM1J8DBr1VbvecLUq_b70NNQ"
}
