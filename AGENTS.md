# Agent handoff and economical execution

## Start

1. Read `docs/STATUS.md` first; keep it under 50 lines.
2. Search `docs/HANDOFF.md` for the relevant topic, then read only that section and the source files needed for the task.
3. Check the current diff before editing. Treat previous test results as historical evidence, not proof of later changes.

## During work

- Keep one owner per edited file when agents are used. Delegate only under applicable authorization.
- Do not repeat a completed investigation unless new evidence or changed files require it.
- Use focused verification; run a full gate at a meaningful integration point or when a concrete risk requires it.
- Preserve the existing implementation and approved scope; collect future ideas separately.

## Before finishing or handing work off

- Update `docs/HANDOFF.md`: objective, changes and file paths, decisions and reasons, verification actually run and results, unresolved issues, and exact next action.
- Update `docs/STATUS.md`: current stage, latest completed work, blocker, and next action, with pointers to relevant handoff sections.
- Record important findings, not raw transcripts, repeated plans, full logs, credentials, or tokens.
- A delegated agent reports its handoff entry to the coordinator; the coordinator consolidates the shared summary to avoid concurrent edits.
- Do not claim code, deployment, external setup, or tests were completed unless verified.

## Current constraints

- Test device: Samsung Galaxy S24 Ultra. Android APK is the preferred native test artifact.
- Firebase: dedicated project `sofra-c03a1`, created and supplied by the user; CLI access verified. Do not modify other projects or enable billing.
- User explicitly authorized implementation and Firebase setup; accounts, persistence and test APK are verified. Current design prototype source: design-preview/. Keep kitchen isometric, fridge one-point frontal perspective, characters flat and animated. No further image generation or music; sound effects cancelled for now. Review the interactive prototype before porting its design to Flutter.

## Mandatory user handoff protocol — 12 October 2026

- Select one checkout per work session and record its absolute path in the handoff. GitHub `origin/main` is the reference. Current selected checkout: `E:\work\SOFRA\app`; the Codex checkout is an inactive snapshot. Do not edit both independently.
- Before delivery, commit all completed changes and push them to `origin main`; verify clean status and matching local/remote commits. Keep unfinished work on a named branch and record it. Do not leave uncommitted work.
- Update `docs/STATUS.md` and relevant `docs/HANDOFF.md` sections with changes and paths, decisions/reasons, checks actually run/results, open issues and the exact next action. Historical results must be labelled as historical.
- When working in the E checkout, also update `E:\work\SOFRA\STATUS.md`, `HANDOFF.md` and `DELIVERY.json` outside Git. Record the final pushed commit hash there after committing the tracked handoff. The tracked handoff records its base commit and points to this final receipt to avoid a self-referential hash.
- End the handoff with the commit information and whether preview servers remain running: port, process identity, source checkout and restart command, or explicitly closed. Inspect the owning process before stopping it.
- For every newly built APK, record filename/version, source commit, SHA256, absolute location, actual S24 Ultra test status and actual Drive upload status. Do not label a previous APK as newly built or tested.
- Record every Firebase change precisely. Only `sofra-c03a1` is authorized; no other project and no billing activation.
- Explicitly record any changed user decisions, including audio, image generation, kitchen/fridge geometry or inventory deduction. Preserve existing decisions unless the user changes them.
- Never write credentials, passwords, tokens or private keys into handoff files or source control.

## Current scope — backend first

- User now asks to complete missing logic without redesigning interfaces; the visual UI will be built elsewhere. Only the subsequently requested functional UI changes are authorized here: male/hijab correction and ordering, general language and EG/SA selection, removing Home from bottom navigation with entry inside Today/Kitchen, a day/week/month meal calendar, and explicit new-purchase selection.
- Backend integration guide: docs/BACKEND-API.md. Use KitchenService as the single state owner in the new UI; do not run legacy UI and new backend writers over the same state simultaneously.
- Financial decisions are explicit in docs/MONEY-RULES.md: budget covers new purchases only; user override before average; alert and suggest without automatic plan edits; explicit purchase toggle; confirmed history prices frozen; no automatic monthly carryover.
- Do not invent current prices, nutrition or medical rules. Nutrition core and sourced banks are authorized/implemented: docs/FOOD-DATA-ARCHITECTURE.md. Recipe/label review coverage, price sources, automatic budget generation and alternatives remain incomplete. Missing data stays unknown.


## Nutrition and external Blender design

- Food API: docs/FOOD-DATA-ARCHITECTURE.md. Keep USDA CC0 and OFF ODbL/DbCL banks separate; preserve provenance, unknowns, exact form/basis and distinct nutrient definitions.
- Recipe selections are explicit per revision and line.54recipes have605review lines and0fully verified bindings.197 generic identity proposals across53recipes now load through RecipeReferenceRepository; see docs/RECIPE-REFERENCES.md. Explicit acceptance/choices, blocked compounds, exact snapshot/source guards and separate ingredient-input estimates are mandatory. Legacy/demo UI does not gain nutrition automatically.
- KitchenService remains the only state owner; cooking freezes nutrition without automatic intake. Preserve append-only corrections and850KBguard. No Firebase migration/billing occurred.
- Blender brief: docs/BLENDER-DESIGN-BRIEF.md. No models/renderer built or thread created. Renderer requires a small asset test onS24Ultra. No UI redesign/audio/image generation authorized by this brief.

## Continuous food bank work

- User explicitly authorizes ongoing economical research and one cheap collection agent. Follow docs/FOOD-BANK-CONTINUITY.md: no arbitrary final record count; checkpoint and resume, check quota with a10%reserve, and preserve quality/source licenses. Never infer successful collection from an attempted request.

## Nutrition summary display

- User-approved summary: energyKcal, protein, totalSugars, fibre, fat, in this order, via primaryDisplayNutrients. Show total fat once; retain all49nutrient fields for future detail. Missing values remain unknown. Do not redesign UI here.

## Recipe revisions and generated cache

- Follow docs/RECIPE-VARIANTS.md. Preserve full immutable snapshots and revision-specific nutrition bindings. Prefer line indices for repeated ingredient choices/measurements. Unknown legacy bindings require explicit re-review.
- Only checkout E:\work\SOFRA\app is active. Its ignored `.dart_tool` and `build` are junctions to C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\sofra-generated-cache. These are generated caches, not a second project. Inspect junction targets before cleanup; never recursively remove a computed target without validating its scope.


## Priorities and pause diagnosis — 13 October 2026

- User explicitly asks to prioritize all research/logic/banks and execute in order. Read docs/RESEARCH-ROADMAP.md and docs/WORK-QUEUE.json after STATUS; the older bank-only schedule no longer describes the whole scope.
- automation-2 is one combined monitor/worker every30minutes. Check actual usage then run tool/work/watchdog.mjs with actual --primary/--weekly/--ordinary. Missing/false/90% prevents costly work. A source backoff delays that source, not independent local implementation.
- One checkout/one owner. Diagnose active task progress with its own lastProgress taskId or lastAttemptAt fallback; after60minutes inspect owner/process/evidence before resuming or releasing it. Do not start a second writer or refresh timestamps as fake progress.
- Current completed units: monitor, source measure catalogue and persistent measure integration. See docs/HOUSEHOLD-MEASURES.md: explicit per-revision/line acceptance, source estimate versus actual quantity, acknowledgement before estimated deduction, atomic stock/cost/nutrition consistency and frozen confidence. Compound-revisions is now implemented (COMPOUND-REVISIONS.md), with explicit quantities/full parent guard/new bindings. Next preparation-evidence has4official sources and9extracted/unmapped candidates but0approved transforms; distinguish data CC0 from unknown document license, keep unarchived hashes null, never apply a universal macro multiplier.
- Close a proven unit with relevant tests/queue evidence/commit/push, then take the next available unit while capacity permits. Product collection remains a helper lane with one cheap gpt-6-luna/medium collector and short context; preserve lock/backoff and its handoff/status. No automatic clinical rules, invented prices or conversions.


## Recipe research and data map —13 October2026

- Start architecture lookup at docs/DATA-MAP.md; detailed food contract remains FOOD-DATA-ARCHITECTURE.md.
- User explicitly requested an additional independent recipe collection agent. Use a bounded economical batch and its own handoff/status; coordinator owns shared files.
- data/recipes/research-candidates.json is research-only, outside shipping recipes and Flutter assets; validate with node tool/recipes/validate-research.mjs. Docs/RECIPE-BANK.md defines provenance, licences, versioning and runtime promotion gaps.
- Keep source licences/attribution separate, unknown times/amounts null, and0unreviewed food/nutrition bindings. Original54recipes unchanged; no guessed timing0 or gram conversions to fit CatalogRecipe.

## Bulk recipes and personal calculation engine —13 October2026

User prioritizes largest practical recipe quantity/cuisine expansion now; continuous bounded source acquisition without a final count cap. See RECIPE-BULK.md/RECIPE-ENGINE.md. One recipe collector lock; Retry-After/max10minminimum and2s pacing, no immediate retry or alternate route around review. Keep original revisions immutable, category observations separate, latest index and parsed recipes derived with provenance/hashes. Source/cuisine metadata is unreviewed, no runtime nutrition or ready recipe claim. During backoff execute recipe-quantities before preparation. Preserve person estimated=true/false/legacy-null; false is not laboratory certainty. Source-from-scratch draft persistence is not implemented; personal revisions still require parents. No UI/Firebase/billing/audio/images changes.


## Identity research readers and pending request isolation

Use RECIPE-IDENTITY-REVIEW.md for current research contracts. Raw USDA snapshot fingerprints differ from transformed Dart FoodRecord snapshots. Validate source text re-extraction and current food manifest/index/shard hashes before using proposals; these are local consistency checks, not upstream signatures or approval. Keep collector/indexer stopped while validating. Never pass generator continuation into a fresh pending page lookup or replace the generator cursor with its category continuation; preserve pendingRequest across runs. A source pool reaching sourceExhausted is discovery/expansion work, not bank completion.

## Independent French source

Follow docs/RECIPE-FRENCH-SOURCE.md and its own checkpoint. French prefix pages include nonrecipes; keep source/parsed counts separate and never sum languages as unique dishes. Source language is not cuisine. Preserve root-based discovery cooldown, underscore cursor verbatim, pending/listing isolation, raw request/revision provenance and null nutrition/amounts. Offline archived listing recovery retains the original gate. No English/runtime/UI changes implied.

## Research identity catalog

Use `node tool/recipes/validate-identity-catalog.mjs` for registered banks. Preserve exact bank SHA/expected counts/current source and food guards; duplicate targets across banks fail. New banks need explicit registration, no auto-discovery. Catalog counts remain research-only/zero runtime approval. English source reader currently excludes French proposals. Never refresh stale targets to hide drift; keep raw USDA and runtime FoodRecord snapshots distinct.

## Fresh source quota evidence

Read actual usage before every new source batch. If automatic command review requires an in-command guard, use a freshly tool-captured ordinary/limit/timestamp report and fail closed when absent,>=90 orolderthan30seconds. PowerShell ConvertFrom-Json may deserialize ISO timestamps to UTC DateTime: cast directly to DateTimeOffset,do not stringify/reparse as localtime. Evidence files expire and cannot be reused as current usage. Preserve source lock/backoff; no alternate route around rejected unchecked actions. See HANDOFF§47.


## Ingredient fate research

Use docs/RECIPE-INGREDIENT-FATE.md and validate-ingredient-fate.mjs before interpreting soaking/draining observations. Exact recipe/line/full-snapshot/method anchors and licences required; retained ingredient/nutrient amounts stay null,0runtime approval. No stock/cost/nutrition behavior changes implied. Current English and French inventories are exhausted; discover another licensed pool without resetting either cursor.


## Independent Spanish source

Use docs/RECIPE-SPANISH-SOURCE.md and collect-wikibooks-es.mjs --resume for existing bank. First49archivedentries seed pending before cursoradvance;policy/SHA/app-rootdiscovery gate required. Own source IDs/locks/backoff and parserv3 null canonical values;multiline unsupported templates/code stay raw/unparsed. Preserve raw revisions,version derived re-extraction and never reset English/French or infer cuisine from language.


## Explicit single choice and operational ordering

Use RECIPE-INGREDIENT-CHOICES.md:chooseRecipeIngredient stores one quantified replacement/newpersonalrevision,fullparent/region/method guards,no inherited foodbindings,history frozen. Calleracknowledgesinstructions;no culinaryequivalence/medicalapproval implied. Sourcebankexpansion nowpriority35/openaftercurrentinventories archived;readyquantity/preparation/import/authoring foundations advance. Preserve continuouseconomicalsource research/no countcap and actualquotas/backoff.

## Import-draft preflight

Use docs/RECIPE-IMPORT-PREFLIGHT.md and tool/recipes/import-preflight.mjs for source draft audits. Current authoritative English reader only. All quantities/optional/choice/form/scaling/times and raw-food references explicit; no source candidates autoaccepted. draftComplete is not runtimeReady (alwaysfalse); retain separate adapter/licence/instruction/runtime form-basis/retention gates.29linked tests/blankbaseline3640recipes verified; no reviewed draft imported. Next registered draft persistence; no unknown-to-zero or concurrent source writers.

Registry follow-up: data/recipes/import-review/registry.json explicitly pins draft raw-byte hashes and exact source attribution/licence. import-draft-registry.mjs exit0 only validates registry consistency; drafts may still be incomplete/runtime0. Current1blankdraft/9lines/50issues,36linkedtests passed. Never silently refresh changed SHA or accept raw USDA ref as runtime binding. Next adapter retains all remaining gates; HANDOFF§55.

## Structural source runtime candidate

Follow docs/RECIPE-RUNTIME-ADAPTER.md. Candidate preserves source/licence/review/full hashes and line maps;requires explicit runtimeingredientIDs/steps/cuisine,never inferred from language/rawfood. validateRuntimeRecipeCandidate rebuilds from currentauthoritativeinputs beforetransportacceptance. runtimeReadyfalse,0foodbindings/actualimports;next native reader/immutable registration must retainfullprovenance envelope,atomic historyguard and allremaining nutrition/form/basis/retention gates.44linkedNode+1Flutterinterop/analyzeclean;full107historical. OFF2287/64,Saudi/globalp11actual503gate23:49:13.371Z;Egyptp8gate01:30:53.428Z. No costlynewunitat/above90 orunknownquota.

## Native reviewed source imports

Use docs/NATIVE-RECIPE-IMPORT.md. TrustedartifactexpectedSHA+exactUTF8pack,crypto3.0.7cachedoffline,strictsource/maps/normalizedcatalogtext;preservefullenvelope. KitchenService.importSourceRecipe mandatorysource/license/instruction+unknownnutrition acknowledgements,importedrootderivedfamily/revision,atomicguard/history. No rawfood-to-runtimebinding/clinicalapproval. Oldbooksreadable;oldclientsdoNOTsupportnewkind,do notenableUI/sharedwritesbeforecompatibleclient. Full142Flutter+1supplementalbinding/46Node/analyzeclean;0actualbankpromotion. Quantity/importinfrastructuredone,datacoverageopen;nextpreparation30thenprivateauthoring34. OFF2378/67,Saudi03:31:56.646Z/Egypt03:56:26.889Z;onecheaphelper/actualquotas/gates.


## Category preparation estimates

PREPARATION-ACCEPTANCE.md describes explicit scoped acceptance for USDA168927/asSold only,0381 or0382 as alternatives. Source/review/FoodRecord fingerprints are consistency pins, not upstream approval. Three vitamin factors only; other46/yield/edibleFraction/licence remain unknown. Preserve frozen confidence/source/scope and separate cooking acknowledgement even with actual grams; no automatic name/cuisine matching or scientific/legal/finished-recipe approval. From-scratch authoring34 next; broader preparation scientific coverage continues separately.


## From-scratch draft calculator

PERSONAL-RECIPE-DRAFTS.md: immutable user drafts in a separate namespace, not plannable CatalogRecipe roots. Preserve unknowns, owned snapshots, sorted-object fingerprint, exact active guard and old retry semantics. Existing input/cooked calculator; no automatic stock/intake. Finalization/planning remains authoring34; no inherited category acceptance from another recipe. No usercloud/UI/APK migration.


## Reviewed personal recipe publication

PERSONAL-RECIPE-PUBLICATION.md: authored root now retains full draft/finalization evidence and exact revision/line food selections. Publish only saved unchanged active draft with explicit metadata/inventory IDs/steps/review and expected active recipe key. Generic save cannot bypass review; retries never reactivate/rebind. Reject unsupported estimated quantities, copied category scope and base precision loss; unknown food stays unknown. Existing meal optional choice remains explicit. Old clients cannot read authored kind; no UI/usercloud activation. Full183Flutter/analyzeclean;user decisions unchanged.

## Egypt/Saudi price research alongside recipe expansion —14October2026

Latest explicit user priority: source real EG/SA grocery/produce/meat prices while an economical independent recipe helper continues bounded licensed expansion. Prices priority30, recipe-bank35 helper; neither ongoing bank has a final record cap. Read PRICE-SOURCES-EG-SA.md and RECIPE-EXPANSION-AR-DE.md. Raw retailer/government/community observations are research-only,0runtime acceptance; public pages do not establish reuse rights or national/current prices. Keep initiative/wholesale/statistical/retail separate and preserve user-price priority/frozen history.

German collector requires actual fresh quota JSON before each request, lane lock/backoff/no-clobber archive writes and unique sequence including100+. Never reuse expired usage evidence or test quota values. Read exact saved cursor; do not reset acquisition. The overwritten original2German response bodies remain lost; current100prefix pages are explicitly new retrievals. Root coordinates shared files/Git; each helper full/small handoff. No UI/Firebase/audio/image changes.
