public class FaxIdempotency {
    // Create a deterministic idempotency key from source + normalized ranges
    public static String makeKey(String contentDocumentId, String normalizedRanges) {
        // Simple, readable key; replace with a hash if you prefer fixed length
        return contentDocumentId + '|' + normalizedRanges;
    }
}
