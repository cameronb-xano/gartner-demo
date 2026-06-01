query "queues" verb=GET {
  api_group = "workflow"
  description = "List specialist queues available for escalated claims."
  input {
  }
  stack {
    var $queues {
      value = {
        items: [
          { key: "auto_specialist", name: "Auto Specialist", sla_hours: 4, lead: "Riley Park" },
          { key: "property_specialist", name: "Property Specialist", sla_hours: 4, lead: "Morgan Lee" },
          { key: "liability_specialist", name: "Liability Specialist", sla_hours: 2, lead: "Jordan Ellis" },
          { key: "complex_claims", name: "Complex Claims", sla_hours: 8, lead: "Avery Stone" },
          { key: "general_review", name: "General Review", sla_hours: 24, lead: "Casey Brooks" }
        ],
        itemsTotal: 5,
        curPage: 1,
        pageTotal: 1
      }
    }
  }
  response = $queues
  guid = "vEllyx15X62eIeHoihEGjwHeOeQ"
}
