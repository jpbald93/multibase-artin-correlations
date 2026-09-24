#!/bin/bash
# Gate: the build must succeed; no sorry/admit/native_decide and no axiom declarations
# anywhere (including `private axiom`); every REQUIRED theorem must have its axioms
# printed, and every theorem may depend only on a SUBSET of Lean's three standard
# axioms (propext, Classical.choice, Quot.sound). Wrapped axiom lists are flattened
# before parsing.
export PATH="$HOME/.elan/bin:$PATH"
cd "$(dirname "$0")" || exit 1
SRC_GLOB="MixedExclusion/*.lean MixedExclusion.lean"
REQUIRED="MixedExclusion.legendreSym_eq_neg_one_of_isPrimitiveRoot MixedExclusion.isSquare_three_iff MixedExclusion.not_primitiveRoot_two_six_of_gap MixedExclusion.not_primitiveRoot_six_two_of_gap"
if grep -rqnE "\bsorry\b|\badmit\b|native_decide|(^|[[:space:]])axiom[[:space:]]" $SRC_GLOB; then
  echo "FAIL: sorry/admit/native_decide or an axiom declaration present"; exit 1; fi
out=$(lake build 2>&1)
echo "$out" | grep -q "Build completed successfully" || { echo "FAIL: build"; echo "$out" | grep -E "error:" | head; exit 1; }
# flatten: join continuation lines of wrapped axiom lists onto their "info:" line
flat=$(echo "$out" | awk '/^(info|warning|error|✔|⚠|✖|Build|trace)/{if(buf!="")print buf; buf=$0; next} {buf=buf" "$0} END{if(buf!="")print buf}')
lines=$(echo "$flat" | grep "depends on axioms")
for t in $REQUIRED; do
  echo "$lines" | grep -q "'$t' depends on axioms" || { echo "FAIL: no axiom report for required theorem $t"; exit 1; }
done
n=$(echo "$lines" | grep -c "depends on axioms")
bad=$(echo "$lines" | sed 's/.*depends on axioms: \[//; s/\].*//' | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort -u | grep -vE '^(propext|Classical\.choice|Quot\.sound)$')
[ -n "$bad" ] && { echo "FAIL: nonstandard axioms: $bad"; exit 1; }
echo "$flat" | grep -q "does not depend on any axioms" && n=$((n + $(echo "$flat" | grep -c "does not depend on any axioms")))
echo "PASS ($n theorems, standard axioms only)"
