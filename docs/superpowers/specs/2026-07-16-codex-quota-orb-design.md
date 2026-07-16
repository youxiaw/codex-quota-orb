# Codex Quota Orb Design

## Goal

Build a macOS desktop utility that keeps Codex quota visible without opening Codex or ChatGPT settings. The app starts as a small floating orb. Clicking the orb opens a compact glass-style panel with current quota windows and a recent usage curve.

## Data Source

The app reads quota through the local Codex runtime, not through ChatGPT web scraping.

It launches the trusted local `codex` executable in `app-server` mode over stdio, performs the JSON-RPC handshake, and calls:

```text
initialize -> initialized -> account/rateLimits/read
```

Supported response shapes:

- `result.rateLimits.primary` / `result.rateLimits.secondary`
- `result.rateLimitsByLimitId.codex.primary` / `secondary`

Each quota window is accepted only when `usedPercent` is in `0..100`. Remaining percentage is computed as `100 - usedPercent`. `windowDurationMins == 300` is treated as the 5-hour window and `10080` as the weekly window.

The app does not read `auth.json`, browser cookies, chat content, or process memory.

## Product Surface

The first screen is the floating orb:

- Always-on-top frameless AppKit window.
- Draggable and position-persistent.
- Color changes by the most constrained quota window.
- Left click toggles the detail panel.
- Right click opens refresh and quit actions. Launch-at-login is documented as a future enhancement rather than part of the MVP.

The detail panel includes:

- 5-hour and weekly quota cards.
- Reset time labels.
- Last refresh status.
- A line chart of locally sampled remaining percentage.

## Architecture

- `CodexQuotaProvider`: resolves and launches the local Codex runtime, sends JSON-RPC, parses rate-limit windows.
- `QuotaHistoryStore`: persists timestamped samples in SQLite under Application Support.
- `QuotaState`: observable app state for the UI.
- `OrbWindowController`: owns the floating orb window.
- `DetailPanelController`: owns the expanded chart panel.
- `SettingsStore`: saves orb position and basic preferences.

The implementation uses Swift, SwiftUI, AppKit, Foundation, and SQLite through the system `sqlite3` library. No third-party package is required for the MVP.

## Error Handling

If Codex is missing, not logged in, or returns no quota windows, the orb shows a neutral unavailable state and the panel shows the exact status. If refresh fails after previous success, the UI keeps the previous sample but marks it stale.

Network access is never requested directly by this app; Codex runtime owns any authenticated quota lookup it performs internally.

## Testing

Core parsing is covered with unit tests using fixture JSON for both known response shapes. Provider integration remains manual because it depends on the user's local Codex installation and login state.

## GitHub Delivery

The project will be committed locally and pushed to a new GitHub repository after verification. The README will document the privacy boundary, build commands, and the fact that this is an independent local utility.
