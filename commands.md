---
type: commands
icm: Forge
---

# Commands — Forge

Key phrases for sessions opened in `D:\MOD CREATION\FORGE`. Forge follows a formal engineering process (`AGENTS.md`): the AI proposes, you approve, then it works. The Voice Hub reads the table below — keep it as a single table with these four columns.

| Phrase | What it does | Use it when… (example) | Skill / rule |
|---|---|---|---|
| where are we and what's unresolved? | Cold resume from `NOW.md`, the roadmap and the pause handoff | Start of any session, especially after a break — "where are we and what's unresolved?" | AGENTS.md "Start here" |
| current understanding | Plays back the AI's reading in four parts — what you said, what it inferred, what it's unsure about, what it would do next. Changes nothing until you confirm | After describing a change by voice, before any plan — "current understanding" | Catch misreadings early |
| what's authorized? | Lists what the roadmap and latest reviews currently allow, and what is gated | Before starting anything new — "what's authorized right now?" | `docs/roadmap/Roadmap.md` |
| plan: … | Validates scope and returns READY FOR APPROVAL (files, risks, plan) or STOP with reasons. Edits nothing | You want work done — "plan: the PF.005 documentation package" | AGENTS.md STOP / READY FOR APPROVAL |
| approved | Carries out the plan just returned, then reports files changed, checks run and Git status | After reading a READY FOR APPROVAL report — "approved" | AGENTS.md Completion Reporting |
| check sync | Runs `tools/sync.py --check` and reports any drift between source and the prototype FS25 loads | Before packaging or after edits — "check sync" | `tools/sync.py` |
| build for testing: … | Walks the runtime verification procedure: sync, package, deploy, capture evidence into `docs/reviews/evidence/` | Ready to try a batch in the game — "build for testing: PF.005" | `docs/developer/FS25RuntimeVerificationDeployment.md` |
| what does the design say about …? | Answers from `docs/` and ADRs with file references, nothing invented | "What does the design say about phone notifications?" | `docs/README.md` index |
| ideation lab: … | Explores a rough feature idea before it becomes a plan; baseline kept in the Second Brain's `ideas/` | "ideation lab: a farm contracts app on the laptop" | `ideation-lab` |
| journal this | Writes the session journal and updates `NOW.md`; asks you first | End of every Forge session | `journal-session` |
| commit this | Groups changes into commits following `docs/style/GitWorkflow.md`, shows the plan, commits after you confirm. Pushing is a separate yes | Work is accepted and you want it saved — "commit this" | GitWorkflow |
