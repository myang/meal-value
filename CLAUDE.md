# MealValue — Claude Code Project Spec

This file is the authoritative spec for all agents working in this repository.
Read it completely before taking any action.

---

## PROJECT

- **App**: MealValue — iOS SwiftUI meal-tracking app
- **Platform**: iOS 17+, Swift 5.9+
- **Architecture**: MVVM. Stores are `@MainActor final class` conforming to `ObservableObject`.
- **Persistence**: JSON to Documents directory via `MealStore`. No Core Data, no SwiftData, no third-party dependencies.
- **Build note**: `xcodebuild` and `swiftc` are broken in this environment. Structural validation is done via Python hooks instead.

---

## CODE STANDARDS

1. **Namespace pattern**: stateless engines use `enum` (not `struct` or `class`) as a static namespace. See `NutritionEngine`, `AdviceEngine`. All HealthKit bridge types follow the same pattern.
2. **No force-unwrap**: use `guard let`, `if let`, or `Result`. Never `!` on optionals unless the API guarantees non-nil (e.g. literal `HKUnit.gram()` — not `quantityType(forIdentifier:)!`).
3. **No `try!`**: always propagate throws or convert to `Result`.
4. **File naming**: all HealthKit integration files → `HealthKit<Feature>.swift`.
5. **Comments**: only `// MARK:` section headers. No inline commentary except `// SCAFFOLD: <reason>` for intentionally incomplete stubs.
6. **No `// TODO:`** comments in committed code.
7. **`@MainActor`**: required on any function that reads or writes `@Published` properties.
8. **Imports**: `import Foundation` + framework-specific only. No unused imports.
9. **Error types**: `enum <Name>Error: LocalizedError` if custom errors are needed.

---

## HEALTHKIT INTEGRATION RULES

1. `HKHealthStore` is a singleton. Access it **only** through `HealthKitManager.shared`. Never instantiate `HKHealthStore()` directly in any file other than `HealthKitManager.swift`.
2. Every `HealthKit<Type>.swift` file **must** declare an `extension … : HealthKitBridgeProtocol` (defined in `HealthKitBridge.swift`).
3. **Authorization check before every write**: confirm `HKAuthorizationStatus.sharingAuthorized` inside the `write()` function. Never write without checking.
4. `HKQuantityType.quantityType(forIdentifier:)` is **failable** — always guard or use `if let`.
5. HealthKit correlation writes use `HKCorrelationType` with child `HKQuantitySample` members.
6. The **read path from HealthKit is intentionally partial**: `MealRecord.layers` is always `[]` for HK-imported records. Do not attempt to reconstruct layers from HK totals. Document this with `// SCAFFOLD: layer detail not recoverable from HK`.
7. Deduplication: preserve `MealRecord.id` in `HKMetadataKey` `"MealValue.id"` on every write. Check this key on import to avoid double-writing.
8. **`import HealthKit`** must appear in every `HealthKit*.swift` file.

---

## HK TYPE ALLOWLIST & UNIT TABLE

These are the only approved HealthKit identifiers. The scaffolder must reject any identifier not in this table.

### Quantity Types

| hk_identifier            | HKQuantityTypeIdentifier string                    | HKUnit                  | maps_to                   |
|--------------------------|-----------------------------------------------------|-------------------------|---------------------------|
| dietaryEnergyConsumed    | HKQuantityTypeIdentifierDietaryEnergyConsumed       | HKUnit.kilocalorie()    | NutritionValues.calories  |
| dietaryProtein           | HKQuantityTypeIdentifierDietaryProtein              | HKUnit.gram()           | NutritionValues.protein   |
| dietaryCarbohydrates     | HKQuantityTypeIdentifierDietaryCarbohydrates        | HKUnit.gram()           | NutritionValues.carbs     |
| dietaryFatTotal          | HKQuantityTypeIdentifierDietaryFatTotal             | HKUnit.gram()           | NutritionValues.fat       |
| dietaryFiber             | HKQuantityTypeIdentifierDietaryFiber                | HKUnit.gram()           | NutritionValues.fiber     |

### Correlation Types

| hk_identifier | HKCorrelationTypeIdentifier string        | maps_to    | child_types (all 5 above must be validated first) |
|---------------|-------------------------------------------|------------|---------------------------------------------------|
| food          | HKCorrelationTypeIdentifierFood           | MealRecord | all 5 quantity types above                        |

---

## MANIFEST CONTRACT

- File: `.claude/healthkit-manifest.json`
- **Read manifest before generating any code.**
- **Check `scaffolded_types[].hk_identifier`** for duplicates. If an entry exists with `status != "pending"`, reject and inform the user.
- **Update manifest after successful code generation** and hook validation.
- Status transitions: `pending → scaffolded → reviewed → validated`
- Correlation type scaffold requires all child quantity types at `status: "validated"` first.

---

## AGENT ROLES

### Orchestrator
- Reads this file and the manifest on every session start.
- Coordinates the pipeline. **Never writes Swift code directly.**
- Spawns subagents with precisely scoped prompts and context.
- Enforces the iteration cap: abort after `iteration_count >= 3`.

### SpecValidatorAgent
- **Only** validates the requested HK identifier against the allowlist and manifest.
- Produces a `SPEC:` block or a `REJECT:` block. Nothing else.
- Does not write files.

### ScaffolderAgent
- Generates exactly **one** Swift file per invocation.
- Has Write access. Must re-read its own output after a hook error before rewriting.
- System instruction: treat every hook error as a compiler error. Fix the specific violation. Max 3 Write attempts.

### ReviewAgent
- Read-only access. Checks generated code quality.
- Outputs `REVIEW_RESULT: PASS|FAIL` with `[CRITICAL]` / `[WARNING]` / `[INFO]` items.

### PatternAgent
- Read-only access. Checks pattern consistency against existing Swift files.
- Outputs `PATTERN_RESULT: PASS|FAIL` with same severity levels.
- ReviewAgent and PatternAgent run **in parallel**.

### ValidationAgent
- Read-only access. Runs the 9-item checklist (see plan).
- Reads manifest to verify state. Outputs `VALIDATED` or `FAIL_LIST`.
- Emits `ABORT` if `iteration_count >= 3`.

---

## HOOK CONTRACT

- Hooks read `tool_input.file_path` (and optionally `tool_input.content`) from stdin JSON.
- **Errors → stderr**, prefixed with `HOOK ERROR [<script-name>]:`. Non-zero exit blocks the tool call.
- `NON_RECOVERABLE:` prefix in error message signals orchestrator to break the loop immediately.
- Hooks must complete within 10 seconds.
- Non-`HealthKit*.swift` files → exit 0 immediately (no-op).

---

## SELF-CORRECTION LOOP

When ScaffolderAgent's `Write` triggers a hook that exits 1, Claude Code surfaces the hook's stderr in the agent's tool result. The agent:
1. Re-reads the file it just wrote.
2. Identifies the specific violation.
3. Writes the corrected file.
4. Hooks fire again.

Loop terminates on: all hooks pass, OR `iteration_count >= 3`, OR `NON_RECOVERABLE` prefix detected.
