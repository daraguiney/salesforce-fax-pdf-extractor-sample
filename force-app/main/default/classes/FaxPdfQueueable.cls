public with sharing class FaxPdfQueueable implements Queueable, Database.AllowsCallouts {
    private Id parentId;
    private String contentDocumentId;
    private String normalizedRanges;
    private Id jobId;

    public FaxPdfQueueable(Id parentId, String contentDocumentId, String normalizedRanges, Id jobId) {
        this.parentId = parentId;
        this.contentDocumentId = contentDocumentId;
        this.normalizedRanges = normalizedRanges;
        this.jobId = jobId;
    }

    public void execute(QueueableContext context) {
        try {
            FaxPdfService.markProcessing(jobId);
            FaxPdfService.ExtractionResult res =
                FaxPdfService.extractPages(parentId, contentDocumentId, normalizedRanges);
            FaxPdfService.markCompleted(jobId, res.resultContentDocumentId, res.message);
        } catch (Exception e) {
            FaxPdfService.markFailed(jobId, e.getMessage());
            throw e;
        }
    }
}
