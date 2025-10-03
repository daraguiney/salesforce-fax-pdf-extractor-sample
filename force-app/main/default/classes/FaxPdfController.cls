public with sharing class FaxPdfController {
    @AuraEnabled(cacheable=true)
    public static FaxDtos.InitResponse init(Id parentId) {
        FaxPdfService.SourceDocInfo info = FaxPdfService.init(parentId);

        FaxDtos.InitResponse res = new FaxDtos.InitResponse();
        res.contentDocumentId = info.contentDocumentId;
        res.fileName = info.fileName;
        res.fileDownloadUrl = info.fileDownloadUrl;
        res.pageCount = info.pageCount; // may be null if unknown
        return res;
    }

    @AuraEnabled
    public static FaxDtos.ExtractResponse requestExtraction(Id parentId, String contentDocumentId, String ranges) {
        // Normalize and validate ranges; if pageCount unknown, allow numeric validation only
        List<FaxRangeParser.PageRange> normalized = FaxRangeParser.normalize(ranges, null);
        String normalizedStr = FaxRangeParser.toRangeString(normalized);

        Fax_Job__c job = FaxPdfService.upsertJob(parentId, contentDocumentId, normalizedStr);
        FaxDtos.ExtractResponse res = new FaxDtos.ExtractResponse();
        res.jobId = job.Id;
        if (job.Status__c == 'Completed') {
            res.status = 'Completed';
            res.message = 'Previously completed job returned.';
            return res;
        }

        System.enqueueJob(new FaxPdfQueueable(parentId, contentDocumentId, normalizedStr, job.Id));
        res.status = 'Queued';
        res.message = 'Extraction queued.';
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static FaxDtos.StatusResponse checkStatus(String contentDocumentId, String ranges) {
        String normalizedStr = FaxRangeParser.toRangeString(FaxRangeParser.normalize(ranges, null));
        String key = FaxIdempotency.makeKey(contentDocumentId, normalizedStr);
        List<Fax_Job__c> jobs = [
            SELECT Status__c, ResultContentDocumentId__c, Log__c
            FROM Fax_Job__c
            WHERE IdempotencyKey__c = :key
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        FaxDtos.StatusResponse res = new FaxDtos.StatusResponse();
        if (jobs.isEmpty()) {
            res.status = 'NotFound';
            res.message = 'No job for this source + ranges.';
            return res;
        }
        Fax_Job__c j = jobs[0];
        res.status = j.Status__c;
        res.message = j.Log__c;
        res.resultContentDocumentId = j.ResultContentDocumentId__c;
        return res;
    }
}
