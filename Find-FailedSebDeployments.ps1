<#
.SYNOPSIS
Finds machines where an SEB config deployment did not succeed.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ExpectedMachinesFile,

    [Parameter()]
    [string]$SuccessFolder,

    [ValidateSet('FileName', 'Content')]
    [string]$SuccessSource = 'FileName',

    [string]$OutputFile
)

if ([string]::IsNullOrWhiteSpace($ExpectedMachinesFile)) {
    $ExpectedMachinesFile = Read-Host 'Enter path to the full machine list .txt file'
}

if ([string]::IsNullOrWhiteSpace($SuccessFolder)) {
    $SuccessFolder = Read-Host 'Enter path to the folder containing successful deployment .txt files'
}

if (-not (Test-Path $ExpectedMachinesFile -PathType Leaf)) {
    throw "Expected machine list file was not found: $ExpectedMachinesFile"
}

if (-not (Test-Path $SuccessFolder -PathType Container)) {
    throw "Success folder was not found: $SuccessFolder"
}

function Get-NormalizedMachineNames {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string[]]$Name
    )

    process {
        foreach ($item in $Name) {
            $normalized = $item.Trim()

            if ([string]::IsNullOrWhiteSpace($normalized)) {
                continue
            }

            if ($normalized.StartsWith('#')) {
                continue
            }

            $normalized.ToUpperInvariant()
        }
    }
}

$expectedMachines = Get-Content -Path $ExpectedMachinesFile |
    Get-NormalizedMachineNames |
    Sort-Object -Unique

if ($expectedMachines.Count -eq 0) {
    throw "No machine names were found in '$ExpectedMachinesFile'."
}

if ($SuccessSource -eq 'FileName') {
    $successfulMachines = Get-ChildItem -Path $SuccessFolder -Filter '*.txt' -File |
        ForEach-Object { $_.BaseName } |
        Get-NormalizedMachineNames |
        Sort-Object -Unique
}
else {
    $successfulMachines = Get-ChildItem -Path $SuccessFolder -Filter '*.txt' -File |
        ForEach-Object { Get-Content -Path $_.FullName } |
        Get-NormalizedMachineNames |
        Sort-Object -Unique
}

$successfulLookup = @{}
foreach ($machine in $successfulMachines) {
    $successfulLookup[$machine] = $true
}

$failedMachines = foreach ($machine in $expectedMachines) {
    if (-not $successfulLookup.ContainsKey($machine)) {
        $machine
    }
}

Write-Host ''
Write-Host 'SEB deployment check'
Write-Host '--------------------'
Write-Host "Expected machines:   $($expectedMachines.Count)"
Write-Host "Successful machines: $($successfulMachines.Count)"
Write-Host "Failed machines:     $($failedMachines.Count)"
Write-Host ''

if ($failedMachines.Count -eq 0) {
    Write-Host 'All machines deployed successfully.'
}
else {
    Write-Host 'Machines where deployment was NOT successful:'
    $failedMachines | ForEach-Object { Write-Host " - $_" }
}

if ($OutputFile) {
    $failedMachines | Set-Content -Path $OutputFile
    Write-Host ''
    Write-Host "Failed machine list written to: $OutputFile"
}