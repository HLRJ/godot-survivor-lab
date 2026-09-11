# Bootstrap Milestone 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a clean Godot 4.7.2 project, preload legal learning assets, and establish Git/GitHub version control.

**Architecture:** Start from a minimal Godot project with no gameplay logic. Organize assets and scenes by responsibility, document licenses, then commit a reproducible baseline before gameplay branches begin.

**Tech Stack:** Godot 4.7.2, GDScript, Git, GitHub, Kenney CC0 assets.

**Spec:** `docs/superpowers/specs/2026-09-12-godot-survivor-lab-design.md`

## Global Constraints
- Godot version is 4.7.2 stable.
- Keep the main branch runnable.
- Third-party assets live under `assets/third_party/`.
- No gameplay code is part of Milestone 0.
- GitHub repository is private.

---

### Task 1: Project skeleton

**Files:** Create `project.godot`, `.gitignore`, directory placeholders, and `README.md`.

- [ ] Create project directories for scenes, scripts, resources, assets, and learning notes.
- [ ] Create a minimal `project.godot` with project name `Godot Survivor Lab`, 1280x720 viewport, and GL Compatibility renderer.
- [ ] Create Godot-aware `.gitignore` entries for `.godot/` and export/build output.
- [ ] Run Godot in editor/import mode against the project and confirm it loads without parse errors.
- [ ] Commit with `chore: bootstrap Godot project`.

### Task 2: Asset baseline

**Files:** Create `assets/third_party/kenney/` content and `LICENSES.md`.

- [ ] Download Kenney Roguelike Characters, Tiny Dungeon, and Interface Sounds from their official pages.
- [ ] Extract each pack into a separate directory under `assets/third_party/kenney/`.
- [ ] Record pack name, official source page, CC0 license, and retrieval date in `LICENSES.md`.
- [ ] Let Godot import the assets and confirm there are no broken imports.
- [ ] Commit with `chore: add CC0 learning assets`.

### Task 3: GitHub baseline

**Files:** Repository metadata and remote configuration only.

- [ ] Initialize Git with default branch `main` if the project is not already a repository.
- [ ] Create private repository `HLRJ/godot-survivor-lab`.
- [ ] Add the GitHub repository as `origin` and push `main`.
- [ ] Verify the remote default branch contains `project.godot`, README, license inventory, and design documents.
- [ ] Confirm `git status` is clean.

### Task 4: Milestone 0 acceptance

- [ ] Open the project with the installed Godot 4.7.2 editor.
- [ ] Confirm the editor recognizes the project and imports the chosen assets.
- [ ] Confirm Git has a clean baseline and GitHub has the same revision.
- [ ] Create learning note `docs/learning-notes/00-bootstrap.md` explaining Scene, Node, project.godot, and why `.godot/` is ignored.
- [ ] Tag the baseline `v0.0-bootstrap` after verification.
