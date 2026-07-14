# LaunchAgent Setup for Splunk Boot-Start

## Problem
macOS LaunchAgent's EnvironmentVariables section was not properly propagating environment variables (SPLUNK_HOME, SPLUNK_DB, SPLUNK_ETC) to the child process started via Program key, causing "Configuration error: The environment variable SPLUNK_DB must not be empty" errors.

## Solution
Created wrapper script at `/Users/mike/splunk/bin/launchd_start.sh` that explicitly exports the required environment variables before executing the actual splunkd binary.

## Wrapper Script
Location: `/Users/mike/splunk/bin/launchd_start.sh`
- Exports SPLUNK_HOME, SPLUNK_DB, SPLUNK_ETC
- Sets PATH to include Splunk bin directory
- Changes to SPLUNK_HOME directory
- Execs splunkd with passed arguments

## Configuration
- com.splunk.splunkd.plist Program key changed from `/Users/mike/splunk/bin/splunkd` to `/Users/mike/splunk/bin/launchd_start.sh`
- EnvironmentVariables section removed from plist (now handled by wrapper script)
- Removed non-functional KeepAlive directives remain as-is

## Verification
- No SPLUNK_DB or SPLUNK_ETC errors in launchd-error.log after reload
- Splunk REST API responds with 200 status on port 8089 with proper authentication
- Port 8089 listening and accepting connections

## Future Maintenance
If Splunk installation path changes, update wrapper script hardcoded paths and reload LaunchAgent:
```bash
launchctl unload ~/Library/LaunchAgents/com.splunk.splunkd.plist
launchctl load ~/Library/LaunchAgents/com.splunk.splunkd.plist
```
