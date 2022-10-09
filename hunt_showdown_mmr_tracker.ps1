<#
.DESCRIPTION
License: MIT https://github.com/nopantsfriday/restart_steam_client/blob/master/LICENSE
After finding out that Hunt: Showdown will allegedly save the current MMR into an xml file, I wrote a small PowerShell script to publish my current MMR via Eclipse Mosquitto MQTT client every time it get's written to the file.
Feel free to use, copy, fork, modify, merge, publish or distribute the script and/or parts of the script.
Big thanks to [r3ap3rpy](https://github.com/r3ap3rpy) who published a [guide](https://github.com/r3ap3rpy/powershell/blob/master/FSWatcher.ps1) on how to use the 
[.NET FileSystemWatcher Class](https://docs.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher?view=net-6.0) in PowerShell.
.LINK
    https://github.com/nopantsfriday/hunt_showdown_mmr_tracker
#>
$watchfolder = 'D:\_Clients\Steam\steamapps\common\Hunt Showdown\user\profiles\default'
$watchfile = 'attributes.xml'
$mosquitto_pub = "$Env:Programfiles\Mosquitto\mosquitto_pub.exe"
$mqtturl = "my-mqtt.url"
$mqtt_user = "user"
$mqtt_password = "password"
$watcher = New-Object IO.FileSystemWatcher $watchfolder, $watchfile -property @{IncludeSubDirectories = $false; NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite' }

if (!(Test-Path "$env:TEMP\huntmmr.txt")) {
    New-Item -Path "$env:TEMP\huntmmr.txt" -ItemType File
}

Register-ObjectEvent $watcher Changed -SourceIdentifier FileChange -Action {
    $XMLPath = "D:\_Clients\Steam\steamapps\common\Hunt Showdown\user\profiles\default\attributes.xml"
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
        Write-Host "$date - MMR differs! The file: $name, was $changeType at $timeStamp! Stored MMR: $fetch_stored_mmr New MMR: $fetch_current_mmr " -ForegroundColor Green -NoNewline; Write-Host "($mmr_delta)" -ForegroundColor Cyan
        Start-Process -WindowStyle Hidden $mosquitto_pub -ArgumentList "-u $mqtt_user -P $mqtt_password -t ""home/spielzimmer/huntmmr"" -m $fetch_current_mmr -h $mqtturl -r"
        Start-Process -WindowStyle Hidden $mosquitto_pub -ArgumentList "-u $mqtt_user -P $mqtt_password -t ""home/spielzimmer/huntmmrdelta"" -m $mmr_delta -h $mqtturl -r"
        $fetch_current_mmr | Out-File "$env:TEMP\huntmmr.txt" -Encoding utf8 -NoNewline
    }
    else {
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        Write-Host "$date - MMR matches! The file: $name, was $changeType at $timeStamp! Stored MMR: $fetch_stored_mmr New MMR: $fetch_current_mmr " -ForegroundColor Yellow -NoNewline; Write-Host "($mmr_delta)" -ForegroundColor Cyan
    }
}
try {
    do {
        Wait-Event -Timeout 1
    } while ($true)
}
finally {
    #Unregister Event when CTRL+C is pressed
    Unregister-Event FileChange
    Write-Host "Filehandler unregistered" -ForegroundColor Magenta
}