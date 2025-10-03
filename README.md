# Salesforce Fax PDF Extractor (Sample)

A minimal, vendor-agnostic example showing how to:
- Preview inbound PDF faxes in a Lightning Web Component (LWC)
- Accept page ranges (e.g., 1–2,6–7)
- Extract selected pages into a new PDF attachment
- Track job status asynchronously (Queueable)
- Keep a clean service architecture with idempotency

This sample is sanitized for public viewing and uses only platform features.

## Highlights
- LWC previews the original PDF and lets users enter page ranges.
- Async Apex performs extraction and links the result to a parent record.
- Fax_Job__c tracks status, idempotency keys, and logs.
- ContentVersion is used for file storage.

## LWC init: what this code does
The connectedCallback loads client-side PDF utilities, then fetches the source doc and syncs job status:
- `loadScript(pdf-lib)`: on-page PDF parsing/manipulation for preview
- `loadScript(FileSaver)`: enables client-side save/downloads (optional)
- Small delay to ensure libs are initialized
- `loadFaxDocument()`: retrieves the source PDF blob/URL
- `checkExtractionStatus()`: polls server to show active/completed jobs

## Setup
1. Deploy metadata with SFDX or Metadata API.
2. Ensure you have a parent record (default is Case) and at least one ContentVersion PDF related to it (via ContentDocumentLink).
3. Grant permissions:
   - Read on Case (or your chosen parent object)
   - Read/Create on ContentVersion
   - Read/Create/Update on Fax_Job__c
4. Add the `pdfExtractor` LWC to a Lightning Record Page (Case by default).
5. Open a Case with a PDF file attached and test page extraction.

## Configuration
- Parent object default: Case. Change `PARENT_SOBJECT` in FaxPdfService to your object (e.g., `Referral__c`).
- Idempotency key: generated from source ContentDocumentId + normalized page ranges.
- Extraction: simulated in Apex. To integrate a real PDF microservice, replace `FaxPdfService.extractPages()` with a callout and Named Credential.

## Notes
- This sample is deliberately simple. It avoids provider specifics and external keys.
- For large documents, consider chunked callouts or batchable chaining.

## License
MIT
