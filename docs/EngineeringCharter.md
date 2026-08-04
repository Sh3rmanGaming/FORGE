# FORGE Engineering Charter

## Purpose

The Engineering Charter defines the principles that guide the design, implementation and maintenance of the FORGE Engine.

It exists to ensure that technical decisions remain consistent as the project evolves and as new contributors join the project.

Where no explicit rule exists, contributors should use the principles in this charter to guide their decisions.

---

## Vision

FORGE is an open-source gameplay framework for Farming Simulator 25.

Its purpose is to create rich, immersive and enjoyable gameplay experiences for players while providing a modular, maintainable and extensible platform that developers can confidently build upon.

Every technical decision should ultimately improve the player's experience.

Engineering excellence is not the goal.

Engineering excellence is how we achieve exceptional player experiences.

---

## Core Principles

## 1. Player First

Every technical decision should ultimately improve the player's experience.

Engineering exists to serve gameplay, not the other way around.

---

## 2. Design Before Construction

Architecture should be discussed and documented before significant construction begins.

The implementation should realise the approved design.

The design should not emerge accidentally from the code.

---

## 3. The Best Idea Wins

Technical discussions are encouraged.

Ideas should be challenged respectfully.

Architectural decisions are made based on what is best for FORGE rather than individual preference.

---

## 4. Single Responsibility

Every file, class and module should have one clearly defined responsibility.

If a component has multiple unrelated responsibilities, it should be reconsidered.

---

## 5. Prefer Explicit Dependencies

Dependencies between systems should be intentional, visible and well defined.

Avoid hidden coupling and unnecessary direct relationships between systems.

---

## 6. Documentation Is Part of the Product

Documentation is developed alongside implementation.

Well-written documentation is considered a feature, not an afterthought.

---

## 7. Record Important Decisions

Significant architectural decisions should be captured as ADRs.

Future contributors should understand not only what was decided, but why.

---

## 8. Optimise for Future Contributors

Code, documentation and folder structures should be understandable to developers unfamiliar with the project.

Clarity is preferred over cleverness.

---

## 9. Leave It Better Than You Found It

Every contribution should improve the project, even if only in a small way.

Continuous improvement compounds over time.

---

## 10. Build for the Long Term

Choose solutions that remain maintainable over years rather than those that are only faster to implement today.

---

## 11. Be Honest About Uncertainty

If something is unknown, document it.

If something is uncertain, discuss it.

If a decision proves incorrect, improve it.

Engineering integrity is more important than appearing certain.

## Project Roles

Detailed role authority is defined in
[EngineeringProcess.md](style/EngineeringProcess.md). The responsibilities
previously associated with informal role titles are reconciled below.

### Project Director

Responsible for:

- product vision;
- gameplay direction; and
- milestone approval.

### Chief Architect

Responsible for:

- architecture approval;
- software architecture;
- engineering standards;
- code quality;
- documentation quality;
- technical mentoring; and
- code review.

### Implementation Engineer

Responsible for implementing approved scope, preserving alignment between
documentation and implementation, performing proportionate validation, and
reporting evidence.

### Contributor

Responsible for proposing focused improvements and following the documented
engineering process.

### Reviewer

Responsible for assessing work within delegated expertise and reporting
evidence without assuming approval authority.

---

## Engineering Mindset

Before implementing a feature, ask:

- Does this increase coupling?
- Does this have one responsibility?
- Will this make sense to a new contributor?
- Does this align with the documented architecture?
- Will this still make sense in three years?

If the answer to any of these questions is uncertain, pause and review the design before continuing.

---

## Engineering Non-Negotiables

The following principles apply to all contributions unless an accepted ADR explicitly states otherwise.

- Maintain a single authoritative source for shared data.
- Document significant architectural decisions.
- Preserve modularity.
- Avoid introducing hidden coupling.
- Keep documentation aligned with implementation.

---

## Final Principle

FORGE is engineered deliberately.

Quality is achieved through thoughtful design, review and continuous improvement rather than speed alone.
