# This is used to circumvent the daily scratch org limits of 6 in dev orgs
# To avoid this limitation, the script checks several dev hubs until it finds one that has an allotment of 1+ scratch org
# This script assumes that the dev hubs have already been authorized locally
param ([string[]]$devHubs, [string]$definitionFile, [int]$durationdays)

Write-Output "Starting scratch org creation script"

if ($devHubs -ne $null) {
    # Make sure the variable is treated as an array, not a single string
    $devHubs = $devHubs -split ","
} else {
    # Otherwise, get the configured default dev hub if no devHubs have been specified via parameter
    Write-Output "No dev hubs specified, checking for default dev hub instead"

    $defaultDevHub = (sfdx config:get defaultdevhubusername  --json | ConvertFrom-Json).result.value
    Write-Output "Default Dev Hub: $defaultDevHub"

    [string[]]$devHubs = $defaultDevHub
}

# Set a default duration in days if none is specified
if ($durationdays -eq $null -Or $durationdays -eq 0) {
    $durationdays = 7
}

Write-Output "List of possible dev hubs: $devHubs"
Write-Output "Using scratch org definition file: $definitionFile"
Write-Output "Scratch org duration in days: $durationdays"

foreach($devHub in $devHubs) {
    Write-Output "Trying dev hub: $devHub"
    $scratchOrgAllotment = ((sfdx force:limits:api:display --json --targetusername $devHub | ConvertFrom-Json).result | Where-Object -Property name -eq "DailyScratchOrgs").remaining
    Write-Output "Total remaining scratch orgs for the day for $devHub : $scratchOrgAllotment"

    if($scratchOrgAllotment -gt 0) {
        Write-Output "Beginning scratch org creation"
        # Create Scratch Org
        try {
            $scratchOrgCreateMessage = sfdx force:org:create --setdefaultusername --targetdevhubusername $devHub --durationdays $durationdays --definitionfile $definitionFile --wait 10
            # Sometimes SFDX lies (UTC date problem?) about the number of scratch orgs remaining in a given day
            # The other issue is that this doesn't throw, so we have to test the response message ourselves
            Write-Output "Scratch org creation mesage: $scratchOrgCreateMessage"
            if($scratchOrgCreateMessage -eq 'The signup request failed because this organization has reached its active scratch org limit') {
                throw $1
            }

            $defaultUsername = (sfdx config:get defaultusername  --json | ConvertFrom-Json).result.value
            if ($defaultUsername -ne $null) {
                Write-Output "Scratch org created in dev hub $devHub, default username is: $defaultUsername"
                break
            }
        } catch {
            Write-Output "There was an issue with scratch org creation, continuing ..."
        }
    }
}

$defaultUsername = (sfdx config:get defaultusername  --json | ConvertFrom-Json).result.value
if ($defaultUsername -eq $null) {
    throw "Scratch org creation failed"
}
