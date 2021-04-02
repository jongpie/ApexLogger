
# This is also the same script that runs on Github via the Github Action configured in .github/workflows - there, the
# DEVHUB_SFDX_URL.txt file is populated in a build step
$testInvocation = 'sfdx force:apex:test:run --testlevel RunLocalTests --codecoverage --outputdir ./tests/apex --resultformat human --wait 45'

function Start-Tests() {
    # Run tests
    Write-Output "Starting test run ..."
    Invoke-Expression $testInvocation
}

# function Reset-SFDX-Json() {
#   Write-Output "Resetting SFDX project JSON at project root"
#   Copy-Item -Path ./scripts/sfdx-project.json -Destination ./sfdx-project.json -Force
#   Remove-Item -Path ./scripts/sfdx-project.json
# }

Write-Output "Starting build script"

$orgInfo = sfdx force:org:display --json --verbose | ConvertFrom-Json
$userNameHasBeenSet = $false
if(Test-Path ".\DEVHUB_SFDX_URL.txt") {
    Write-Output "Auth file already exists, continuing"
} else {
    $orgInfo.result.sfdxAuthUrl | Out-File -FilePath ".\DEVHUB_SFDX_URL.txt"
}

# TODO remove, or possible use similar apporach for managed package stff
# Write-Output "Copying deploy SFDX project json file to root directory, storing backup in /scripts"
# Copy-Item -Path ./sfdx-project.json -Destination ./scripts/sfdx-project.json
# Copy-Item -Path ./scripts/deploy-sfdx-project.json -Destination ./sfdx-project.json -Force

# Authorize Dev Hub using prior creds. There's some issue with the flags --setdefaultdevhubusername and --setdefaultusername both being passed when run remotely

sfdx auth:sfdxurl:store --sfdxurlfile ./DEVHUB_SFDX_URL.txt --setalias nebula-logger --setdefaultdevhubusername --setdefaultusername

# For local dev, store currently auth'd org to return to
# Also store test command shared between script branches, below
$scratchOrgAllotment = ((sfdx force:limits:api:display --json | ConvertFrom-Json).result | Where-Object -Property name -eq "DailyScratchOrgs").remaining

Write-Output "Total remaining scratch orgs for the day: $scratchOrgAllotment"
Write-Output "Test command to use: $testInvocation"

$shouldDeployToSandbox = $false

if($scratchOrgAllotment -gt 0) {
    Write-Output "Beginning scratch org creation"
    # Create Scratch Org
    try {
        $scratchOrgCreateMessage = sfdx force:org:create -f config/project-scratch-def.json -a nebula-logger-scratch-org -s -d 1
        # Sometimes SFDX lies (UTC date problem?) about the number of scratch orgs remaining in a given day
        # The other issue is that this doesn't throw, so we have to test the response message ourselves
        if($scratchOrgCreateMessage -eq 'The signup request failed because this organization has reached its active scratch org limit') {
            throw $1
        }
        $userNameHasBeenSet = $true
        # Deploy
        Write-Output 'Pushing source to scratch org ...'
        sfdx force:source:push
        # Run tests
        Start-Tests
        Write-Output "Scratch org tests finished running with success: $?"
        # Delete scratch org
        try {
            sfdx force:org:delete -p -u nebula-logger-scratch-org
        } catch {
            Write-Output "Scratch org deletion failed, continuing ..."
        }
    } catch {
        Write-Output "There was an issue with scratch org creation, continuing ..."
        $shouldDeployToSandbox = $true
    }
}

if($shouldDeployToSandbox) {
    Write-Output "No scratch orgs remaining, running tests on sandbox"

    try {
        # Deploy
        Write-Output "Deploying source to sandbox ..."
        sfdx force:source:deploy --sourcepath nebula-logger
        Start-Tests
    } catch {
        #Reset-SFDX-Json
        throw 'Error!'
    }
}

# If the priorUserName is not blank and we used a scratch org, reset to it
if($orgInfo.result.username -And $userNameHasBeenSet) {
    # for some reason, setting straight from $orgInfo.result.username results in some weird destructuring
    # whereas this works, no problem
    $priorUserName = $orgInfo.result.username
    Write-Output "Resetting SFDX to previously authorized org"
    sfdx force:config:set defaultusername=$priorUserName
}

#Reset-SFDX-Json

Write-Output "Build + testing finished successfully, preparing to upload code coverage"

