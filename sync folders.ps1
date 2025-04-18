

####### Sync files and folders from multiple sources to multiple destinations  ##############


$syncList = @(
    @{ Source = "C:\Users\Spartacus\Desktop\CravingsApp\"; Destination = "D:\PROJECTS\CravingsApp\" },
    @{ Source = "C:\Users\Spartacus\Desktop\"; Destination = "D:\DESKTOP Backup\" }
)


#######################      END     ################################


function Get-Hash($Path) {
    try {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    } catch {
        return ""
    }
}

foreach ($item in $syncList) {
    $src = $item.Source
    $dst = $item.Destination

    if (Test-Path $src -PathType Container) {
        # Sync folders (copy new/updated files only)
        Get-ChildItem -Recurse $src | ForEach-Object {
            $relativePath = $_.FullName.Substring($src.Length)
            $targetPath = Join-Path $dst $relativePath
            if (!(Test-Path $targetPath) -or (Get-Hash $_.FullName) -ne (Get-Hash $targetPath)) {
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

        if (!(Test-Path $dstFile) -or (Get-Hash $src) -ne (Get-Hash $dstFile)) {
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            Copy-Item $src -Destination $dstFile -Force
            Write-Host "📄 Synced file: $src → $dstFile"
        }
    }
    else {
        Write-Warning "⚠️ Source not found: $src"
    }
}

# Pause to keep window open
Write-Host "`n⏳ Press any key to exit..."
[void][System.Console]::ReadKey($true)
