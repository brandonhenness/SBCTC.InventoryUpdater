# SBCTC Inventory Updater

This PowerShell script is designed for the State Board for Community and Technical Colleges (SBCTC) to update SharePoint list items based on inventory data from a CSV file. The script uses a configuration file to map CSV columns to SharePoint fields, handle date conversions, and update only the fields that have changed. Detailed logging is provided to track the script's execution and any errors encountered.

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

1. Install PowerShell 7.2 or later:
    - Follow the [PowerShell Installation Guide](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell).
    - During installation, make sure to check the box that adds the PowerShell 7 right-click menu option.
2. Install the PnP.PowerShell module:
    ```powershell
    Install-Module -Name PnP.PowerShell -Scope CurrentUser
    ```
3. Download the script from GitHub:
    - Navigate to the GitHub repository.
    - Click on the **Code** button.
    - Select **Download ZIP**.
    - Unzip the downloaded file.
    - Move `SBCTC.InventoryUpdater.ps1` to the desired location.

## Usage

1. Place the `SBCTC.InventoryUpdater.ps1` script in the desired directory.
2. Run the script. If the `config.json` file does not exist, it will be created automatically.
3. Modify the `config.json` file as needed after it is created.
4. Run the script again to update SharePoint list items based on the CSV file.

### Running the Script

#### Option 1: Using PowerShell 7

1. Open PowerShell 7 and navigate to the script directory.
2. Run the script:
    ```powershell
    ./SBCTC.InventoryUpdater.ps1
    ```
3. A file dialog will prompt you to select the CSV file containing the inventory data.
4. After selecting the CSV file, you will be asked to authenticate to the SharePoint server. Use the email associated with your account on the SBCTC SharePoint server.

#### Option 2: Using the Right-Click Menu

If you have the right-click menu option installed for PowerShell 7:

1. Right-click the `SBCTC.InventoryUpdater.ps1` script.
2. Select **Run with PowerShell 7**.
3. A file dialog will prompt you to select the CSV file containing the inventory data.
4. After selecting the CSV file, you will be asked to authenticate to the SharePoint server. Use the email associated with your account on the SBCTC SharePoint server.

## Configuration

### Field Mappings

The `config.json` file contains a `FieldMappings` section that maps CSV columns to the corresponding SharePoint fields. The key is the SharePoint field name, and the value is the CSV column name.

Example `FieldMappings` section:
```json
{
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

### Editing Field Mappings

To edit the field mappings:

1. Open the `config.json` file in a text editor.
2. Locate the `FieldMappings` section.
3. Modify the values to match the column names in your CSV file. Ensure that the keys (SharePoint field names) remain unchanged.
4. Save the changes to the `config.json` file.

Example:
If your CSV file has a column named `device_type` that should map to the SharePoint field `AssetType`, you would update the `AssetType` mapping as follows:
```json
"AssetType": "device_type"
```

## Logging

The script logs its execution details to `SBCTC.InventoryUpdater.log` in the same directory as the script. The log level can be adjusted by changing the `logLevel` setting in the `config.json` file.

- Set to `DEBUG` for detailed logging.
- Set to `INFO` for general logging.

## License

SBCTC Inventory Updater is licensed under the [GNU General Public License v3.0](LICENSE).

## Author

Brandon Henness

## Contact

Email: [brandon.henness@doc1.wa.gov](mailto:brandon.henness@doc1.wa.gov)

## Version

v2024051500

## Notes

- Ensure the CSV file is properly formatted.
- The script checks for required PowerShell version and PnP.PowerShell module.
- Handle errors gracefully and log them appropriately.

## Copyright

© 2024 Brandon Henness
