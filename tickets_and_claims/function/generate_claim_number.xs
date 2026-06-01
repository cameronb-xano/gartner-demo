function "generate_claim_number" {
  description = "Generate a human-readable claim number like CLM-2026-00001 based on current claim count for the year"
  input {
  }
  stack {
    var $year { value = now|format_timestamp:"Y":"UTC" }

    db.query "claim" {
      return = { type: "count" }
    } as $total

    var $next_seq { value = $total + 1 }
    var $seq_text { value = $next_seq|to_text }
    var $padded_raw { value = "00000" ~ $seq_text }
    var $start { value = ($padded_raw|strlen) - 5 }
    var $padded { value = $padded_raw|substr:$start:5 }
    var $claim_number { value = "CLM-" ~ $year ~ "-" ~ $padded }
  }
  response = $claim_number
  guid = "iPt-3aPzgPQFOBrA74GIvVXV-eA"
}
