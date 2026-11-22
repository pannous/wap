# the helper of the shell tests that check what a run says (source it): check <what> <got> <expected> counts a failure
failures=0
check() {
	if [ "$2" = "$3" ]; then echo "✓ $1"; else echo "✗ $1: got $2, expected $3"; failures=$((failures + 1)); fi
}
