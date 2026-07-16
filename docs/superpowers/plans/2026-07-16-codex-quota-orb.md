# Codex Quota Orb Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS floating orb app that reads local Codex quota via `account/rateLimits/read` and shows current quota plus a history curve.

**Architecture:** A Swift Package executable owns AppKit windows, SwiftUI views, a Codex JSON-RPC provider, a SQLite history store, and app state. The quota provider has pure parsing tests and the UI consumes a single observable `QuotaState`.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, Foundation, XCTest, system `sqlite3`, local Codex runtime.

## Global Constraints

- Platform: macOS 13 or newer.
- Data source: local Codex `app-server` JSON-RPC `account/rateLimits/read`.
- Privacy: do not read `auth.json`, browser cookies, chat content, or process memory.
- Dependencies: no third-party package for MVP.
- Display: floating orb first; click opens detail panel with quota cards and a line chart.

---

### Task 1: Package, Domain Models, and Parser

**Files:**
- Create: `Package.swift`
- Create: `Sources/CodexQuotaOrb/QuotaModels.swift`
- Create: `Sources/CodexQuotaOrb/CodexRateLimitParser.swift`
- Create: `Tests/CodexQuotaOrbTests/CodexRateLimitParserTests.swift`

**Interfaces:**
- Produces: `QuotaWindow`, `QuotaSnapshot`, `CodexRateLimitParser.parse(_ data: Data, now: Date) throws -> QuotaSnapshot`

- [ ] Create the Swift package and parser tests.
- [ ] Implement parser support for `result.rateLimits` and `result.rateLimitsByLimitId.codex`.
- [ ] Run `swift test`; expected result: parser tests pass.
- [ ] Commit with `feat: add quota parser`.

### Task 2: Codex RPC Provider

**Files:**
- Create: `Sources/CodexQuotaOrb/CodexExecutableResolver.swift`
- Create: `Sources/CodexQuotaOrb/CodexRPCClient.swift`
- Create: `Sources/CodexQuotaOrb/CodexQuotaProvider.swift`
- Create: `Tests/CodexQuotaOrbTests/CodexRPCClientTests.swift`

**Interfaces:**
- Consumes: `CodexRateLimitParser.parse`
- Produces: `CodexQuotaProvider.fetch() async throws -> QuotaSnapshot`

- [ ] Add a test transport that returns JSON-RPC fixture lines.
- [ ] Implement JSON-RPC handshake: `initialize`, `initialized`, `account/rateLimits/read`.
- [ ] Resolve Codex from `/Applications/ChatGPT.app/Contents/Resources/codex`, `PATH`, and common user binary locations.
- [ ] Run `swift test`; expected result: parser and RPC tests pass.
- [ ] Commit with `feat: read codex rate limits`.

### Task 3: History Store and App State

**Files:**
- Create: `Sources/CodexQuotaOrb/QuotaHistoryStore.swift`
- Create: `Sources/CodexQuotaOrb/QuotaState.swift`
- Create: `Tests/CodexQuotaOrbTests/QuotaHistoryStoreTests.swift`

**Interfaces:**
- Consumes: `QuotaSnapshot`
- Produces: `QuotaHistoryStore.save(_:)`, `QuotaHistoryStore.recentSamples(limit:)`, `QuotaState.refresh()`

- [ ] Add SQLite-backed sample storage under Application Support.
- [ ] Store timestamp, five-hour remaining, weekly remaining, and reset timestamps.
- [ ] Implement `QuotaState` refresh, stale status, and error status.
- [ ] Run `swift test`; expected result: all tests pass.
- [ ] Commit with `feat: persist quota history`.

### Task 4: Floating Orb and Detail Panel

**Files:**
- Create: `Sources/CodexQuotaOrb/CodexQuotaOrbApp.swift`
- Create: `Sources/CodexQuotaOrb/AppDelegate.swift`
- Create: `Sources/CodexQuotaOrb/OrbWindowController.swift`
- Create: `Sources/CodexQuotaOrb/OrbView.swift`
- Create: `Sources/CodexQuotaOrb/DetailPanelController.swift`
- Create: `Sources/CodexQuotaOrb/DetailPanelView.swift`
- Create: `Sources/CodexQuotaOrb/QuotaLineChartView.swift`

**Interfaces:**
- Consumes: `QuotaState`
- Produces: working macOS executable `CodexQuotaOrb`

- [ ] Build a transparent always-on-top orb window.
- [ ] Add drag persistence and click-to-toggle detail panel.
- [ ] Render glass-style orb, quota cards, reset labels, and line chart.
- [ ] Add right-click menu: refresh and quit.
- [ ] Run `swift build`; expected result: build succeeds.
- [ ] Commit with `feat: add floating quota orb ui`.

### Task 5: README, Verification, and GitHub Publish

**Files:**
- Create: `README.md`
- Create: `.gitignore`
- Modify: existing project files as needed for verification fixes.

**Interfaces:**
- Consumes: completed app and tests
- Produces: local commit and pushed GitHub repository

- [ ] Document build, run, privacy boundary, data source, and known limitations.
- [ ] Run `swift test` and `swift build`.
- [ ] Commit with `docs: document codex quota orb`.
- [ ] Create a GitHub repository and push the branch.
