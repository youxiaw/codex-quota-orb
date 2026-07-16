#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

swiftc \
  Sources/CodexQuotaOrb/QuotaModels.swift \
  Sources/CodexQuotaOrb/CodexRateLimitParser.swift \
  Tests/ParserTests/main.swift \
  -o /tmp/codex-quota-parser-tests
/tmp/codex-quota-parser-tests

swiftc \
  Sources/CodexQuotaOrb/QuotaModels.swift \
  Sources/CodexQuotaOrb/CodexRateLimitParser.swift \
  Sources/CodexQuotaOrb/CodexRPCClient.swift \
  Tests/RPCTests/main.swift \
  -o /tmp/codex-quota-rpc-tests
/tmp/codex-quota-rpc-tests

swiftc \
  Sources/CodexQuotaOrb/QuotaModels.swift \
  Sources/CodexQuotaOrb/QuotaHistoryStore.swift \
  Tests/HistoryTests/main.swift \
  -lsqlite3 \
  -o /tmp/codex-quota-history-tests
/tmp/codex-quota-history-tests

echo "All tests passed"
