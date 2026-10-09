# Current architecture

The authoritative game is the **parent project** at C:\04 Programming Language Lua, using Lua 5.1/LuaJIT and LÖVE 11.5. The earlier sari-sari-tindahan skeleton was archived and removed during the authorized cleanup; it is not part of the runtime. No SQL server is used.

The existing src, data, tests, and tools structure is retained for the presentation deadline. A large file-layout migration is deferred. Old workbench compatibility paths remain until they can be removed with caller/test verification.

## Responsibilities and dependency direction

**data -> model -> systems -> commands -> views/UI -> app -> main**

| Location | Responsibility |
|---|---|
| data/ | Product catalog, ten-day/cumulative unlock definitions, tuning, config, navigation, and assets |
| src/model/ | Plain run state, cloning, and numeric/data validation |
| src/systems/ | Inventory, FIFO costing, orders, day flow, retail, portions, TindaPay, payment, reports, and restock rules |
| src/commands.lua | Named mutation gateway for player actions; errors/history |
| src/persistence/ | Strict schema, data-only encoding, verified temporary writes, backup rotation/recovery |
| src/ui/ | Read-only display models, layout, widgets, theme, assets, drawing helpers |
| src/views/ | Screens that render models and delegate actions; no independent economic rules |
| src/app.lua, src/app/ | Input lifetime, navigation, UI state, command delegation, simulation scheduling, save feedback |
| main.lua, conf.lua | LÖVE callbacks, runtime configuration, diagnostic entry points |
| tests/, tools/ | Regressions, smoke fixtures/checks, asset checks, local packaging |

Systems do not import views, app, or graphics. Persistence validates domain data but does not render it. Views query state and delegate economic mutations through app commands. The app also schedules the domain day update once per frame. Held controls, hover, tickets, and preview selection stay outside persisted economic state.

## Transaction boundary

Money is **integer centavos**, receipt amounts are whole pesos, and stock uses integer pieces, grams, or milliliters. Prices and targets are frozen when the order line is created. Random orders use current cumulative unlocks; tender is chosen only after the basket is final.

An unfinished sale reserves stock and stages tender. Confirmation validates and publishes stock, actual drawer pieces, wallet movements, ledger, history, and completed references together. A completed reference prevents duplicate commits. Cancel/timeout releases reservations and staged tender. TindaPay principal and fees remain distinct; transfers are verified before their lines are staged.

Measured service portions use daily tolerance bounds. The shared hold controller supplies integer fill amounts; systems own reservations, FIFO waste, spill costs, and reset rules. P10/P20 conversion uses the frozen price while retaining the quoted peso amount.

## Day and save lifecycle

Ten teaching days lead into endless play. data/levels.lua returns cumulative unlocks. Day 2 spotlights cash_in and cash_out. Loading and preparing a new day refresh the active profile. Reports separate revenue/fees/tips, inventory costs, and losses. Daily goal misses do not by themselves lose the run.

A save contains plain acyclic data, not code, functions, graphics objects, or callbacks. Active retail/reservations cannot be checkpointed. Writes are encoded, validated, verified in a temporary file, and promoted while preserving the last-good backup. A malformed primary can fall back to that backup with a visible warning.

Source checkpoints are in the parent saves/ folder; packaged checkpoints are beside Tindahan.love. Failed autosaves warn without replaying a purchase or rolling back a completed in-memory action; Save shop retries. Next morning does not advance after a failed checkpoint.

## Verification and release

Source tests and smoke checks are developer-only. Diagnostic smoke uses isolated storage so it cannot overwrite player checkpoints. tools/build.ps1 creates a fresh runtime-only .love and launcher, preserving existing release folders. The package requires an installed LÖVE 11.5.

Use [the readiness report](presentation-readiness/REPORT.md) for actual outputs, checked screenshots, independent review, exact release path, and unverified items. Automated checks are not a complete human playthrough.
