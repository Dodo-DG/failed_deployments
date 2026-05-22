<#
.SYNOPSIS
Finds machines where an SEB config deployment did not succeed.

.DESCRIPTION
Compares the full list of expected machine names with the machine names found in
the deployment success output folder.

By default, the script assumes each successful machine is represented by a .txt
file named after the machine, for example:

    CLUSTER-PC-01.txt
    CLUSTER-PC-02.txt

If your .txt files contain machine names inside the files instead, run with:

    -SuccessSource Content

.PARAMETER ExpectedMachinesFile
Path to a text file containing all machines that should receive the deployment.
Use one machine name per line.

.PARAMETER SuccessFolder
Path to the folder containing the successful deployment .txt files.

.PARAMETER SuccessSource
Use FileName when successful machines are represented by .txt filenames.
Use Content when successful machines are listed inside the .txt files.

.PARAMETER OutputFile
Optional path where the failed machine names should be written.

.PARAMETER SebConfigName
Optional room or SEB configuration description to include in the deployment
summary.

.EXAMPLE
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile .\Room101-Machines.txt -SuccessFolder .\SuccessfulDeployments

.EXAMPLE
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile .\Room101-Machines.txt -SuccessFolder .\SuccessfulDeployments -OutputFile .\FailedDeployments.txt

.EXAMPLE
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile .\Room101-Machines.txt -SuccessFolder .\SuccessfulDeployments -SuccessSource Content

.EXAMPLE
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile .\Room101-Machines.txt -SuccessFolder .\SuccessfulDeployments -SebConfigName "Room 101 - Maths SEB Config"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ExpectedMachinesFile,

    [Parameter()]
    [string]$SuccessFolder,

    [ValidateSet('FileName', 'Content')]
    [string]$SuccessSource = 'FileName',

    [string]$OutputFile,

    [string]$SebConfigName,

    [string]$PasswordFile
)

if ([string]::IsNullOrWhiteSpace($ExpectedMachinesFile)) {
    $ExpectedMachinesFile = Read-Host 'Enter path to the full machine list .txt file'
}

if ([string]::IsNullOrWhiteSpace($SuccessFolder)) {
    $SuccessFolder = Read-Host 'Enter path to the folder containing successful deployment .txt files'
}

if ([string]::IsNullOrWhiteSpace($SebConfigName)) {
    $SebConfigName = Read-Host 'Enter SEB configuration name or room information (optional)'
}

$ExpectedMachinesFile = $ExpectedMachinesFile.Trim().Trim('"').Trim("'")
$SuccessFolder = $SuccessFolder.Trim().Trim('"').Trim("'")
$SebConfigName = $SebConfigName.Trim().Trim('"').Trim("'")

# Handle optional password file containing the SEB password
if ([string]::IsNullOrWhiteSpace($PasswordFile)) {
    $PasswordFile = Read-Host 'Enter path to the .txt file containing the SEB password (optional)'
}

$PasswordFile = $PasswordFile.Trim().Trim('"').Trim("'")

$SebPassword = 'Not specified'
if (-not [string]::IsNullOrWhiteSpace($PasswordFile)) {
    if (-not (Test-Path $PasswordFile -PathType Leaf)) {
        throw "Password file was not found: $PasswordFile"
    }

    try {
        $SebPassword = (Get-Content -Path $PasswordFile -Raw).Trim()
    }
    catch {
        throw "Failed to read password file: $PasswordFile - $($_.Exception.Message)"
    }
}

if ([string]::IsNullOrWhiteSpace($SebConfigName)) {
    $SebConfigName = 'Not specified'
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
Write-Host "SEB config / room:   $SebConfigName"
Write-Host "SEB password:        $SebPassword"
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
