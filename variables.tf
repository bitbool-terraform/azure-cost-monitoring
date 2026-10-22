variable "resource_group" {
  description = "Resource group used for the Action Group (existing by default)."
  type        = string
}

variable "location" {
  description = "Location of the monitoring resource group, if the module creates it."
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {}

variable "email_addresses" {
  description = "Recipients of budget Action Group notifications and native anomaly emails."
  type        = list(string)

  validation {
    condition     = length(var.email_addresses) > 0 && length(distinct(var.email_addresses)) == length(var.email_addresses)
    error_message = "At least one email address is required, and addresses must be unique."
  }
}

variable "subscription_budget_amount" {
  description = "Monthly cost budget for the entire subscription, in its billing currency."
  type        = number

  validation {
    condition     = var.subscription_budget_amount > 0
    error_message = "subscription_budget_amount must be positive."
  }
}

variable "actual_thresholds" {
  description = "Actual spending alert percentages. Up to four when forecast alerts are also used."
  type        = list(number)
  default     = [85, 100, 120]

  validation {
    condition = (
      length(var.actual_thresholds) >= 1 &&
      length(var.actual_thresholds) <= 4 &&
      length(distinct(var.actual_thresholds)) == length(var.actual_thresholds) &&
      alltrue([for t in var.actual_thresholds : t > 0 && t <= 1000])
    )
    error_message = "Supply 1-4 unique actual alert percentages between 0 and 1000."
  }
}

variable "forecast_threshold" {
  description = "Forecasted monthly spending percent; set null to disable forecast notifications."
  type        = number
  default     = 100
  nullable    = true

  validation {
    condition     = var.forecast_threshold == null ? true : (var.forecast_threshold > 0 && var.forecast_threshold <= 1000)
    error_message = "forecast_threshold must be null or between 0 and 1000."
  }
}

variable "resource_budgets" {
  description = "Optional named per-resource budgets; ResourceId cost dimension is used."
  type = map(object({
    resource_id       = string
    amount            = number
    actual_thresholds = optional(list(number))
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, v in var.resource_budgets :
      v.amount > 0 &&
      (v.actual_thresholds == null ? true : (
        length(v.actual_thresholds) >= 1 &&
        length(v.actual_thresholds) <= 4 &&
        length(distinct(v.actual_thresholds)) == length(v.actual_thresholds) &&
        alltrue([for t in v.actual_thresholds : t > 0 && t <= 1000])
      ))
    ])
    error_message = "Each resource budget needs a positive amount and, if overridden, 1-4 unique actual thresholds between 0 and 1000."
  }
}

variable "resource_group_budgets" {
  description = "Optional monthly budgets for resource groups."
  type = map(object({
    resource_group_id = string
    amount            = number
  }))
  default = {}
}

variable "enable_anomaly_alert" {
  description = "Enable native Azure Cost Management daily subscription anomaly emails."
  type        = bool
  default     = true
}

variable "use_common_alert_schema" {
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for resources supporting tags (RG and Action Group)."
  type        = map(string)
  default     = {}
}