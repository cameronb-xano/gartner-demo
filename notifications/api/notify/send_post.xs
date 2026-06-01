query "send" verb=POST {
  api_group = "notify"
  description = "Send a notification using a template. Renders {{var}} placeholders against the supplied vars object. Called by other workspaces (Tickets, Billing) to notify customers."
  input {
    int customer_id
    text recipient filters=trim {
      description = "Email/phone/device token"
    }
    text template_name filters=trim
    enum channel?="email" {
      values = ["email", "sms", "push", "inapp"]
    }
    json vars?
    text source? filters=trim
  }
  stack {
    db.query "notification_template" {
      where = $db.notification_template.name == $input.template_name && $db.notification_template.channel == $input.channel && $db.notification_template.is_active == true
      return = { type: "single" }
    } as $template

    var $rendered_subject { value = "" }
    var $rendered_body { value = "" }

    conditional {
      if ($template != null) {
        var.update $rendered_subject { value = $template.subject ?? "" }
        var.update $rendered_body { value = $template.body }
        conditional {
          if ($input.vars != null) {
            object.keys {
              value = $input.vars
            } as $var_keys
            foreach ($var_keys) {
              each as $key {
                var $placeholder { value = "{{" ~ $key ~ "}}" }
                var $val { value = ($input.vars|get:$key)|to_text }
                var.update $rendered_subject { value = $rendered_subject|replace:$placeholder:$val }
                var.update $rendered_body { value = $rendered_body|replace:$placeholder:$val }
              }
            }
          }
        }
      }
      else {
        var.update $rendered_subject { value = ("[" ~ $input.template_name ~ "]") }
        var.update $rendered_body { value = "Template not found; logging notification only." }
      }
    }

    db.add "notification" {
      data = {
        customer_id: $input.customer_id,
        recipient: $input.recipient,
        channel: $input.channel,
        template_name: $input.template_name,
        subject: $rendered_subject,
        body: $rendered_body,
        status: "sent",
        source: $input.source,
        vars: $input.vars,
        sent_at: now,
        created_at: now
      }
    } as $notification
  }
  response = $notification
  guid = "oYcwoWEiJ3tgfgvzhnyXLcBcYD0"
}
