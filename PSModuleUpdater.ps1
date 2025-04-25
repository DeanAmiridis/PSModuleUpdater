<#
.SYNOPSIS
Checks installed PowerShell modules against the PowerShell Gallery for available updates,
displays the comparison, and optionally updates modules flagged as needing an update
after user confirmation. Handles publisher check failures by offering a retry option.

.DESCRIPTION
This script performs the following actions:
1. Retrieves all modules installed via PowerShellGet.
2. For each module, queries the PowerShell Gallery for the latest stable version.
3. Compares the installed version with the latest available version.
4. Displays a table summarizing the comparison results.
5. Identifies modules where an update is available.
6. If updates are available, lists those modules and prompts the user for confirmation (Y/N).
7. If confirmed, attempts to update each identified module using Update-Module -Force.
8. If an update fails specifically due to a publisher check, it tracks that module.
9. After the initial update attempt, if any modules failed the publisher check, it lists them
   and prompts the user (Y/N) again to retry *those specific modules* using -SkipPublisherCheck.
10. Reports success or failure for all update attempts.

.NOTES
- Requires the PowerShellGet module.
- Run PowerShell as Administrator for best results.
- Checking many modules against the online gallery can take time.
- Uses the official 'PSGallery' repository.
- Current Date for context: Friday, April 25, 2025.

.EXAMPLE
.\PSModuleUpdater.ps1
#>

# --- Section 1: Check Installed Modules vs Gallery ---

# Get all modules installed via PowerShellGet
Write-Host "Gathering installed modules..." -ForegroundColor Cyan
$installedModules = Get-InstalledModule -ErrorAction SilentlyContinue

if (-not $installedModules) {
    Write-Warning "No modules found that were installed via Install-Module, or Get-InstalledModule failed."
    exit
}

Write-Host "Found $($installedModules.Count) installed modules. Checking against PowerShell Gallery..." -ForegroundColor Cyan

# Array to hold the comparison results
$comparisonResults = @()
$i = 0 # Counter for progress

# Loop through each installed module
foreach ($module in $installedModules) {
    $i++
    $moduleName = $module.Name
    $installedVersionStr = $module.Version
    $latestVersionStr = "N/A" # Default if not found or error
    $status = "Unknown"

    # Display progress
    Write-Progress -Activity "Checking PowerShell Gallery" -Status "Checking '$($moduleName)' ($($i)/$($installedModules.Count))" -PercentComplete (($i / $installedModules.Count) * 100)

    try {
        # Query the PowerShell Gallery for the latest STABLE version of the module
        $latestModuleInfo = Find-Module -Name $moduleName -Repository PSGallery -ErrorAction Stop | Select-Object -First 1

        if ($null -ne $latestModuleInfo) {
            $latestVersionStr = $latestModuleInfo.Version

            # Compare versions using [version] type casting
            if ([version]$installedVersionStr -lt [version]$latestVersionStr) {
                $status = "Update Available"
            } elseif ([version]$installedVersionStr -eq [version]$latestVersionStr) {
                $status = "Up-to-date"
            } else {
                 $status = "Installed Newer/Different"
            }
        } else {
             $status = "Not Found in Gallery"
             $latestVersionStr = "Not Found"
        }

    } catch {
        # Catch errors from Find-Module
        $status = "Error/Not Found in Gallery"
        $latestVersionStr = "Error Checking"
        # Write-Warning "Could not check module '$($moduleName)'. Error: $($_.Exception.Message)" # Uncomment for detailed errors
    }

    # Add the comparison details to our results array
    $comparisonResults += [PSCustomObject]@{
        ModuleName        = $moduleName
        InstalledVersion  = $installedVersionStr
        LatestVersion     = $latestVersionStr
        Status            = $status
        InstalledPath     = $module.InstalledLocation
    }
}

# Complete the progress bar
Write-Progress -Activity "Checking PowerShell Gallery" -Completed

# Display the full comparison results
Write-Host "`nModule Version Comparison Results:" -ForegroundColor Cyan
if ($comparisonResults.Count -gt 0) {
    $comparisonResults | Format-Table -AutoSize
} else {
    Write-Host "No comparison results generated."
    exit # Exit if nothing to process further
}

# --- Section 2: Identify Updates and Prompt User ---

# Filter for modules needing updates
$modulesToUpdate = $comparisonResults | Where-Object { $_.Status -eq "Update Available" }

# Check if any modules were found needing updates
if ($modulesToUpdate.Count -gt 0) {
    Write-Host "`nModules with available updates found:" -ForegroundColor Yellow
    # Display only the modules that need updating
    $modulesToUpdate | Select-Object ModuleName, InstalledVersion, LatestVersion | Format-Table -AutoSize

    # Prompt user for confirmation to update these specific modules
    $prompt = Read-Host "Do you want to attempt updating these $($modulesToUpdate.Count) module(s) now? (Requires Administrator privileges) (Y/N)"

    # --- Section 3: Perform Initial Updates if Confirmed ---
    if ($prompt -eq 'Y' -or $prompt -eq 'y') {
        Write-Host "`nStarting initial module updates (using Update-Module -Force)..." -ForegroundColor Green

        # Initialize list to track modules failing publisher check
        $failedPublisherCheckModules = @()

        foreach ($moduleInfo in $modulesToUpdate) {
            Write-Host "--> Attempting to update '$($moduleInfo.ModuleName)' from $($moduleInfo.InstalledVersion) to $($moduleInfo.LatestVersion)..."
            try {
                # Update the specific module, use -Force to avoid further prompts/issues and handle loaded modules
                 Update-Module -Name $moduleInfo.ModuleName -Force -ErrorAction Stop
                 Write-Host "    Successfully updated '$($moduleInfo.ModuleName)'." -ForegroundColor Green
            } catch {
                # Check if the error was specifically a Publisher Check failure
                # The FullyQualifiedErrorId is often 'Modules_PublisherVerificationFailed' or similar
                # Checking the exception message text provides broader compatibility but might be less precise
                if ($_.Exception.Message -like "*publisher check failed*" -or $_.FullyQualifiedErrorId -eq 'Modules_PublisherVerificationFailed') {
                    Write-Warning "    Update failed for '$($moduleInfo.ModuleName)' due to Publisher Check failure. Will prompt later to retry."
                    # Add to the list for potential retry
                    $failedPublisherCheckModules += $moduleInfo
                } else {
                    # Report other errors if the update fails
                    Write-Warning "    Failed to update '$($moduleInfo.ModuleName)'. Error: $($_.Exception.Message)"
                }
            }
        }
        Write-Host "`nInitial module update attempt finished." -ForegroundColor Cyan

        # --- Section 4: Handle Publisher Check Failures ---
        if ($failedPublisherCheckModules.Count -gt 0) {
            Write-Host "`nThe following modules failed the initial update due to a publisher check:" -ForegroundColor Yellow
            $failedPublisherCheckModules | Select-Object ModuleName, InstalledVersion, LatestVersion | Format-Table -AutoSize

            $retryPrompt = Read-Host "Do you want to retry updating these $($failedPublisherCheckModules.Count) module(s) by skipping the publisher check? (Y/N)"

            if ($retryPrompt -eq 'Y' -or $retryPrompt -eq 'y') {
                 Write-Host "`nRetrying updates with -SkipPublisherCheck..." -ForegroundColor Green
                 foreach ($moduleInfoRetry in $failedPublisherCheckModules) {
                     Write-Host "--> Retrying update for '$($moduleInfoRetry.ModuleName)' (skipping publisher check)..."
                     try {
                          Update-Module -Name $moduleInfoRetry.ModuleName -Force -SkipPublisherCheck -ErrorAction Stop
                          Write-Host "    Successfully updated '$($moduleInfoRetry.ModuleName)' on retry." -ForegroundColor Green
                     } catch {
                          Write-Warning "    Retry failed for '$($moduleInfoRetry.ModuleName)'. Error: $($_.Exception.Message)"
                     }
                 }
                 Write-Host "`nRetry update process finished." -ForegroundColor Cyan
            } else {
                 Write-Host "`nRetry update process skipped by user." -ForegroundColor Yellow
            }
        }

    } else {
        # User chose not to update initially
        Write-Host "`nUpdate process skipped by user." -ForegroundColor Yellow
    }
} else {
    # No modules found with status "Update Available"
    Write-Host "`nAll checked modules appear to be up-to-date or no applicable updates were found." -ForegroundColor Green
}

Write-Host "`nScript finished." -ForegroundColor Cyan
