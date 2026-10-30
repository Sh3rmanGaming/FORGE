# ADR-009 - Semantic FORGE Design Tokens

**Status:** Accepted
**Date:** 2026-08-22

## Context

POC Hosts hardcode color, spacing, and typography values. Freezing those values
would make visual refinement expensive and inconsistent.

## Options Considered

1. Let each Host/application hardcode its own styling.
2. Freeze the POC orange/dark palette as final.
3. Reference semantic roles whose approved theme values are centrally owned.

## Decision

Select option 3. Components reference semantic surface, text, accent, state,
border, spacing, typography, and motion roles. Token role meaning is stable;
concrete palette/assets remain subject to Design Lead and product approval.

## Consequences

Applications share a coherent language without sharing one layout. Brand accent
does not stand in for unread, selected, warning, error, or action semantics.
