public with sharing class FaxPdfService {
    public static final String PARENT_SOBJECT = 'Case'; // change to your object API name as needed

    public class SourceDocInfo {
        public String contentDocumentId;
        public String fileName;
        public String fileDownloadUrl;
        public Integer pageCount;
    }

    // Returns the most recent PDF ContentDocument linked to ParentId.
    public static SourceDocInfo init(Id parentId) {
        if (parentId == null) throw new AuraHandledException('ParentId required.');
        // Enforce access to parent
        sObject parent = Database.query('SELECT Id FROM ' + PARENT_SOBJECT + ' WHERE Id = :parentId');
        if (parent == null) throw new AuraHandledException('Parent not found');

        ContentDocumentLink cdl = [
            SELECT ContentDocumentId, ContentDocument.Title,
                   ContentDocument.LatestPublishedVersionId,
                   ContentDocument.FileType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentId
            ORDER BY SystemModstamp DESC
            LIMIT 1
        ];
        if (cdl == null || cdl.ContentDocument.FileType != 'PDF') {
            throw new AuraHandledException('No PDF found on the record.');
        }
        ContentVersion cv = [
            SELECT Id, Title, ContentDocumentId, VersionData, FileExtension
            FROM ContentVersion
            WHERE Id = :cdl.ContentDocument.LatestPublishedVersionId
            LIMIT 1
        ];

        // NOTE: Apex cannot count PDF pages natively; in a real system, store pageCount upon ingest or query from a service.
        Integer pageCount = null;

        SourceDocInfo info = new SourceDocInfo();
        info.contentDocumentId = cdl.ContentDocumentId;
        info.fileName = cv.Title + '.' + cv.FileExtension;
        info.fileDownloadUrl = '/sfc/servlet.shepherd/document/download/' + cdl.ContentDocumentId;
        info.pageCount = pageCount;
        return info;
    }

    public class ExtractionResult {
        public String resultContentDocumentId;
        public String message;
    }

    // Simulated extraction: stores a new ContentVersion with ranges metadata in the title.
    public static ExtractionResult extractPages(Id parentId, String contentDocumentId, String normalizedRanges) {
        if (parentId == null || String.isBlank(contentDocumentId) || String.isBlank(normalizedRanges)) {
            throw new AuraHandledException('Invalid extraction request.');
        }

        // Enforce access to parent
        sObject parent = Database.query('SELECT Id FROM ' + PARENT_SOBJECT + ' WHERE Id = :parentId');

        ContentVersion src = [
            SELECT Id, VersionData, Title, ContentDocumentId, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];

        // In a real system, call out to a PDF service with src.VersionData + ranges,
        // then create a new ContentVersion with the resulting bytes.
        // Here we simulate by reusing the same bytes and annotating the title.

        ContentVersion cv = new ContentVersion();
        cv.Title = src.Title + ' (Pages ' + normalizedRanges + ')';
        cv.PathOnClient = cv.Title + '.' + src.FileExtension;
        cv.VersionData = src.VersionData; // placeholder: same data
        insert cv;

        // Link to parent
        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = parentId,
            ShareType = 'V'
        );

        ExtractionResult res = new ExtractionResult();
        res.resultContentDocumentId = cv.ContentDocumentId;
        res.message = 'Extraction simulated. Replace with real service for actual page slicing.';
        return res;
    }

    // Create or fetch an idempotent job. If an identical job exists and completed, return it.
    public static Fax_Job__c upsertJob(Id parentId, String contentDocumentId, String normalizedRanges) {
        String key = FaxIdempotency.makeKey(contentDocumentId, normalizedRanges);
        List<Fax_Job__c> existing = [
            SELECT Id, Status__c, ResultContentDocumentId__c
            FROM Fax_Job__c
            WHERE IdempotencyKey__c = :key
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return existing[0];
        }
        Fax_Job__c job = new Fax_Job__c();
        job.ParentId__c = parentId;
        job.SourceContentDocumentId__c = contentDocumentId;
        job.Ranges__c = normalizedRanges;
        job.Status__c = 'Queued';
        job.IdempotencyKey__c = key;
        insert job;
        return job;
    }

    public static void markProcessing(Id jobId) {
        update new Fax_Job__c(Id = jobId, Status__c = 'Processing');
    }
    public static void markCompleted(Id jobId, String resultDocId, String message) {
        Fax_Job__c j = new Fax_Job__c(Id = jobId);
        j.Status__c = 'Completed';
        j.ResultContentDocumentId__c = resultDocId;
        j.Log__c = message;
        update j;
    }
    public static void markFailed(Id jobId, String message) {
        Fax_Job__c j = new Fax_Job__c(Id = jobId);
        j.Status__c = 'Failed';
        j.Log__c = message;
        update j;
    }
}
