query "assignments" verb=GET {
  api_group = "workflow"
  description = "List demo adjuster assignments for the recorded claims workflow."
  input {
  }
  stack {
    var $assignments {
      value = {
        items: [
          {
            id: 1042,
            claim_id: 1042,
            claim_number: "CLM-2026-01042",
            claim_type: "property",
            queue: "property_specialist",
            priority: "high",
            assigned_to: "Maya Specialist",
            status: "assigned",
            created_at: now
          }
        ],
        itemsTotal: 1,
        curPage: 1,
        pageTotal: 1
      }
    }
  }
  response = $assignments
  guid = "wgFNvNWsh7RnQz9EbFVn9fT_Pn4"
}
