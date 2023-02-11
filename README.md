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