# Telegram bot setup

The daily brief and capture flow use a personal Telegram bot to send the morning task list and receive replies like `1 done` or `add: review draft`. This doc covers setup and — critically — how to handle the bot token without leaking it.

The bot token is the only true secret in this whole workflow. Treat it like a password. It MUST NOT appear in `personal_config.json`, in this repo, in any committed file, or in any chat transcript.

## 1. Create the bot

1. Open Telegram (mobile or desktop).
2. Search for `@BotFather` and start a chat.
3. Send `/newbot`.
4. Reply with a display name (e.g., "My Daily Brief").
5. Reply with a handle ending in `bot` (e.g., `<your-bot-handle>`).
6. BotFather returns a token in the form `<numeric>:<35-char-blob>`. Save it to a password manager. Do not paste it anywhere else yet.

## 2. Get your chat ID

The bot can't message you until you message it first.

1. From your personal Telegram account, send any message to the new bot (e.g., "hello").
2. Open this URL in a browser, substituting your token: `https://api.telegram.org/bot<TOKEN>/getUpdates`
3. In the JSON response, find `result[0].message.chat.id`. It's a ~10-digit integer.
4. Record this number — it goes in `personal_config.json` (not a secret on its own).

## 3. Where the values go

| Value | Sensitivity | Storage |
|---|---|---|
| `chat_id` (10-digit int) | not a secret by itself | `~/.claude/state/personal_config.json` under `telegram.chat_id` |
| `bot_handle` (e.g., `<your-bot-handle>`) | public | same file, `telegram.bot_handle` |
| `bot_token` (`<numeric>:<blob>`) | **SECRET** | **Never** on disk. Use `gh secret set TELEGRAM_BOT_TOKEN` for the orchestration repo; optionally a local env var for ad-hoc testing |

### Pattern A — token in the cloud-routine config

If you run the cloud-routine orchestration ([../orchestration/README.md](../orchestration/README.md), Pattern A), there is no GitHub Actions layer: the routine itself calls the Bot API with `curl`, and the token is pasted into the routine's configuration on claude.ai. It is then visible only inside your own claude.ai account. The same rules apply — never in this repo, never in `personal_config.json` — plus one more: **treat routine exports and screenshots as sensitive**, since the routine body contains the token verbatim. Rotate via BotFather `/revoke` if a routine definition ever leaks.

### Setting the token as a GitHub Actions secret (Pattern B)

The orchestration repo (`lan-daily-brief` or your fork) runs the actual cron. From your fork's working directory:

```powershell
# Windows
gh secret set TELEGRAM_BOT_TOKEN
# Paste the token when prompted
```

```bash
# macOS / Linux
gh secret set TELEGRAM_BOT_TOKEN
```

This stores the token encrypted on GitHub; it is exposed to workflow runs as `${{ secrets.TELEGRAM_BOT_TOKEN }}` and never written to disk on your machine.

### Setting the token locally (only if you also run capture locally)

```powershell
# Windows PowerShell
setx TELEGRAM_BOT_TOKEN "<your-token>"
# Open a NEW shell after setx; the current session won't see the change
```

```bash
# macOS / Linux
echo 'export TELEGRAM_BOT_TOKEN="<your-token>"' >> ~/.zshrc
exec zsh
```

## 4. Test send

Confirm the bot can reach you. The token comes from the env var; never inline it.

```powershell
# Windows PowerShell
Invoke-RestMethod -Method Post `
  -Uri "https://api.telegram.org/bot$env:TELEGRAM_BOT_TOKEN/sendMessage" `
  -Body @{ chat_id = "<your-chat-id>"; text = "hello from setup" }
```

```bash
# macOS / Linux
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
  -d "chat_id=<your-chat-id>&text=hello from setup"
```

You should see the message arrive in Telegram within a couple seconds.

## 5. If you accidentally commit the token

Treat it as fully compromised — Telegram's `getUpdates` accepts any caller with the token, so anyone scraping public repos can hijack your bot.

1. Open BotFather, send `/revoke`, pick the bot, generate a new token.
2. Update `gh secret set TELEGRAM_BOT_TOKEN` with the new value.
3. Update any local env var (`setx` / `~/.zshrc`).
4. Force-rewrite the leaky commit out of git history if it was pushed:
   ```bash
   git filter-repo --replace-text <(echo "<old-token>==>REDACTED")
   git push --force
   ```
   (Force-push only after confirming the secret is rotated; otherwise you're just hiding the problem.)

## 6. Capture flow — where the bot fits

The capture path is owned by the orchestration layer, not by this skill repo. Under Pattern A, an hourly cloud routine polls `getUpdates`, parses the capture grammar, and writes to Notion — see [../orchestration/README.md](../orchestration/README.md). The legacy Pattern B flow:

- `lan-daily-brief` GitHub Actions cron runs every 30 minutes during waking hours.
- It calls Telegram `getUpdates`, parses each reply against the grammar (`<N> done`, `<N> push <day>`, `<N> drop`, `add: <text>`, free-form), and writes results to your Notion Tasks DB.
- A separate cron at your local morning time runs `/daily-brief`, pushes the formatted list, and persists `today_brief.json` so the capture cron can resolve `1 done` numerically.

Repo: see the `lan-daily-brief` README for the full GitHub Actions wiring.
