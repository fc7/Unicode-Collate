#!/bin/sh

echo "Running UCA conformance tests ... Be patient!"
TEST_UCA_CONFORMANCE=1 perl -Mblib t/uca_conformance_shifted.t 2>&1 | tee > t/uca_conformance_shifted.log
TEST_UCA_CONFORMANCE=1 perl -Mblib t/uca_conformance_non_ignorable.t 2>&1 | tee > t/uca_conformance_non_ignorable.log
echo "Done: see log files under t/uca_conformance_*.log"
