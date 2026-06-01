query "templates" verb=GET {
  api_group = "notify"
  description = "List active notification templates"
  input {
    text channel? filters=trim|lower
  }
  stack {
    db.query "notification_template" {
      where = $db.notification_template.channel ==? $input.channel && $db.notification_template.is_active == true
      sort = { name: "asc" }
      return = { type: "list" }
    } as $templates
  }
  response = $templates
  guid = "a1_69DKekm0Gx9_JJ6n2REhiGRE"
}
