@IsTest
public class FaxTestDataFactory {
    public static Case makeCase() {
        Case c = new Case(Subject = 'Test');
        insert c;
        return c;
    }

    public static ContentDocument makePdfOn(Id parentId) {
        // Minimal PDF bytes ("%PDF-1.4..." header with EOF). This is a tiny legal PDF.
        Blob pdf = Blob.valueOf('%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF');
        ContentVersion cv = new ContentVersion(
            Title = 'Sample',
            PathOnClient = 'sample.pdf',
            VersionData = pdf
        );
        insert cv;

        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = parentId,
            ShareType = 'V'
        );
        return [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];
    }
}
