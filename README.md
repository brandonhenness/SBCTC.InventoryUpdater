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
3. Download the script from GitHub:
    - Navigate to the GitHub repository.
    - Click on the **Code** button.
    - Select **Download ZIP**.
    - Unzip the downloaded file.
    - Move `SBCTC.InventoryUpdater.ps1` and `config.json` to the desired location.

## Configuration

Create a `config.json` file in the same directory as the script. The configuration file should map the CSV columns to the corresponding SharePoint fields.

Example `config.json`:
```json
{
    "SharePoint": {
        "siteURL": "https://yoursharepointsite",
        "listName": "YourListName"
    },
    "Permissions": [
        { "site": "SCCC", "email": "user1@example.com" },
        { "site": "SCCC", "email": "user2@example.com" },
        { "site": "SCCC", "email": "user3@example.com" },
        { "site": "SCCC", "email": "user4@example.com" },
        { "site": "SCCC", "email": "user5@example.com" }
    ],
    "FieldMappings": {
        "Title": "asset_id",
        "AssetType": "asset_type",
        "Manufacturer": "manufacturer",
        "Model": "model",
        "SerialNumber": "serial_number",
        "Status": "status",
        "DOCID_x0028_currentowner_x0029_": "doc_number",
        "LastName_x0028_currentowner_x002": "last_name",
        "FirstName_x0028_currentowner_x00": "first_name",
        "DueDate": "transaction_timestamp",
        "AgreementForm": "agreement_signed",
        "OriginatingSite": "origin_site",
        "CurrentSite": "current_site",
        "PurchasePrice": "asset_cost",
        "Color": "color",
        "Housing": "housing_cell",
        "Unit": "housing_unit",
        "IncidentInvolvement": null,
        "PurchaseDate": null,
        "OrderNumber": null,
        "Program": null,
        "ConditionNotes": null,
        "OMNI": null
    }
}
```
## Usage

1. Place the `SBCTC.InventoryUpdater.ps1` script and `config.json` file in the same directory.
2. Open PowerShell and navigate to the script directory.
3. Run the script:
    ```powershell
    ./SBCTC.InventoryUpdater.ps1
    ```
4. A file dialog will prompt you to select the CSV file containing the inventory data.

## Logging

The script logs its execution details to `SBCTC.InventoryUpdater.log` in the same directory as the script. The log level can be adjusted by changing the `$global:logLevel` variable.

- Set to `DEBUG` for detailed logging.
- Set to `INFO` for general logging.

## License

Licensed under GNU General Public License v3.0.

## Author

Brandon Henness

## Contact

Email: [brandon.henness@doc1.wa.gov](mailto:brandon.henness@doc1.wa.gov)

## Version

2024051400

## Notes

- Ensure the CSV file is properly formatted.
- The script checks for required PowerShell version and PnP.PowerShell module.
- Handle errors gracefully and log them appropriately.

## Copyright

© 2024 Brandon Henness
