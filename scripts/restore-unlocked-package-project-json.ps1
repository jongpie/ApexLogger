# There are 2 versions of sfdx-project.json - 1 for the unlocked package and 1 for the managed package
# This script handles switching to the managed package's version of the file

$rootProject = "./sfdx-project.json"
$unlockedProject = "./unlocked-sfdx-project.json"
$managedProject = "./packages/managed-package/sfdx-project.json"

Write-Output "Restoring unlocked package's version of sfdx-project.json"
Write-Output "Copying $rootProject to $managedProject"
Copy-Item -Path $rootProject -Destination $managedProject -Force
Write-Output "Ovewriting $rootProject with $unlockedProject"
Copy-Item -Path $unlockedProject -Destination $rootProject -Force
Remove-Item -Path $unlockedProject