# Elita Session Log Observability with Splunk

Splunk Enterprise ingestion platform for elita session logs (10.4.1, Free license, 500MB/day).

## Installation & Setup

### 1. Prerequisites

Splunk is pre-installed at ~/splunk (unpacked from tarball).

### 2. Start Splunk

```bash
~/splunk/bin/splunk start --accept-license --no-prompt
```

Splunk will start and listen on `http://127.0.0.1:8000` and `http://localhost:8000`.

### 3. Admin Credentials (First Time)

On first access, Splunk prompts for admin credentials. Default:
- **Username**: admin
- **Password**: changeme (change on first login)

For automation (scripted startup), set via environment:
```bash
export SPLUNK_USERNAME=admin
export SPLUNK_PASSWORD=1234qwer
~/splunk/bin/splunk start --accept-license --no-prompt
```

### 4. Switch to Free License

1. Go to **Settings > Licensing** (or http://127.0.0.1:8000/en-US/app/launcher/licensing)
2. Click **Change License Group** (if license slave is configured)
3. Or via CLI:
```bash
~/splunk/bin/splunk set licenses-location ~/splunk/etc/licenses/elita_free -auth admin:1234qwer
```

Free license applies automatically (500MB/day ingest, perpetual use, single instance).

### 5. Install Monitoring Configuration

Copy config files to Splunk app directory:

```bash
mkdir -p ~/splunk/etc/apps/elita_session/local
cp observability/splunk/*.conf ~/splunk/etc/apps/elita_session/local/
```

Restart Splunk to apply:
```bash
~/splunk/bin/splunk restart
```

### 6. Verify Monitoring

Check if Splunk is monitoring the elita sessions directory:

```bash
~/splunk/bin/splunk list forward-server -auth admin:1234qwer
~/splunk/bin/splunk list inputs -auth admin:1234qwer | grep -A3 "elita"
```

Or in the Web UI: **Settings > Data Inputs > Files & Directories**.

## Stopping & Starting

### Stop Splunk

```bash
~/splunk/bin/splunk stop
```

### Start Splunk (without license prompt)

```bash
~/splunk/bin/splunk start --accept-license --no-prompt
```

## Search Examples

Access the search UI at: **http://127.0.0.1:8000** > **Search & Reporting**

### Recipe 1: All Traffic for One Agent

Find all events (any kind) for a specific agent:

```spl
sourcetype=elita_session agent=kenny
```

Shows all logs from the kenny agent, including boot events, routing calls, and standard logs.

### Recipe 2: All Tool-Call Routing Events

Find only the emoji-based routing events (asks, tells, replies):

```spl
sourcetype=elita_session (kind=ask OR kind=tell OR kind=reply)
```

Or direct regex:

```spl
sourcetype=elita_session (🤔 OR 📢 OR ✨)
```

Example output:
```
🤔 dude → kenny | execute_task
📢 kenny → dude | task_complete
✨ kenny | acknowledged
```

### Recipe 3: Count Asks Per Sender (Stats)

Aggregate tool-call asks by sender:

```spl
sourcetype=elita_session kind=ask 
| stats count as ask_count by sender
| sort - ask_count
```

Shows which agents initiated the most queries.

### Advanced: Combined Ask/Tell/Reply Timeline

```spl
sourcetype=elita_session (kind=ask OR kind=tell OR kind=reply)
| table _time, kind, sender, target, receiver, message
| sort _time
```

## Configuration Files

Located in: **observability/splunk/**

- **inputs.conf** — Monitoring input definition (directory, index, sourcetype)
- **props.conf** — Parsing and field extraction configuration
- **transforms.conf** — Regex patterns for extracting sender, target, receiver, message, agent, pid, kind

## Log Format

Session logs ingested from `~/.elita/sessions/{name}_{pid}.log`:

**Routing Events**:
```
🤔 sender → target | message      (ask: sender queries target)
📢 sender → target | message      (tell: sender instructs target)
✨ receiver | message             (reply: receiver acknowledges)
```

**Boot Events**:
```
🚀 boot node=xxx cwd=/path argv=[...]
```

**Standard Logs**:
```
2026-07-13T15:30:45.123Z [boot] message
2026-07-13T15:30:46.100Z [info] agent: description
```

## Data Retention & Cleanup

Logs don't accumulate permanently — events roll off after 1 day to keep the index lightweight.

**Retention settings** (configured in indexes.conf):
- **frozenTimePeriodInSecs**: 86400 (1 day)
- **maxTotalDataSizeMB**: 500

Events are automatically deleted 1 day after ingestion. This means Splunk is optimized for inspecting recent session activity, not long-term history.

To adjust retention:
1. Edit `observability/splunk/indexes.conf`
2. Change `frozenTimePeriodInSecs` (86400 = 1 day, 604800 = 7 days)
3. Restart Splunk: `~/splunk/bin/splunk restart`

## Free License Caveats & Limits

- **Capacity**: 500MB per day ingest limit
- **Instance**: Single instance only (no distributed search)
- **Features**:
  - ✓ Full search capabilities
  - ✗ No alerting
  - ✗ Search disabled after 3 violations in 30 days
- **Duration**: Perpetual (no expiration)

If you hit the 500MB/day limit, either:
1. Wait for rollover (daily reset)
2. Delete old index data: `~/splunk/bin/splunk clean eventdata -index elita`
3. Upgrade to a commercial license

## Troubleshooting

### Logs Not Appearing

1. **Check monitoring configuration**:
   ```bash
   ~/splunk/bin/splunk list inputs -auth admin:1234qwer | grep -A5 "monitor"
   ```

2. **Verify file permissions**:
   ```bash
   ls -la ~/.elita/sessions/*.log | head -5
   ```
   Splunk must have read access. If needed:
   ```bash
   chmod 644 ~/.elita/sessions/*.log
   ```

3. **Check Splunk logs**:
   ```bash
   tail -100 ~/splunk/var/log/splunk/splunkd.log
   ```

### Web UI Not Accessible

- Restart Splunk: `~/splunk/bin/splunk restart`
- Check port 8000 is available: `lsof -i :8000`
- Verify service is running: `~/splunk/bin/splunk status`

### License Violations

If you exceed 500MB/day:
```bash
~/splunk/bin/splunk list license-usage -auth admin:1234qwer
```

## References

- Splunk docs: https://docs.splunk.com
- Field extraction: https://docs.splunk.com/Documentation/Splunk/latest/Knowledge/Aboutfieldextraction
- Search Processing Language (SPL): https://docs.splunk.com/Documentation/Splunk/latest/SearchReference/Searching
- Input monitoring: https://docs.splunk.com/Documentation/Splunk/latest/Forwarding/Forwarddata
