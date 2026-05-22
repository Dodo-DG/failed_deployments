# SEB Failed Deployment Checker

This repository contains a PowerShell script that checks which machines did not
receive a SEB configuration deployment successfully.

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

- (Optional) A `.txt` file containing the SEB password (use `-PasswordFile`)
- (Optional) A `.txt` file containing the SEB build information (use `-BuildFile`)
- (Optional) use `-SuccessSource Content` when successful machines are listed inside each `.txt` file

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

### 3. SEB Password File (optional)

Create a `.txt` file that contains the SEB password on a single line. Pass its path with the `-PasswordFile` parameter. If you omit the parameter the script will prompt for the path at runtime.

Example file name:

```text
seb-password.txt
```

Example contents:

```text
my-secret-password
```

### 4. SEB Build File (optional)

Create a `.txt` file that contains the SEB build information (for example a build identifier or version string). Pass its path with the `-BuildFile` parameter. If omitted the script will prompt for the path at runtime.

Example file name:

```text
seb-build.txt
```

Example contents:

```text
Build 2026-05-22
```

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
names. If the `.txt` files instead contain machine names in their content,
use `-SuccessSource Content`.

## How To Run The Script

1. Open PowerShell.
2. Go to the folder containing `Find-FailedSebDeployments.ps1`.

Example:

```powershell
cd "Z:\Documentation\"
```

3. Run the script:

```powershell
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile "Z:\Documentation\All Cluster Machines\DEPARTMENT_ROOMNUMBER.txt" -SuccessFolder "Z:\Deployment Summary\DEPARTMENT-ROOMNUMBER-YYYY-MM-DD-ICTTICKET" -PasswordFile "Z:\Documentation\Passwords\YYYY-MM-DD.txt" -BuildFile "Z:\Documentation\Build\MODULE.txt"
```

Replace the names with the real ones based on the day of the exam and the build of the exam.

## Running Without Parameters

The script can also be run without parameters:

```powershell
.\Find-FailedSebDeployments.ps1
```

It will ask for:

```text
Enter path to the full machine list .txt file
Enter path to the folder containing successful deployment .txt files
Enter path to the .txt file containing the SEB password (optional)
Enter path to the .txt file containing the SEB build info (optional)
```

When pasting paths into these prompts, at the moment it works with the surrounding quotes. If not, you can drop the quotes.

Example:

```text
Z:\Documentation\All Cluster Machines\DEPARTMENT_ROOMNUMBER.txt
```

## Example Output

```text
SEB deployment check
--------------------
SEB password:        password
SEB build:           Build for the day 2026-05-14
Expected machines:   10
Successful machines: 9
Failed machines:     1

Machines where deployment was NOT successful:
 - PC10
```
**SAFE TO IGNORE**

All the rooms will have a main Panopto console and another admin machine which also have deployments enabled on them, but they will not be used by the students, hence the sum of failed machines and successful machines might be more than the expected machines. This is expected as the admin and main Panopto console machines are not in the list for Expected machines. 

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
Test-Path "Z:\Documentation\All Cluster Machines\DEPARTMENT_ROOMNUMBER.txt" -PathType Leaf
```

It should return:

```text
True
```

If the script says it cannot find the successful deployment folder, check the
folder path:

```powershell
Test-Path "Z:\Deployment Summary\DEPARTMENT-ROOMNUMBER-YYYY-MM-DD-ICTTICKET" -PathType Container
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
-ExpectedMachinesFile "Z:\Documentation\All Cluster Machines\DEPARTMENT_ROOMNUMBER.txt"
```

Incorrect:

```powershell
-ExpectedMachinesFile "Z:\Documentation\All Cluster Machines"
```

### Success folder was not found

This means the `-SuccessFolder` path is wrong or points to a file instead of a
folder.

Correct:

```powershell
-SuccessFolder "Z:\Deployment Summary\DEPARTMENT-ROOMNUMBER-YYYY-MM-DD-ICTTICKET"
```

Incorrect:

```powershell
-SuccessFolder "Z:\Deployment Summary\DEPARTMENT-ROOMNUMBER-YYYY-MM-DD-ICTTICKET\DEPARTMENT_ROOMNUMBER.txt"
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
.\Find-FailedSebDeployments.ps1 -ExpectedMachinesFile "Z:\Documentation\All Cluster Machines\DEPARTMENT_ROOMNUMBER.txt" -SuccessFolder "Z:\Deployment Summary\DEPARTMENT-ROOMNUMBER-YYYY-MM-DD-ICTTICKET" -SuccessSource Content
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
