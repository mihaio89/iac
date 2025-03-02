# Configure the Azure provider
provider "azurerm" {
  features {}  # The 'features' block is required for the provider to initialize.
}

# Define the subscription ID variable
variable "subscription_id" {
  description = "The Subscription ID where the resources will be created"
  type        = string  # This variable is required to specify the subscription.
}

# Define the resource group name variable (defaults to 'rg-health')
variable "resource_group_name" {
  default = "rg-health"  # The default value for the resource group name.
}

# Define the action group name variable (defaults to 'ag-resourcehealth')
variable "action_group_name" {
  default = "ag-resourcehealth"  # The default name for the action group.
}

# Define the location variable (defaults to 'EastUS')
variable "location" {
  default = "EastUS"  # The default Azure region where resources will be created.
}

# Resource group definition
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name  # Name of the resource group, taken from the 'resource_group_name' variable.
  location = var.location            # Location of the resource group, taken from the 'location' variable.
}

# Action group definition (for handling alerts)
resource "azurerm_monitor_action_group" "action_group" {
  name                = var.action_group_name  # Name of the action group, taken from the 'action_group_name' variable.
  resource_group_name = azurerm_resource_group.resource_group.name  # Resource group where the action group will be created.
  short_name          = "ResourceHealth"           # Short name used in alert notifications (up to 22 characters).
  location            = "Global"               # Location of the action group (this is always global for action groups).

  enabled = true  # Enable the action group to be active.

  # Email receiver configuration for the action group
  email_receiver {
    name                  = "emailReceiver"               # Name of the email receiver.
    email_address         = "example@example.com"         # The email address to send alerts to.
    use_common_alert_schema = true                        # Use the common alert schema for notifications.
  }
}

# Activity Log Alert definition (for monitoring resource health)
resource "azurerm_monitor_activity_log_alert" "activity_log_alert" {
  name                = "[ResourceHealth]-${var.subscription_id}"  # Name of the activity log alert, includes the subscription ID.
  resource_group_name = azurerm_resource_group.resource_group.name  # Resource group where the activity log alert will be created.
  scopes              = ["/subscriptions/${var.subscription_id}"]   # Scopes define the subscription where the alert applies.
  description         = "Alert for resources that become unavailable."  # Description of the alert.

  # Criteria that must be met for the alert to trigger
  criteria {
    # All criteria must match for this condition to be met
    all_of {
      field  = "category"  # The category of the activity log.
      equals = "ResourceHealth"  # Only trigger if the category is 'ResourceHealth'.
    }

    # Any one of the following conditions must match
    any_of {
      field  = "properties.cause"  # Check the cause property.
      equals = "PlatformInitiated"  # Trigger alert if the cause is 'PlatformInitiated'.
    }

    any_of {
      field  = "properties.currentHealthStatus"  # Check the current health status property.
      equals = "Degraded"  # Trigger alert if the current health status is 'Degraded'.
    }

    any_of {
      field  = "properties.previousHealthStatus"  # Check the previous health status property.
      equals = "Available"  # Trigger alert if the previous health status was 'Available'.
    }
  }

  # Action to be taken when the alert is triggered
  action {
    action_group_id = azurerm_monitor_action_group.action_group.id  # Link the action group that will be notified when the alert triggers.
  }
}
