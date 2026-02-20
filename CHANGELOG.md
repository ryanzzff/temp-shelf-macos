# Changelog

All notable changes to TempShelf are documented here.

---

## Unreleased

### Verify destination copy before trashing source files

**Context**: When Option+drag-out trashes the source file after a delay,
clicking "Stop" on Finder's conflict dialog meant the source was trashed
even though no copy was made — causing data loss.

**Solution**: Before trashing, use Spotlight to search for a file with the
same name and verify it has matching content. Only trash if a verified copy
exists. If no match is found (user clicked "Stop", or copy failed), the
source file is kept.

### Handle file operations ourselves for drag-out

**Context**: Previous implementation told Finder whether to copy or move via
`sourceOperationMaskFor`. Problem: when a file already exists at the
destination, Finder shows a conflict dialog ("Keep Both / Stop / Replace")
for **copy** but **silently fails** for **move**.

**Solution**: Always tell Finder to **copy**. We handle "move" ourselves by
moving the source file to Trash after Finder's copy succeeds. This way
Finder's conflict resolution UI works for both copy and move scenarios.
Source files go to Trash (not permanent delete) so the user can recover
if they clicked "Stop" on the conflict dialog.

**Expected behavior**:
- Default drag-out → Finder copies the file. Source file **stays**. Item
  removed from shelf.
- Option + drag-out → Finder copies the file (with conflict dialog if
  needed). Source file **moved to Trash**. Item removed from shelf.
