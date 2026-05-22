# SEB Failed Deployment Checker

This repository contains a PowerShell script that checks which machines did not
receive an SEB configuration deployment successfully.

The script is intended for rooms or clusters where another deployment process
creates `.txt` files for machines where deployment succeeded. This script
compares those successful deployment files against a full expected machine list
and reports any missing machines.

## Script

Main script:

```text
Find-FailedSebDeployments.ps1
```

## What The Script Does

The script compares two things:

1. A full list of all machines that should receive the SEB configuration.
2. A folder containing `.txt` files for machines where the deployment succeeded.

It then returns the machines that are in the full machine list but missing from
the successful deployment folder.

For example, if a room has 10 machines:

```text
PC01
PC02
PC03
PC04
PC05
PC06
PC07
PC08
PC09
PC10
```

And the successful deployment folder contains:

```text
PC01.txt
PC02.txt
PC03.txt
PC04.txt
PC05.txt
PC06.txt
PC07.txt
PC08.txt
PC09.txt
```

The script will report:

```text
PC10
```

because `PC10.txt` is missing from the successful deployment folder.

## Requirements

- Windows computer
- PowerShell
- The file `Find-FailedSebDeployments.ps1`
- A full machine list `.txt` file
- A folder containing the successful deployment `.txt` files

## Required Input Files

### 1. Full Machine List

Create a `.txt` file containing every machine that should receive the SEB
configuration.

Example file name:

```text
Room101-Machines.txt
```

Example contents:

```text
PC01
PC02
PC03
PC04
PC05
PC06
PC07
PC08
PC09
PC10
```

Use one machine name per line.

### 2. Successful Deployment Folder

This is the folder created by the SEB deployment process. It should contain
`.txt` files for machines where the deployment was successful.

Example:

```text
SuccessfulDeployments
```

Example contents:

```text
PC01.txt
PC02.txt
PC03.txt
PC04.txt
PC05.txt
PC06.txt
PC07.txt
PC08.txt
PC09.txt
```

By default, the script uses the `.txt` file names as the successful machine
names.

## How To Run The Script

1. Open PowerShell.
2. Go to the folder containing `Find-FailedSebDeployments.ps1`.

Example:

```powershell
cd "C:\Path\To\SEB FAILED DEPLOYMENTS"
```

3. Run the script:

```powershell
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile "C:\Path\To\Room101-Machines.txt" -SuccessFolder "C:\Path\To\SuccessfulDeployments" -SebConfigName "Room 101 - Maths SEB Config"
```

Replace the paths with the real paths on the computer.

## Recommended Command

Use this command when you want the failed machine list saved to a file:

```powershell
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile "C:\Path\To\Room101-Machines.txt" -SuccessFolder "C:\Path\To\SuccessfulDeployments" -SebConfigName "Room 101 - Maths SEB Config" -OutputFile "C:\Path\To\FailedDeployments.txt"
```

This creates a file called `FailedDeployments.txt` containing only the machines
where the deployment was not successful.

## Running Without Parameters

The script can also be run without parameters:

```powershell
.\Find-FailedSebDeployments.ps1
```

It will ask for:

```text
Enter path to the full machine list .txt file
Enter path to the folder containing successful deployment .txt files
Enter SEB configuration name or room information (optional)
```

When pasting paths into these prompts, paste the path without surrounding
quotes.

Example:

```text
C:\Users\Manager\Desktop\Room101-Machines.txt
```

## Example Output

```text
SEB deployment check
--------------------
SEB config / room:   Room 101 - Maths SEB Config
Expected machines:   10
Successful machines: 9
Failed machines:     1

Machines where deployment was NOT successful:
 - PC10
```

## If PowerShell Blocks The Script

If PowerShell says scripts are disabled, run this command in the same PowerShell
window:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run the script again.

This only changes the execution policy for the current PowerShell window.

## Checking Paths Before Running

If the script says it cannot find the machine list file, check the path:

```powershell
Test-Path "C:\Path\To\Room101-Machines.txt" -PathType Leaf
```

It should return:

```text
True
```

If the script says it cannot find the successful deployment folder, check the
folder path:

```powershell
Test-Path "C:\Path\To\SuccessfulDeployments" -PathType Container
```

It should return:

```text
True
```

## Common Issues

### Expected machine list file was not found

This means the `-ExpectedMachinesFile` path is wrong or points to a folder
instead of a `.txt` file.

Correct:

```powershell
-ExpectedMachinesFile "C:\Path\To\Room101-Machines.txt"
```

Incorrect:

```powershell
-ExpectedMachinesFile "C:\Path\To"
```

### Success folder was not found

This means the `-SuccessFolder` path is wrong or points to a file instead of a
folder.

Correct:

```powershell
-SuccessFolder "C:\Path\To\SuccessfulDeployments"
```

Incorrect:

```powershell
-SuccessFolder "C:\Path\To\SuccessfulDeployments\PC01.txt"
```

### Paths contain spaces

If a path contains spaces, put it inside quotes when using command-line
parameters.

Example:

```powershell
-SuccessFolder "C:\Users\Manager\Desktop\SEB Results\SuccessfulDeployments"
```

## Alternative Success File Format

By default, the script assumes successful machines are represented by file names:

```text
PC01.txt
PC02.txt
PC03.txt
```

If the `.txt` files contain machine names inside the files instead, run the
script with:

```powershell
-SuccessSource Content
```

Example:

```powershell
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile "C:\Path\To\Room101-Machines.txt" -SuccessFolder "C:\Path\To\SuccessfulDeployments" -SuccessSource Content
```

## Manager Quick Guide

1. Confirm the full room machine list `.txt` file exists.
2. Confirm the successful deployment folder exists.
3. Open PowerShell.
4. Go to the folder containing this script.
5. Run the recommended command.
6. Review the failed machines shown in PowerShell.
7. If `-OutputFile` was used, open the generated failed deployment file.
8. Re-run deployment only for the failed machines, if required.

## Notes

- Blank lines in the full machine list are ignored.
- Lines starting with `#` are ignored.
- Machine name matching is case-insensitive.
- The output file contains only failed machine names, one per line.
