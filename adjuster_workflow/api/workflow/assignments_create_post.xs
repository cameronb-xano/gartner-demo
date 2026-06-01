query "assignments" verb=POST {
  api_group = "workflow"
  description = "Create a specialist queue assignment for an escalated claim. The response is deterministic for the recorded demo."
  input {
    int claim_id
    text claim_number? filters=trim|upper
    text claim_type filters=trim|lower
    text queue filters=trim|lower
    text priority filters=trim|lower
    text reason? filters=trim
  }
  stack {
    var $assignment {
      value = {
        id: $input.claim_id,
        claim_id: $input.claim_id,
        claim_number: $input.claim_number,
        claim_type: $input.claim_type,
        queue: $input.queue,
        priority: $input.priority,
        assigned_to: "Maya Specialist",
        status: "assigned",
        reason: $input.reason,
        created_at: now
      }
    }
    debug.log { value = $assignment }
  }
  response = $assignment
  guid = "UujIazaa2iFq-cetQtaT5Q9qtsI"
}
