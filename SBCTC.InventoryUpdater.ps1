<#
.SYNOPSIS
    SBCTC Inventory Updater script for updating SharePoint list items based on CSV data.

.DESCRIPTION
    This PowerShell script is designed for the State Board for Community and Technical Colleges (SBCTC)
    to update SharePoint list items based on inventory data from a CSV file. The script uses a configuration
    file to map CSV columns to SharePoint fields, handle date conversions, and update only the fields that
    have changed. Detailed logging is provided to track the script's execution and any errors encountered.

.AUTHOR
    Brandon Henness

.CONTACT
    Email: brandon.henness@doc1.wa.gov

.VERSION
    2024051400

.DATE
    2024-05-14

.NOTES
    Requires PowerShell 7.2 or later.
    Requires the PnP.PowerShell module.

.LICENSE
    Licensed under GNU General Public License v3.0

.COPYRIGHT
    Copyright (c) 2024 Brandon Henness
#>

# Define the global log level variable
$global:logLevel = "INFO"  # Set to "DEBUG" for debugging, "INFO" for production

function Write-LogMessage {
    param (
        [string]$message,
        [string]$level = "INFO"
    )

    # Check if the message level should be logged based on the global log level
    $logLevels = @{
        "DEBUG"   = 0
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
    }

    if ($logLevels[$level] -ge $logLevels[$global:logLevel]) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp][$level] $message"

        Add-Content -Path $logFilePath -Value $logEntry

        switch ($level) {
            "INFO"    { $color = "White" }
            "ERROR"   { $color = "Red" }
            "WARNING" { $color = "Yellow" }
            "DEBUG"   { $color = "Cyan" }
            default   { $color = "White" }
        }

        Write-Host $logEntry -ForegroundColor $color
    }
}

function ConvertTo-SharePointDate($dateString) {
    if ([string]::IsNullOrWhiteSpace($dateString) -or $dateString -eq 'NULL') {
        return $null
    } else {
        try {
            [DateTime]$date = [DateTime]::Parse($dateString)
            return $date.ToString("yyyy-MM-ddTHH:mm:ss")
        } catch {
            Write-LogMessage "Failed to parse date: '$dateString'" "ERROR"
            return $null
        }
    }
}

function Write-ErrorLog {
    param (
        [string]$message,
        [Exception]$exception
    )

    Write-LogMessage "$message Error: $($exception.Message)" "ERROR"
}

function Write-ScriptInfo {
    Write-LogMessage "Script: `tSBCTC.InventoryUpdater.ps1"
    Write-LogMessage "Author: `tBrandon Henness"
    Write-LogMessage "Contact:`tbrandon.henness@doc1.wa.gov"
    Write-LogMessage "Version:`t2024051400"
    Write-LogMessage "Date:   `t2024-05-14"
    Write-LogMessage "Licensed under GNU General Public License v3.0"
    Write-LogMessage "Copyright (c) 2024 Brandon Henness"
}

# Path to the log file
$logFilePath = "$PSScriptRoot\SBCTC.InventoryUpdater.log"

# Check if the log file exists, if not, create it
if (-Not (Test-Path $logFilePath)) {
    New-Item -Path $logFilePath -ItemType File | Out-Null
}

# Clear the log file at the start
Clear-Content -Path $logFilePath

# Log script metadata
Write-ScriptInfo

# Main script
try {
    # Ensure this script runs in PowerShell 7+
    if ($PSVersionTable.PSVersion -lt [Version]"7.2") {
        throw "This script requires PowerShell 7.2 or later."
    }

    # Check for required PnP PowerShell module
    if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
        throw "PnP.PowerShell module is not installed. Please install it using 'Install-Module -Name PnP.PowerShell -Scope CurrentUser'.`nFor more information, visit https://pnp.github.io/powershell/articles/installation.html."
    }

    # Load the Windows Forms assembly
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Write-LogMessage "Windows Forms assembly loaded successfully." "INFO"
    } catch {
        Write-ErrorLog "Failed to load the Windows Forms assembly." $_
        exit
    }

    # Get the directory of the script
    $scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
    $configPath = Join-Path -Path $scriptDirectory -ChildPath 'config.json'
    $configData = Get-Content -Path $configPath | ConvertFrom-Json

    Write-LogMessage "Configuration loaded successfully." "INFO"
    Write-LogMessage "Configuration Data: $($configData | ConvertTo-Json -Depth 10)" "DEBUG"

    # Verify FieldMappings
    if ($null -eq $configData.FieldMappings) {
        Write-LogMessage "FieldMappings not found in configuration." "ERROR"
        exit
    } else {
        Write-LogMessage "FieldMappings found in configuration." "INFO"
    }

    # Attempt to access FieldMappings.Keys explicitly
    $fieldMappingsKeys = $configData.FieldMappings | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
    Write-LogMessage "FieldMappings Keys: $($fieldMappingsKeys -join ', ')" "DEBUG"

    # Iterate through FieldMappings keys
    foreach ($key in $fieldMappingsKeys) {
        Write-LogMessage "Key: $key, Value: $($configData.FieldMappings.$key)" "DEBUG"
    }

    # Create and configure the OpenFileDialog
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog

    # Set the initial directory to the directory of the script
    $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
    $openFileDialog.initialDirectory = $scriptPath

    $openFileDialog.filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
    $openFileDialog.Title = "Select a CSV File for SharePoint Import"

    # Show the OpenFileDialog
    $result = $openFileDialog.ShowDialog()

    # Exit if no file is selected
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-LogMessage "File selection cancelled." "WARNING"
        exit
    }

    $csvPath = $openFileDialog.FileName
    Write-LogMessage "Selected file: $csvPath" "INFO"

    # Attempt to import the CSV file
    try {
        $csvData = Import-Csv -Path $csvPath
        Write-LogMessage "CSV file imported successfully." "INFO"
    } catch {
        Write-ErrorLog "Failed to import CSV file. Please ensure the file is in a valid CSV format." $_
        exit
    }

    # Try to get the current PnP connection
    try {
        $connection = Get-PnPConnection
    } catch {
        Write-LogMessage "Current PnP connection not found." "INFO"
    }

    # Check if the connection is available and valid for the intended URL
    if ($null -eq $connection -or $connection.Url -ne $configData.SharePoint.siteURL) {
        # No valid connection to the desired site, so perform authentication
        Write-LogMessage "Not connected to $($configData.SharePoint.siteURL). Attempting to authenticate..." "INFO"
        try {
            Connect-PnPOnline -Url $configData.SharePoint.siteURL -UseWebLogin -ErrorAction Stop
            Write-LogMessage "Connected to SharePoint site: $($configData.SharePoint.siteURL)" "INFO"
        } catch {
            Write-ErrorLog "Error connecting to SharePoint site." $_
            exit
        }
    } else {
        # Already connected to the correct site
        Write-LogMessage "Already connected to $($configData.SharePoint.siteURL)" "INFO"
    }

    # Print an initial log message
    Write-LogMessage "Starting to process CSV data and map to SharePoint fields"

    foreach ($row in $csvData) {
        if ($null -eq $row) {
            Write-LogMessage "Row is null, skipping this row." "ERROR"
            continue
        }
        
        $csvMap = @{}
        $fieldsChanged = $false

        # Retrieve FieldMappings keys
        $fieldMappingsKeys = $configData.FieldMappings | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name

        foreach ($key in $fieldMappingsKeys) {
            $csvFieldName = $configData.FieldMappings.$key
            $fieldValue = $row.$csvFieldName

            Write-LogMessage "Mapping CSV column '$csvFieldName' to SharePoint field '$key' with value '$fieldValue'" "DEBUG"

            if ($fieldValue -eq "NULL" -or $null -eq $fieldValue) {
                $csvMap[$key] = $null
                continue
            }

            if ($key -like "*Date" -or $key -eq "DueDate") {
                $dateValue = ConvertTo-SharePointDate $fieldValue
                if ($null -ne $dateValue) {
                    $csvMap[$key] = $dateValue
                }
            } else {
                $csvMap[$key] = $fieldValue
            }
        }

        $indexValue = $row.PSObject.Properties[$configData.FieldMappings.Title].Value
        $csvSNFieldName = $configData.FieldMappings.SerialNumber
        $csvSN = $row.PSObject.Properties[$csvSNFieldName].Value

        # Build a query that filters by both index and serial number
        $query = @"
        <View>
            <Query>
                <Where>
                    <And>
                        <Eq><FieldRef Name='Title'/><Value Type='Text'>$indexValue</Value></Eq>
                        <Eq><FieldRef Name='SerialNumber'/><Value Type='Text'>$csvSN</Value></Eq>
                    </And>
                </Where>
            </Query>
        </View>
"@
        try {
            $listItems = Get-PnPListItem -List $configData.SharePoint.listName -Query $query
            if ($listItems.Count -eq 0) {
                $newItem = Add-PnPListItem -List $configData.SharePoint.listName -Values $csvMap -ErrorAction Stop
                Write-LogMessage "Created new item with Asset tag # '$indexValue' and Serial Number '$csvSN'" "INFO"
                Write-LogMessage "New Item ID: $($newItem.Id)" "DEBUG"
                Write-LogMessage "New Item GUID: $($newItem.FieldValues.UniqueId)" "DEBUG"
            } else {
                foreach ($item in $listItems) {
                    if ($null -eq $item) {
                        Write-LogMessage "Item is null, skipping this item." "ERROR"
                        continue
                    }

                    Write-LogMessage "Processing item with Asset tag # '$indexValue' and Serial Number '$csvSN'" "DEBUG"
                    Write-LogMessage "Item ID: $($item.Id)" "DEBUG"
                    Write-LogMessage "Item GUID: $($item.FieldValues.UniqueId)" "DEBUG"

                    # Check for changes
                    foreach ($key in $csvMap.Keys) {
                        $csvValue = $csvMap[$key]
                        if ($null -eq $csvValue) {
                            Write-LogMessage "CSV Value for key '$key' is null, skipping this key." "DEBUG"
                            continue
                        }
                        
                        if (-not $item.PSObject.Properties.Match($key)) {
                            Write-LogMessage "Item does not contain key '$key', skipping this key." "DEBUG"
                            continue
                        }

                        $spValue = $item[$key]
                        if ($null -eq $spValue) {
                            Write-LogMessage "SharePoint Value for key '$key' is null." "DEBUG"
                        }

                        Write-LogMessage "CSV Value Type: $($csvValue.GetType().Name), SharePoint Value Type: $($spValue.GetType().Name)" "DEBUG"

                        # Convert CSV value to double if SharePoint value is double
                        if ($spValue.GetType().Name -eq "Double" -and $csvValue.GetType().Name -eq "String") {
                            $csvValue = [double]$csvValue
                        }

                        # Convert CSV value to DateTime if SharePoint value is DateTime
                        if ($spValue.GetType().Name -eq "DateTime" -and $csvValue.GetType().Name -eq "String") {
                            try {
                                $csvValue = [DateTime]::Parse($csvValue)
                            } catch {
                                Write-LogMessage "Failed to parse CSV date value '$csvValue' for key '$key'" "ERROR"
                                continue
                            }
                        }

                        if ($csvValue -ne $spValue) {
                            Write-LogMessage "Difference found in field '$key': CSV Value = '$csvValue', SharePoint Value = '$spValue'" "DEBUG"
                            $fieldsChanged = $true
                            break
                        }
                    }

                    if ($fieldsChanged) {
                        # Check if DOCID has changed
                        if ($item["DOCID_x0028_currentowner_x0029_"] -ne $csvMap["DOCID_x0028_currentowner_x0029_"]) {
                            $csvMap["OMNI"] = $false
                        }
                        $updateResult = Set-PnPListItem -List $configData.SharePoint.listName -Identity $item.Id -Values $csvMap -ErrorAction Stop
                        if ($updateResult) {
                            Write-LogMessage "Updated item with Asset tag # '$indexValue' and Serial Number '$csvSN'" "INFO"
                            Write-LogMessage "Updated Item ID: $($item.Id)" "DEBUG"
                            Write-LogMessage "Updated Item GUID: $($item.FieldValues.UniqueId)" "DEBUG"
                        } else {
                            $errorMessage = $_.Exception.Message
                            Write-LogMessage "Failed to update item with Asset tag # '$indexValue' and Serial Number '$csvSN'. Error: $errorMessage" "ERROR"
                        }
                    } else {
                        Write-LogMessage "No changes detected for item with Asset tag # '$indexValue' and Serial Number '$csvSN'" "INFO"
                    }
                }
            }
        } catch {
            Write-LogMessage "Error processing row with Asset tag # '$indexValue' and Serial Number '$csvSN'. Error: $_" "ERROR"
        }
    }

    Write-LogMessage "Finished processing CSV data"
    Disconnect-PnPOnline
} catch {
    # Log the error message
    Write-ErrorLog "Error: Unhandled exception occurred." $_
    Disconnect-PnPOnline
    # Display the error message in a message box (if needed)
    [System.Windows.Forms.MessageBox]::Show("An unhandled exception occurred: $($_.Exception.Message)")
}
