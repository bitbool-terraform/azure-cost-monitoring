data "azurerm_subscription" "current" {}

resource "azurerm_monitor_action_group" "cost" {
  name                = format("%s-%s-ag",data.azurerm_subscription.current.display_name,var.name_prefix)
  resource_group_name = var.resource_group
  short_name          = substr(var.name_prefix, 0, 12)
  location            = var.location
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = toset(var.email_addresses)
    content {
      name                    = "email-${substr(md5(email_receiver.value), 0, 12)}"
      email_address           = email_receiver.value
      use_common_alert_schema = var.use_common_alert_schema
    }
  }
}

resource "azurerm_consumption_budget_subscription" "subscription" {
  name            = format("%s-sub-monthly-budget",data.azurerm_subscription.current.display_name)
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.subscription_budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = local.budget_start_date
  }

  dynamic "notification" {
    for_each = var.actual_thresholds
    content {
      enabled        = true
      operator       = "GreaterThanOrEqualTo"
      threshold      = notification.value
      threshold_type = "Actual"
      contact_groups = [azurerm_monitor_action_group.cost.id]
    }
  }

  dynamic "notification" {
    for_each = var.forecast_threshold == null ? [] : [var.forecast_threshold]
    content {
      enabled        = true
      operator       = "GreaterThanOrEqualTo"
      threshold      = notification.value
      threshold_type = "Forecasted"
      contact_groups = [azurerm_monitor_action_group.cost.id]
    }
  }

  lifecycle {
  ignore_changes = [time_period]
  }
}

resource "azurerm_consumption_budget_resource_group" "resource_group" {
  for_each = var.resource_group_budgets

  name              = "${each.key}-rg-monthly-budget"
  resource_group_id = each.value.resource_group_id
  amount            = each.value.amount
  time_grain        = "Monthly"

  time_period {
    start_date = local.budget_start_date
  }

  dynamic "notification" {
    for_each = var.actual_thresholds
    content {
      enabled        = true
      operator       = "GreaterThanOrEqualTo"
      threshold      = notification.value
      threshold_type = "Actual"

      contact_groups = [azurerm_monitor_action_group.cost.id]
    }
  }

  dynamic "notification" {
    for_each = var.forecast_threshold == null ? [] : [var.forecast_threshold]
    content {
      enabled        = true
      operator       = "GreaterThanOrEqualTo"
      threshold      = notification.value
      threshold_type = "Forecasted"

      contact_groups = [azurerm_monitor_action_group.cost.id]
    }
  }
  lifecycle {
  ignore_changes = [time_period]
  }
}

resource "azurerm_consumption_budget_subscription" "resource" {
  for_each = var.resource_budgets

  name            = "${each.key}-monthly-budget"
  subscription_id = data.azurerm_subscription.current.id
  amount          = each.value.amount
  time_grain      = "Monthly"

  time_period {
    start_date = local.budget_start_date
  }

  filter {
    dimension {
      name   = "ResourceId"
      values = [each.value.resource_id]
    }
  }

  dynamic "notification" {
    for_each = each.value.actual_thresholds == null ? var.actual_thresholds : each.value.actual_thresholds
    content {
      enabled        = true
      operator       = "GreaterThanOrEqualTo"
      threshold      = notification.value
      threshold_type = "Actual"
      contact_groups = [azurerm_monitor_action_group.cost.id]
    }
  }

  dynamic "notification" {
    for_each = var.forecast_threshold == null ? [] : [var.forecast_threshold]
    content {
      enabled        = true
      operator       = "GreaterThanOrEqualTo"
      threshold      = notification.value
      threshold_type = "Forecasted"
      contact_groups = [azurerm_monitor_action_group.cost.id]
    }
  }
  lifecycle {
  ignore_changes = [time_period]
  }
}

resource "azurerm_cost_anomaly_alert" "subscription" {
  count = var.enable_anomaly_alert ? 1 : 0

  name            = format("%s-cost-anomaly",data.azurerm_subscription.current.display_name)
  display_name    = "Daily subscription cost anomalies"
  subscription_id = data.azurerm_subscription.current.id
  email_subject   = "Azure subscription cost anomaly"
  email_addresses = var.email_addresses
  notification_email = var.email_addresses[0]
}