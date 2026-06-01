query "notifications" verb=GET {
  api_group = "notify"
  description = "List notification delivery log"
  input {
    int customer_id?
    text channel? filters=trim|lower
    text status? filters=trim|lower
    text template_name? filters=trim
    int page?=1 filters=min:1
    int per_page?=25 filters=min:1|max:100
  }
  stack {
    db.query "notification" {
      where = $db.notification.customer_id ==? $input.customer_id && $db.notification.channel ==? $input.channel && $db.notification.status ==? $input.status && $db.notification.template_name ==? $input.template_name
      sort = { created_at: "desc" }
      return = {
        type: "list",
        paging: { page: $input.page, per_page: $input.per_page, totals: true }
      }
    } as $notifications
  }
  response = $notifications
  guid = "zL4DXJuBinGiKZiRy0UHbLGrIU4"
}
