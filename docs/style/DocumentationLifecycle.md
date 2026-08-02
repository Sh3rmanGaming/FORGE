# Documentation Lifecycle

## Purpose

This document defines how documentation within the FORGE project is created, reviewed, approved, implemented and maintained.

Documentation is treated as part of the product and follows a defined lifecycle, just like source code.

Every document should accurately communicate whether it represents an idea, an approved design, implemented behaviour, or verified behaviour.

---

## Documentation States

### Draft

The document is being actively written.

Characteristics:

- May be incomplete.
- May contain open questions.
- Should not be considered authoritative.

---

### Review

The initial draft has been completed.

Characteristics:

- Ready for technical review.
- Open questions are being resolved.
- Changes are expected.

---

### Approved

The design has been accepted by the Project Architect.

Characteristics:

- Represents the intended design.
- May not yet be implemented.
- Serves as the implementation target.

---

### Implemented

The documented behaviour now exists in the codebase.

Characteristics:

- Code has been written.
- Documentation reflects implementation.
- Awaiting verification.

---

### Verified

The implementation has been reviewed against the documentation.

Characteristics:

- Design and implementation match.
- Behaviour has been validated through testing or review.
- The document is considered authoritative.
- Future changes require review.

---

## State Transitions

```text
Draft
    ↓
Review
    ↓
Approved
    ↓
Implemented
    ↓
Verified
```

Documents may return to an earlier state whenever significant architectural changes occur.

---

## Responsibilities

### Project Architect

- Approves documentation.
- Owns product and architectural intent.

### Engineering Lead

- Authors technical documentation.
- Ensures implementation matches design.
- Reviews documents for technical accuracy.

### Contributors

- Suggest improvements.
- Follow the documented lifecycle.
- Do not mark documents as Approved or Verified.

---

## Principles

- Documentation is part of the product.
- Design precedes implementation.
- Code implements approved designs.
- Documentation must remain trustworthy.
- Architectural decisions are recorded in ADRs.
- Significant documentation changes should be reviewed.