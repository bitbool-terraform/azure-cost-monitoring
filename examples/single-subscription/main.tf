terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.36.0, < 6.0.0"
    }
  }
}

variable "subscription_id" { type = string }
variable "budget_start_date" { type = string }
variable "email_addresses" { type = list(string) }
variable "foundry_resource_id" { type = string }

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "cost_monitoring" {
  source = "../../modules/cost-monitoring"

  # Change to false to reuse an existing resource group.
  create_resource_group   = true
  resource_group_name     = "rg-cost-monitoring"
  resource_group_location = "swedencentral"

  budget_start_date        = var.budget_start_date
  subscription_budget_name = "monthly-subscription-budget"
  subscription_budget_amount = 500
  actual_thresholds        = [50, 80, 100]
  forecast_threshold       = 100
  email_addresses          = var.email_addresses

  resource_budgets = {
    foundry = {
      resource_id = var.foundry_resource_id
      amount      = 100
      actual_thresholds = [50, 80, 100]
    }
  }

  enable_anomaly_alert = true
  anomaly_alert_name  = "cost-anomaly"

  tags = {
    managed_by = "terraform"
    purpose    = "cost-monitoring"
  }
}

output "cost_action_group_id" {
  value = module.cost_monitoring.action_group_id
}
