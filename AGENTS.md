# Brinkball agent guide

Inspect `git status` before editing and preserve unrelated work. Keep benchmark evidence,
human playtest results and App Store outcomes factual; never infer missing results.

## Physical iPhone testing

When Tom asks to run or test the app on his attached iPhone, discover the current
`.xcodeproj` or `.xcworkspace` and shared scheme. Prefer the workspace when the project
uses workspace-managed dependencies, then run from the repository root:

```bash
/Users/tommurton/GitHub/Build-an-app/scripts/test-on-iphone.sh <container> <scheme>
```

Use the helper's final `PHYSICAL_IPHONE_TESTS_PASSED` or
`PHYSICAL_IPHONE_TESTS_FAILED` line as the result. Swift Testing results are separate
from XCTest's potentially misleading `Executed 0 tests` footer. If the scheme has no
test action or tests, report that limitation rather than treating build success as test
coverage.
