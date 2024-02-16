import static org.junit.Assert.*;
import org.junit.*;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

class IsMoon implements StringChecker {
    public boolean checkString(String s) {
        return s.equalsIgnoreCase("moon");
    }
}

class IsNumeric implements StringChecker {
    public boolean checkString(String s) {
        return s.matches("-?\\d+(\\.\\d+)?");
    }

}

public class TestListExamples {
    @Test(timeout = 500)
    public void testMergeRightEnd() {
        List<String> left = Arrays.asList("a", "b", "c");
        List<String> right = Arrays.asList("a", "d");
        List<String> merged = ListExamples.merge(left, right);
        List<String> expected = Arrays.asList("a", "a", "b", "c", "d");
        assertEquals(expected, merged);
    }

    @Test
    public void testFilter() {
        List<String> list = Arrays.asList("moon", "sun", "moon", "moon", "sun");
        List<String> filtered = ListExamples.filter(list, new IsMoon());
        List<String> expected = Arrays.asList("moon", "moon", "moon");
        assertEquals(expected, filtered);

        List<String> list2 = Arrays.asList("moon", "sun", "moon", "moon", "sun");
        List<String> filtered2 = ListExamples.filter(list2, new StringChecker() {
            public boolean checkString(String s) {
                return s.equalsIgnoreCase("sun");
            }
        });
        List<String> expected2 = Arrays.asList("sun", "sun");
        assertEquals(expected2, filtered2);
        
        // The objects should be different
        assertNotSame("objects same but", filtered, filtered2);

        // Run tests with the numeric checker
        List<String> list3 = Arrays.asList("1", "2", "3", "4", "5");
        List<String> filtered3 = ListExamples.filter(list3, new IsNumeric());
        List<String> expected3 = Arrays.asList("1", "2", "3", "4", "5");
        assertEquals(expected3, filtered3);

        List<String> list4 = Arrays.asList("1", "2", "b", "4", "and");
        List<String> filtered4 = ListExamples.filter(list4, new IsNumeric());
        List<String> expected4 = Arrays.asList("1", "2", "4");
    }
}
