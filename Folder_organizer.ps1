$rootPath = "" # The root path where your folders and files are located. Insert directory in the quotes
$duplicatesPath = Join-Path -Path $rootPath -ChildPath "Duplicates" # Path for duplicate files

# Function to delete empty directories
function Remove-EmptyDirectories {
    param (
        [Parameter(Mandatory=$true)]
        [string]$path
    )

    Get-ChildItem -Path $path -Directory | ForEach-Object {
        Remove-EmptyDirectories -path $_.FullName
        if (-not (Get-ChildItem -Path $_.FullName)) {
            Remove-Item $_.FullName
            Write-Host "Removed empty directory: $($_.FullName)"
        }
    }
}

Get-ChildItem -Path $rootPath -Recurse -File | ForEach-Object {
    $file = $_
    $extension = $file.Extension
    $extensionFolder = if ($extension) { $extension.TrimStart('.') } else { 'NoExtension' }
    $destinationFolder = Join-Path -Path $rootPath -ChildPath $extensionFolder

    # Skip if the file is already in its proper extension folder
    if ($file.DirectoryName -ne $destinationFolder) {
        # Create a directory for the extension if it doesn't exist
        if (-not (Test-Path -Path $destinationFolder)) {
            New-Item -ItemType Directory -Path $destinationFolder
        }

        # Move the file to the directory
        $destinationPath = Join-Path -Path $destinationFolder -ChildPath $file.Name
        if (Test-Path -Path $destinationPath) {
            # Handle duplicates
            $duplicatesExtensionPath = Join-Path -Path $duplicatesPath -ChildPath $extensionFolder
            if (-not (Test-Path -Path $duplicatesExtensionPath)) {
                New-Item -ItemType Directory -Path $duplicatesExtensionPath
            }

            $duplicateDestinationPath = Join-Path -Path $duplicatesExtensionPath -ChildPath $file.Name
            if (Test-Path -Path $duplicateDestinationPath) {
                # If the file already exists, append a timestamp to its name
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                $newName = "${baseName}_$(Get-Date -Format "yyyyMMddHHmmss")$($file.Extension)"
                $duplicateDestinationPath = Join-Path -Path $duplicatesExtensionPath -ChildPath $newName
            }
            Move-Item -Path $file.FullName -Destination $duplicateDestinationPath
            Write-Host "Moved duplicate file: $($file.Name) to $duplicatesExtensionPath"
        } else {
            Move-Item -Path $file.FullName -Destination $destinationFolder
            Write-Host "Moved file: $($file.Name) to $extensionFolder"
        }
    }
}

# Remove any empty directories in the root path
Remove-EmptyDirectories -path $rootPath

Write-Host "File organization complete. Empty directories have been removed."
