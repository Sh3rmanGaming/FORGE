# ADR-005 - Laptop Single-Application Desktop Model

**Status:** Accepted
**Date:** 2026-08-22

## Context

The accepted Laptop Host already enforces one active application and excludes
windows, but its POC shell does not formally establish the long-term product
model.

## Options Considered

1. Introduce conventional movable/resizable overlapping windows.
2. Treat Laptop as a large Phone launcher.
3. Retain a Desktop plus exactly one active full-workspace application.

## Decision

Select option 3. Laptop Desktop is Host-owned and presents app shortcuts,
attention badges, minimal status, and transient toasts. Opening an app replaces
the workspace. OS Home/Desktop closes the active app through existing lifecycle.
Back remains logical application navigation. No minimise state, windows,
taskbar, z-order, or multi-app rendering is introduced.

## Consequences

The existing one-active-app lifecycle is retained. Laptop applications may use
dense desktop-appropriate layouts without window-management complexity.
