# ADR-008 - Notification Deep Linking Through ForgeOS Navigation

**Status:** Accepted
**Date:** 2026-08-22

## Context

Notifications already store logical app/route/parameter destinations, but Hosts
have no generic activation sequence.

## Options Considered

1. Let each Host or application interpret destinations independently.
2. Add a second notification-specific navigation stack.
3. Add one ForgeOS activation operation over existing lifecycle and Navigation.

## Decision

Select option 3. ForgeOS preflights notification existence, target device,
registered app, presentation availability, route, and route parameters before
performing open, activate, and navigate in order. It stops on failure and
promises no distributed rollback. Successful navigation may mark the
notification read but never mutates linked domain state.

Actionable notification routes declare an optional bounded parameter schema in
their existing App Registry route definition. Navigation Service applies that
same schema to direct navigation, resume restoration, and deep-link activation.
Legacy routes without a schema retain controlled-plain-data validation during
transition. No Host or notification component performs application-specific
parameter validation.

Preflight is side-effect-free and does not guarantee later lifecycle or
navigation success. The activation detail distinguishes validation, open,
activation, navigation, and read-update failure from success and reports the
last completed stage. A read-update failure occurs after successful navigation
and does not roll navigation back.

## Consequences

Navigation Service and notification route records are retained. App Registry
route declarations gain additive validation metadata. Layered outcomes report
partial completion without implying rollback.
