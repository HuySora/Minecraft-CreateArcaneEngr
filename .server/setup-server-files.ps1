if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"  `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}

# Push location to the current script directory
Push-Location $PSScriptRoot

# Source directory and target link directory for each folder
$folders = @{
    "config" = @{
        "source" = "..\config"
        "ignoreNames" = @() # Add file or folder names to ignore
    }
    "defaultconfigs" = @{
        "source" = "..\defaultconfigs"
        "ignoreNames" = @()
    }
    "kubejs" = @{
        "source" = "..\kubejs"
        "ignoreNames" = @()
    }
    "libraries" = @{
        "source" = "..\..\libraries"
        "target" = "libraries"
        "ignoreNames" = @()
        "link" = $true
    }
    "mods" = @{
        "source" = "..\mods"
        "ignoreNames" = @(
            "auudio_forge_1.0.3_MC_1.18-1.18.2.jar",
            "do-a-barrel-roll-2.5.3+1.18.2-forge.jar",
            "drippyloadingscreen_forge_2.2.2_MC_1.18.2.jar",
            "effective_fg-1.2.4.jar",
            "extremesoundmuffler-3.30_forge-1.18.2.jar",
            "fancymenu_forge_2.14.9_MC_1.18.2.jar",
            "fancymenu_video_extension_forge_1.1.1_MC_1.18.2.jar",
            "FancyVideo-API-forge-2.2.0.0.jar",
            "fm_audio_extension_forge_1.1.1_MC_1.18-1.18.2.jar",
            "FpsReducer2-forge-1.18.2-2.0.jar",
            "LegendaryTooltips-1.18.2-1.3.1.jar",
            "MouseTweaks-forge-mc1.18-2.21.jar",
            "oculus-flywheel-compat-1.18.2-0.2.1.jar",
            "oculus-mc1.18.2-1.6.4.jar",
            "rubidium_extras-1.18.2_v1.3.2.jar",
            "rubidium-0.5.6.jar",
            "simple-rpc-1.18.2-3.2.4.jar"
        )
    }
    "multiblocked" = @{
        "source" = "..\multiblocked"
        "ignoreNames" = @()
    }
}

# Function to copy files from source to target directory
function Copy-Files {
    param(
        [string]$sourceDirectory,
        [string]$targetDirectory,
        [string[]]$ignoreNames
    )

    # Get files and folders in the source directory
    $items = Get-ChildItem -Path $sourceDirectory

    # Loop through each item and copy it to the target directory
    foreach ($item in $items) {
        # Check if item is not in the ignore list
        if ($ignoreNames -notcontains $item.Name) {
            # Check if item is a directory or file
            if ($item.PSIsContainer) {
                # Copy directory to target directory
                Write-Host "Copying directory: Copy-Item -Path `"$($item.FullName)`" -Destination `"$targetDirectory\$($item.Name)`" -Recurse -Force"
                $src = [Management.Automation.WildcardPattern]::Escape($item.FullName)
                $dest = [Management.Automation.WildcardPattern]::Escape("$targetDirectory\$($item.Name)")
                Copy-Item -Path $src -Destination $dest -Recurse -Force
            } else {
                # Copy file to target directory
                Write-Host "Copying file: Copy-Item -Path `"$($item.FullName)`" -Destination `"$targetDirectory`" -Force"
                $src = [Management.Automation.WildcardPattern]::Escape($item.FullName)
                $dest = [Management.Automation.WildcardPattern]::Escape($targetDirectory)
                Copy-Item -Path $src -Destination $dest -Force
            }
        }
    }
}

# Loop through each folder and create symbolic links or copy files
foreach ($folderName in $folders.Keys) {
    $folder = $folders[$folderName]
    $sourceDirectory = $folder["source"]
    $targetDirectory = $folderName
    $ignoreNames = $folder["ignoreNames"]

    # Remove previous symbolic link and folder if they exist
    if (Test-Path -Path $targetDirectory) {
        Write-Host "Removing previous symbolic link and folder: rmdir `"$targetDirectory`" /s /q"
        git rm --cached -r "$targetDirectory"
        # Check if item is a directory or file
        if (Test-Path -Path $targetDirectory -PathType Container) {
            cmd /c rmdir "$targetDirectory" /s /q
        } else {
            cmd /c del "$targetDirectory" /q
        }
    }

    # Check if symbolic link should be created
    if ($folder["link"]) {
        # Create symbolic link for directory
        Write-Host "Creating symbolic link for folder: mklink /D `"$targetDirectory`" `"$sourceDirectory`""
        cmd /c mklink /D "$targetDirectory" "$sourceDirectory"
        git reset HEAD -- "$targetDirectory"
    } else {
        # Create new target directory
        Write-Host "Creating target directory: New-Item -Path `"$targetDirectory`" -ItemType Directory"
        New-Item -Path $targetDirectory -ItemType Directory | Out-Null
        # Copy files from source to target directory
        Write-Host "Copying files to target directory..."
        Copy-Files -sourceDirectory $sourceDirectory -targetDirectory $targetDirectory -ignoreNames $ignoreNames
    }
}

# Pop back to the previous location
Pop-Location

pause
