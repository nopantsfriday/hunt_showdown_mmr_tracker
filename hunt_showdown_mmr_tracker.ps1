<#
.DESCRIPTION
# About
After finding out that Hunt: Showdown will allegedly save the current MMR into an xml file, I wrote a small PowerShell script to publish my current MMR via Eclipse Mosquitto MQTT client every time it get's written to the file.

Big thanks to [r3ap3rpy](https://github.com/r3ap3rpy) who published a [guide](https://github.com/r3ap3rpy/powershell/blob/master/FSWatcher.ps1) on how to use the [.NET FileSystemWatcher Class](https://docs.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher?view=net-6.0) in PowerShell.

 ## Update: 2023-02-11

 Being tired of manually copying Nvidia Highlights of Hunt Showdown, I found [Kamille_92](https://twitter.com/Kamille_92/)'s [AutoSave-Highlights-for-Hunt-Showdown](https://github.com/waibcam/AutoSave-Highlights-for-Hunt-Showdown) script and incorporated [my script](https://github.com/nopantsfriday/hunt_showdown_mmr_tracker/blob/4817e722e634f5d4e35d6a874ee5a9352056816b/hunt_showdown_mmr_tracker.ps1).

# Authors
* [nopantsfriday](https://github.com/nopantsfriday) - Initial [hunt_showdown_mmr_tracker.ps1](https://github.com/nopantsfriday/hunt_showdown_mmr_tracker/blob/4817e722e634f5d4e35d6a874ee5a9352056816b/hunt_showdown_mmr_tracker.ps1) script
* [waibcam](https://github.com/waibcam) - All parts in the current PowerShell script that refer to the automatic saving of NVIDIA highlights were developed by [Kamille_92](https://twitter.com/Kamille_92/). 

# License
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/nopantsfriday/restart_steam_client/blob/master/LICENSE)

This project is licensed under the GNU General Public License v3.0
.LINK
    https://github.com/nopantsfriday/hunt_showdown_mmr_tracker
#>

#ALT + Z -> Highlights -> Path of the folder "Temporary files"
$TempHighlightsPath = "$env:USERPROFILE\Videos\NVIDIA_TEMP\Hunt  Showdown" # <-- Configure this

#Path where you want to move the Highlights
$DestinationPath = "$env:USERPROFILE\Videos\Hunt  Showdown" # <-- Configure this

#Change if necessary
$SteamPath = "D:\_Clients\Steam" # <-- Configure this

#MMR tracker
$mmr_watchfolder = "$SteamPath\steamapps\common\Hunt Showdown\user\profiles\default"
$mmr_watchfile = 'attributes.xml'
$mosquitto_pub = "$Env:Programfiles\Mosquitto\mosquitto_pub.exe"
$mosquitto_topic_mmr = "home/spielzimmer/huntmmr"
$mosquitto_topic_mmr_delta = "home/spielzimmer/huntmmrdelta"
$mqtturl = "my-mqtt.url"
$mqtt_user = "user"
$mqtt_password = "password"
$elo_watcher = New-Object IO.FileSystemWatcher $mmr_watchfolder, $mmr_watchfile -property @{IncludeSubDirectories = $false; NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite' }

if (!(Test-Path "$env:TEMP\huntmmr.txt")) {
    New-Item -Path "$env:TEMP\huntmmr.txt" -ItemType File
}

Write-Host "Starting script." -ForegroundColor DarkGray


#############################################################
####################### Testing Paths #######################
#############################################################
if ((Test-Path -Path $TempHighlightsPath) -eq $false) {
	Write-Error "`nTemp Highlights Path `"$TempHighlightsPath`" doesn't exist.`nExiting in 10 sec."
	Start-Sleep -Seconds 10
	exit
}

if ((Test-Path -Path $DestinationPath) -eq $false) {
	Write-Host "`nDestination Path `"$DestinationPath`" doesn't exist.`nTrying to create it..." -NoNewline -ForegroundColor Yellow
	
	$result = New-Item "$DestinationPath" -ItemType Directory
	
	if ((Test-Path -Path $DestinationPath) -eq $false) {
		Write-Host "`nImpossible to create `"$DestinationPath`".`nExiting in 10 sec.".
		Start-Sleep -Seconds 10
		exit
	}
	else {
		Write-Host " OK, folder has been created." -ForegroundColor Yellow
	}
}



#############################################################
# This Part if not mandatory, you can remove it if you want #
#############################################################

#testing steam path
if ((Test-Path -Path "$SteamPath\steam.exe") -eq $false) {
	Write-Warning "`nsteam.exe can't be found in `"$SteamPath`".`nExiting in 10 sec."
	Start-Sleep -Seconds 10
	exit
}
else {
	#Checking if Hunt game is started and starts it if needed.
	if ( (Get-Process -Name "HuntGame" -ErrorAction SilentlyContinue).Count -eq 0) {
		$counter = 0;
		#Waiting for Hunt Showdown to start
		while ( (Get-Process -Name "HuntGame" -ErrorAction SilentlyContinue).Count -eq 0) {
			Start-Sleep -Seconds 1
			if ($counter -eq 0) {
				#Starting Hunt Showdown
				& "$SteamPath\steam.exe" "steam://rungameid/594650"
				
				Write-Host "`nWaiting for Hunt Showdown to start..." -NoNewline
			}
			$counter++
		}

		Write-Host " OK." -ForegroundColor Cyan
	}
}
#############################################################
#############################################################
#############################################################


# specify which files you want to monitor
$FileFilter = '*.mp4'  

# specify whether you want to monitor subfolders as well:
$IncludeSubfolders = $true

# specify the file or folder properties you want to monitor:
$AttributeFilter = [IO.NotifyFilters]::FileName

# specify the type of changes you want to monitor:
$ChangeTypes = [System.IO.WatcherChangeTypes]::Created

# specify the maximum time (in milliseconds) you want to wait for changes:
$Timeout = 1000

# define a function that gets called for every change:
function Invoke-MoveCreatedFile {
	param
	(
		[Parameter(Mandatory)]
		[System.IO.WaitForChangedResult]
		$ChangeInformation
	)

	$Name = $ChangeInformation.Name
	
	# Waiting 5 seconds so file can be fully created
	Start-Sleep -Seconds 5

	Write-Host "`n`tNew Highlights detected" -ForegroundColor Green
	
	$FullFromPath = "$TempHighlightsPath\$Name"
	$FileName = [System.IO.Path]::GetFileName($FullFromPath)
	$FromPath = $FullFromPath.Replace($FileName, "")
	$GameName = $Name.Replace("\$FileName", "")
	
	#There can be several files added, so we are going to get them and move them one by one.
	$Files_To_Move = Get-ChildItem -Path "$FromPath\$FileFilter" | Select-Object Name, CreationTime
		
	foreach ($File_To_Move in $Files_To_Move) {
		$FileName = $File_To_Move.Name
		$FileCreationTime = $File_To_Move.CreationTime

		$year = Get-Date -Date $FileCreationTime -Format "yyyy"
		$month = Get-Date -Date $FileCreationTime -Format "MM"
		$day = Get-Date -Date $FileCreationTime -Format "dd"
		
		$FullDestinationPath = $DestinationPath
		
		if ((Test-Path -Path $FullDestinationPath) -eq $false) {
			#Create directory if not exists
			$result = New-Item "$FullDestinationPath" -ItemType Directory
		}

		if ((Test-Path -Path $FullDestinationPath) -eq $true) {
			$result = Move-Item -Path "$FromPath\$FileName" -Destination "$FullDestinationPath" -Force -PassThru
			Write-Host $FullDestinationPath

			$New_FileName = $result.Name
			if ((Test-Path -Path "$FullDestinationPath\$New_FileName") -eq $true) {
				Write-Host "`t`t$FileName moved" -ForegroundColor DarkGreen
			}
			else {
				Write-Host "`t`t$FileName hasn't been moved :(" -ForegroundColor Red
			}
		}
		else {
			Write-Host "`tFolder $GameName\$year\$month\$day doesn't exist or can't be created" -ForegroundColor Red
			Write-Host "`tFile hasn't been moved." -ForegroundColor Red
		}
	}
}

# use a try...finally construct to release the
# filesystemwatcher once the loop is aborted
# by pressing CTRL+C


try {
	Write-Host "`nWaiting for new Highlights and tracking MMR... " -NoNewline

	Register-ObjectEvent $elo_watcher Changed -SourceIdentifier FileChange -Action {
		$XMLPath = "$mmr_watchfolder\$mmr_watchfile"
		$XML = [xml](Get-Content $XMLPath)
		$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		$fetch_stored_mmr = (Get-Content "$env:TEMP\huntmmr.txt")
		$fetch_current_mmr = ($XML.Attributes.Attr | Where-Object name -EQ "MissionBagPlayer_0_1_mmr" | Select-Object -ExpandProperty Value)
		#$fetch_current_mmr = (Select-Xml -Path $XMLPath -XPath '/Attributes/Attr'  | Select-Object -ExpandProperty Node | Where-Object -Property Name -EQ 'MissionBagPlayer_0_1_mmr' | Select-Object -ExpandProperty Value)
		$mmr_delta = ($fetch_current_mmr) - ($fetch_stored_mmr)
		if (!($fetch_stored_mmr -eq $fetch_current_mmr)) {
			$name = $Event.SourceEventArgs.Name
			$changeType = $Event.SourceEventArgs.ChangeType
			$timeStamp = $Event.TimeGenerated
			Write-Host "$date - MMR changed. $name was $changeType at $timeStamp! Stored MMR:" -ForegroundColor Green -NoNewline;  Write-Host " $fetch_stored_mmr " -ForegroundColor DarkMagenta -NoNewline; Write-Host "New MMR:" -ForegroundColor Green -NoNewline; Write-Host " $fetch_current_mmr " -ForegroundColor Magenta -NoNewline; Write-Host "($mmr_delta)" -ForegroundColor Cyan
			Start-Process -WindowStyle Hidden $mosquitto_pub -ArgumentList "-u $mqtt_user -P $mqtt_password -t ""$mosquitto_topic_mmr"" -m $fetch_current_mmr -h $mqtturl -r"
			Start-Process -WindowStyle Hidden $mosquitto_pub -ArgumentList "-u $mqtt_user -P $mqtt_password -t ""$mosquitto_topic_mmr_delta"" -m $mmr_delta -h $mqtturl -r"
			$fetch_current_mmr | Out-File "$env:TEMP\huntmmr.txt" -Encoding utf8 -NoNewline
		}
		else {
			$name = $Event.SourceEventArgs.Name
			$changeType = $Event.SourceEventArgs.ChangeType
			$timeStamp = $Event.TimeGenerated
			Write-Host "$date - MMR equal. $name was $changeType at $timeStamp! Stored MMR:" -ForegroundColor Yellow -NoNewline;  Write-Host " $fetch_stored_mmr " -ForegroundColor DarkMagenta -NoNewline; Write-Host "New MMR:" -ForegroundColor Yellow -NoNewline; Write-Host " $fetch_current_mmr " -ForegroundColor Magenta -NoNewline; Write-Host "($mmr_delta)" -ForegroundColor Cyan
		}
	} | out-null

	# create a filesystemwatcher object
	$watcher = New-Object -TypeName IO.FileSystemWatcher -ArgumentList $TempHighlightsPath, $FileFilter -Property @{
		IncludeSubdirectories = $IncludeSubfolders
		NotifyFilter          = $AttributeFilter
	}

	# start monitoring manually in a loop:
	do {
		# wait for changes for the specified timeout
		# IMPORTANT: while the watcher is active, PowerShell cannot be stopped
		# so it is recommended to use a timeout of 1000ms and repeat the
		# monitoring in a loop. This way, you have the chance to abort the
		# script every second.
		$result = $watcher.WaitForChanged($ChangeTypes, $Timeout)
		# if there was a timeout, continue monitoring:
		if ($result.TimedOut) { continue }

		Invoke-MoveCreatedFile -Change $result
		# the loop runs forever until you hit CTRL+C    
	} while ( (Get-Process -Name "HuntGame" -ErrorAction SilentlyContinue).Count -eq 0) {
		$true
	}
	
	$watcher.Dispose()
	Unregister-Event FileChange
	Write-Host 'FileSystemWatcher removed.' -ForegroundColor Magenta
}
finally {
	# release the watcher and free its memory:
	$watcher.Dispose()
	Unregister-Event FileChange
	Write-Host 'FileSystemWatcher removed.' -ForegroundColor Magenta
}
