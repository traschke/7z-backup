function FullBackup ($pathToBackup, $backupDestinationPath) {
    $parsedBackupPath = $pathToBackup.Replace("\", "_").Replace(":", "")
    $backupFilename = [string]::Format("{0}-Base-{1}.7z", $parsedBackupPath, $(GetTimeStamp))
    $backupFilePath = [System.IO.Path]::Combine($backupDestinationPath, $backupFilename)

    $tmp7zCall = "a `"{0}`" `"{1}`" -m0=Copy -x!`"System Volume Information`" -x!`"`$RECYCLE.BIN`" -x!`"Config.Msi`" -x!`"" + $configFile + "`" -w`"{2}`""
    $7zCall = [string]::Format($tmp7zCall, $backupFilePath, $pathToBackup, $backupDestinationPath)

    echo $([string]::Format("Creating full backup of `"{0}`" to `"{1}`"...", $pathToBackup, $backupFilePath))
    ShowNotification "Full Backup of `"$pathToBackup`" started!"
    #echo $7zCall

    Invoke-Expression "7z $7zCall"
    CreateConfig $backupFilePath

    ShowNotification "Full Backup of `"$pathToBackup`" finished!"
}

function DifferentialBackup ($pathToBackup, $backupDestinationPath) {
    $config = $(ParseConfig)
    $baseFile =  $config.Get_Item("Basefile")

    if ([System.IO.File]::Exists($baseFile)) {
        $parsedBackupPath = $pathToBackup.Replace("\", "_").Replace(":", "")
        $backupFilename = [string]::Format("{0}-Diff-{1}.7z", $parsedBackupPath, $(GetTimeStamp))
        $backupFilePath = [System.IO.Path]::Combine($backupDestinationPath, $backupFilename)

        $tmp7zCall = "u `"{0}`" `"{1}`" -m0=Copy -u- -up0q3r2x2y2z0w2!`"{2}`" -x!`"System Volume Information`" -x!`"`$RECYCLE.BIN`" -x!`"Config.Msi`" -x!`"{3}`" -w`"{4}`""
        $7zCall = [string]::Format($tmp7zCall, $baseFile, $pathToBackup, $backupFilePath, $(GetConfigExclutionString), $backupDestinationPath)

        echo $([string]::Format("Creating differential backup of `"{0}`" to `"{1}`" based on `"{2}`"...", $pathToBackup, $backupFilePath, $baseFile))
        ShowNotification "Diffenrential Backup of `"$pathToBackup`" started!"
        #echo $7zCall

        Invoke-Expression "7z $7zCall"

        ShowNotification "Diffenrential Backup of `"$pathToBackup`" finished!"
    } else {
        echo "Basefile `"$baseFile`" not found!"
        ShowNotification "Basefile `"$baseFile`" not found!"
    }
}

function ShowNotification([string] $message) {
    New-BurntToastNotification -FirstLine "Backup Tool" -SecondLine $message.Trim()
}

function GetConfigExclutionString() {
    if ($configFile.IndexOf(":") = 1) {
        return $configFile.Substring(3)
    } else {
        return $configFile
    }
}

function CreateConfig ($baseFile) {
    $stream = [System.IO.StreamWriter] $configFile
    $stream.WriteLine("Basefile=" + $baseFile)
    $stream.Close()
}

function ParseConfig () {
    Get-Content "$configFile" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
    return $h
}

function GetTimeStamp () {
    return $(get-date -f yyyyMMdd-HHmmss)
}

function DecideBackup () {
    if ([System.IO.Directory]::Exists($pathToBackup)) {
        if ([System.IO.Directory]::Exists($backupDestinationPath)) {
            if ([System.IO.File]::Exists($configFile)) {
                # Diffenrential Backup
                echo "Differential backup"
                DifferentialBackup $pathToBackup $backupDestinationPath
            } else {
                # Full Backup
                echo "Full backup"
                FullBackup $pathToBackup $backupDestinationPath
            }
        } else {
            echo "Backup destination `"$backupDestinationPath`" does not exist! Aborting..."
            ShowNotification "Backup destination `"$backupDestinationPath`" does not exist! Aborting..."
        }
    } else {
        echo "Path to backup `"$pathToBackup`" does not exist! Aborting..."
        ShowNotification "Path to backup `"$pathToBackup`" does not exist! Aborting..."
    }
}

if ((Get-Command "7z" -ErrorAction SilentlyContinue) -eq $null) 
{ 
   Write-Host "Unable to find 7z in your PATH. Please fix that. Exiting..."
   exit 1
}

$pathToBackup = $args[0]
$backupDestinationPath = $args[1]
$configFile = [System.IO.Path]::Combine($pathToBackup + "\", "backupconfig.ini")
DecideBackup