```terraform
module "cost_monitoring" {
  source = "../../modules/cost-monitoring"

  resource_group = 
  location       = 
  name_prefix    = 

  email_addresses = []

  enable_anomaly_alert = true
  tags = {}

  # Subscription Level
  subscription_budget_amount = 500
  actual_thresholds        = [50, 80, 100]
  forecast_threshold       = 100

  # RG Level
 resource_group_budgets = {
    databases = {
      resource_group_id = azurerm_resource_group.databases.id
      amount            = 200
    }
  }

  # Resource Level
  resource_budgets = {
    foundry = {
      resource_id = var.foundry_resource_id
      amount      = 100
      actual_thresholds = [50, 80, 100]
    }
  }
}
```