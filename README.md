# 7z-backup
Simple PowerShell script that handles diffenrential backups via 7zip

## Prerequisities
* PowerShell
* PowerShell module "BurnedToast"
 * In PowerShell do `PS> Install-Module -Name BurntToast -RequiredVersion 0.4` to install it
* 7zip (Note that `7z.exe` must be in your `PATH`or the script won't find it)

## How to run the script
Run the script with following paramters:
`backup.ps1 <PATH-TO-BACKUP> <DESTINATION-PATH>`

### Example
To run powershell with this script in background, do the following:

`powershell -windowstyle hidden -File C:\backup.ps1 "D:" "X:\Backups\\"`

This will run the script, backup all contents of `D:\` to a 7z-File that will be located at `X:\Backups\`.

## How the script works
Note that you don't have to give a filename in destination path, the script will create one according to the backup path and a timestamp.

If you run the script the first time on a path you would like to backup, it will create a full backup of this path. It will then create a config file in this path with the location of the full backup.
If you run the script on that path again, it will look for the full backup given in the config file and will perform a diffenrential backup against this.

