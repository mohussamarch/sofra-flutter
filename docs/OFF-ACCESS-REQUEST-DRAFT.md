# Open Food Facts — prepared usage-form draft

Status: prepared for review only; not submitted, no account/contact/message created.

## Why this is needed

The current official API introduction asks users to read its reuse terms and complete the API usage form before using the API. It recommends direct exports when collecting more than a few hundred products. Our previous HTTP401 has not been diagnosed; completing the form is not a guarantee that it will resolve that response.

- Documentation: https://openfoodfacts.github.io/openfoodfacts-server/api/
- Linked form: https://docs.google.com/forms/d/e/1FAIpQLSdIE3D8qvjC_zRJw1W8OmuHhsWJ_NSckiiniAHlfaVwUZCziQ/viewform
- Checked14October2026. No authentication or alternate endpoint was attempted during this review.

## Fields actually visible on the first form page

| Field | Prepared answer |
|---|---|
| Email (required) | Awaiting the user's chosen contact address; none supplied or inferred |
| App topic | nutrition |

Later form pages have not been inspected because the first page requires the contact address. Do not claim these are all fields or submit unknown answers.

## Project description prepared if requested on later pages

Sofra (سُفرة) is an Android/Flutter meal-planning and kitchen-inventory prototype. We intend to use product barcodes, ingredient declarations and nutritional facts, with initial interest in Egypt and Saudi Arabia. Data keeps provenance and uncertainty; imported community records are not automatically verified nutrition or allergen facts. The current use is read-only research, with no planned product edits or image uploads in this request. We will review the documented export route for larger datasets and retain the source licence/attribution requirements.

No contact email, legal/company identity, launch date, traffic projection or licence acceptance is invented. Additional fields require factual answers. No passwords, keys or tokens belong in this form or draft.

## Authorization boundary and next action

Submitting the form sends the chosen email and project-use information to Open Food Facts through its linked Google Form. The user has authorized research, but has not authorized this external submission or provided a contact address. Request those two items together; once granted, inspect the remaining form pages, prepare factual answers and proceed only within the approved scope. If a field cannot be answered from project facts, ask for that missing information while continuing independent recipe/logic work.

Until resolved, preserve the existing collector checkpoints and HTTP backoff; do not repeatedly retry401 or change source routes/accounts. Product bank stays2378 records/67 archives. This access draft is not product growth, source permission or source-side approval.
