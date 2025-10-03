@IsTest
private class FaxPdfTests {
    @IsTest
    static void initFindsPdf() {
        Case c = FaxTestDataFactory.makeCase();
        ContentDocument cd = FaxTestDataFactory.makePdfOn(c.Id);
        Test.startTest();
        FaxDtos.InitResponse res = FaxPdfController.init(c.Id);
        Test.stopTest();
        System.assertEquals(cd.Id, res.contentDocumentId);
        System.assertNotEquals(null, res.fileDownloadUrl);
    }

    @IsTest
    static void requestAndRunQueueable() {
        Case c = FaxTestDataFactory.makeCase();
        ContentDocument cd = FaxTestDataFactory.makePdfOn(c.Id);
        Test.startTest();
        FaxDtos.ExtractResponse resp = FaxPdfController.requestExtraction(c.Id, cd.Id, '1-2,2,5-6');
        // Should be queued
        System.assertEquals('Queued', resp.status);
        // Run queueable
        Test.stopTest();

        // Check status via controller
        FaxDtos.StatusResponse status = FaxPdfController.checkStatus(cd.Id, '1-2,2,5-6');
        System.assertEquals('Completed', status.status);
        System.assertNotEquals(null, status.resultContentDocumentId);
    }

    @IsTest
    static void idempotentRequests() {
        Case c = FaxTestDataFactory.makeCase();
        ContentDocument cd = FaxTestDataFactory.makePdfOn(c.Id);

        Test.startTest();
        FaxDtos.ExtractResponse r1 = FaxPdfController.requestExtraction(c.Id, cd.Id, '1,2,3');
        Test.stopTest();

        // Second request with same ranges should reuse job
        FaxDtos.ExtractResponse r2 = FaxPdfController.requestExtraction(c.Id, cd.Id, '1-3');
        System.assertEquals(r1.jobId, r2.jobId);
    }
}
