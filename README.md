# PSModuleUpdater 🚀

This PowerShell script checks your installed modules (those installed via `Install-Module`) against the official PowerShell Gallery (PSGallery) to identify available updates. It then provides an option to update the outdated modules automatically.

## ✨ Features

* **Comprehensive Check:** Retrieves all modules installed using `PowerShellGet`.
* **Version Comparison:** Compares the installed version of each module against the latest *stable* version available in the PSGallery. Uses proper `[version]` casting for accurate comparison (e.g., understands `1.10.0` is newer than `1.9.0`).
* **Clear Summary:** Displays a table showing each module's name, installed version, latest available version, and update status (`Up-to-date`, `Update Available`, `Installed Newer/Different`, `Not Found in Gallery`, `Error Checking`).
* **Targeted Updates:** Identifies modules specifically marked as "Update Available".
* **User Confirmation:** If updates are available, it lists the specific modules and prompts the user (Y/N) before proceeding with any updates.
* **Automated Update (Optional):** If confirmed, it attempts to update only the necessary modules using `Update-Module -Force` to prevent further prompts and handle modules currently in use.
* **Progress Indicator:** Shows a progress bar `[████     ]` while checking modules against the gallery.
* **Error Handling:** Includes basic error handling for gallery lookups and individual module update attempts.

## ⚙️ Requirements

1.  **PowerShell:** Version 5.1 or later (required for `PowerShellGet`).
2.  **PowerShellGet Module:** This module provides the necessary `Get-InstalledModule`, `Find-Module`, and `Update-Module` cmdlets. It's typically included in modern Windows versions (Windows 10/11) and PowerShell 6+.
    * You can ensure you have the latest version by running (as Administrator): `Install-Module PowerShellGet -Force`
3.  **Internet Connection:** 🌐 Required to query the PowerShell Gallery.
4.  **Administrator Privileges:** 🛡️ **Highly recommended** to run the script as Administrator. This ensures the script can:
    * See modules installed for `AllUsers`.
    * Have the necessary permissions to update modules, especially those installed system-wide.

## ▶️ How to Use

1.  **Save the Script:** Save the PowerShell script code to a file, for example, `Check-AndUpdateModules.ps1`. 💾
2.  **Open PowerShell as Administrator:**
    * Right-click the PowerShell icon.
    * Select "Run as administrator".
3.  **Navigate to the Script Directory:** Use the `cd` command to change to the directory where you saved the script file.
    ```powershell
    cd C:\path\to\your\scripts
    ```
4.  **Run the Script:** Execute the script.
    ```powershell
    .\Check-AndUpdateModules.ps1
    ```
5.  **Review Output:** The script will first display a table comparing all your installed modules to the gallery versions. 📊
6.  **Confirm Updates (if applicable):** If modules with available updates are found, they will be listed separately, and you will be prompted `(Y/N)` to proceed with updating them.
    * Enter `Y` to attempt the updates. ✅
    * Enter `N` (or anything else) to skip the update process. ❌

## 📋 Output Explanation

The main output table includes these columns:

* **ModuleName:** The name of the installed module.
* **InstalledVersion:** The version currently installed on your system.
* **LatestVersion:** The latest stable version found in the PSGallery.
* **Status:**
    * `Update Available`: ⬆️ A newer stable version exists in the gallery.
    * `Up-to-date`: ✔️ The installed version matches the latest stable gallery version.
    * `Installed Newer/Different`: 🤔 The installed version is newer than the latest stable version in the gallery (could be a pre-release or from a different source).
    * `Not Found in Gallery`: ❓ The module (by that name) couldn't be found in the PSGallery.
    * `Error Checking`: ❗ An error occurred trying to query the gallery for this module (e.g., network issue).
* **InstalledPath:** The directory where the module is installed.

If updates are performed, the script will indicate success or failure for each module update attempt.

## ⚠️ Notes & Caveats

* **Performance:** Checking each module against the online gallery can take time ⏳, especially if you have many modules installed.
* **Scope:** The script checks and updates modules installed via `Install-Module` and queries the official `PSGallery`. It doesn't manage modules installed manually or via other methods.
* **Pre-release Versions:** The script specifically looks for the latest *stable* version in the gallery (`Find-Module` default behavior). It won't prompt you to update to a pre-release version unless your installed version is older than the *latest stable* version.
* **Update Failures:** Individual module updates might fail due to various reasons (permissions, network issues, conflicts). The script attempts to report these errors but will continue trying to update other modules in the list.


