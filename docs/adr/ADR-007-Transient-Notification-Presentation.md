# ADR-007 - Transient Notification Presentation

**Status:** Accepted
**Date:** 2026-08-22

## Context

Notification Service owns durable records, but current Hosts render permanent
Home/Desktop feeds that conflict with the approved product direction.

## Options Considered

1. Keep permanent notification feeds.
2. Move notification authority into Hosts.
3. Retain Notification Service and add transient Host presentation cues.

## Decision

Select option 3. A ForgeOS presentation coordinator consumes completed
notification creation events and sends detached cues to targeted operational
Hosts. Phone renders top banners; Laptop renders bottom-right toasts. Host queues
and animation are session-only. Expiry changes no read/dismiss state.

## Consequences

Notification persistence and authority remain unchanged. Sound assets and final
motion values require later Design Lead approval.
