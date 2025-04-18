####### Sync files and folders from multiple sources to multiple destinations ##############

$syncList = @(
    @{ Source = "C:\Users\Spartacus\Desktop\CravingsApp"; Destination = "D:\PROJECTS\CravingsApp" },
    @{ Source = "C:\Users\Spartacus\Desktop\CravingsApp\SETUP"; Destination = "D:\PROJECTS\SETUP" },
    @{ Source = "C:\Users\Spartacus\Desktop"; Destination = "D:\DESKTOP Backup" }
)

#######################      END     ################################

function Get-Hash($Path) {
    try {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    } catch {
        Write-Warning "⚠️ Skipping inaccessible file: $Path"
        return $null
    }
}

foreach ($item in $syncList) {
    $src = $item.Source.TrimEnd('\')
    $dst = $item.Destination.TrimEnd('\')

    if (Test-Path $src -PathType Container) {
        # Sync folders (copy new/updated files only)
        Get-ChildItem -Recurse $src -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($src.Length)
            $targetPath = Join-Path $dst $relativePath

            $srcHash = Get-Hash $_.FullName
            $dstHash = if (Test-Path $targetPath) { Get-Hash $targetPath } else { $null }

            if ($srcHash -ne $dstHash) {
                New-Item -ItemType Directory -Path (Split-Path $targetPath) -Force | Out-Null
                Copy-Item $_.FullName -Destination $targetPath -Force
                Write-Host "📂 Synced: $($_.FullName) → $targetPath"
            }
        }
    }
    elseif (Test-Path $src -PathType Leaf) {
        # Sync individual file
        $fileName = Split-Path $src -Leaf
        $dstFile = Join-Path $dst $fileName

        $srcHash = Get-Hash $src
        $dstHash = if (Test-Path $dstFile) { Get-Hash $dstFile } else { $null }

        if ($srcHash -ne $dstHash) {
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            Copy-Item $src -Destination $dstFile -Force
            Write-Host "📄 Synced file: $src → $dstFile"
        }
    }
    else {
        Write-Warning "⚠️ Source not found: $src"
    }
}

