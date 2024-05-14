# SBCTC Inventory Updater

This PowerShell script updates SharePoint list items based on inventory data from a CSV file. It maps CSV columns to SharePoint fields using a configuration file and handles date conversions, updating only the fields that have changed.

## Features

- Reads a CSV file containing inventory data.
- Maps CSV columns to SharePoint fields using a configuration file (config.json).
- Converts date strings to SharePoint date format.
- Logs script execution details and errors to a log file.
- Only updates SharePoint list items when changes are detected.

## Requirements

- PowerShell 7.2 or later
- PnP.PowerShell module

## Installation

1. Install PowerShell 7.2 or later: [PowerShell Installation Guide](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
2. Install the PnP.PowerShell module:
    ```powershell
    Install-Module -Name PnP.PowerShell -Scope CurrentUser
    ```

## Configuration

Create a `config.json` file in the same directory as the script. The configuration file should map the CSV columns to the corresponding SharePoint fields.

Example `config.json`:
```json
{
  "SharePoint": {
    "siteURL": "https://yoursharepointsite",
    "listName": "YourListName"
  },
  "FieldMappings": {
    "Title": "AssetTag",
    "SerialNumber": "SerialNumber",
    "DOCID_x0028_currentowner_x0029_": "DOCID",
    "PurchaseDate": "PurchaseDate",
    "DueDate": "DueDate"
  }
}
