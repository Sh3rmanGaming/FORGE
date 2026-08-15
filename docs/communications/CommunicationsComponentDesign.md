# FORGE Communications Component Design

**Status:** Approved
**Milestone:** M3.001 - Communications Architecture

## Purpose

Translate the Communications architecture into bounded components,
responsibilities, dependencies, and lifecycle interactions.

## Components

```text
Communications
  Communications.lua                 domain facade/coordinator
  CommunicationsService.lua          authoritative inbox state
  CommunicationsPersistence.lua      namespace restoration/repair adapter
  CommunicationsApp.lua              built-in app definition and provider

ForgeOS
  ApplicationPresentationService.lua bounded Host/application adapter
```

Names are proposed implementation locations for M3.002-M3.005 and are not
implemented by M3.001.

## Communications Facade

`FORGE.Communications` coordinates the domain service and exposes the bounded
in-process operations required by FORGE-owned producers and the built-in app.
It must not expose State Store references or persistence containers.

Proposed domain operations:

```lua
createMessage(definition)
markMessageRead(messageId)
archiveMessage(messageId)
getMessage(messageId)
getMessages(includeArchived)
getUnreadCount()
```

The exact addon-facing acquisition path remains open. These operations are not
added to the cross-mod ForgeOS facade during M3.001.

## Communications Service

Responsibilities:

- validate message definitions;
- allocate monotonic message identifiers;
- stage and atomically replace Communications namespace state;
- preserve read/archive invariants;
- provide detached queries ordered oldest-to-newest;
- enforce retention;
- publish completed domain events; and
- coordinate linked-notification read propagation after message commit.

It does not register applications, navigate, draw, process input, or own
notification state.

## Persistence Adapter

Responsibilities:

- register `forge.communications` with State Store/Save Manager through the
  established Engine integration;
- establish older-state defaults;
- validate and repair restored records in a staged detached copy;
- replace the namespace atomically; and
- preserve unrelated namespaces and player records.

It does not invent missing messages or select arbitrary duplicate winners.

## Communications Application

Responsibilities:

- register `forge.communications` during `REGISTRATION_OPEN`;
- declare Phone and Laptop presentations and routes;
- provide detached inbox/detail models;
- translate approved application actions into Communications operations;
- report Communications-owned unread badge state; and
- return declarative navigation requests.

It does not own message records, Host layout, ForgeOS navigation state, or
notification records.

## Application Presentation Service

This ForgeOS-owned adapter is the only new M3 integration point between Hosts
and an application's private presentation provider.

Responsibilities:

- gate on `RUNTIME_ACTIVE`;
- require a visible operational Host and active app where applicable;
- confirm app registration, resolved presentation, and lifecycle eligibility;
- retrieve the provider retained privately by App Registry;
- validate provider protocol version;
- invoke model queries and action handlers under `pcall`;
- validate and detach returned data;
- apply a validated navigation request only through ForgeOS Navigation facade;
- return deterministic operation results; and
- reject re-entrant model/action invocation for the same app/device pair.

It must not:

- expose provider references;
- call arbitrary draw functions;
- allow a model query to mutate ForgeOS state;
- store domain state;
- provide registry or State Store access to an app;
- create a general widget system; or
- support third-party providers until separately approved.

## Provider Protocol

Proposed private provider shape:

```lua
{
    protocolVersion = 1,
    getModel = function(context) ... end,
    performAction = function(context, actionId, parameters) ... end,
    getBadge = function(context) ... end
}
```

The context is detached and contains only:

```text
playerId
deviceId
appId
presentationId
routeId
routeParameters
```

It contains no service, registry, Host, Engine, State Store, or callback
reference.

`getModel` and `getBadge` are side-effect-free queries. `performAction` may
mutate only the provider's owning domain through its bounded domain facade.

## Action Outcome

An action returns a domain outcome:

```lua
{
    completed = true | false,
    domainResult = "success" | "notFound" | "...",
    navigation = {
        operation = "navigate" | "back" | "home",
        routeId = "...",          -- navigate only
        parameters = {}            -- optional controlled data
    }                              -- optional
}
```

The adapter's `ForgeOSResult` classifies transport, phase, validation, provider
execution, and navigation mediation. A provider that executes normally but
declines a domain action returns adapter `SUCCESS` with `completed = false` and
a controlled `domainResult`; it is not misclassified as a callback failure.
The outcome is detached and validated. `home` means navigate to the
presentation default route; it does not hide a device. Domain mutation and
subsequent navigation are not a cross-service transaction. An action must not
depend on navigation success for domain correctness.

## Invocation Precedence

Model query:

1. argument shape;
2. `RUNTIME_ACTIVE` gate;
3. registered device and app;
4. active-app/lifecycle eligibility;
5. resolved presentation and route;
6. provider/protocol availability;
7. re-entrancy gate;
8. contained provider invocation;
9. model validation and detachment.

Action:

1. argument shape and controlled parameters;
2. `RUNTIME_ACTIVE` gate;
3. registered device and app;
4. active-app/lifecycle eligibility;
5. resolved presentation and declared action;
6. provider/protocol availability;
7. re-entrancy gate;
8. contained provider invocation;
9. result/outcome validation;
10. optional ForgeOS navigation request.

## Runtime Interaction

```text
Host draws
  -> request detached model
  -> render known Communications primitives

Host receives normalized input
  -> submit declared action identifier and detached parameters
  -> provider performs bounded domain operation
  -> adapter applies optional validated navigation
  -> next draw obtains fresh model
```

Hosts do not cache authoritative models across state-changing actions.

## Failure and Re-entrancy

One operation guard exists per `deviceId/appId`. A re-entrant query/action is
rejected with `NOT_AVAILABLE`. Provider errors are contained, produce one
controlled diagnostic per failed invocation, and return no partial model or
navigation. Listener errors after domain commit do not alter the result.

## Test Boundaries

Component tests must prove validation, detachment, result precedence,
side-effect-free queries, re-entrancy rejection, provider failure containment,
navigation mediation, and absence of private references. Integration tests must
prove Phone/Laptop shared message state with independent navigation.
