# B.15 - Structure & Naming Audit (Progress)

This document started as the baseline audit and now tracks completed cleanup progress.

## Progress snapshot

- ✅ Batch 1 renames completed
- ✅ Confirmed-unused legacy dialog files removed
- ✅ Batch 2 renames completed

---

## 1) Current structure status

The top-level `lib/` domain grouping is consistent and aligns with project architecture:

- `components/`
- `config/`
- `constants/`
- `dialogs/`
- `logic/`
- `managers/`
- `models/`
- `providers/`
- `screens/`
- `services/`
- `styles/`
- `utils/`

No immediate domain-folder moves are recommended.

---

## 2) Naming consistency findings

### 2.1 Files already aligned with Dart convention

Most files correctly use `snake_case.dart` (examples):

- `error_boundary.dart`
- `game_top_bar_component.dart`
- `logging_handler.dart`
- `secure_storage.dart`

### 2.2 Completed Batch 1 renames

The following outliers were normalized to `snake_case` and imports were updated:

- `lib/managers/gameLayoutManager.dart` → `lib/managers/game_layout_manager.dart`
- `lib/models/apiModels.dart` → `lib/models/api_models.dart`
- `lib/models/boardState.dart` → `lib/models/board_state.dart`

### 2.3 Completed Batch 2 renames

Additional outliers normalized to `snake_case` and import paths updated:

- `lib/dialogs/androidTabletDialog.dart` → `lib/dialogs/android_tablet_dialog.dart`
- `lib/models/gameMode.dart` → `lib/models/game_mode.dart`
- `lib/models/layoutModels.dart` → `lib/models/layout_models.dart`
- `lib/utils/wordUtilities.dart` → `lib/utils/word_utilities.dart`

> Recommendation: rename in small batches and update imports atomically per batch.

---

## 3) Unused `.dart` cleanup status

The following legacy files were confirmed unused and removed:

- `lib/dialogs/password_recovery_dialog.dart` ✅ removed
- `lib/dialogs/reset_password_dialog.dart` ✅ removed

Rationale used:

- No in-repo Dart references/imports found.
- Both belonged to deprecated password recovery flow.

---

## 4) Confirmed-in-use reference checks

The following were verified as in use (to avoid accidental cleanup):

- `lib/components/error_boundary.dart` (imported in `lib/main.dart`)
- `lib/dialogs/androidTabletDialog.dart` (used in `lib/main.dart`)
- `lib/dialogs/failure_dialog.dart` (used in `lib/main.dart`)
- `lib/dialogs/enhanced_error_dialog.dart` (used by error handling/dialog flow)
- `lib/managers/userManager.dart` (instantiated by `gameManager`)

---

## 5) Implementation order status

1. **Low-risk removals first** ✅ completed
   - Removed legacy unused dialogs.
2. **Naming normalization pass 1** ✅ completed
   - Renamed three core outliers and updated import paths.
3. **Naming normalization pass 2** ✅ completed
   - Additional outliers normalized and imports updated.
4. **Post-pass audit refresh** ✅ completed for Batches 1 & 2
   - This document updated with current status.

---

## 6) Next decision needed

Batches 1 and 2 are complete. Next optional cleanup pass would be:

1. Run analyzer/build validation and fix any fallout warnings.
2. Review remaining naming polish opportunities (if any) discovered during QA.
3. Finalize B.15 as complete and lock this guide as baseline.
