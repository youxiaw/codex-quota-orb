# Codex Quota Orb

Codex Quota Orb is a local-first macOS desktop utility for keeping Codex quota visible while you work. It starts as a small floating glass orb. Click the orb to open a compact panel with quota cards and a recent trend curve.

## Features

- Floating always-on-top orb for quick quota visibility.
- Click-to-open detail panel with 5-hour and weekly quota windows.
- Local history curve backed by SQLite.
- Reads quota through the local Codex runtime JSON-RPC method `account/rateLimits/read`.
- Does not read `auth.json`, browser cookies, chat content, or process memory.
- No third-party dependencies.

## Data Source

The app launches the trusted local Codex executable in `app-server` mode and talks to it over stdio:

```text
initialize -> initialized -> account/rateLimits/read
```

It accepts these response shapes:

- `result.rateLimits.primary` / `result.rateLimits.secondary`
- `result.rateLimitsByLimitId.codex.primary` / `secondary`

`usedPercent` is converted to remaining quota with:

```text
remainingPercent = 100 - usedPercent
```

`windowDurationMins == 300` is treated as the 5-hour window. `windowDurationMins == 10080` is treated as the weekly window.

## Requirements

- macOS 13 or newer
- Swift toolchain / Xcode Command Line Tools
- Installed and logged-in Codex runtime, usually from the ChatGPT desktop app or Codex CLI

## Build

```bash
swift build
```

Run from the build output:

```bash
.build/debug/CodexQuotaOrb
```

Build a simple `.app` bundle:

```bash
bash scripts/package-app.sh
open "dist/Codex Quota Orb.app"
```

## Test

The project uses lightweight self-contained test executables because some Command Line Tools installations do not ship `XCTest` or Swift `Testing`.

```bash
bash scripts/run-tests.sh
```

## Privacy

Codex Quota Orb is independent and is not affiliated with or endorsed by OpenAI. It does not call ChatGPT web backend endpoints directly. It does not store tokens, account IDs, prompts, source code, or conversations. It stores only local quota samples and UI position data on your Mac.

Quota history is stored under:

```text
~/Library/Application Support/CodexQuotaOrb/history.sqlite
```

## Limitations

- The app depends on the local Codex runtime exposing `account/rateLimits/read`.
- If Codex is not installed, not logged in, or changes the local RPC response shape, the orb will show an unavailable or stale state.
- Launch at login and signed release packaging are intentionally outside the MVP.
