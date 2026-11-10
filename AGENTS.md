# Repository Codex instructions

Read `docs/WORKING_RULES.md` before planning or changing code. Follow the repository's architecture and applicable `docs/continuity/` documents. Repo-specific rules take precedence over global defaults. Do not implement beyond an approved bounded checkpoint, and do not merge without explicit approval. Independently review changed code and report checks actually run.

## Codex visual-acceptance boundary (2026-11-10)

- **Do not delegate visual/UI acceptance to Codex.** Codex must not use computer-use, screenshots, remote desktop, GUI automation, or manual window inspection to perform or claim visual verification. Do not request permission to do so.
- **The user performs visual acceptance.** If visual inspection is required, stop at that gate, give the user concise manual verification steps, and record the result as **NOT VISUALLY VERIFIED** until the user explicitly reports acceptance.
- Non-visual work remains allowed: source review, implementation, automated tests (including widget/integration tests), static analysis, builds, CLI/API checks, artifact integrity, executable metadata, and logs. These checks are not substitutes for user-observed UI acceptance.
- Never assert that a window rendered correctly, an interaction looked right, or visual acceptance passed solely from test results, process existence, screenshots, or tool output.
