# Changelog

All notable changes to the FORGE project are documented in this file.

The format is based on chronological milestone releases rather than semantic software releases.

## M2/M3 Presentation Foundation (In Progress)

### Added

- Approved semantic presentation architecture, application UX, device UX, and
  design-system contracts.
- PF.001 declarative-model, component, property, token, attention, route-schema,
  notification-cue, layered activation-result, and defensive-limit definitions.
- PF.001 definition/load-order runtime verification and bounded freeze with the
  retained M1-M3 suite.
- Approved bounded PF.001 declarative-node, text-flow, action-reference, Host
  action, semantic-state, and component-contract clarification; runtime
  verification passed and the clarified definition baseline was accepted and
  refrozen.
- PF.002 (2026-08-22): frozen model-v2 detachment, validation, semantic
  layout, text, render-plan, Host hit-region, action-mediation, and last-safe
  pipelines; independent Phone/Laptop runtime view sessions and neutral
  cross-Host mutation tests, retaining the Communications model-v1 path.
  Synchronized package validation and clean FS25 runtime, save, and shutdown
  verification passed; accepted and frozen.
- PF.003 (2026-08-22): Host-owned Laptop Desktop with registry-derived compact
  shortcuts, bounded shortcut paging, generic unresolved-icon fallback, trusted
  application viewport, and generic model-v2 rendering through PF.002. Removed
  the permanent Laptop notification feed, hardcoded Communications launch,
  oversized cards, and six-app cap. Verified, visually reviewed, accepted and
  frozen.
- PF.004 (2026-08-29): Host-owned compact Phone Home with registry-derived
  shortcuts, deterministic bounded paging, trusted standard/compact geometry,
  protected shell and application viewport boundaries, and generic model-v2
  rendering through PF.002. Removed the permanent Phone notification feed,
  generic shell notification mutation, hardcoded Communications launcher,
  four-app cap, and Active Surface/debug presentation. Verified, visually
  reviewed, accepted and frozen.
- Communications model-v1 renderers remain the sole isolated compatibility
  exception inside the trusted viewports; PF.007 (Laptop) and PF.008 (Phone)
  own their migration and removal. PF.005-PF.009 remain unauthorized.

### Changed

- Accepted ADR-005 through ADR-009.
- Broad future milestone terminology now uses `Projects` while retaining
  narrower historical uses of contract.

---

## M3 – Communications

**Released:** 2026-08-17

### Added

- Authoritative Communications message domain and savegame persistence.
- Notification integration with explicit partial-success outcomes.
- Detached Phone and Laptop application presentation contracts.
- Cross-launch persistence and retained-regression verification.

---

## M2 – ForgeOS

**Released:** 2026-08-08

### Added

- ForgeOS lifecycle, navigation, application, notification, persistence, and
  Host foundations.
- Bounded Phone and Laptop presentation Hosts.
- Runtime verification and final M2 architecture reconciliation.

---

## M1 – Engine

**Status:** Complete

### Added

- Dedicated definition tables.
- Logging definitions.
- Structured logging service.
- Engine synchronisation tool.
- Complete Event Bus implementation.
- Engine bootstrap scaffold.
- Initial logger test harness.
- State Store with explicit namespace registration, validated value access, removal, namespace clearing, and full runtime cleanup.
- Manual State Store runtime verification harness.

---

## M0 – Foundation

**Released:** 2026-08-01

### Added

- Repository structure.
- Engineering Charter.
- Engineering Guide.
- Development Environment guide.
- Coding Standards.
- Documentation Lifecycle.
- File Header Standard.
- Contributing guide.
- Architecture Decision Record (ADR) process.
- Initial engine architecture.
- Startup lifecycle documentation.
- Roadmap.
- Reference prototype.

---

Future milestones will be appended to this document as development progresses.
