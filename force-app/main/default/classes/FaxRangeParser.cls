public class FaxRangeParser {
    public class PageRange {
        public Integer start;
        public Integer end;
        public PageRange(Integer s, Integer e) {
            start = s; end = e;
        }
    }

    // Normalize input like "1-2, 2, 5-7, 7-9" into merged, sorted, non-overlapping ranges.
    public static List<PageRange> normalize(String input, Integer maxPage) {
        if (String.isBlank(input)) {
            throw new AuraHandledException('Page ranges required.');
        }
        List<PageRange> ranges = new List<PageRange>();
        for (String token : input.replaceAll('\\s+', '').split(',')) {
            if (String.isBlank(token)) continue;
            Integer s, e;
            if (token.contains('-')) {
                List<String> parts = token.split('-');
                if (parts.size() != 2) throw new AuraHandledException('Invalid range: ' + token);
                s = Integer.valueOf(parts[0]);
                e = Integer.valueOf(parts[1]);
            } else {
                s = Integer.valueOf(token);
                e = s;
            }
            if (s <= 0 || e <= 0 || (maxPage != null && (s > maxPage || e > maxPage))) {
                throw new AuraHandledException('Range out of bounds: ' + token);
            }
            if (s > e) {
                Integer tmp = s; s = e; e = tmp;
            }
            ranges.add(new PageRange(s, e));
        }
        ranges.sort(new PageRangeComparator());
        ranges = mergeRanges(ranges);
        return ranges;
    }

    private class PageRangeComparator implements System.Comparator<PageRange> {
        public Integer compare(PageRange a, PageRange b) {
            if (a.start == b.start) return 0;
            return a.start < b.start ? -1 : 1;
        }
    }

    private static List<PageRange> mergeRanges(List<PageRange> ranges) {
        if (ranges.isEmpty()) return ranges;
        List<PageRange> merged = new List<PageRange>();
        PageRange cur = ranges[0];
        for (Integer i = 1; i < ranges.size(); i++) {
            PageRange nxt = ranges[i];
            if (nxt.start <= cur.end + 1) {
                cur.end = Math.max(cur.end, nxt.end);
            } else {
                merged.add(cur);
                cur = nxt;
            }
        }
        merged.add(cur);
        return merged;
    }

    public static String toRangeString(List<PageRange> ranges) {
        List<String> out = new List<String>();
        for (PageRange r : ranges) {
            out.add(r.start == r.end ? String.valueOf(r.start) : (r.start + '-' + r.end));
        }
        return String.join(',', out);
    }
}
