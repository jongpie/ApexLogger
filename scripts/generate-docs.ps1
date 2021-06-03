# This script is used to generate the markdown files used by Github pages
npx apexdocs-generate --configPath config/apexdocs.json --scope global public --sourceDir nebula-logger/main --targetDir docs

# Make a few adjustments to the generated markdown files so that they work correctly in Github Pages
$indexPageFile = "docs/index.md"
Write-Output "Processing file: $indexPageFile"
(Get-Content -path $indexPageFile -Raw) -replace ".md","" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Logger-Engine/","logger-engine/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Log-Management/","log-management/" | Set-Content -Path $indexPageFile -NoNewline

$docsSubdirectories = "docs/*/*.*"
foreach($file in Get-ChildItem $docsSubdirectories) {
    Write-Output "Processing file: $file"
    (Get-Content -path $file -Raw) -replace ".md","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "/Logger-Engine/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "/Log-Management/","" | Set-Content -Path $file -NoNewline
}

prettier ./docs --write
