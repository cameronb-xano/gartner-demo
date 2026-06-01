query "templates" verb=POST {
  api_group = "notify"
  description = "Create or upsert a notification template"
  input {
    text name filters=trim
    enum channel {
      values = ["email", "sms", "push", "inapp"]
    }
    text subject? filters=trim
    text body filters=trim
    bool is_active?=true
  }
  stack {
    db.add_or_edit "notification_template" {
      field_name = "name"
      field_value = $input.name
      data = {
        name: $input.name,
        channel: $input.channel,
        subject: $input.subject,
        body: $input.body,
        is_active: $input.is_active,
        created_at: now
      }
    } as $template
  }
  response = $template
  guid = "07JZgz3LAiHmUQD1pHt0tLhdYac"
}
