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

## Historical intervals and real collector formatting

Keep official/msit-2025-06-ranges.json separate from pointquotes; these36EGP/kg ranges areJune2025,nevercurrent or midpointestimates. official-price-ranges.mjs requires explicitperiod/EG/EGP;0runtime/rightsapproval. RawPDFexternal source-cache only, notGit; see sourceSHA/page in PRICE-SOURCES-EG-SA.md.

German archive sequence must return an integer for D2format; numericcomparison alone missed a Double fromMeasure-Object. Actualformatter regression nowmandatory withcollision/quota/failure-reservation checks. Local preHTTP failures must recordlocal-error-stop, preserve continuation andnot createHTTPbackoff. Use approvedscopedescalation forCIM/E/network;do not bypass processchecks on sandboxdenial.

## Source access scope and user-facing recipe terminology

Use source-access.mjs for OFF401/403 backoff shared across markets; do not treat another country/category as a separate allowed source during an active refusal gate. Keep monitor and collector behavior aligned; invalid source failure dates block source work. No real OFF retry during the current09:49:45.471Z gate; source503 remains job-scoped.

User clarified terminology: English/German/French/Spanish are source languages, not approved cuisines. Say «وصفات مجمعة تحت المراجعة» for parsed candidates; never present them as ready recipes or distinct dish totals. Source language cannot establish recipe cuisine/nutrition/readiness.

## User correction: modern Arabic YouTube recipes first —14October2026

User explicitly prioritizes modern recipes from Arab cooking personalities on YouTube and says stop current old/historical recipe book/reference collection. Stop further Wikibooks recipe collection, including saved German continuation, unless user later authorizes it. Preserve acquired banks and provenance; no deletion. RECIPE-ACQUISITION-ARABIC-YOUTUBE.md is the current acquisition plan and count definition. Official channel/video identity and reuse review required, ingredients/servings/time unknowns preserved; no fabricated chef popularity, video content, cuisine or nutritional bindings. No video/audio/image downloads or UI changes.

Catalogue54recipes/4cuisines (12Egyptian,14Levantine,14Saudi,14Italian);6056researchrecords beforededup/review, notunique/readydishes;0shared verifiedmulti-methoddishgroups and0YouTuberecipescollected sofar. Engine support is not populated data. Next source work must discover/verify official ArabicYouTube channels and collect bounded reviewed candidates, then explicit family/variant links and nutrition calculation. Do not resume saved book cursors from old handoffs. Currentquota90primary/89weekly prohibits newcostlycollection until freshallowedreading.

## Explicit local curation and backend parallel work

User now explicitly authorizes a separate agent to PROCESS the existing6056localrecords into actualrecipes, in parallel with modernArabiccreator acquisition andanotheragent buildingmissingbackendlogic. This is localreview/normalization, not newbooksourcecollection. Preserve sourcefacts/unknowns/provenance and stopcounting rawrecords asreadyrecipes. Firstnewbackendunit is stock-aware plannedpurchasepreview;fullmonthlyautoplanner/scanner/APK remainseparate. No visualUIredesign/Firebase/billing. Root coordinates sharedfiles andGit;domain/serviceworker ownership assigned explicitly.

## Current integration checkpoint —14October2026

Read FEATURE-STATUS.md/RECIPE-LIBRARY.md for actual built versus UI/source coverage. From-scratch publication is implemented (older unimplemented statements are historical). New bundled read-only library22source records is separate from54planning recipes; never call2not-cookable records complete or infer timings/food/rights. Build/check selected manifest via tool/recipes/build-recipe-library.mjs; preserve trusted compiled hash and exact raw source files. Modern creator6website records are not YouTube extractions (14discovery/4partial/0completevideo). Local16are user-authorized reuse of archived records, no booknetwork. Purchase preview is read-only; no monthly budget optimizer claim.

## User price-source correction —14October2026

Market retailer/delivery catalog feeds are now primary. Government statistical tables are secondary helpers and must not block implementation. MARKET-PRICE-INTEGRATIONS.md and retailer-integrations EG/SA dossiers distinguish partner own-vendor APIs from public all-store price access. Prefer cooperating merchant read-only POS/CSV or authorized Salla/Zid/catalog feed; don't claim a live relationship or reuse permission. No contacting/onboarding/credentials without direct user authorization. Offline Talabat candidate adapter is implemented; no live source connected. Keep delivery fees/pack basis/branch/observed versus effective date distinct; CPI percentage APIs cannot become currency price feeds.

User explicitly authorized continuing up to99% in this continuation. Watchdog supports --quota-limit99 only when human-authorized; default90 remains. Unknownusage/ordinaryfalse alwaysblock. No credit purchase/reset. Current readable library24records/3packs; source/rights/nutrition gates remain unchanged.

## Library review into private calculation — current §71

Follow docs/LIBRARY-RECIPE-CALCULATOR.md.31readable records are separate from54planning recipes. Persist the full RecipeLibraryDraftReview via KitchenService.saveLibraryRecipeDraft, never discard librarySource or republish library-origin content through generic authoring. Explicit every-line identities/amounts/forms/scaling/exclusions, canonical source+review pins, atomic rollback/reload/stale retry guards required. finalizePersonalRecipe blocks library-origin pending proper source-import/rights approval. Current224Flutter/analyze clean; ongoing source coverage unknowns remain. Local curation20(8/10/2),11creatorwebsite/0completeYT. Do not resume oldbooknetwork; source-backed metadata0/ranges are not guessed scalar times. No user decision changes thisunit.

## §72 attribution and core research lane

Library44/7packs/28snapshots; local28/22sourcecuisine-regionlabels,16creatorwebsite/0completeYT. Preserve singularcreator andcreatorslist via exactcreatorId scopedsourcecontext; oldreview envelopes remain readable, enrichedcurrentpins require re-review. Officialallergen evidence atdata/food/allergen-evidence/20261014 is research-only historicalSFDAmenu scope,EGunknown; no runtimealias/product/medical/currentlaw acceptance. Validate with tool/food/validate-allergen-evidence.mjs. Keep every-sourcebank batch bounded, then advance an independentcore unit; endlessready recipecollection is not a reason to starve logic/health/price coverage. User decisions unchanged; no newbooknetwork or UI/cloud/billing.

## Current §75 — research evidence and continuing work

55library records/9packs/36snapshots,36archive+19creatorwebsite;30local source labels,0newcompleteYT/automaticnutrition approvals. PRODUCT-LABEL-EVIDENCE.md defines4manufacturer website observations:13contains/3mayContain, source vocabulary proposed, market/GTIN/pack/nutrition/localbinding unknown. Read-only repository preserves deep-owned context; no medical/product acceptance. OFF documented pre-use form has draft but needs user-approved contact/submission; timerexpiry alone does not resolve401. Use independentcore work while waiting. All helpers return ownership before sharedintegration/Git; final receipt outsideGit.

## Current §76 — indexed source quantity triage

Library63 records/10 packs/44 snapshots;44 local (10 culinary fully specified/32 review/2 not cookable)+19 creator websites.38 local source region/cuisine labels, not approved national cuisines. RecipeLibraryCoverageReport is source-only read-only triage of632 lines with shared calculator source pins, not saved personal decisions or nutrition approval. Preserve repeated/excluded/optional/procedural indices; missing remains null, source zero flagged, raw units other than g/kg require explicit review. Use RECIPE-LIBRARY-COVERAGE.md before consuming counters; they overlap. Original54 planning records and no-UI/cloud/billing/medical-inference constraints unchanged.

## Current §77 — progress and source request scope

Library65 records/11packs/44snapshots=44archive+21creatorwebsite;38local source labels,0newcompleteYT. Preserve recipe-scoped sourceIndex request indexes/outcomes in private reviews; lookup by original index, not subset position. No direct-body/video/date/rights/food approval from indexed extracts. Old envelopes decode; enriched current pins require re-review. Watchdog uses latest actual task.lastProgressAt/global matching taskId, attempts only fallback. No false progress via refreshed attempts or unrelated work. See HANDOFF§77/LIBRARY-RECIPE-CALCULATOR.md; all unchanged scope decisions apply.

## Current §78 — source quantity counts

Use quantityReviewLineCount for unique pending quantity lines; missing-amount/unit/unit-review counts overlap.592of669 current source lines need quantity review. Other77 still require explicit food/form/inclusion/scaling/source acceptance.65library/38local source labels and all source/rights/runtime approvals unchanged. No saved personal-review inspection or completion percentage inferred.4focusedFlutter/analyze clean;239full atd7e444c historical.

## Current §79 — recipe line search and video evidence

66libraryrecords=44archive+21website+1indexedvideodescription;12packs/44snapshots,38local source labels. RecipeLibraryFoodSearch requires exact sourcepin/lineIndex/explicitquery; preserve owned candidates and packaged-only market scope. Explicit food/form/amount/scaling/inclusion and private review remain required. Creator-youtube validates matchingcase-sensitivevideoID/canonicalURL; website presentyoutubeDerived mustfalse, legacyomissionreadable. Indexeddescription/directbody/media/transcript/rights stay distinct.603of681source lines need quantity review; no automatic binding. Source helper14underlyingrequests exceeded8; before nextcall sumqueries+opens against remaining budget, stopbeforeoverrun. Root consolidates sharedfiles/Git. Detailed§79/DELIVERY verification. OFFneeds authorizedcontact/form separately; noUI/Firebase/billing changes.
