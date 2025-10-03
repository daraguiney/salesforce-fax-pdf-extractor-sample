public class FaxDtos {
    public class InitRequest {
        @AuraEnabled public Id parentId;
    }
    public class InitResponse {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileDownloadUrl;
        @AuraEnabled public Integer pageCount;
    }

    public class ExtractRequest {
        @AuraEnabled public Id parentId;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String ranges; // e.g., "1-2,6-7"
    }
    public class ExtractResponse {
        @AuraEnabled public Id jobId;
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }

    public class StatusResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
        @AuraEnabled public String resultContentDocumentId;
    }
}
