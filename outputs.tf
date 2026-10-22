output "subscription_id" {
  value = data.azurerm_subscription.current.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.cost.id
}

output "subscription_budget_id" {
  value = azurerm_consumption_budget_subscription.subscription.id
}

output "resource_budget_ids" {
  value = { for k, v in azurerm_consumption_budget_subscription.resource : k => v.id }
}

output "anomaly_alert_id" {
  value = var.enable_anomaly_alert ? azurerm_cost_anomaly_alert.subscription[0].id : null
}
