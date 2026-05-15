# MCP catalog

The Model Context Protocol servers this workflow relies on. Cross-platform install commands assume the toolchain from [platforms.md](platforms.md). Verify any install with `claude mcp list`.

There are three integration shapes here:

- **Stdio MCPs** (open-source, run locally) — configured in `~/.claude.json` (or `%USERPROFILE%\.claude.json`) via `claude mcp add`.
- **HTTP / OAuth gateway MCPs** (vendor-hosted, added via CLI) — added once via `claude mcp add ... --transport http`; tokens live in the gateway, not on disk. Notion is the main example.
- **claude.ai web-portal connectors** (Anthropic-hosted catalog) — added through the browser at the claude.ai settings page; auto-refreshing OAuth; no CLI command. See [claude.ai web-portal connectors](#claudeai-web-portal-connectors-oauth-browser-based-setup) below.

Sections:

- [Stdio MCPs](#stdio-mcps)
- [HTTP / OAuth gateway MCPs](#http--oauth-gateway-mcps)
- [claude.ai web-portal connectors](#claudeai-web-portal-connectors-oauth-browser-based-setup)
- [Web-portal connector setup, step-by-step](#web-portal-connector-setup-step-by-step)
- [Blocked / institutional MCPs](#blocked--institutional-mcps)
- [Sanity check](#sanity-check)
- [Token refresh procedures](#token-refresh-procedures)

## Stdio MCPs

### 1. arxiv

- **Summary**: search and read arXiv papers without leaving the terminal.
- **Used by**: `/litreview`, `/cite`, `/evaluate-idea-marketing`, `/evaluate-idea-science`.
- **Secrets**: none.

```powershell
# Windows
claude mcp add arxiv -- uvx arxiv-mcp-server
```

```bash
# macOS / Linux
claude mcp add arxiv -- uvx arxiv-mcp-server
```

Verify: `claude mcp list` shows `arxiv` as `connected`.

### 2. semantic-scholar

- **Summary**: Semantic Scholar paper / author / citation graph queries.
- **Used by**: `/litreview`, `/bibcheck`, `/cite`.
- **Secrets**: none required (the underlying API is rate-limited but free); optionally set `SEMANTIC_SCHOLAR_API_KEY` in your shell for a higher quota.

```powershell
# Windows
claude mcp add semantic-scholar -- uvx --from "git+https://github.com/zongmin-yu/semantic-scholar-fastmcp-mcp-server.git" semantic-scholar-fastmcp-mcp-server
```

```bash
# macOS / Linux
claude mcp add semantic-scholar -- uvx --from "git+https://github.com/zongmin-yu/semantic-scholar-fastmcp-mcp-server.git" semantic-scholar-fastmcp-mcp-server
```

### 3. openalex

- **Summary**: OpenAlex bibliographic graph (Crossref-grade metadata, author disambiguation, institutional signals).
- **Used by**: `/litreview`, `/bibcheck`, `/cite`.
- **Secrets**: `OPENALEX_API_KEY` — OpenAlex's "polite pool" key is just your email address. No registration needed.

```powershell
# Windows
setx OPENALEX_API_KEY "you@example.com"
claude mcp add openalex -- npx -y @cyanheads/openalex-mcp-server
```

```bash
# macOS / Linux
echo 'export OPENALEX_API_KEY="you@example.com"' >> ~/.zshrc
claude mcp add openalex -- npx -y @cyanheads/openalex-mcp-server
```

On Windows, if `npx` can't find Node due to a space in the install path, see the Node launch workaround in [platforms.md](platforms.md). Example JSON entry:

```json
{
  "mcpServers": {
    "openalex": {
      "command": "C:\\PROGRA~1\\nodejs\\npx.cmd",
      "args": ["-y", "@cyanheads/openalex-mcp-server"],
      "env": {"OPENALEX_API_KEY": "you@example.com"}
    }
  }
}
```

### 4. zotero

- **Summary**: read and write to your Zotero library — search items, fetch metadata, pull fulltext.
- **Used by**: `/cite`, `/bibcheck`, `/litreview`.
- **Secrets**:
  - `ZOTERO_API_KEY` — create at `https://www.zotero.org/settings/keys`. Grant read access to your library; grant write only if you want `/cite` to add items.
  - `ZOTERO_LIBRARY_ID` — numeric user ID (top of the API keys page) or a group ID.
  - `ZOTERO_LIBRARY_TYPE` — `user` or `group`.

```powershell
# Windows
setx ZOTERO_API_KEY "<your-key>"
setx ZOTERO_LIBRARY_ID "<your-numeric-id>"
setx ZOTERO_LIBRARY_TYPE "user"
claude mcp add zotero -- uvx zotero-mcp
```

```bash
# macOS / Linux
cat >> ~/.zshrc <<'EOF'
export ZOTERO_API_KEY="<your-key>"
export ZOTERO_LIBRARY_ID="<your-numeric-id>"
export ZOTERO_LIBRARY_TYPE="user"
EOF
claude mcp add zotero -- uvx zotero-mcp
```

The Zotero MCP is read-mostly; for programmatic adds, `/cite` falls back to the Zotero Web API directly.

### 5. playwright

- **Summary**: headless browser automation — navigate, click, fill forms, screenshot.
- **Used by**: ad-hoc web scraping in `/litreview` when an MCP source 404s; downloading conference PDFs behind soft paywalls; sanity-checking your own website.
- **Secrets**: none.

```powershell
# Windows
claude mcp add playwright -- npx -y @playwright/mcp
# One-time browser download:
npx playwright install chromium
```

```bash
# macOS / Linux
claude mcp add playwright -- npx -y @playwright/mcp
npx playwright install chromium
```

### 6. github

- **Summary**: read and write GitHub issues, PRs, files, releases, code search.
- **Used by**: orchestration repo (`lan-daily-brief`) housekeeping; manual `/loop` checks on PR status.
- **Secrets**: `GITHUB_PERSONAL_ACCESS_TOKEN` — fetch from your existing `gh` login.

```powershell
# Windows
$env:GITHUB_PERSONAL_ACCESS_TOKEN = (gh auth token)
setx GITHUB_PERSONAL_ACCESS_TOKEN "$env:GITHUB_PERSONAL_ACCESS_TOKEN"
claude mcp add github -- npx -y @modelcontextprotocol/server-github
```

```bash
# macOS / Linux
export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
echo "export GITHUB_PERSONAL_ACCESS_TOKEN=\"$(gh auth token)\"" >> ~/.zshrc
claude mcp add github -- npx -y @modelcontextprotocol/server-github
```

Note: the official `gh extension install` flow is in beta on Windows. The npm server above is the portable option.

## HTTP / OAuth gateway MCPs

CLI-added gateways. The first tool call opens a browser; the gateway holds the refresh token.

### 7. notion

- **Summary**: read and write pages, databases, comments, views.
- **Used by**: `/log-todo`, `/notion-log`, `/notion-meeting-notes`, `/capture`, `/daily-brief`, `/task-pulse`.
- **Secrets**: none stored locally; OAuth handled by the Notion MCP gateway.

```powershell
# Windows
claude mcp add notion --transport http https://mcp.notion.com/mcp
```

```bash
# macOS / Linux
claude mcp add notion --transport http https://mcp.notion.com/mcp
```

On first tool call the CLI opens a browser; sign in, pick the workspace, allow the integration. See [notion-setup.md](notion-setup.md) for the workspace structure the skills expect.

## claude.ai web-portal connectors (OAuth, browser-based setup)

A second OAuth path: connectors hosted in Anthropic's claude.ai catalog. These are added from the browser at the claude.ai settings page (URL drifts; navigate from Settings → Connectors). The same Claude account that powers Claude Code sees them, so any connector you turn on in the web portal also appears as `mcp__claude_ai_<Provider>__<action>` tools inside Claude Code.

**Why use them.** No `claude mcp add` command, no env vars, no local binary to maintain. OAuth tokens refresh automatically inside the gateway. The trade-off: you can only enable what Anthropic has approved into the catalog — arbitrary third-party HTTP MCPs still need CLI-added gateways or stdio installs.

**How they show up.** Once connected in the web portal, `claude mcp list` lists them alongside locally-configured MCPs (you may need to restart the Claude Code session). Tools appear with the prefix `mcp__claude_ai_<Provider>__<action>` — e.g., `mcp__claude_ai_Gmail__create_draft`, `mcp__claude_ai_Hugging_Face__paper_search`.

**Connector status callout.** The catalog evolves: Anthropic adds and retires connectors over time. The table below reflects what was available as of this writing; check the live catalog from the claude.ai Settings → Connectors page for the current set. If a connector is greyed out under a Pro subscription, it may require a different plan tier or an institutional admin to enable.

### Per-connector summary

| Connector | What it does | Why useful for an academic workflow | Typical OAuth scopes | Skill that uses it |
|---|---|---|---|---|
| **Gmail** | Read/triage emails, create drafts, manage labels and threads. | Turn advisor or co-author emails into Notion tasks; draft R&R cover letters; surface paper-request emails. | `mail.read`, `mail.compose`, `labels.modify` | Planned `/email-triage` (see [future-work.md](future-work.md)); ad-hoc during `/log-todo` when reading off an email screenshot. |
| **Google Drive** | Search and read Drive files and folders; fetch metadata and permissions. | Pull a co-author's draft from a shared folder; archive a project that lives in Drive; export meeting-notes PDFs. | `drive.readonly` (typically) | `/cite` occasionally (PDFs in Drive); manual reference lookups. |
| **Hugging Face** | Search models, datasets, papers, spaces; fetch docs; hub queries. | Locate a dataset for replication; read a model card before citing; track new GAN / SAE / LLM releases. | `read` (anonymous works for most queries) | `/litreview` when the query touches an ML topic. |
| **Microsoft 365** | Outlook mail, calendar, Teams, OneDrive. | Would be useful for calendar ingest and mail triage, but commonly blocked. See caveat below. | Tenant-defined; usually requires admin consent | None — commonly blocked. |
| **Scholar Gateway** | Authentication bridge that lets MCPs reach paywalled content through institutional access where available. | `/cite`, `/bibcheck`, `/litreview` when papers behind paywalls need verification. | Institutional login-token passthrough | `/cite`, `/bibcheck`, `/litreview` (best-effort). |
| **Resy** | Restaurant reservations. | Lifestyle. `/log-todo` "book dinner with collaborator" entries. | Account-bound | None. |
| **StubHub** | Event tickets. | Lifestyle / conference-trip planning. | Account-bound | None. |
| **Booking.com** | Accommodations search. | Conference-trip booking. | Anonymous read for search | None. |
| **Expedia** | Flights and hotels search. | Conference-trip booking. | Anonymous read for search | None. |
| **Tripadvisor** | Hotel search, details, comparison. | Conference-trip planning. | Anonymous read | None. |
| **Trivago** | Accommodation search and suggestions. | Conference-trip planning. | Anonymous read | None. |

**Microsoft 365 caveat.** Many university tenants (Yale and others) block this connector at the admin level. The OAuth consent screen returns `AADSTS65001` ("tenant admin consent required") and never completes. There is no end-user workaround. Substitute: publish your Outlook calendar as a secret iCal URL and forward Outlook mail to a personal Gmail, then pair with the Gmail connector — see [outlook-gmail.md](outlook-gmail.md).

**Scholar Gateway caveat.** The gateway is only as useful as your institutional subscriptions. Papers your library does not license still return nothing; the gateway is not a paywall bypass.

**Lifestyle / travel connectors.** The Resy / StubHub / Booking.com / Expedia / Tripadvisor / Trivago set are not academic, but they make `/log-todo`-style "find me a flight to the conference" entries usable from a single chat. Treat them as optional; this list will go stale as Anthropic adjusts the catalog.

## Web-portal connector setup, step-by-step

Generic OAuth flow. Same shape for every connector in the catalog.

1. Sign into `claude.ai` with the same account you use for Claude Code. (Pro or Max subscription may gate some connectors; Anthropic adjusts which ones over time — check the catalog page.)
2. Open Settings → Connectors. The exact URL drifts; navigate from the settings menu rather than memorizing it.
3. Browse the catalog; click "Connect" on any connector.
4. A browser tab opens for the provider's OAuth flow (Google, Microsoft, Hugging Face, etc.). Sign in to that provider, review the scopes, click "Allow".
5. Return to claude.ai. The connector now shows as "Connected".
6. In Claude Code, run `claude mcp list`. The new connector should appear with the `mcp__claude_ai_<Provider>__` tool prefix. If it does not, restart the Claude Code session and re-run.
7. To revoke: same settings page, click "Disconnect". Tokens are dropped on Anthropic's side; nothing local to clean up.

## Blocked / institutional MCPs

### Microsoft 365 (Outlook + Teams)

Many universities lock down M365 tenant-level OAuth so the Anthropic connector cannot authenticate at all — the consent screen shows "admin approval required" and never returns. There is no end-user workaround if your IT department has not approved third-party OAuth apps.

Recommended substitute: publish your Outlook calendar as a secret iCal link and parse it locally (see [outlook-gmail.md](outlook-gmail.md)). For email, forward institutional mail to a personal Gmail and pair with the Gmail connector in claude.ai.

## Sanity check

After all of the above:

```bash
claude mcp list
```

Expected output: a list with status `connected` for `arxiv`, `semantic-scholar`, `openalex`, `zotero`, `playwright`, `github`, `notion`. Any claude.ai web-portal connectors you have enabled (Gmail, Google Drive, Hugging Face, Scholar Gateway, etc.) appear as additional rows once you have signed into claude.ai in the browser.

If anything fails on Windows with a "path not found" error, the Node launch path workaround in [platforms.md](platforms.md) is the first thing to check.

## Token refresh procedures

A reminder of how each secret is renewed.

| MCP | Renewal procedure |
|---|---|
| `arxiv` | None — public API. |
| `semantic-scholar` | If you set an API key, request a new one at the Semantic Scholar API portal; otherwise none. |
| `openalex` | None — the "key" is just your email; change it by updating the env var. |
| `zotero` | `https://www.zotero.org/settings/keys` → revoke and reissue. Update env vars and re-run `claude mcp list`. |
| `playwright` | None — local browser. To upgrade the browser binary: `npx playwright install chromium`. |
| `github` | `gh auth refresh -h github.com -s repo,read:org` to expand scopes; otherwise rotate via `gh auth logout` + `gh auth login`. |
| `notion` | OAuth refresh happens automatically via the gateway. To force re-consent: `claude mcp remove notion` then re-add. |
| claude.ai web-portal connectors (Gmail, Google Drive, Hugging Face, Scholar Gateway, lifestyle set) | Tokens refresh automatically inside the Anthropic gateway. To force re-consent: claude.ai Settings → Connectors → Disconnect → Connect. |

## Editing `~/.claude.json` directly

For most cases `claude mcp add` is enough. If you do need to edit the file directly (debugging, scripted setup), here's the canonical location.

| OS | Path |
|---|---|
| Windows | `%USERPROFILE%\.claude.json` |
| macOS / Linux | `~/.claude.json` |

The file is JSON with a top-level `mcpServers` map. Each entry has `command`, `args`, and optional `env`. After editing, restart any running Claude session.

If the JSON is malformed, the CLI refuses to start with a parse error pointing at the byte offset — usually a trailing comma or an unescaped backslash in a Windows path. Use forward slashes in paths to avoid the second.
