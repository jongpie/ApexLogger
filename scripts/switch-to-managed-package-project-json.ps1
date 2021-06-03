# There are 2 versions of sfdx-project.json - 1 for the unlocked package and 1 for the managed package
# This script handles switching to the managed package's version of the file

$rootProject = "./sfdx-project.json"
$unlockedProject = "./unlocked-sfdx-project.json"
$managedProject = "./packages/managed-package/sfdx-project.json"

Write-Output "Switching to managed package's version of sfdx-project.json"
Write-Output "Copying $rootProject to $unlockedProject"
Copy-Item -Path $rootProject -Destination $unlockedProject -Force
Write-Output "Ovewriting $rootProject with $managedProject"
Copy-Item -Path $managedProject -Destination $rootProject -Force