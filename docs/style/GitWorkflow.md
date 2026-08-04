# FORGE Git Workflow

**Status:** Review  
**Version:** 1.0

## Purpose

This document defines the intended Git workflow for FORGE. It protects
authoritative source, keeps changes reviewable, and establishes evidence
required for branch promotion and release.

## Scope

This workflow applies to source, documentation, tests, tooling, synchronized
copies, generated artifacts, tags, releases, and hotfixes.

## Branch Model

### `development`

The active integration branch for approved development work.

- Feature, documentation, test, and maintenance changes integrate here.
- Work may be incomplete at milestone level but MUST remain reviewable.
- Direct changes require the same review and validation as merged changes.

### `experimental`

The stabilization branch for integrated work being evaluated before release.

- Promotion from `development` requires the applicable subsystem or milestone
  checks.
- Only stabilization fixes, review corrections, and release preparation should
  occur here.
- Experimental behavior MUST be identified and MUST NOT silently redefine
  approved contracts.

### `main`

The release branch.

- It represents accepted release history.
- Promotion requires completed release checks and authorization.
- Direct feature development MUST NOT occur on `main`.

The intended promotion flow is:

```text
development
    ↓
experimental
    ↓
main
```

All branches MAY be public. This policy does not assert that every branch
currently exists locally or remotely.

## Commit Conventions

Commits SHOULD use:

```text
<type>(<scope>): <summary>
```

Common types include:

- `feat`
- `fix`
- `docs`
- `test`
- `refactor`
- `build`
- `chore`

The summary SHOULD be imperative, specific, and concise. A commit SHOULD
represent one coherent objective. Architectural consequences and compatibility
notes belong in the body when relevant.

## Staging Discipline

- Inspect `git status` and the complete diff before staging.
- Stage only files belonging to the approved task.
- Do not absorb unrelated or pre-existing work.
- Review staged content independently from unstaged content.
- Do not use broad staging commands when the working tree contains unrelated
  changes.
- Generated files MUST be reviewed under the generated-file policy before
  staging.

## Promotion Requirements

### `development` to `experimental`

Applicable requirements include:

- approved scope is complete;
- architecture and documentation are aligned;
- relevant tests and static checks pass;
- generated or synchronized copies are current where required;
- unresolved risks and deferrals are recorded;
- the promotion diff has been reviewed; and
- the Chief Architect accepts the technical promotion evidence.

### `experimental` to `main`

Applicable requirements include:

- stabilization is complete;
- release documentation and changelog are current;
- required automated and manual verification passes;
- no unaccepted release blocker remains;
- release contents and version are confirmed;
- the Chief Architect accepts technical readiness; and
- the Project Director authorizes release promotion.

Promotion SHOULD preserve reviewable history and MUST NOT conceal unreviewed
changes.

## Tags

- Tags identify accepted release or milestone points.
- Tag names MUST follow the repository's selected release convention.
- Existing historical tags MUST NOT be rewritten merely to normalize naming.
- Create or push a tag only with explicit authorization.
- A tag MUST point to the exact reviewed commit intended for that release or
  milestone.

## Releases

A release requires:

- an authorized `main` commit;
- confirmed version metadata;
- completed release checks;
- current release notes or changelog;
- reviewed packaged or synchronized artifacts where applicable; and
- Project Director authorization.

Public branch visibility does not itself constitute a release.

## Dirty Working Tree Policy

Before editing:

1. inspect tracked, staged, untracked, and ignored state as relevant;
2. classify which changes belong to the current task;
3. preserve unrelated work; and
4. stop if safe separation is not possible.

A dirty tree is not automatically an error. It is a constraint that MUST be
handled explicitly. Do not discard, overwrite, stage, or include another
contributor's work without authorization.

## Generated and Synchronized Files

- Authoritative source MUST be identified before changing a derived copy.
- Generated or synchronized files MUST NOT become an accidental source of
  truth.
- Prefer repeatable tooling over manual duplicate edits when the documented
  workflow supports it.
- Inspect tool destinations and the dirty tree before generation or
  synchronization.
- Review the complete generated diff.
- Do not run a mutating tool when known source/destination drift has not been
  adjudicated.
- Generated artifacts belong in Git only when repository policy explicitly
  tracks them.

## Git Safety

Without explicit authorization, contributors and automation MUST NOT:

- stage;
- commit;
- amend;
- push;
- force-push;
- create or delete tags;
- delete or rename branches;
- rewrite history;
- discard working-tree changes; or
- perform destructive cleanup.

Prefer read-only inspection and non-destructive commands. Confirm exact targets
before any authorized destructive operation. Never use history rewriting to
hide mistakes or bypass review.

## Hotfix Policy

A hotfix addresses a release-critical defect with the smallest safe change.

1. Confirm the affected released baseline.
2. Obtain Project Director authorization for hotfix scope.
3. Obtain Chief Architect acceptance for any contract or architecture impact.
4. Apply focused implementation and tests.
5. Validate release artifacts.
6. Promote the reviewed correction to `main`.
7. propagate the correction back through active branches so histories do not
   diverge.
8. Create release tags only after authorization.

Emergency timing does not remove documentation, testing, review, or repository
safety requirements. If the hotfix changes an architectural contract, the
contract and Architecture Change Log MUST be updated as part of the authorized
work.

## Maintenance

This workflow MUST be reviewed when branch strategy, release authority,
generated-file ownership, or repository automation changes.

## Related Documents

- [Repository Guide](../../AGENTS.md)
- [Engineering Process](EngineeringProcess.md)
- [Engineering Charter](../EngineeringCharter.md)
- [Documentation Lifecycle](DocumentationLifecycle.md)
