# Outlook & Gmail integration

The Microsoft 365 MCP is blocked at many universities (see [mcps.md](mcps.md)). This doc covers two workarounds: forwarding institutional email to a personal Gmail, and bridging Outlook calendar via a secret iCal link.

## 1. Email forwarding (institutional Outlook → personal Gmail)

The simplest path: forward all incoming Outlook mail to a Gmail you control, then use Gmail's connector or MCP for triage.

### Native Outlook forwarding

1. Open Outlook on the web (`outlook.office.com`).
2. Settings (gear icon) → Mail → Forwarding.
3. Enable forwarding, enter `you@example.com`, save.
4. Optionally check "Keep a copy of forwarded messages" so your institutional archive stays intact.

If your tenant disables forwarding (some do for DLP reasons), use Gmail's pull-mode instead.

### Gmail pulls from Outlook via IMAP/POP

1. In Outlook web: Settings → Mail → Sync email → enable IMAP. Copy the IMAP server (`outlook.office365.com`, port 993, SSL).
2. In Gmail: Settings → Accounts and Import → "Check mail from other accounts" → Add a mail account.
3. Enter your institutional address, choose "Import emails from my other account (POP3)" or use IMAP via Gmailify if offered.
4. Use your university password — or, if your tenant requires modern auth, an app-specific password (Microsoft Account → Security → App passwords). Many tenants don't support app passwords; in that case this path is blocked and you're back to native forwarding.

## 2. Calendar bridge (Outlook → iCal URL)

The M365 MCP would normally surface calendar events to skills like `/daily-brief`. When it's blocked, publish your Outlook calendar as a secret-URL ICS feed and parse it locally.

### Publish Outlook calendar as ICS

1. Outlook on the web → Calendar → Settings → Shared calendars.
2. "Publish a calendar" → pick your calendar → permission `Can view all details`.
3. Copy the ICS URL — it will look like `https://outlook.office365.com/owa/calendar/<long-token>/calendar.ics`.
4. **This URL is a secret** (anyone with it can read your full calendar). Treat like the Telegram bot token: store in env var or GitHub Actions secret, never in `personal_config.json` or this repo.

### Store the ICS URL

For the orchestration repo:

```powershell
# Windows
gh secret set CALENDAR_ICS_URLS
# Paste the ICS URL when prompted; comma-separate if you have multiple calendars
```

```bash
# macOS / Linux
gh secret set CALENDAR_ICS_URLS
```

For local testing:

```powershell
# Windows
setx CALENDAR_ICS_URLS "https://outlook.office365.com/owa/calendar/.../calendar.ics"
```

```bash
# macOS / Linux
echo 'export CALENDAR_ICS_URLS="https://outlook.office365.com/owa/calendar/.../calendar.ics"' >> ~/.zshrc
```

### Same flow for Google Calendar

If your primary calendar is Google, follow the parallel path:

1. Google Calendar → Settings → pick the calendar → "Integrate calendar".
2. Copy the **secret address in iCal format** (the URL labelled "Secret address", not the "Public address").
3. Add to `CALENDAR_ICS_URLS` the same way — multiple comma-separated URLs are supported.

If you rotate the secret address (Google's "Reset" button), every consumer needs the new URL.

## 3. Gmail MCP — optional

Anthropic offers a Gmail connector at `claude.ai/settings/connectors`. It's an OAuth flow in the browser; once linked it provides tools like `search_threads`, `create_draft`, `label_message`.

This is nice-to-have for an email-triage skill (see [future-work.md](future-work.md)) but not required for the daily brief / capture path. Skills currently in this repo do not depend on the Gmail MCP.

## 4. Verify

```powershell
# Windows — confirm the ICS feed downloads
Invoke-WebRequest -Uri $env:CALENDAR_ICS_URLS -OutFile cal.ics; Get-Content cal.ics -TotalCount 10
```

```bash
# macOS / Linux
curl -s "$CALENDAR_ICS_URLS" | head -20
```

You should see `BEGIN:VCALENDAR` followed by `VEVENT` blocks. If you see HTML or a 404, the URL is wrong or the publish step didn't complete.
