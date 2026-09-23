# Implementation Plan

- [ ] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Three-Defect Repository State
  - **CRITICAL**: This test MUST FAIL on unfixed code — failure confirms the bugs exist
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior — it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate each of the three bugs
  - **Scoped PBT Approach**: Scope the property to the concrete failing cases for each bug condition
  - Check that `aula-02/Dockerfile` (capital D) exists — expected: NOT found (only `dockerfile` exists)
  - Check that `aula-02/.gitignore` exists and contains the rule `.env` — expected: file NOT found
  - Check that `aula-02/ia-analise.md` contains all required sections — expected: all present (or flag if any missing)
  - Use shell assertions or a script: `test -f aula-02/Dockerfile` (exit 1 on unfixed), `test -f aula-02/.gitignore` (exit 1 on unfixed), `grep -q "^.env$" aula-02/.gitignore` (exit 1 on unfixed)
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS for bugs 1 and 2 (proves bugs exist); bug 3 may already pass if `ia-analise.md` is complete
  - Document counterexamples found (e.g., `ls aula-02/Dockerfile` → "No such file or directory"; `cat aula-02/.gitignore` → file not found)
  - Mark task complete when test is written, run, and failures are documented
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Existing Files and Behaviors Unchanged
  - **IMPORTANT**: Follow observation-first methodology
  - Observe: `app.js` current content/checksum on unfixed code
  - Observe: `package.json` current content/checksum on unfixed code
  - Observe: `docker-compose.yml` current structure (services, healthchecks, volumes, network `technova`) on unfixed code
  - Observe: `.env.example` exists and is tracked by Git on unfixed code
  - Observe: existing content in `ia-analise.md` on unfixed code
  - Write property-based checks: for all files NOT in the bug-condition set, their content after fix equals their content before fix
  - Record checksums before fix: `md5sum aula-02/app.js aula-02/package.json aula-02/docker-compose.yml aula-02/.env.example`
  - Verify `git check-ignore aula-02/.env.example` returns non-zero (not ignored) on unfixed code
  - Verify tests PASS on UNFIXED code (baseline confirmed)
  - **EXPECTED OUTCOME**: Tests PASS (confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 3. Fix for three-defect Docker build and repository hygiene bugs

  - [ ] 3.1 Rename dockerfile to Dockerfile (fix Bug 1 — case-sensitive filesystem)
    - Run `git mv aula-02/dockerfile aula-02/Dockerfile` so Git tracks the rename correctly on case-insensitive filesystems too
    - Verify `aula-02/Dockerfile` exists and `aula-02/dockerfile` no longer exists after rename
    - Note: `docker-compose.yml` already has `dockerfile: Dockerfile` explicitly — no change needed there
    - _Bug_Condition: isBugCondition(repoState) where fileExists("aula-02/dockerfile") AND NOT fileExists("aula-02/Dockerfile")_
    - _Expected_Behavior: fileExists("aula-02/Dockerfile") AND NOT fileExists("aula-02/dockerfile") AND docker-compose.yml references "dockerfile: Dockerfile"_
    - _Preservation: docker-compose.yml services, healthchecks, volumes, rede technova, app.js, package.json all unchanged_
    - _Requirements: 1.1, 2.1, 3.1, 3.2_

  - [ ] 3.2 Create aula-02/.gitignore (fix Bug 2 — credentials exposure)
    - Create `aula-02/.gitignore` with at minimum: `.env`, `node_modules/`, `*.log`, `npm-debug.log*`, `.DS_Store`, `Thumbs.db`
    - Verify `.env` is listed in `.gitignore`
    - Verify `node_modules/` is listed in `.gitignore`
    - Verify `.env.example` is NOT listed in `.gitignore` (must remain tracked)
    - Run `git check-ignore -v aula-02/.env` — must return a match
    - Run `git check-ignore -v aula-02/.env.example` — must return no match
    - _Bug_Condition: isBugCondition(repoState) where NOT fileExists("aula-02/.gitignore") OR NOT containsRule(".gitignore", ".env")_
    - _Expected_Behavior: fileExists(".gitignore") AND containsRule(".gitignore", ".env") AND containsRule(".gitignore", "node_modules/")_
    - _Preservation: .env.example remains Git-tracked and unmodified_
    - _Requirements: 1.2, 2.2, 3.3_

  - [ ] 3.3 Verify and complete ia-analise.md if any section is missing (fix Bug 3)
    - Check all required sections are present: "Prompt Utilizado", "Output Original do Kiro", "Alterações que Fiz Manualmente", "Minha Avaliação"
    - If any section is missing or empty, add it — preserving all existing content
    - Do NOT remove or edit any content already written
    - _Bug_Condition: isBugCondition(repoState) where any required section is absent in ia-analise.md_
    - _Expected_Behavior: allSectionsPresent("ia-analise.md") with "Prompt Utilizado", "Output Original", "Alterações Manuais", "Avaliação Reflexiva" all filled_
    - _Preservation: all pre-existing text in ia-analise.md unchanged_
    - _Requirements: 1.3, 2.3, 3.4_

  - [ ] 3.4 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Three-Defect Repository State Resolved
    - **IMPORTANT**: Re-run the SAME test from task 1 — do NOT write a new test
    - The test from task 1 encodes the expected behavior for all three bug conditions
    - Run: `test -f aula-02/Dockerfile` → must exit 0
    - Run: `test -f aula-02/.gitignore` → must exit 0
    - Run: `grep -q "^\.env$" aula-02/.gitignore` → must exit 0
    - **EXPECTED OUTCOME**: All assertions PASS (confirms all three bugs are fixed)
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ] 3.5 Verify preservation tests still pass
    - **Property 2: Preservation** - Existing Files and Behaviors Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2 — do NOT write new tests
    - Re-run checksums: `md5sum aula-02/app.js aula-02/package.json aula-02/.env.example` — must match pre-fix values
    - Verify `docker-compose.yml` has the same services, healthchecks, volumes, and network as before (only `dockerfile: Dockerfile` in build block, which was already present)
    - Verify `git check-ignore aula-02/.env.example` still returns non-zero (not ignored)
    - Verify existing content of `ia-analise.md` is intact (no lines removed)
    - **EXPECTED OUTCOME**: All preservation checks PASS (confirms no regressions)
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 4. Checkpoint — Ensure all tests pass
  - Re-run the full test suite from tasks 1 and 2 one final time
  - Confirm: `aula-02/Dockerfile` exists (capital D), `aula-02/dockerfile` does not exist
  - Confirm: `aula-02/.gitignore` exists with `.env` and `node_modules/` rules, `.env.example` still tracked
  - Confirm: `aula-02/ia-analise.md` has all required sections filled
  - Confirm: `app.js`, `package.json`, `docker-compose.yml`, `.env.example` checksums unchanged
  - Ensure all tests pass; ask the user if any questions arise
