CPATH='.:lib/hamcrest-core-1.3.jar:lib/junit-4.13.2.jar'

TESTER_NAME='TestListExamples'

rm -rf student-submission
rm -rf grading-area

mkdir grading-area

# Output a line at the end of the output containing the score percentage if the --simple_output flag was passed
simple_output=false
for arg in "$@"; do
    if [ "$arg" = "--simple_output" ] || [ "$arg" = "-s" ]; then
        simple_output=true
        break
    fi
done

# Get the first non-option argument (the student's submission)
student_submission=""
for arg in "$@"; do
    if [ "${arg:0:1}" != "-" ]; then
        student_submission=$arg
        break
    fi
done

if [ -z "$student_submission" ]; then
    echo "Error: No student submission provided"
    if [ "$simple_output" = true ]; then
        echo "0.0"
    fi
    exit 1
fi

echo -n '[WAIT] Cloning student submission...'
git clone --quiet $student_submission student-submission > grading-area/clone_output.txt 2>&1
# Ensure the clone was successful
if [ $? -ne 0 ]; then
    echo -e '\r[FAIL]'
    echo "Error: Could not clone student submission"
    cat grading-area/clone_output.txt
    if [ "$simple_output" = true ]; then
        echo "0.0"
    fi
    exit 1
fi
echo -e '\r[ OK '

# Check for expected files
if [ ! -d student-submission ]; then
    echo "Internal error: unexpected directory structure"
    if [ "$simple_output" = true ]; then
        echo "0.0"
    fi
    exit 1
fi

if [ ! -f student-submission/ListExamples.java ]; then
    echo "Error: ListExamples.java not found (is it in the root of the repository?)"
    if [ "$simple_output" = true ]; then
        echo "0.0"
    fi
    exit 1
fi


# Copy our lib/ directory to ensure no fiddling with the JUnit files
cp -r lib grading-area
# Copy necessary files to grading area
cp student-submission/ListExamples.java grading-area
cp TestListExamples.java grading-area

# Compile
echo -n '[WAIT] Compiling student submission (pass 1)...'
javac -cp $CPATH grading-area/ListExamples.java > grading-area/compile_output.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e '\r[FAIL]'
    echo "Error: Compilation failed!"
    cat grading-area/compile_output.txt
    if [ "$simple_output" = true ]; then
        echo "0.0"
    fi
    exit 1
fi
echo -e '\r[ OK '

# Ensure we have the functions:
# - static List<String> filter(List<String> <NAME>, StringChecker <NAME>)
# - static List<String> merge(List<String> <NAME>, List<String> <NAME>)
echo -n '[WAIT] Checking function headers...'
filter_present=false
javap -cp grading-area ListExamples > grading-area/javap_output.txt
if grep -q 'filter(java.util.List<java.lang.String>, StringChecker)' grading-area/javap_output.txt; then
    filter_present=true
else
    echo -e '\r[FAIL]'
    echo "Error: filter function with correct signature not found"
    if [ "$simple_output" = true ]; then
        echo "0.0"
    fi
    exit 1
fi
if grep -q 'merge(java.util.List<java.lang.String>, java.util.List<java.lang.String>)' grading-area/javap_output.txt; then
    merge_present=true
else
    echo -e '\r[FAIL]'
    echo "Error: merge function with correct signature not found"
    if [ "$simple_output" = true ]; then
        echo "0.0"
    fi
    exit 1
fi
echo -e '\r[ OK '

# Compile the test file
echo -n '[WAIT] Compiling (pass 2)...'
javac -cp $CPATH grading-area/TestListExamples.java grading-area/ListExamples.java > grading-area/compile_output.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e '\r[FAIL]'
    echo "Error: Compilation failed!"
    cat grading-area/compile_output.txt
    if [ "$simple_output" = true ]; then
        echo "0.0"
    fi
    exit 1
fi
echo -e '\r[ OK '


# Check if the --full_error or -f flags were passed
full_error=false
for arg in "$@"; do
    if [ "$arg" = "--full_error" ] || [ "$arg" = "-f" ]; then
        full_error=true
        break
    fi
done

# Run tests
echo -n '[WAIT] Running tests...'
# Run the tests, storing the output to a buffer file    
java -cp $CPATH:grading-area org.junit.runner.JUnitCore TestListExamples > grading-area/test_output.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e '\r[ OK '

    time_taken=$(grep -oE 'Time: [0-9.]+' grading-area/test_output.txt | grep -oE '[0-9.]+')
    echo "Tests ran in $time_taken seconds"

    echo "Coverage: 100% (all tests passed)"

    if [ "$simple_output" = true ]; then
        echo "1.0"
    fi
else
    echo -e '\r[ OK '

    time_taken=$(grep -oP 'Time: \K[0-9.]+' grading-area/test_output.txt)
    echo "Tests ran in $time_taken seconds"

    num_failures=$(awk 'NR==4' grading-area/test_output.txt | grep -oE '[0-9]+')

    num_tests=$(awk 'NR==2' grading-area/test_output.txt | grep -oP '\.' | wc -l)

    num_passed=$((num_tests - num_failures))
    percent_coverage=$((num_passed * 100 / num_tests))
    echo "Coverage: $num_passed/$num_tests ($percent_coverage%) with $num_failures failures"

    if [ "$full_error" = true ]; then
        echo -e "\nJUnit output:"
        cat grading-area/test_output.txt
    else
        failure_lines=$(grep -nP '^[0-9]+\) .+\('$TESTER_NAME'\)' grading-area/test_output.txt | cut -d: -f1)

        for line in $failure_lines; do
            # Get the test number
            test_num=$(awk -v line="$line" 'NR==line' grading-area/test_output.txt | grep -oP '^[0-9]+')
            echo -e "\nTest $test_num failed:"

            error_message=$(awk -v line="$line" 'NR==line+1' grading-area/test_output.txt)
            location_at=$(awk -v line="$line" 'NR==line+2' grading-area/test_output.txt | sed -e 's/^[ \t]*//')
            echo "$error_message  --> $location_at"
        done
        echo -e "\nRun with --full_error or -f for full error messages."
    fi

    if [ "$simple_output" = true ]; then
        # Convert percent coverage to a decimal without bc
        decimal_coverage=$((percent_coverage * 10 / 100))
        echo "0.$decimal_coverage"
    fi
fi