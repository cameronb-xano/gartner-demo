table "user" {
  auth = true
  schema {
    int id
    timestamp created_at?=now
    text name filters=trim
    email email filters=trim|lower {
      sensitive = true
    }
    password password {
      sensitive = true
    }
    enum role?="agent" {
      values = ["agent", "supervisor", "admin"]
    }
    bool is_active?=true
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "email"}]}
    {type: "btree", field: [{name: "role"}]}
  ]
  guid = "Nh9QNG3k8C-rUSlNU1q6gERSTl4"
}
