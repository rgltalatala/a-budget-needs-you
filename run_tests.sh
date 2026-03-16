#!/usr/bin/env bash

ROOT="$(cd "$(dirname "$0")" && pwd)"
FAILED=0

echo "========== Backend tests =========="
(cd "$ROOT/backend" && bundle exec rails test) || FAILED=1

echo ""
echo "========== Frontend tests =========="
(cd "$ROOT/frontend" && npm run test:run) || FAILED=1

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "Some tests failed."
  exit 1
fi
