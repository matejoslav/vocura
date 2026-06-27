# VocuraKit SPM Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move all of Vocura's logic and UI into a Swift Package (`VocuraKit`) so unit tests run as fast "logic tests" against the library instead of launching the host app — which permanently removes the Keychain password prompt during tests and lets `SettingsManager` keep a fat, honest `init`.

**Architecture:** The app becomes a thin shell. `VocuraKit` (an SPM library at the repo root) contains everything currently under `Sources/Core`, `Sources/UI`, `Sources/utils`. The app target `Vocura` contains only `App/VocuraApp.swift` (`@main` + `AppDelegate`) and links `VocuraKit`. Tests move into the package's test target and run via `swift test` with no host application, so the app never boots during testing.

**Tech Stack:** Swift 6.3 toolchain, swift-tools 5.9, SwiftPM, XcodeGen 2.45, XCTest, macOS 14 deployment target.

## Global Constraints

- macOS deployment target: `14.0` (verbatim, both `Package.swift` and `project.yml`)
- `SWIFT_VERSION`: `5.9`; swift-tools-version: `5.9`
- Bundle identifier: `dev.matejoslav.vocura`
- Keychain service string stays `com.vocura.app` (in `KeychainHelper`) — do not change
- Code signing: `CODE_SIGN_STYLE: Automatic`, `CODE_SIGN_IDENTITY: "-"`
- Every commit must leave both `swift test` green AND `xcodebuild build` (app) succeeding
- This is a refactor: behavior is unchanged for the shipping app. Success = same tests pass, plus no Keychain prompt during `swift test`.
- Do NOT change unrelated code, comments, or formatting (CLAUDE.md §3 Surgical Changes)

---

## File Structure (target end state)

```
vocura/
├── Package.swift                         # NEW — defines VocuraKit + VocuraKitTests
├── App/
│   └── VocuraApp.swift                   # moved; the ONLY app-target source
├── Sources/VocuraKit/
│   ├── Core/        (Constants, KeychainHelper, HotkeyManager, STTService,
│   │                 TextInserter, KeyShortcut, AudioRecorder, SettingsManager)
│   ├── Core/Protocols/ (the 6 protocol files)
│   ├── UI/          (SettingsView, BubbleView, ShortcutRecorder, FloatingBubbleWindow)
│   └── utils/       (BubblePositioner)
├── Tests/VocuraKitTests/                 # moved from Tests/
│   ├── *.swift  (all test files, @testable import VocuraKit)
│   └── Mocks/
├── Resources/                            # unchanged — stays with the app target
│   ├── Info.plist
│   └── Vocura.entitlements
└── project.yml                           # app target only + local package dependency
```

**Responsibilities:**
- `Package.swift` — declares the library product and test target; the single source of truth for `swift test`.
- `App/VocuraApp.swift` — app lifecycle only: `@main`, menu bar, activation policy, accessibility prompt, wiring `hotkeyAction`.
- `Sources/VocuraKit/**` — all domain logic + SwiftUI/AppKit UI. Public surface only where the app shell needs it.
- `Tests/VocuraKitTests/**` — logic tests; no host app.

---

## Task 0: Create a working branch

**Files:** none

- [ ] **Step 1: Confirm clean tree on main and branch**

Run:
```bash
cd /Users/matejoslav/projects/vocura
git status --short
git checkout -b spm-extraction
```
Expected: working tree has the current uncommitted DI/bootstrap work. If anything is uncommitted, commit it first on `main` (or stash) so this branch starts from a known state, then branch.

> NOTE: If the prior session's bootstrap work is still uncommitted, commit it on `main` BEFORE branching:
> ```bash
> git add -A && git commit -m "refactor: isolate tests from Keychain via bootstrap()"
> ```
> Then `git checkout -b spm-extraction`.

---

## Task 1: Restructure into the `VocuraKit` package (no behavior change)

This is one atomic structural move — the repo is not buildable half-done, so all moves + config land together, but each step is independently verified. The workaround code (`bootstrap()`, `Constants.Environment`, `AppEnvironmentTests`, the `AppDelegate` guard) is **kept as-is** in this task; Task 2 removes it.

**Files:**
- Create: `Package.swift`
- Move: `Sources/Core` → `Sources/VocuraKit/Core`
- Move: `Sources/UI` → `Sources/VocuraKit/UI`
- Move: `Sources/utils` → `Sources/VocuraKit/utils`
- Move: `Sources/VocuraApp.swift` → `App/VocuraApp.swift`
- Move: `Tests/*.swift` → `Tests/VocuraKitTests/`, `Tests/Mocks` → `Tests/VocuraKitTests/Mocks`
- Modify: `Sources/VocuraKit/UI/SettingsView.swift` (access levels)
- Modify: `Sources/VocuraKit/UI/FloatingBubbleWindow.swift` (access levels)
- Modify: every file under `Tests/VocuraKitTests/` (`@testable import Vocura` → `@testable import VocuraKit`)
- Rewrite: `project.yml`

**Interfaces:**
- Produces: SPM product `VocuraKit` (library). Public symbols the app shell consumes: `SettingsManager` (already public) `.shared`/`.hotkeyAction`/`.bootstrap()`; `WindowManager` → `public`, `WindowManager.shared` → `public`, `WindowManager.toggleRecording()` → `public`; `SettingsView` → `public struct` + `public init()` + `public var body`; `Constants` (already public).
- Consumes: nothing from later tasks.

- [ ] **Step 1: Create `Package.swift`**

Create `Package.swift`:
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VocuraKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "VocuraKit", targets: ["VocuraKit"]),
    ],
    targets: [
        .target(name: "VocuraKit"),
        .testTarget(name: "VocuraKitTests", dependencies: ["VocuraKit"]),
    ]
)
```

- [ ] **Step 2: Move source files into the package layout**

Run:
```bash
cd /Users/matejoslav/projects/vocura
mkdir -p Sources/VocuraKit App
git mv Sources/Core  Sources/VocuraKit/Core
git mv Sources/UI    Sources/VocuraKit/UI
git mv Sources/utils Sources/VocuraKit/utils
git mv Sources/VocuraApp.swift App/VocuraApp.swift
```
Expected: `git status` shows the renames; `Sources/` now contains only `VocuraKit/`.

- [ ] **Step 3: Move test files into the package test target**

Run:
```bash
cd /Users/matejoslav/projects/vocura
mkdir -p Tests/VocuraKitTests
git mv Tests/Mocks Tests/VocuraKitTests/Mocks
for f in Tests/*.swift; do git mv "$f" Tests/VocuraKitTests/; done
```
Expected: all `*.swift` test files and the `Mocks/` dir now live under `Tests/VocuraKitTests/`.

- [ ] **Step 4: Repoint test imports to the package module**

Run:
```bash
cd /Users/matejoslav/projects/vocura
grep -rl "import Vocura" Tests/VocuraKitTests | xargs sed -i '' 's/@testable import Vocura/@testable import VocuraKit/; s/^import Vocura$/import VocuraKit/'
grep -rn "import Vocura" Tests/VocuraKitTests
```
Expected: every match now reads `VocuraKit` (no bare `import Vocura` / `@testable import Vocura` remaining).

- [ ] **Step 5: Raise access levels on the two types the app shell uses — `SettingsView`**

In `Sources/VocuraKit/UI/SettingsView.swift`, change the declaration from:
```swift
struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingSaveSuccess = false

    var body: some View {
```
to:
```swift
public struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingSaveSuccess = false

    public init() {}

    public var body: some View {
```
(Only the `struct`, the new `public init()`, and `body` change. Leave the body contents untouched.)

- [ ] **Step 6: Raise access levels — `WindowManager`**

In `Sources/VocuraKit/UI/FloatingBubbleWindow.swift`, change:
```swift
class WindowManager: ObservableObject {
    static let shared = WindowManager()
```
to:
```swift
public class WindowManager: ObservableObject {
    public static let shared = WindowManager()
```
and change:
```swift
    func toggleRecording() {
```
to:
```swift
    public func toggleRecording() {
```
(Do not touch `FloatingBubbleWindow`, `BubbleView`, or the `@Published` properties — they stay internal and are reached by tests via `@testable`.)

- [ ] **Step 7: Run the package test suite**

Run:
```bash
cd /Users/matejoslav/projects/vocura
swift test 2>&1 | tail -20
```
Expected: `Test Suite 'All tests' passed` with the full count (32 tests). **No Keychain password prompt appears** — this is the core proof of the change.

> RISK CHECKPOINT (AppKit in logic tests): `WindowManagerTests` and `FloatingBubbleWindowTests` build `NSPanel` / `NSHostingView`. With no running app, `NSApp` may be nil and these can crash/hang.
> If `swift test` fails or hangs in those two suites, apply this fallback: add the following to BOTH `Tests/VocuraKitTests/WindowManagerTests.swift` and `Tests/VocuraKitTests/FloatingBubbleWindowTests.swift` — add `import AppKit` at the top (if absent) and add an `override class func setUp()` that initializes the shared app without launching a run loop:
> ```swift
> override class func setUp() {
>     super.setUp()
>     _ = NSApplication.shared   // ensures NSApp is non-nil for headless AppKit object creation
> }
> ```
> Re-run `swift test`. If it still hangs specifically on window animation, change those tests to assert on construction only (they already do) and confirm no `run()`/`orderFront` path is exercised in tests (it isn't — tests only build the window and read flags).

- [ ] **Step 8: Rewrite `project.yml` for the thin app + package dependency**

Replace the entire contents of `project.yml` with:
```yaml
name: Vocura
options:
  bundleIdPrefix: dev.matejoslav
  deploymentTarget:
    macOS: "14.0"
  createIntermediateGroups: true
  generateEmptyDirectories: true

settings:
  base:
    MACOSX_DEPLOYMENT_TARGET: "14.0"
    SWIFT_VERSION: "5.9"
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
    ENABLE_HARDENED_RUNTIME: YES
    DEAD_CODE_STRIPPING: YES
    CODE_SIGN_STYLE: Automatic
    CODE_SIGN_IDENTITY: "-"

packages:
  VocuraKit:
    path: .

targets:
  Vocura:
    type: application
    platform: macOS
    sources:
      - path: App
    dependencies:
      - package: VocuraKit
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: dev.matejoslav.vocura
        PRODUCT_NAME: Vocura
        INFOPLIST_FILE: Resources/Info.plist
        CODE_SIGN_ENTITLEMENTS: Resources/Vocura.entitlements
        LD_RUNPATH_SEARCH_PATHS:
          - "$(inherited)"
          - "@executable_path/../Frameworks"
```
(The `VocuraTests` xcodegen target is intentionally removed — tests now run via `swift test`.)

- [ ] **Step 9: Make `App/VocuraApp.swift` import the package**

In `App/VocuraApp.swift`, add `import VocuraKit` directly under the existing `import AppKit` line (top of file):
```swift
import SwiftUI
import AppKit
import VocuraKit
```
(No other changes to this file in Task 1 — the `bootstrap()` call and the env guard stay for now.)

- [ ] **Step 10: Regenerate the Xcode project and build the app**

Run:
```bash
cd /Users/matejoslav/projects/vocura
xcodegen generate
xcodebuild build -project Vocura.xcodeproj -scheme Vocura -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | tail -5
```
Expected: `** BUILD SUCCEEDED **`. If the build reports missing symbols, they are types the app shell uses that still need `public` — add `public` to exactly that declaration in `Sources/VocuraKit/...` and rebuild (do not broaden more than the error requires).

- [ ] **Step 11: Commit**

```bash
cd /Users/matejoslav/projects/vocura
git add -A
git commit -m "refactor: extract logic and UI into VocuraKit Swift package"
```

---

## Task 2: Restore fat `init` and delete the test-environment workaround

Now that tests never launch the app, the workaround that kept I/O out of `init` is dead weight. Put the I/O back in `init` and delete the env-detection scaffolding.

**Files:**
- Modify: `Sources/VocuraKit/Core/SettingsManager.swift` (fat `init`, remove `bootstrap()`)
- Modify: `App/VocuraApp.swift` (remove env guard + `bootstrap()` call)
- Modify: `Sources/VocuraKit/Core/Constants.swift` (remove `Environment`)
- Delete: `Tests/VocuraKitTests/AppEnvironmentTests.swift`
- Modify: `Tests/VocuraKitTests/SettingsManagerTests.swift` (drop `bootstrap()` calls)

**Interfaces:**
- Consumes: `SettingsManager(keychainService:hotkeyManager:)` and `MockKeychain` / `MockHotkeyManager` from Task 1.
- Produces: `SettingsManager.init` performs `loadSettings()` (Keychain read + hotkey registration) at construction. `SettingsManager.bootstrap()` no longer exists. `Constants.Environment` no longer exists.

- [ ] **Step 1: Update the SettingsManager tests to expect load-on-init (write the failing expectation first)**

In `Tests/VocuraKitTests/SettingsManagerTests.swift`, change the two load-path tests to assert immediately after construction (remove the `manager.bootstrap()` lines and restore the `OnInit` name):
```swift
    func testLoadsAPIKeyFromKeychainOnInit() {
        let mockKeychain = MockKeychain()
        mockKeychain.mockValue = "stored-key"
        let manager = SettingsManager(keychainService: mockKeychain, hotkeyManager: MockHotkeyManager())

        XCTAssertEqual(manager.apiKey, "stored-key")
    }

    func testApiKeyDefaultsToEmptyWhenKeychainEmpty() {
        let mockKeychain = MockKeychain()
        mockKeychain.mockValue = nil
        let manager = SettingsManager(keychainService: mockKeychain, hotkeyManager: MockHotkeyManager())

        XCTAssertEqual(manager.apiKey, "")
    }
```
(Leave `testSettingAPIKeySavesToKeychain` unchanged.)

- [ ] **Step 2: Run those tests to verify they fail**

Run:
```bash
cd /Users/matejoslav/projects/vocura
swift test --filter SettingsManagerTests 2>&1 | tail -15
```
Expected: `testLoadsAPIKeyFromKeychainOnInit` FAILS with `XCTAssertEqual failed: ("") is not equal to ("stored-key")` — because `init` does not yet load. (`testApiKeyDefaultsToEmptyWhenKeychainEmpty` may pass vacuously; that's fine.)

- [ ] **Step 3: Restore fat `init` in `SettingsManager` and delete `bootstrap()`**

In `Sources/VocuraKit/Core/SettingsManager.swift`, replace:
```swift
    init(
        keychainService: KeychainServiceProtocol = KeychainHelper.shared,
        hotkeyManager: HotkeyManaging = HotkeyManager.shared
    ) {
        self.keychainService = keychainService
        self.hotkeyManager = hotkeyManager
    }

    /// Loads persisted settings (Keychain + hotkey) and registers the hotkey.
    /// Kept out of `init` so constructing the singleton performs no I/O.
    public func bootstrap() {
        loadSettings()
    }

    private func loadSettings() {
```
with:
```swift
    init(
        keychainService: KeychainServiceProtocol = KeychainHelper.shared,
        hotkeyManager: HotkeyManaging = HotkeyManager.shared
    ) {
        self.keychainService = keychainService
        self.hotkeyManager = hotkeyManager
        loadSettings()
    }

    private func loadSettings() {
```

- [ ] **Step 4: Run the SettingsManager tests to verify they pass**

Run:
```bash
cd /Users/matejoslav/projects/vocura
swift test --filter SettingsManagerTests 2>&1 | tail -15
```
Expected: all `SettingsManagerTests` PASS.

- [ ] **Step 5: Simplify `AppDelegate` (remove the env guard and the `bootstrap()` call)**

In `App/VocuraApp.swift`, replace the body of `applicationDidFinishLaunching`:
```swift
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Skip launch-time wiring (Keychain read, hotkey registration) under tests.
        guard !Constants.Environment.isRunningTests else { return }

        setupMenuBar()

        // Ensure the app doesn't show in the dock
        NSApp.setActivationPolicy(.accessory)

        // Prompt for accessibility permissions once at startup
        requestAccessibilityPermissions()

        // Set up the hotkey action (connects Core to UI)
        SettingsManager.shared.hotkeyAction = {
            WindowManager.shared.toggleRecording()
        }

        // Load persisted settings and register hotkeys (performs Keychain I/O)
        SettingsManager.shared.bootstrap()
    }
```
with:
```swift
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()

        // Ensure the app doesn't show in the dock
        NSApp.setActivationPolicy(.accessory)

        // Prompt for accessibility permissions once at startup
        requestAccessibilityPermissions()

        // Connect Core to UI. Settings load + hotkey registration already
        // happened in SettingsManager.init; the registered closure reads
        // hotkeyAction lazily, so setting it here is sufficient.
        SettingsManager.shared.hotkeyAction = {
            WindowManager.shared.toggleRecording()
        }
    }
```

- [ ] **Step 6: Remove `Constants.Environment`**

In `Sources/VocuraKit/Core/Constants.swift`, delete the entire `Environment` enum:
```swift
    public enum Environment {
        /// True when the process is hosting an XCTest run, used to skip real I/O at app launch.
        public static var isRunningTests: Bool {
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        }
    }
```
(Leave `UserDefaults`, `Keychain`, and `App` enums intact.)

- [ ] **Step 7: Delete the now-obsolete test**

Run:
```bash
cd /Users/matejoslav/projects/vocura
git rm Tests/VocuraKitTests/AppEnvironmentTests.swift
```

- [ ] **Step 8: Run the full package suite**

Run:
```bash
cd /Users/matejoslav/projects/vocura
swift test 2>&1 | tail -20
```
Expected: `Test Suite 'All tests' passed`, count is 31 (32 minus the deleted `AppEnvironmentTests`). No Keychain prompt.

- [ ] **Step 9: Rebuild the app to confirm the shell still compiles**

Run:
```bash
cd /Users/matejoslav/projects/vocura
xcodebuild build -project Vocura.xcodeproj -scheme Vocura -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | tail -5
```
Expected: `** BUILD SUCCEEDED **` (no references to `bootstrap` or `Constants.Environment` remain).

- [ ] **Step 10: Commit**

```bash
cd /Users/matejoslav/projects/vocura
git add -A
git commit -m "refactor: restore SettingsManager fat init and drop test-env workaround"
```

---

## Task 3: Verify end-to-end and document the workflow

**Files:**
- Modify: `README.md` (add a short "Running tests" note) — only if a README test section does not already exist; otherwise skip the README edit and just do the verification steps.

- [ ] **Step 1: Full clean verification of both build paths**

Run:
```bash
cd /Users/matejoslav/projects/vocura
swift test 2>&1 | tail -5
xcodebuild build -project Vocura.xcodeproj -scheme Vocura -destination 'platform=macOS' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED"
```
Expected: tests pass with no prompt; app builds.

- [ ] **Step 2: Confirm the real app still reads the Keychain (manual smoke test)**

Run:
```bash
cd /Users/matejoslav/projects/vocura
open -a "$(xcodebuild -project Vocura.xcodeproj -scheme Vocura -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{d=$2} / FULL_PRODUCT_NAME /{n=$2} END{print d"/"n}')"
```
Expected: the app launches; opening Settings shows the stored Deepgram key (a Keychain prompt here is the *normal, real-app* behavior and is allowed — only the *test* prompt was the problem). Quit the app afterward.

- [ ] **Step 3: Add a "Running tests" note to the README (only if missing)**

If `README.md` has no testing section, append:
```markdown
## Running tests

Unit tests live in the `VocuraKit` package and run without launching the app:

```bash
swift test
```

Build the app with:

```bash
xcodegen generate   # if project.yml changed
xcodebuild build -project Vocura.xcodeproj -scheme Vocura -destination 'platform=macOS'
```
```

- [ ] **Step 4: Commit (only if the README was changed)**

```bash
cd /Users/matejoslav/projects/vocura
git add README.md
git commit -m "docs: document VocuraKit test workflow"
```

- [ ] **Step 5: Finish the branch**

Use the `superpowers:finishing-a-development-branch` skill to decide how to integrate (merge to `main` / open a PR). Do not merge without the user's go-ahead.

---

## Rollback

Every task is a single commit. To abandon: `git checkout main && git branch -D spm-extraction`. The generated `Vocura.xcodeproj` is reproduced by `xcodegen generate`, so no manual project surgery is needed on rollback.

## Notes / known risks

- **AppKit in logic tests** (Task 1, Step 7) is the only real unknown. The fallback (`_ = NSApplication.shared` in `setUp`) is the standard fix; if even that is flaky, the two UI test suites are the candidates to quarantine — everything else is pure logic and is guaranteed to run headless.
- **`AppIcon`**: `VocuraApp` loads `AppIcon` via `NSImage(named:)` / `Bundle.main`. No asset catalog is tracked in git today (the code already falls back to an SF Symbol), so nothing needs to move. If an `Assets.xcassets` is added later, it belongs to the app target, not the package.
- **Over-public surface**: only raise `public` on declarations the build actually demands (Task 1 Step 10). Do not pre-emptively make Core types public-er than they already are.
```
