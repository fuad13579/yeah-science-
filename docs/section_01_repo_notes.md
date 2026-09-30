# Repository Notes - Phase 1


### Application Entry Point

The main application entry point is:

app/__main__.py

The application is launched using:

python -m app

When Python runs the module with `-m app`, it executes the `__main__.py` file inside the app package.

---

## Configuration

Important configuration files:

### Application configuration logic

app/config.py

Purpose:
- Handles loading and accessing configuration values.

### Configuration values

config/default.json

Purpose:
- Stores default runtime settings such as application parameters and connection settings.

---

## Important Repository Components

### app/

Contains the ground station application.

Important files:

- __main__.py
  - Application startup point.

- controller.py
  - Handles application control logic.

- telemetry.py
  - Handles communication and telemetry exchange.

- config.py
  - Loads configuration.

---

### simulator/

Contains the rover simulator.

Purpose:
- Simulates rover behavior.
- Communicates with the ground station.

---

### qml/

Contains UI components.

Purpose:
- Defines interface elements.
- Handles user interaction.

---

### docs/

Important documentation files:

- docs/tasks.md
  - Contains Phase 1 task requirements.

- docs/protocol.md
  - Describes simulator telemetry protocol and communication.

---

### scripts/

Important script:

scripts/launch.sh

Purpose:
- Provides a launch command for the application.

---

# Git History Inspection

Command:

git log --oneline --all

Purpose:
- Shows previous commits and project development history.

Observation:
- The repository contains meaningful development commits.
- Commit messages follow a structured format:


---


# Generated File Cleanup

During repository inspection, the following file was identified:

runtime/station.log

This file is generated during application execution and is not source code.

Generated files should not be tracked because they create unnecessary changes in Git.

The cleanup process:

1. Added runtime files to .gitignore.

Example:

runtime/

2. Removed the file from Git tracking while keeping the local copy:

git rm --cached runtime/station.log

3. Committed the cleanup.

Commit:

chore(repo): ignore runtime logs and add repository notes

---

# Checking Git File Mode

Command:

git ls-files --stage scripts/launch.sh

Purpose:
- Shows Git index information for a tracked file.

Breakdown:

git ls-files:
- Lists files tracked by Git.

--stage:
- Shows additional index information:
  - file mode
  - object hash
  - staging number
  - file path

Example:

100644 <hash> 0 scripts/launch.sh

File modes:

100644:
- Normal file.
- Not executable.

100755:
- Executable file.

This command is useful for checking whether scripts have the correct executable permission stored in Git.

---

# Fixing launch.sh Executable Permission

Problem:

The script:

scripts/launch.sh

did not have the executable permission stored in Git.

Git showed the file mode as:

100644

which means the file was tracked as a normal file and could not be executed directly as a script.

---

## Fix

Command used:

git update-index --chmod=+x scripts/launch.sh

Explanation:

- git update-index modifies the Git staging index.
- --chmod=+x changes the executable permission bit stored by Git.
- scripts/launch.sh specifies the file being modified.

This does not change the file content. It only changes the permission metadata that Git tracks.

After the fix, Git stores the file mode as:

100755

Meaning:
- Owner: read, write, execute
- Group: read, execute
- Others: read, execute

The script can now be treated as an executable file.

---

## Verification

Command:

git ls-files --stage scripts/launch.sh

Before:

100644 scripts/launch.sh

After:

100755 scripts/launch.sh

The change was then committed so that the executable permission is preserved when others clone the repository.


# Accidental Commit Recovery

## Case 1: Commit exists only locally

If a commit is accidentally created on the main branch but has not been pushed, history can be safely rewritten.

Steps:

1. Create a new branch to preserve the accidental commit:

git branch feature-branch

2. Move main back to the previous commit:

git reset --hard HEAD~1

3. Continue development from the new branch.

Reason:

A branch keeps a reference to the commit. Without a branch, the commit may become unreachable after resetting.

---

## Case 2: Commit was already pushed/shared

If a commit has already been pushed and teammates may depend on it, history should not be rewritten.

Instead, use:

git revert <commit-id>

This creates a new commit that reverses the previous change while keeping the original history.

Workflow:

1. Identify the problematic commit.

2. Create a revert commit:

git revert <commit-id>

3. Push the revert commit and merge through a Pull Request.

Test result:

An accidental commit:

test: accidental commit demo

was reversed using:

Revert "test: accidental commit demo"

The original commit remained in history, while the new commit safely undid its changes.

Conclusion:

- Local-only mistake:
  - Use branch + reset.
  - History can be rewritten safely.

- Shared/pushed mistake:
  - Use revert.
  - Preserve history other people depend on.