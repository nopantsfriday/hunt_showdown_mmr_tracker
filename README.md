[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/nopantsfriday/restart_steam_client/blob/master/LICENSE)
# About
After finding out that Hunt: Showdown will allegedly save the current MMR into an xml file, I wrote a small PowerShell script to publish my current MMR via Eclipse Mosquitto MQTT client every time it get's written to the file.

Feel free to use, copy, fork, modify, merge, publish or distribute the script and/or parts of the script.

Big thanks to [r3ap3rpy](https://github.com/r3ap3rpy) who published a [guide](https://github.com/r3ap3rpy/powershell/blob/master/FSWatcher.ps1) on how to use the [.NET FileSystemWatcher Class](https://docs.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher?view=net-6.0) in PowerShell.