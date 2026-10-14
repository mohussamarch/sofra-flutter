# Official allergen evidence — 14 October 2026

Research only; not a product allergen database or a current-law compliance engine.

- 4 source access records: 2 retrieved SFDA sources, 1 unavailable NFSA entry point, 1 timed-out SFDA FAQ.
- 7 concise source paraphrases; source URLs, authority, jurisdiction, publication uncertainty and locators are explicit.
- 15 proposed Arabic vocabulary correspondences to existing canonical identifiers: 14 allergen groups plus wheat as a separate specific ingredient.
- Exact substrings identify published vocabulary only. A group name does not establish all members or a product's allergen status. No translation/name matching is installed in Flutter.
- Contains, possible cross-contact, free-from and unknown remain distinct. Missing warnings establish no absence.
- Egypt's rules, vocabulary and declaration semantics remain unknown. Saudi/EU/US rules cannot fill that gap.
- Both documents' reuse licences remain unknown; no source body was archived, so every body SHA256 is null.
- Historical Saudi menu guidance is not a verified current consolidated packaged-food label standard. No thresholds or clinical rules were adopted.
- The notice displays 2019-09-01 while its body dateline says 2019-09-03. Its announced start date is 2019-10-01; publication dates are not inferred from PDF URL directories.

Run from the active checkout:

    node tool/food/validate-allergen-evidence.mjs
    node --test tool/food/validate-allergen-evidence.test.mjs

The validator checks local structure/provenance consistency and research boundaries. It cannot authenticate unarchived upstream text, establish current law, grant source rights, or approve a product.
