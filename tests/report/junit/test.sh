#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup
        rlRun "pushd data"
        rlRun "set -o pipefail"
    rlPhaseEnd

    # Basic format checks
    for method in tmt; do
        rlPhaseStartTest "$method"
            rlRun "tmt run -avr execute -h $method report -h junit --file junit.xml 2>&1 >/dev/null | tee output" 2
            rlAssertGrep "3 tests passed, 2 tests failed and 2 errors" "output"
            rlAssertGrep '00:00:00 pass /test/shell/escape"<speci&l>_chars (on default-0)' "output"
            rlAssertGrep '<testsuite name="/plan" disabled="0" errors="2" failures="2" skipped="0" tests="7"' "junit.xml"
            rlAssertGrep 'fail</failure>' "junit.xml"

            # Test the escape of special characters
            rlAssertGrep '<testcase name="/test/shell/escape&quot;&lt;speci&amp;l&gt;_chars">' "junit.xml"
            rlAssertGrep '<system-out>&lt;speci&amp;l&gt;"chars' "junit.xml"
        rlPhaseEnd
    done

    # Check the flavor argument
    for method in tmt; do
        rlPhaseStartTest "$method"
            rlRun "tmt run -avr execute -h $method report -h junit --file junit.xml --flavor default 2>&1 >/dev/null | tee output" 2
            rlAssertGrep "3 tests passed, 2 tests failed and 2 errors" "output"
        rlPhaseEnd
    done

    # Check the mutually exclusive arguments
    for method in tmt; do
        rlPhaseStartTest "$method"
            rlRun "tmt run -avr execute -h $method report -h junit --file junit.xml --flavor custom 2>&1 >/dev/null | tee output" 2
            rlAssertGrep "The 'custom' flavor requires the '--template-path' argument." "output"

            rlRun "tmt run -avr execute -h $method report -h junit --file junit.xml --template-path custom.xml.j2 2>&1 >/dev/null | tee output" 2
            rlAssertGrep "The '--template-path' can be used only with '--flavor=custom'." "output"

        rlPhaseEnd
    done

    # Check the 'custom' flavor with a custom XML template
    for method in tmt; do
        rlPhaseStartTest "$method"
            rlRun "tmt run -avr execute -h $method report -h junit --file custom-template-out.xml --template-path custom.xml.j2 --flavor custom 2>&1 >/dev/null | tee output" 2

            rlAssertGrep '<test name="/test/beakerlib/fail" value="fail"/>' "custom-template-out.xml"
            rlAssertGrep '<test name="/test/beakerlib/pass" value="pass"/>' "custom-template-out.xml"
            rlAssertGrep '<test name="/test/shell/pass" value="pass"/>' "custom-template-out.xml"
            rlAssertGrep '<test name="/test/shell/timeout" value="error"/>' "custom-template-out.xml"
            rlAssertGrep '<test name="/test/shell/escape&quot;&lt;speci&amp;l&gt;_chars" value="pass"/>' "custom-template-out.xml"
        rlPhaseEnd
    done

    # The 'custom' flavor with a custom **non-XML** template must not work
    for method in tmt; do
        rlPhaseStartTest "$method"
            rlRun "tmt run -avr execute -h $method report -h junit --file custom-template-out.xml --template-path non-xml-custom.j2 --flavor custom 2>&1 >/dev/null | tee output" 2

            rlAssertGrep 'The generated XML output is not a valid XML file.' "output"
        rlPhaseEnd
    done

    rlPhaseStartCleanup
        rlRun "rm output junit.xml custom-template-out.xml"
        rlRun "popd"
    rlPhaseEnd
rlJournalEnd
