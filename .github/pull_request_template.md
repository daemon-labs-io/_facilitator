# 📝 Pull Request

## Is this PR related to an open issue?

- [ ] Yes, it resolves: [Link Issue Number(s) Here]
- [ ] No, this is a new change/addition.

## Description of changes

- **What was changed?** (e.g., Added a new section, corrected a command, rephrased a paragraph)
- **Where was the change made?** (e.g., `WORKSHOP.md`, line 45; `README.md` section Prerequisites)

## Why is this change necessary?

- [ ] Correction: Fixing a typo, broken link, or inaccurate information.
- [ ] Clarification: Making a confusing section easier to understand.
- [ ] Addition: Adding entirely new content/steps to the workshop.
- [ ] Refactoring: Reorganising content without changing the meaning.
- [ ] Other: [Please describe]

---

## Cross-platform (Mac, Windows, Chromebook, Linux) checklist

**Contributor must confirm the following to maintain compatibility across all target systems:**

- [ ] **Path separation:** Directory paths use **forward slashes (`/`)** only (avoiding Windows-style backslashes `\`).
- [ ] **Shell commands:** Commands use only **universal syntax** (e.g., `docker compose up`, avoiding complex OS-specific utilities).
- [ ] **Terminal check:** The instructions are clear and functional when run from common terminals across Mac, Windows, Chromebook (Crosh/Terminal), and Linux.
- [ ] **Case sensitivity:** Filenames are referenced correctly using **case-sensitive** best practices to prevent errors when pulled down on different operating systems.
- [ ] **Prerequisites slignment:** The changes do not introduce any new local tools that are not explicitly documented in the **Prerequisites Guide**.

---

## Reviewer checklist

- [ ] The content follows the style and tone of existing documentation.
- [ ] The changes are grammatically correct and free of typos.
- [ ] The file structure is maintained (e.g., no unnecessary files added).
- [ ] (If applicable) All internal and external links are working.
