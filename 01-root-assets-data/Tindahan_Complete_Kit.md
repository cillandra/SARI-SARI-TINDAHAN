# Tindahan Complete Kit: from zero to finished game

A cozy 2D sari-sari store simulator in Lua + LÖVE 11.5 for Windows. Contents: **Part A** the step-by-step roadmap, **Part B** all the prompts in the order you use them.

> Honest note: no prompt or AI can guarantee a game with zero bugs. This kit makes the AI write tests first, run them, and report exactly what it checked. Your job is to play each stage and say "continue" only when it works.

---

# PART A: ROADMAP (START TO FINISH)

## Stage 0: Install the tools (one time)

1. **LÖVE 11.5**: download from love2d.org (64-bit installer). Default path `C:\Program Files\LOVE\`. Check in a terminal: `"C:\Program Files\LOVE\lovec.exe" --version`.
2. **VS Code** with the extensions *Lua* (sumneko) and *StyLua* (code formatter).
3. **A coding AI that can read/write files and run commands** in your folder (for example Claude Code, Cursor, or similar). A plain chat window is not enough for a 40+ file project.
4. **Krita** (free) for cleaning and exporting art. Optional: **Git** (`git init` gives you save points) and **luacheck**.
5. Create the project folder `C:\04 Programming Language Lua` and the subfolders `docs`, `docs\mockups`, `assets`.

## Stage 1: Give the AI everything it needs

1. Copy **Prompt 1, Prompt 2 and Prompt 3** (Part B) into one file: `C:\04 Programming Language Lua\docs\BRIEF.md`.
2. Put your written spec and implementation plan into `docs\` too.
3. Take a screenshot of each mockup board (Counter, Shelves, Sukli, Bigas, Tingi, Utang, Phone) and save them in `docs\mockups\`. Also save your inspiration screenshots there.
4. Open your AI in `C:\04 Programming Language Lua` and send this first message:

   > Read docs/BRIEF.md and every file in docs/. Do NOT write code yet. Do the AUDIT described in Prompt 1 section 0 and tell me the state of every task. Then wait.

## Stage 2: Build, one task at a time (the main loop)

Repeat for Tasks 1 to 9 (listed in Prompt 1):

1. Tell the AI: **"Do Task N from docs/BRIEF.md. Tests first. Stop when finished."**
2. It writes the tests, makes them fail, writes the code, and runs `lovec.exe "C:\04 Programming Language Lua" --test`.
3. **You** launch the game (`Play Tindahan.bat`) and try what that task added (use the checklist in Stage 6).
4. If anything is wrong, paste the **exact error text or a screenshot** and the file name. Do not paraphrase.
5. Only when it works: make a backup (zip the folder, or `git commit`) and say **"continue"**.

## Stage 3: Art in parallel (do not wait for the code)

1. Use **Prompt 4** to generate assets with an image AI, or draw them in Krita.
2. Export as PNG-24 with transparency, at **2x** the design size, named by the manifest ID (for example `prop_phone.png`).
3. Put them in `assets\img\{scene,prop,char,icon,ui,fx}`.
4. Run `lovec.exe "C:\04 Programming Language Lua" --check-assets` and fix every warning. The game still runs without art (labeled placeholders), so you can add art any time.

## Stage 4: Independent review (after Task 6 or 7, and again at the end)

Paste **Prompt 5** into a NEW chat or agent session (a fresh session reviews more honestly than the one that wrote the code). Apply the actionable fixes through the building AI, then rerun all tests.

## Stage 5: Playtest and balance

Use **Prompt 6**. Play Days 1 to 11 yourself, write down what felt unfair or boring, and let the AI tune the numbers in `data/tuning.lua` (never in code).

## Stage 6: What you check yourself (the "does it really work" list)

- [ ] The game starts, and **Continue** resumes with identical cash, wallet, stock.
- [ ] Day 1: serve customers with the counter, shelves, sukli. Wrong change causes a complaint.
- [ ] Weigh rice and repack oil/sugar; underfilled bags cannot be sold.
- [ ] Day 4 cash-in and Day 6 cash-out: wrong recipient/amount/reference are rejected and no money changes.
- [ ] Double-click everything: money and stock never duplicate.
- [ ] Wait until a customer's patience runs out in every view: the customer leaves, nothing is stuck.
- [ ] Resize the window (small, large, full screen): text stays sharp, clicks still land correctly.
- [ ] Escape pauses everything.
- [ ] Play through Day 10 into Day 11 without a crash.
- [ ] Close the game mid-day, reopen: nothing corrupted. Delete the save file by hand: the game offers a new run.

## Stage 7: Package and share

1. **Make the .love file:** zip the *contents* of `C:\04 Programming Language Lua` (so `main.lua` is at the top of the zip, not inside a folder), exclude `docs`, `tests`, `tools`, `.git`, and rename the zip to `Tindahan.love`. Test it by dragging it onto `love.exe`.
2. **Make a standalone .exe (optional):** in a terminal in the LÖVE install folder: `copy /b love.exe+Tindahan.love Tindahan.exe`. Copy `Tindahan.exe` together with all the `.dll` files and `license.txt` from the LÖVE folder into a new folder, then zip that folder.
3. Test it on a PC (or a clean folder) that has **no** LÖVE installed.
4. Share the zip (for example on itch.io). Include README controls and the note that the digital wallet is fictional.

## Troubleshooting

| Problem | What to do |
| --- | --- |
| The AI skips ahead or rewrites everything | Say: "Stop. Follow docs/BRIEF.md. Only Task N. Preserve existing files." |
| The AI shortens files with "..." | Say: "Give the COMPLETE file. No snippets, no placeholders." |
| The game crashes | Paste the **exact** error and the file. Ask for a fix **plus a test** that would have caught it. |
| Blurry text or images | Re-read Prompt 2 section 1; run the asset checker; check for any image scaled over 1.25x. |
| An AI "claims" it works but it does not | Ask: "Show the exact command you ran and its output." |
| Context gets too long, the AI forgets rules | Start a new session and begin with Stage 1 step 4 again. The rules live in `docs/BRIEF.md`. |
| Balance feels unfair | Use Prompt 6; change only `data/tuning.lua`. |

## Definition of done (version 1)

All tests pass; you can play Days 1 to 11 with the mouse only; save, quit and resume with identical balances; no duplicated money or stock from repeated clicks; no reservations left behind after timeouts; sharp visuals at 1024x768, 1280x720, 1920x1080, 2560x1440; every low-money state is recoverable; verification evidence is in `docs/reviews/verification.md`.

---

# PART B: THE PROMPTS

Order of use: **Prompts 1 + 2 + 3** together as `docs/BRIEF.md` (Stage 1) -> build tasks -> **Prompt 4** for art -> **Prompt 5** for review -> **Prompt 6** for balance and release.

---

## PROMPT 1: MASTER BUILD

````
# TINDAHAN: MASTER BUILD PROMPT

## 0. ROLE AND FIRST STEPS
You are the lead engineer on "Tindahan", a cozy, challenging sari-sari store simulator for Windows PC, written in Lua for LÖVE 11.5 (LuaJIT / Lua 5.1 syntax). Project root: C:\04 Programming Language Lua.
An earlier version may already exist. BEFORE writing code:
1. List the project folder and read README.md, docs/, data/, src/, tests/.
2. Run `lovec.exe "C:\04 Programming Language Lua" --test` and record the result and runtime version.
3. Produce an AUDIT: for each task in section 9 mark it DONE-VERIFIED, DONE-BUT-WEAK, or MISSING, with evidence (test names, files).
4. Preserve existing files. Improve and extend rather than rewrite. Do not rename public functions without listing the change and updating every caller and test.
Honesty rule: never claim something works unless you ran it. Record exact commands, assertions that passed, and what you could not check. Do not promise zero defects.
Precedence if instructions conflict: (1) money, transaction and save integrity (section 3), (2) game design (sections 4-5), (3) art and UI direction (Prompts 2 and 3). State any conflict and pick the simplest option that satisfies this order.

## 1. VISION
A cozy, 2D, counter-facing management game. The player serves neighbors, makes tingi sales (by piece or peso amount), gives exact sukli from a limited drawer, weighs rice, repacks oil, sugar and flour, grants utang to trusted suki, and handles fictional digital-wallet cash-in/cash-out. Success: a player finishes consecutive days, meets all ten daily situations, saves and resumes, and keeps playing on Day 11+. Day 10 never ends the run. Art: flat hand-painted cartoon scenes in the spirit of cozy cafe/pizza-shop management games (original designs, never copied).

## 2. TECH
- Lua 5.1/LuaJIT compatible. LÖVE 11.5. No external libraries.
- 1280x720 design canvas, scaled and letterboxed to any window; all input goes through `Layout.toCanvas(x, y, w, h) -> canvasX, canvasY, inside`.
- Mouse alone is enough to play. Keys 1-7 are optional station shortcuts. Escape pauses.
- Domain code runs headless so tests run without a window. `main.lua --test` runs tests through love.exe and exits with a matching status code. `--smoke` captures screenshots of each activity into the save directory and exits. `--check-assets` validates assets.
- Deliver: source, `Play Tindahan.bat`, `run-game.ps1` (clear install instructions if LÖVE is missing), `Tindahan.love`, README, `stylua.toml`.

## 3. NON-NEGOTIABLE INVARIANTS
1. Money is integer centavos; weight integer grams; volume integer milliliters. No float currency. Pesos exist only in display and the price-entry field.
2. Commands return `true` or `nil, "player-readable error"`. Queries never mutate state. Assert integer money and non-negative stock at command boundaries.
3. A transaction commits EXACTLY ONCE. Repeated clicks, reused reference IDs or re-issued confirms change nothing.
4. Stock reserved for an active basket cannot be sold twice. Cancel/timeout returns intact packaged items. Opened portions return only when safe; otherwise their cost is recorded as spoilage.
5. Tendered cash, selected change and wallet payouts are STAGED and applied atomically at final confirmation. Timeout, cancel or brownout releases every staged item and reservation. Funds never vanish.
6. The player chooses change from the drawer's ACTUAL denomination counts. The UI shows amount due and tender, never the computed change. Short change requires correction; excess change is recorded as a loss.
7. Inventory is FIFO batches with recorded cost. Sales recognize actual batch cost. A quoted basket keeps its quoted prices.
8. One simulation update runs regardless of the open view. Patience falls in every view. Escape pauses the entire simulation. Preparation and reports are untimed.
9. All randomness comes from a stored seed.
10. Saves are DATA parsed by a strict codec, never executed as Lua. Write to a temp file, verify, then replace while keeping the last good backup. Corrupt or unsupported-version saves give a readable error and offer backup recovery or a new game. Never persist renderer objects, functions or incomplete transactions.
11. The game never reaches an unusable state. If cash, stock and wallet cannot continue, show recovery: "restart this day from its morning snapshot" or "new run". This works even when the only money left is in the wallet.
12. Views issue commands and render state. They never duplicate economic rules.

## 4. DAILY LOOP
Morning preparation (untimed) -> open store -> about 8 minutes of service (configurable) -> arrivals stop at closing -> remaining customers finished or lost -> close and review (untimed) -> auto-save -> next morning.
Preparation: buy wholesale stock, set prices, exchange coins/bills, prepack portions, move money between drawer and wallet at a disclosed conversion charge (concrete denomination bundles shown; combined balances preserved except the charge; unavailable during service), buy ice, read tutorial hints (hints only here).
Report: revenue, cost of goods, operating costs, spoilage, change losses, unpaid credit, abandoned customers, cash, wallet, reputation. Cash flow and profit are separate. Service fees are separate from wallet transfers (a transfer moves assets; only the fee is income). Persisting: inventory batches, drawer, wallet, reputation, customer relationships, debts, completed references.

## 5. GAME CONTENT
### 5.1 Catalog: exactly 36 fictional products, all buyable on Day 1
Data in data/products.lua: id, name, category, icon key, stock unit, sale unit, cost and price (centavos, margins roughly 15-35%), shelf life, portion sizes, demand-by-day path, unlock rules, and `cabinet = {section, slot}`. Original names, no real brands. Starting stock covers a manageable subset; cash limits purchasing. Every product appears in demand by Day 10.
- Staples and loose goods (7): regular rice, premium rice, cooking oil, sugar, salt, flour, mongo beans.
- Noodles and canned (7): pancit canton, soup noodles, sardines, tuna, corned beef, meat loaf, canned beans.
- Snacks and sweets (6): candy, chewing gum, crackers, biscuits, chips, peanuts.
- Drinks and sachets (7): bottled water, cola, orange soda, powdered juice, instant coffee, coffee mix, powdered milk.
- Household and toiletries (6): shampoo, conditioner, bath soap, toothpaste, detergent, dishwashing (sachets except soap).
- Everyday essentials (3): eggs, candles, matches.
Bulk goods (rice, oil, sugar, flour, salt, mongo beans) sell by measured portions (g/ml or peso value). Sachets, candy, gum, eggs, packaged goods sell by piece. Cold drinks have a defined brownout loss rule. Orders have 1-3 lines, generated only from enabled products and valid portion sizes.
### 5.2 Customers
Archetypes vary by order size, patience, tender, loyalty, credit eligibility (kid, nanay, tambay, suki, haggler, hurried). Named suki have relationships that grow with good service and decay with bad. Finite queue (cap 6) with visual warnings; spawn intervals and patience tuned so the player can recover. Each visit is EITHER retail OR one wallet service. At zero patience the customer leaves, reservations resolve, a bounded reputation penalty applies. Reputation stays in a fixed range and scales arrival rate within a capped band.
### 5.3 Cash drawer
Denominations 1, 5, 10, 20, 50, 100, 500, 1000 pesos (stored as centavos). Tender enters the drawer when received; change comes from actual counts. If change is impossible: cancel/refund (reputation cost) or exchange denominations in preparation. Difficulty: Easy (guided), Normal, Hard (wrong change causes complaint and loss).
### 5.4 Scale and repacking
Scale: add/remove measured portions (scoops) to hit the target; requests by weight or peso value ("bente pesos na bigas"). Repacking: hold to pour, release near the amount; prepare before opening or during service. Tolerances configurable with a learnable indicator. Underfill must be corrected; overfill consumes extra stock and lowers margin. Prepacked portions are inventory batches keeping quantity and age. Logic in src/systems/portions.lua, independent of the renderer.
### 5.5 Utang
Activates Day 5. Only eligible named suki ask, up to a visible per-customer cap. Granting creates a debtor balance and does NOT add drawer cash. Repayment (with selected denominations) raises cash and lowers receivables without counting revenue twice.
### 5.6 Digital wallet (fictional, no real accounts)
Display name configurable in data/tuning.lua (default "TindaPay"). Flat fee PHP 10 per completed service, paid separately in physical cash. Wallet customers join the same queue; patience runs while the phone or drawer is open. HUD shows drawer cash and wallet separately. Show principal, fee, recipient and balances before confirmation.
- Cash-in (Day 4): reserve wallet funds BEFORE accepting tender; verify recipient and principal; confirm: wallet -= principal, drawer += principal + fee (accounting for change).
- Cash-out (Day 6): customer sends principal to the store wallet; match the incoming transaction's reference, amount and confirmed status (a screenshot is not enough); reserve a feasible denomination combination BEFORE accepting; customer pays the fee; the player selects actual denominations totaling the principal; confirm: wallet += principal, drawer -= principal, plus the fee.
- Unique reference ID per service; completed references can never be reused.
- Wrong recipient/amount, unconfirmed transfer, insufficient funds, unavailable denominations: actionable feedback and NO partial balance change. Timeout, cancel or brownout reverses pending services.
- Day 7 raises service demand. Day 9 disables wallet services during an announced outage and wallet customers don't spawn then.
- Scam events and e-load are future features.
### 5.7 Ten days, then endless
Each morning announces the situation with actionable advice; every day still has mixed ordinary orders.
1 Opening (simple orders, stocking, sukli). 2 School rush (small purchases, coins). 3 Rice and tingi (weighing and repacking frequent). 4 Barya shortage and cash-in launch (fewer starting coins; prepare denominations and wallet). 5 Utang (credit and repayment activate). 6 Supplier price increase and cash-out launch. 7 Payday (bigger baskets, debt repayments, more wallet demand). 8 Rain (altered arrivals, essentials demand). 9 Brownout (dim lighting with candle glow, cold-stock spoilage, buyable ice, wallet outage). 10 Fiesta (drink and snack rush, milestone report).
Day 11+: repeatable seeded rotation with ordinary days and CAPPED increases. No endless escalation.

## 6. ARCHITECTURE
```
main.lua (callbacks and boot only)   conf.lua   game.lua (thin loader only, optional)
src/app.lua  src/commands.lua  src/strict.lua
src/model/state.lua
src/systems/ inventory cash retail portions customers days economy debt wallet reputation
src/persistence/ codec save
src/ui/ layout theme assets fonts format widgets hotspot bubble sparkle tween zorder art cabinet_layout
src/views/ menu preparation counter shelves drawer scale repack notebook phone report recovery
data/ products customers days tuning assets
tests/ run test_catalog test_retail test_portions test_wallet test_days test_save test_layout
tools/ check_assets check_globals run_all_checks
assets/ img/{scene,prop,char,icon,ui,fx} fonts sfx music
docs/ design plan decisions controls reviews/
```
Dependency rule: data -> model -> systems -> commands -> views/ui -> app -> main. A module may only require modules to its left. systems/ never requires ui/, views/ or love.graphics. views/ contain no economic formulas.

## 7. KEY INTERFACES (extend, do not break)
State.new(seed), State.clone(state); Products.byId/list; Inventory.available/reserve/release/consume/purchase; Cash.total/canPay; Retail.begin/add/stageTender/commit/cancel; Economy.report; Portions.target/adjust/confirm/prepack; Debt.grant/repay; Wallet.begin/verify/stageCash/commit/cancel/convert; Customers.update/spawn/current; Days.prepare/open/update/close/next/retry; Codec.encode/decode; Save.write/read/exists; App:update/draw/mousepressed/mousereleased/keypressed/resize.

## 8. REQUIRED TESTS (write FIRST, watch fail, then implement)
- Catalog: exactly 36 unique products, positive integer costs/prices, valid categories/units/portions/cabinet slots (unique, max 8 per section), demand by Day 10 for each, clone independence.
- Retail: cannot reserve more than stock; cancel restores stock; cost conserved across partial batches; commit once; repeated commit changes nothing; real denominations; excess change recorded as loss; short change requires correction; recovery possible with zero cash/stock.
- Portions: peso-value rounding deterministic; underfill cannot confirm; overfill consumes real stock; prepacked keep quantity and age; discard records cost.
- Debt: cap and eligibility; repayment raises cash and lowers receivables without duplicate revenue.
- Wallet (principal 10000, fee 1000 centavos): cash-in wallet -10000, cash +11000; cash-out wallet +10000, cash -9000; combined assets +1000; fee-only revenue 1000; wrong recipient/amount, unconfirmed transfer, reused reference, insufficient balance, denomination shortage, duplicate clicks leave balances unchanged; timeout/cancel/brownout release reservations; conversion changes combined assets only by its charge; recovery with money only in the wallet.
- Days: identical seeds give identical orders; only enabled valid products; capped queue; pause stops timers; patience falls in all views; timeout releases reservations; closing stops arrivals but resolves the queue; days 1-10 match situations; day after 10 is 11; rotation doesn't escalate endlessly; outage stops wallet arrivals; morning retry restores seed and balances; deterministic accelerated simulations for Days 1-11.
- Save: round trip keeps day, seed, batches, cash, wallet, debts, history, shelf layout; corrupt/truncated data fails safely without executing; unsupported version gives a readable error; failed write preserves the old save; backup recovery works; a safe checkpoint remains after load.
- Layout: canvas center maps correctly at 1280x720, 1920x1080, 1024x768; letterbox clicks return inside=false; paused app leaves model time unchanged; repeated clicks cannot bypass guards.

## 9. TASKS (one at a time; stop and report after each; wait for "continue")
1 Data and run model. 2 Stock, cash, retail, economy. 3 Portions and utang. 4 Wallet services and reserve conversion. 5 Customers and daily progression (ten situations plus Day 11 rotation). 6 Playable cozy-scene views per Prompts 2 and 3. 7 Persistence and launch docs (codec, save, README, scripts, .love package). 8 Independent review, fixes, final verification (separate gameplay and code reviews; label findings OBSERVED or INFERRED; record dispositions in docs/reviews/). 9 Cozy polish (art pass, rain/brownout looks, sound hooks that fail silently, balance pass, readability at 1024x768 and 2560x1440).
After each task report: complete contents of every new/changed file, exact commands run with results, what could not be verified, and the next task.

## 10. DEFERRED (only after the user approves v1)
E-load and bills payment; wallet scam events; chores and cleanliness; theft and counterfeit bills; street and palengke scenes; typhoon extras, inspections, price wars; upgrades catalog; helper; special services (ice candy, street food, LPG, videoke); second branch; story endings; recurring cast story events; seasonal systems.
````

---

## PROMPT 2: GRAPHICS, UI/UX AND CLEAN STRUCTURE STANDARD

```
# GRAPHICS, UI/UX AND STRUCTURE STANDARD FOR "TINDAHAN"
Applies on top of Prompt 1. Lua, LÖVE 11.5, project root C:\04 Programming Language Lua.

## 0. NO-HALLUCINATION RULES
1. Use ONLY LÖVE 11.5 API functions you are certain exist. If unsure, say so and use a simpler known call. Never invent functions, options or modules.
2. Every image, font and sound used in code must be listed in data/assets.lua. Code never contains a raw file path outside the manifest. If a file is missing, draw a labeled placeholder in palette colors and log ONE warning. The game never crashes on a missing asset.
3. Never claim something looks right unless you captured it with `--smoke` and checked it. State what you checked and what you could not.
4. Ambiguity: pick the simplest option that satisfies the requirement and record it in docs/decisions.md.

## 1. CRISP RENDERING (NO BLUR, NO PIXELATION)
Target: smooth cartoon art with sharp edges at 1024x768, 1280x720, 1920x1080, 2560x1440.
1. conf.lua: `t.window.highdpi = true`, `t.window.msaa = 4`, resizable, minimum 960x540, vsync on.
2. Do NOT render into a 1280x720 canvas and stretch it (that blurs). Keep the 1280x720 DESIGN space but draw directly to the window with one scale transform and a letterbox offset: `scale = math.min(w/1280, h/720)`. Hit-testing uses the same transform (`Layout.toCanvas`).
3. Author raster art at 2x design size (a 1280x720 scene is a 2560x1440 PNG). Load with `love.graphics.newImage(path, {mipmaps = true})`, `setFilter("linear","linear")`, `setMipmapFilter("linear", 0)`.
4. Never scale an image up by more than 1.25x; flag such assets in the asset report.
5. Snap sprite and outline positions to whole PHYSICAL pixels: `x = math.floor(x * scale + 0.5) / scale`.
6. Crisp text: create fonts with `love.graphics.newFont(size, "normal", scale * love.window.getDPIScale())`, cache by (size, scale), rebuild on resize (debounced 150 ms). Use a rounded font from the manifest with LÖVE's default as fallback. Body text >= 22 px design size, secondary >= 18, never below 16.
7. Procedural fallback art: `setLineStyle("smooth")`, rounded shapes with enough segments, rely on MSAA, no per-frame jitter.
8. Atlases: 4 px transparent padding AND color-extruded edges so no seams or bleeding occur when scaled. Export PNG-24, straight alpha, no white/black halos.
9. Static layers may be cached to a canvas at the ACTUAL window pixel size and rebuilt on resize, never lower.
10. Draw order is constants in src/ui/zorder.lua: background < midground < customers < counter_back < props < counter_front < speech_bubbles < HUD < toasts < overlays/tint < pause menu.

## 2. ART DIRECTION
Cozy flat hand-painted cartoon: chunky rounded shapes, colored outlines (a darker shade of each fill; default #5B3426, 3 px design size, 4 px on characters), two-tone shading, subtle paper-grain overlay (multiply 25-35%, rebuilt per resolution), big-headed chibi characters with simple dot eyes and four expressions (happy, waiting, impatient, angry).
Main scene layers: street background -> interior midground (side shelves, striped awning, tali rack of sachets, customer) -> big wooden foreground counter with props. Slim display-only maroon HUD plates with a cream value box. Cream speech bubbles (4 px outline) with A/B reply bubbles and round letter badges.
Palette (only in src/ui/theme.lua as 0-1 floats): cream #FBEFD9, cream_shade #EBD3B0, maroon #7A3B3B, outline #5B3426, mustard #E9B44C, salmon #F2A28E, rose #E57A7A, sage #A8B98A, pandan #6F9A55, steel_blue #6E8CA0, sky #BFE0E6, soft_pink #FBD5D5, wood #E8B987, wood_dark #B5754A, chili_red #F0594B, teal #2FA39A, night_purple #6C5A93.
Overlays: morning #FFE9A8 15%, afternoon #FFB36B 15%, evening #6C5A93 25%, rain = cool tint plus raindrops, brownout = dark blue 55% plus a warm candle glow. Body text contrast >= 4.5:1 (add a cream plate behind text if an overlay breaks it).
Originality: do NOT copy characters, layouts, logos or assets from any existing game.

## 3. ASSET MANIFEST AND PIPELINE
data/assets.lua entries: `{ id, kind = "image"|"font"|"sound"|"atlas", path, designSize = {w,h}, scale2x = true, anchor = {x,y}, hotspot = {x,y,w,h}? }`.
- src/ui/assets.lua is the ONLY module that loads files. It validates existence, dimensions (2x designSize) and alpha, and returns a placeholder on failure.
- `--check-assets` prints id, found?, pixel size, expected size, max upscale factor, warnings; exits non-zero on mismatch.
- Names: lowercase snake_case with kind prefix (`scene_street_bg.png`, `prop_phone.png`, `char_nanay_happy.png`, `icon_product_sugar.png`, `ui_plate_maroon.png`). Folders assets/img/{scene,prop,char,icon,ui,fx}, assets/fonts, assets/sfx, assets/music.
- Needed (all optional at runtime): scene layers (street, interior, counter, home, rain overlay), props (candy jars, timbangan, notebook, tray, phone, alkansya, lucky cat, rice sack, oil gallon, scoops, bags, bins, clock, calendar, radio, ref), characters (>= 8 archetypes x 4 expressions), 36 product icons, UI (HUD plate, bubble 9-slice, A/B badge, sign tags, sparkle, patience ring), fx (coin, pop, dust), cabinet section frame.

## 4. UI/UX RULES
Layout: 8 px base grid, 24 px safe margin, min hit target 44x44 design px, never overlapping clickables (top-most z wins, resolved in the `hotspot` module). Always visible in EVERY view: current order, patience ring/bar, queue warning, day/time, drawer cash, wallet, reputation.
States for every prop: idle, hover (scale 1.08, ease-out 120 ms, sparkle), pressed (0.96), disabled (55% opacity + tooltip saying why), attention (pulsing sparkle). No dead clicks: if nothing happens, show a toast explaining why.
Feedback within 100 ms of every command: pop animation, floating "+₱/-₱", sound hook or toast. Errors (from `nil, "message"`) appear as a cream toast near the relevant prop in plain Taglish/English, never console-only. Colors carry meaning: chili_red = loss/error, pandan = success, mustard = attention, steel_blue = neutral; never color alone (add an icon or word).
Interaction: drag shows a ghost, highlights valid slots, snaps, and returns to origin if dropped wrong; provide undo BEFORE confirming a transaction. Confirm steps show the numbers; destructive actions need a confirm prop. Tooltips after 400 ms (name, price, stock, unit) and never cover the order card. Keyboard: 1-7 stations, Escape pause, Enter confirms the focused confirm prop, Tab cycles hotspots in a defined order; fully playable by mouse alone. Animation: micro 100-150 ms, transitions 200-300 ms, never block input over 300 ms; honor a "reduce motion" setting.
Readability: text left-aligned in bubbles, <= 40 chars per line, <= 3 lines. Money always shown with ₱ and two decimals from integer centavos through ONE formatter (`format.money(centavos)`).

## 5. CLEAN FRONTEND / BACKEND STRUCTURE
"Backend" = domain code (state, systems, persistence) with NO LÖVE graphics calls. "Frontend" = rendering, input, views, UI. Use the folder tree and dependency rule from Prompt 1 section 6 (no exceptions, no circular requires).
- One file = one module = one responsibility, returning one local table. Header comment in every file: purpose, public API (name, args, returns), dependencies.
- snake_case files/functions, PascalCase module tables, UPPER_SNAKE constants.
- No globals: src/strict.lua errors on undeclared global access; `.luacheckrc` forbids globals except `love`.
- Functions short (about 50 lines or less where practical); early returns for guards. Tuning numbers live in data/tuning.lua with unit comments (centavos, seconds, grams).
- Errors: commands return `true` or `nil, "message"`; internal bugs use `assert`; a top-level handler in main.lua writes a crash report to the save directory and shows a friendly error screen.
- commands.lua is the single entry point views use to change state, keeping a ring buffer of the last 200 commands for the F1 debug overlay (day, time, cash, wallet, reputation, queue, FPS). F2 skips 1 hour, F3 adds ₱1,000, F4 spawns a customer (debug builds only, off by default).
- Format with StyLua; lint with luacheck if available; `tools/run_all_checks.lua` runs tests, global-leak check, asset check, circular-require check, dependency-direction check; record output in docs/reviews/verification.md.
- Keep ARCHITECTURE.md (module list, dependency diagram, data flow of a sale and of a wallet cash-out) and CHANGELOG.md updated every task.

## 6. VISUAL ACCEPTANCE CHECKLIST (`--smoke`, then review the screenshots)
For counter, shelves, sukli, bigas, tingi, notebook, phone, preparation, report, recovery, pause, rain, brownout, fiesta at 1024x768, 1280x720, 1920x1080, 2560x1440:
sharp edges, no stretch blur | crisp unclipped text | no jagged circles | no pixelation | no atlas seams or bleeding | palette respected | consistent outlines | no overlapping clickables | required HUD info visible | hover/pressed/disabled/attention states present | toasts readable on every overlay | letterbox clicks ignored and in-canvas clicks accurate.
Mark each OBSERVED (seen in a screenshot) or NOT CHECKED. Never mark what you did not see.
```

---

## PROMPT 3: SCREENS (SHELF CABINET + EVERY WINDOW)

```
# SCREENS ADDENDUM: THE CABINET AND EVERY WINDOW
Reference mockups are in docs/mockups/ (Counter, Shelves, Sukli, Bigas, Tingi, Utang, Phone). Match their layout and spirit.
Common to all views: 1280x720 design space; display-only HUD plates (Day/time, Cash, Wallet, Suki); an ORDER CARD top-right with the order, a patience bar and the queue count; a "Back to Counter" sign bottom-left; no menu-style buttons (actions are props or sign tags); hover scale 1.08 + sparkle; pressed 0.96; disabled 55% opacity with a tooltip; every no-op click shows a toast saying why. Money via ONE formatter from integer centavos. Rules live in systems/, never in views. Each view gets `--smoke` screenshots at 1024x768, 1280x720, 1920x1080, 2560x1440 (no clipped text, no overlapping clickables, HUD visible).

## W1. COUNTER (home)
Layers: street background, interior midground (side shelves, awning, tali rack), customer at the window, big foreground counter. Props: candy jars, timbangan, utang notebook, coin/bill tray, phone, alkansya, lucky cat; wall clock (pause), calendar (day summary/save when safe), radio (settings). Clicks: customer = take order; tray = Sukli; scale or rice sack = Bigas; notebook = Utang; phone = Phone; shelves = cabinet; curtain = Tingi; cat = small daily luck bonus. Customer: chibi, 4 expressions, patience ring, cream bubble with the order (Taglish) and item chips, A/B reply bubbles for quirky orders. Basket on the counter with quantity badges. Queue as figures outside the window plus a warning pulse at 5-6 waiting.

## W2. SHELVES (cabinet; replaces any list or tab UI)
Products are NEVER a text list or row of tab buttons. Six wooden cabinet sections in a 3x2 grid (Staples 7, Noodles & Canned 7, Snacks 6, Drinks & Sachets 7, Household 6, Essentials 3) at (40,100) (450,100) (860,100) (40,402) (450,402) (860,402), each 380x268 with a hanging category tag and 8 cubbies (4x2, 84x100, 8 px gap) with a wooden plank at the bottom. One cubby per product: the product picture on the plank, a cream PRICE TAG under it, a round STOCK BADGE top-right. Unused cubbies stay dimmed; spare Essentials cubbies hold decor (plant, cat). Positions come from src/ui/cabinet_layout.lua and `cabinet = {section, slot}` in data/products.lua.
Interaction: click a product to pick/buy it (click and hold for quantity, +1 per 200 ms after 400 ms, capped by stock); drag to the counter basket also works. Hover: scale 1.1, sparkle, tooltip after 400 ms (name, price per unit, stock with unit, action). States: idle, hover, pressed, sold out (55% opacity, dark badge "0", tooltip "Sold out"), low stock (pulsing badge and sparkle), reserved (shows basket quantity), expired (red-tinted badge). In preparation the same cabinet is the stocking view: click a cubby to open a crate prop to set the buy quantity; click the price tag to adjust the sale price with +/- sticker icons; drag products between cubbies in the same section (upper row sells slightly faster); the layout persists in the save.

## W3. SUKLI (cash drawer)
Left: receipt card with ONLY Total and Tender (never the computed change). Center: open wooden drawer with 5 bill slots (20, 50, 100, 500, 1000) and 3 coin slots (1, 5, 10), each showing a picture and a count "xN". Right: change tray with the selected pieces and "Napili: ₱X". Bottom-right yellow sign "Ibigay ang sukli".
Click or drag a bill/coin from a slot to the tray; click a piece in the tray to return it; counts update live; cannot select more than the drawer has (toast). Tender enters the drawer when received. Confirm commits once. Short change = complaint toast and a correction step; extra change = recorded loss. If exact change is impossible: cancel/refund. Difficulty Easy shows a hint; Hard none.

## W4. BIGAS (rice scale)
Left: open rice sack with scoop. Center: large round timbangan with swinging needle and a pan with a rice mound; digital grams below. Top-right: target card ("Gusto: 500 g", tolerance text, a green tolerance bar with a red marker for current weight). Right: bag prop ("Plastik, i-tali") and a yellow sign "I-confirm ang timbang".
Click the sack to add a scoop (default 50 g), click the pan to remove one; hold to repeat after 400 ms. Peso-value requests convert to grams with deterministic rounding. Underfill cannot confirm (toast shows the shortfall); overfill consumes real stock and lowers margin; the needle eases with a small overshoot. Tolerances from data/tuning.lua.

## W5. TINGI (repacking)
Top: steel bins (asukal, harina, asin, kape, more) each with a scoop. Bottom-left: tray of plastic bags. Center: wooden work board with a bag being filled. Beside it: a gallon (oil/vinegar/soy) that tilts when held, with a pour stream and a vertical fill meter with a red target line and green tolerance band. Right: "Handa na" basket listing prepared packs.
Pick a bag size (P5/P10/P20, 1/4 kg, etc.) by clicking a bag; hold on the gallon to pour and release near the line; click a bin to scoop N scoops. Prepared packs become inventory batches with quantity and age, sellable during service. Cancel returns safe items; discarded opened portions record cost. Spills only on clear overfill (cost recorded).

## W6. UTANG (notebook)
Center: open spiral notebook. Left page: suki list with name, balance/limit ("₱120.00 / ₱300.00"), status dot (green ok, red near limit). Right page: selected suki, history, and a speech card when someone asks for credit ("Pa-utang muna po ng ₱180") with A/B reply bubbles ("Sige po", "Hindi muna") and a green sign "Tumanggap ng bayad". A pencil prop marks interactivity.
Only eligible named suki ask; the card shows the remaining limit; granting creates a debtor balance and adds NO drawer cash; repayment uses a small Sukli-style tray and raises cash while lowering receivables without duplicating revenue. Unlocks Day 5 (closed notebook with a tooltip before then).

## W7. PHONE (fictional wallet; default name "TindaPay")
Left: the customer's phone with a screenshot and the warning "Hindi sapat ang screenshot lang". Center: the store phone with Cash In / Cash Out tabs, an INCOMING TRANSFER card with check items (Tatanggap, Ref, Halaga, Status) and a green sign "I-verify at Tanggapin". Right: summary card (Principal, Fee paid separately in cash, Wallet, Drawer), a history card, and a yellow sign "Piliin ang ibibigay na pera" opening the Sukli-style tray for payout.
Rules (systems/wallet.lua): cash-in unlocks Day 4, cash-out Day 6; verify recipient, reference, amount, confirmed status; reserve funds or feasible denominations BEFORE accepting; stage everything and commit once atomically; completed references can never be reused; wrong data gives actionable errors and no balance change; the Day 9 outage greys the phone with an announcement. Morning phone: top half loads the wallet from the drawer, bottom half withdraws cash, showing exact denomination bundles and the disclosed charge.

## W8. PREPARATION (morning, untimed)
Cozy morning scene: half-open shop front, wooden prep table, notice board. Props: cabinet (buy and price), phone (wallet load/withdraw), coin purse (exchange denominations), repack corner (to W5), ice box (buy ice before a brownout day), a daily-situation poster (today's situation with 2-3 advice lines), an alarm clock "Buksan ang tindahan" that starts the day, a small cat for tutorial hints. No patience bar here. Hints only here.

## W9. REPORT (end of day, untimed)
A home table with the day's ledger as paper notes on a corkboard: Revenue, Cost of goods, Operating costs, Spoilage, Change losses, Unpaid credit, Abandoned customers, separate cards for Cash flow and Profit, Service fees (separate from transfers), Reputation and its change. A piggy bank shows cash; a small chart shows the last 7 days. A calendar prop "Susunod na araw" advances the day (auto-saves first). Day 10 shows a milestone card; the game never ends there.

## W10. RECOVERY
Shown when cash, stock and wallet cannot support another day. A gentle closed-shop scene with two props: a rewinding clock "Ulitin ang araw" (restore the morning snapshot) and a fresh sign "Bagong tindahan" (new run). Works even when the only money left is in the wallet. A corrupt save shows a readable message with backup recovery.

## W11. PAUSE / MENU / SETTINGS
Escape or the wall clock pauses ALL simulation. The pause overlay is a wooden board with props: resume (door sign), save now (calendar, only at a safe transaction boundary; otherwise a tooltip explains), radio (volume, difficulty Easy/Normal/Hard, reduce motion, text size), quit (lamp). Title screen: shop front with New (open sign) and Continue (notebook); Continue is dimmed with a tooltip if no valid save exists.

## SHARED ACCEPTANCE
Same palette, outlines, grain and z-order constants as Prompt 2. No view contains economic formulas. docs/controls.md lists for every view the props, click, drag and keyboard actions. Each view has a test or smoke script verifying it opens, closes, keeps the order card and patience, and returns to the Counter without leaking a reservation.
```

---

## PROMPT 4: ART GENERATION PACK (for an image AI or your own drawing)

Image AIs are weak at text and edges. Generate each asset **separately**, with **no text inside any image** (the game draws all text), and use your inspiration only as a *general style* (do not copy characters or assets from any existing game; describe the style instead of naming a game).

**Style block (put at the start of every prompt)**

```
cozy 2D game illustration, flat hand-painted cartoon style with subtle gouache paper grain, clean smooth edges, colored outlines slightly darker than each fill in warm chocolate brown, soft two-tone shading, chunky rounded shapes, warm pastel palette of cream, mustard yellow, rose pink, sage green, steel blue and maroon, Filipino sari-sari neighborhood store details, cute and cozy mobile management game art, front-facing flat orthographic view, no perspective distortion, sharp crisp edges, ultra high resolution, original design
```

**Negative prompt**

```
blurry, soft focus, low resolution, pixel art, pixelated, jpeg artifacts, noise, 3D render, photorealistic, glossy plastic, heavy gradients, harsh black outlines, text, letters, numbers, logos, brand names, watermark, signature, UI elements, extra fingers, distorted hands, asymmetrical eyes, cropped objects, cluttered composition, muddy dark colors, baked-in vignette, crowd of people, copyrighted characters
```

**Asset prompts** (replace \[STYLE BLOCK\] with the style block; keep the same seed or one style-reference image)

- **Street background (layer 1):** `[STYLE BLOCK] A quiet Philippine neighborhood street seen through a shop window, pastel two-story buildings in salmon, soft pink and sage green, a small tricycle parked at the side, hanging electric wires, a few potted plants, bright daytime sky in pale blue, empty street, no people, no shop interior, no counter, 2560x1440, calm empty space in the center`
- **Interior midground (layer 2):** `[STYLE BLOCK] Inside of a small sari-sari store seen from behind the counter, cream walls, wooden shelves on the left and right walls stocked with simple colorful boxes, cans and bottles without labels or text, a red-and-cream striped awning over a large open window in the middle, a string of hanging snack sachets under the awning, a small Santo Niño shrine in one corner, empty window area in the center for a customer, no counter, no people, 2560x1440`
- **Counter (layer 3):** `[STYLE BLOCK] Wide wooden shop counter seen from the front at the bottom of the frame, warm tan wood with visible planks and a darker top edge, completely empty surface, plain solid pure white background above the counter, 2560x500` (remove the white in Krita)
- **Cabinet section (the organizer):** `[STYLE BLOCK] A single wooden store organizer cabinet front view, darker wood frame, eight empty square cubbies in two rows of four, each with a thick wooden shelf plank at the bottom, a hanging wooden label tag with no text at the top, plain solid white background, 760x536`
- **Props (one per image):** `[STYLE BLOCK] A single [PROP] centered on a plain solid white background, full object visible with padding, no ground shadow, no text, 1024x1024`. Props: glass candy jar with colorful candies; old mechanical kitchen scale (timbangan) with round dial and metal pan; spiral-bound notebook with plain cover; small round tray with a few coins and a bill; smartphone on a stand with a plain blue screen and no app text; round glass piggy-bank jar with coins; white lucky cat figurine with orange patch and raised paw; burlap rice sack with scoop; plastic gallon of cooking oil with a blank label; metal scoop; stack of clear plastic bags; steel storage bin; round wall clock with plain face; wall calendar with plain grid and no numbers; small old radio; mini refrigerator with glass door; wooden drawer tray with empty compartments for coins and bills.
- **Customers (original, four expressions each):** `[STYLE BLOCK] Character sheet of one original cute chibi character, [DESCRIPTION], big head, simple dot eyes, small nose, rosy cheeks, half-body front view, arms hidden below the frame, plain solid white background, four poses in a row showing only facial changes: happy, waiting, impatient with a sweat drop, angry with steam, same outfit and hair in all four, 2560x1024`. Descriptions: middle-aged nanay with a short wavy brown bob, rose blouse, tote bag; small kid with a bowl haircut and school uniform; tambay with a cap and sleeveless shirt; elderly suki with gray hair in a bun and glasses; hurried office worker with a lanyard; cheerful delivery guy with a helmet. Vary ages, body types and hairstyles.
- **Product icons (36, same prompt each time):** `[STYLE BLOCK] Single product icon of [PRODUCT], generic packaging with no brand, no text, no labels, centered on a plain solid white background, soft rounded shapes, slightly oversized, 512x512`
- **UI pieces (no text, no icons inside):** slim rounded rectangle HUD plate in dark maroon with a thin warm brown outline and an empty lighter cream box on the right (1024x256); cream speech bubble with thick brown outline and a small tail at the bottom left; round mustard badge with a thick brown outline and no letter; small yellow four-point sparkle star with a thin outline; small wooden hanging sign tag with a rope and no text.

**Workflow:** generate at the highest resolution -> pick the sharpest -> upscale only with a quality AI upscaler (never plain stretching) -> remove the background and clean stray marks in Krita -> export PNG-24 with transparency at 2x the design size -> rename by the manifest ID -> run `--check-assets`. If an image looks wrong, regenerate it. The game never depends on a bad asset: the placeholder takes over automatically.

---

## PROMPT 5: INDEPENDENT AUDIT AND CLEANUP (use in a NEW session)

```
# INDEPENDENT AUDIT OF "TINDAHAN"
You are a reviewer, not the author. Project: C:\04 Programming Language Lua (Lua, LÖVE 11.5). Read docs/BRIEF.md (the requirements) and ALL source files. Do not trust any claims in the docs or README: verify by reading code and, where possible, running it (`lovec.exe "C:\04 Programming Language Lua" --test`, `--smoke`, `--check-assets`, `tools/run_all_checks.lua`).
Label every finding OBSERVED (you saw it in code or output) or INFERRED (you believe it from reading). Do not invent problems; if unsure, say "not verified".

## Review 1: Code and architecture
1. Dependency rule violations (data -> model -> systems -> commands -> views/ui -> app -> main): list every offending `require`. Any `love.graphics` or `love.window` call inside src/systems/ or src/model/. Any economic formula inside src/views/. Circular requires. Duplicated rules in more than one place.
2. Globals: undeclared globals, accidental global functions, leaked state.
3. Money and units: any float currency, any `/` or `*` on money without integer rounding, any value displayed without `format.money`, any weight or volume not in integers.
4. Transaction invariants: for every command in retail, wallet, debt, portions, inventory, check commit-once, staging, reservation release on cancel/timeout/brownout, duplicate click handling, reused reference rejection, and atomic ledger writes. Trace each money-changing path and show where an interruption between two steps could lose or duplicate money or stock.
5. Persistence: strict data-only codec (never `loadstring` or `dofile` on save data), schema/version validation, temp-write + verify + last-good backup, failure messages, corrupt-file behavior, incomplete transactions never saved.
6. Error handling: every command returns `true` or `nil, "message"`; no silent failures; the top-level crash handler works.
7. Code hygiene: files with several responsibilities, functions over about 80 lines, magic numbers that belong in data/tuning.lua, dead code, TODOs, inconsistent naming, missing header comments.

## Review 2: Gameplay and UX (play it through `--smoke` screenshots, a scripted day, and by reading the views)
1. Days 1-11: does each situation do what the brief says? Is the ordinary retail loop present every day? Does Day 11+ avoid endless escalation?
2. Fairness: patience vs. action time; can a player recover from a bad rush? Can any state trap the player (no cash, no stock, wallet only)?
3. Readability: required HUD info visible in every view; text size and contrast; clipped or overlapping elements; clickable areas overlapping.
4. Every mockup in docs/mockups/ vs the implemented view: list differences.
5. Visual quality: blur, pixelation, seams, inconsistent outlines, palette drift, text crispness at 1024x768, 1280x720, 1920x1080, 2560x1440.
6. Controls: mouse-only completeness, keys 1-7, Escape pause, back-to-counter always present, tooltips, toasts for every no-op.

## Output format
1. Summary table: area, status (PASS / FAIL / NOT VERIFIED), evidence.
2. Findings list ordered by severity (CRITICAL = can duplicate/lose money or stock, corrupt a save or crash; HIGH; MEDIUM; LOW), each with: file and line, what is wrong, how to reproduce or why you believe it, suggested fix, a test that would catch it.
3. What you could NOT check, and why.
Do not edit code in this session. Do not claim the game is bug-free.
```

---

## PROMPT 6: PLAYTEST, BALANCE AND RELEASE

```
# BALANCE AND RELEASE FOR "TINDAHAN"
Project: C:\04 Programming Language Lua. Use docs/BRIEF.md as the requirements. Change ONLY numbers in data/tuning.lua, data/products.lua, data/days.lua and data/customers.lua unless a bug forces a code change (then add a test).

## Part 1: Balance report (before changing anything)
Run deterministic accelerated simulations for Days 1-11 with at least 5 seeds and several simple strategies (careless, average, careful). Report per day: customers served, abandoned, revenue, cost of goods, operating costs, profit, ending cash and wallet, reputation, spoilage, change losses, debt outstanding, number of times a bankruptcy/recovery state appeared. Print the table.
Targets (adjust and explain if you change them): an average player ends Day 1 with a small profit; Days 4, 6, 9 are noticeably harder but recoverable; a careless player can lose money but never reaches an unrecoverable state without the recovery screen; a careful player's profit grows gradually across Days 1-10; no day has more than 2 customers waiting beyond the queue cap on average; queue wait time is fair (patience is longer than the typical service time for the typical order).

## Part 2: Tuning
Propose the smallest set of number changes that meets the targets. For each: old value, new value, reason. Apply, rerun the simulations, and show before/after. Never hide difficulty by making the player immortal.

## Part 3: Human playtest notes
Based on the player's notes (pasted below), list which problem each one matches (pacing, confusing UI, unfair queue, unclear instruction, too many clicks, readability), the fix, and the file changed. Do not change unrelated systems.
PLAYTEST NOTES: [paste what felt unfair, boring, or unclear]

## Part 4: Release checklist
1. Run all checks (`--test`, `tools/run_all_checks.lua`, `--check-assets`, StyLua check) and paste the actual outputs into docs/reviews/verification.md.
2. Build `Tindahan.love`: zip the contents of C:\04 Programming Language Lua (main.lua at the zip root), exclude docs, tests, tools, .git, .tools; verify it launches by dragging onto love.exe.
3. Build a standalone folder: `copy /b love.exe+Tindahan.love Tindahan.exe`, plus all LÖVE .dll files and license.txt; verify it launches on a folder without LÖVE installed.
4. README: how to run, controls, progression, wallet fiction note, saves location, known limitations. CHANGELOG up to date.
5. Report: exact commands, outputs, what was verified, what was not, and remaining limitations. Do not claim anything unverified.
```

---

## QUICK START (the 6 first actions)

1. Install LÖVE 11.5 and VS Code; create `C:\04 Programming Language Lua`.
2. Save Prompts 1 + 2 + 3 as `docs\BRIEF.md`; add screenshots to `docs\mockups\`.
3. Open your coding AI in that folder; send the Stage 1 message (audit only).
4. Say "Do Task 1. Tests first. Stop when finished." Run the game, check it, then "continue".
5. Make the art with Prompt 4 while the code is being built.
6. After Task 6/7, paste Prompt 5 into a new session; after that, balance with Prompt 6; then package.