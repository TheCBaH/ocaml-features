#!/bin/sh
# Fails if src/*/devcontainer-feature.json changed relative to origin/main
# without a version bump, so a green merge never silently publishes nothing.
set -eu

if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
    echo "origin/main does not exist yet; skipping version-bump check"
    exit 0
fi

status=0
for feature_json in src/*/devcontainer-feature.json; do
    if git diff --quiet origin/main -- "$(dirname "$feature_json")"; then
        continue
    fi
    old_version=$(git show "origin/main:$feature_json" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' || echo "")
    new_version=$(python3 -c 'import json; print(json.load(open("'"$feature_json"'"))["version"])')
    if [ "$old_version" = "$new_version" ]; then
        echo "::error file=$feature_json::$(dirname "$feature_json") changed but version is still $new_version (was $old_version on origin/main)"
        status=1
    else
        echo "$feature_json: $old_version -> $new_version"
    fi
done
exit $status
