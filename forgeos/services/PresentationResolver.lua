---=============================================================================
--- FORGE ForgeOS Presentation Resolver
---
--- Resolves one registered app presentation for one registered device.
---
--- Responsibilities:
---     • Enforce the runtime-active resolution gate.
---     • Resolve exact, capability, and default presentations.
---     • Apply deterministic priority and diagnostic ordering.
---     • Return detached declarative resolution data.
---
--- This service must never execute app assets or own runtime availability.
---=============================================================================

FORGE.PresentationResolver = {}

local Resolver = FORGE.PresentationResolver
local Result = FORGE.Definitions.ForgeOSResult
local Reason =
    FORGE.Definitions.AppAvailabilityReason
local Match =
    FORGE.Definitions.PresentationMatchType
local Phase = FORGE.Definitions.ForgeOSPhase

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

local function missingCapability(
    requirements,
    capabilities
)
    if requirements == nil then
        return nil
    end

    local identifiers = {}
    for capabilityId in pairs(requirements) do
        table.insert(identifiers, capabilityId)
    end
    table.sort(identifiers)

    for _, capabilityId in ipairs(identifiers) do
        if capabilities[capabilityId] ~= true then
            return capabilityId
        end
    end

    return nil
end

local function capabilityFailure(capabilityId)
    return Result.CAPABILITY_MISSING, {
        reason = Reason.MISSING_CAPABILITY,
        missingCapability = capabilityId
    }
end

local function successResolution(
    appId,
    deviceId,
    presentationKey,
    presentation,
    matchType
)
    return Result.SUCCESS, {
        appId = appId,
        deviceId = deviceId,
        presentationKey = presentationKey,
        presentationId = presentation.id,
        matchType = matchType,
        presentation = presentation
    }
end

local function hasRequirements(presentation)
    return presentation.requiredCapabilities
            ~= nil
        and next(
            presentation.requiredCapabilities
        ) ~= nil
end

local function collectCapabilityCandidates(
    app,
    deviceId
)
    local candidates = {}

    for presentationKey, presentation in pairs(
        app.presentations
    ) do
        if presentationKey ~= deviceId
            and presentationKey
                ~= app.defaultPresentation
            and hasRequirements(presentation) then
            table.insert(candidates, {
                key = presentationKey,
                presentation = presentation,
                priority =
                    presentation.priority or 0
            })
        end
    end

    table.sort(
        candidates,
        function(left, right)
            if left.priority ~= right.priority then
                return left.priority > right.priority
            end
            return left.key < right.key
        end
    )

    return candidates
end

local function resolve(appId, deviceId)
    local app =
        FORGE.AppRegistry:getAppDefinition(appId)
    if app == nil then
        return Result.NOT_REGISTERED, {
            reason = Reason.APP_NOT_REGISTERED
        }
    end

    local device =
        FORGE.DeviceRegistry
            :getDeviceDefinition(deviceId)
    if device == nil then
        return Result.NOT_REGISTERED, {
            reason = Reason.DEVICE_NOT_REGISTERED
        }
    end

    local support =
        app.supportedDevices[deviceId]
    if support == false
        or (
            support == nil
            and not app.allowCapabilityFallback
        ) then
        return Result.NOT_AVAILABLE, {
            reason = Reason.DEVICE_NOT_SUPPORTED
        }
    end

    local appMissing =
        missingCapability(
            app.requiredCapabilities,
            device.capabilities
        )
    if appMissing ~= nil then
        return capabilityFailure(appMissing)
    end

    local firstMissing = nil
    local exact = app.presentations[deviceId]
    if exact ~= nil then
        local missing =
            missingCapability(
                exact.requiredCapabilities,
                device.capabilities
            )
        if missing == nil then
            return successResolution(
                appId,
                deviceId,
                deviceId,
                exact,
                Match.EXACT_DEVICE
            )
        end
        firstMissing = missing
    end

    for _, candidate in ipairs(
        collectCapabilityCandidates(
            app,
            deviceId
        )
    ) do
        local missing =
            missingCapability(
                candidate.presentation
                    .requiredCapabilities,
                device.capabilities
            )
        if missing == nil then
            return successResolution(
                appId,
                deviceId,
                candidate.key,
                candidate.presentation,
                Match.CAPABILITY
            )
        end
        firstMissing = firstMissing or missing
    end

    local defaultKey = app.defaultPresentation
    local defaultPresentation =
        defaultKey ~= nil
        and app.presentations[defaultKey]
        or nil
    if defaultPresentation ~= nil then
        local missing =
            missingCapability(
                defaultPresentation
                    .requiredCapabilities,
                device.capabilities
            )
        if missing == nil then
            return successResolution(
                appId,
                deviceId,
                defaultKey,
                defaultPresentation,
                Match.DEFAULT
            )
        end
        firstMissing = firstMissing or missing
    end

    if firstMissing ~= nil then
        return capabilityFailure(firstMissing)
    end

    return Result.PRESENTATION_NOT_FOUND, {
        reason = Reason.PRESENTATION_NOT_FOUND
    }
end

function Resolver:resolvePresentation(
    appId,
    deviceId
)
    if not isIdentifier(appId)
        or not isIdentifier(deviceId) then
        return Result.INVALID_ARGUMENT, nil
    end

    if FORGE.ForgeOSCore:getPhase()
        ~= Phase.RUNTIME_ACTIVE then
        return Result.NOT_AVAILABLE, nil
    end

    local succeeded, result, resolution =
        pcall(resolve, appId, deviceId)
    if not succeeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource
                .APP_PRESENTATION,
            "Unexpected presentation resolution failure: %s",
            FORGE.Logger:safeToString(
                result,
                "<unprintable error>"
            )
        )
        return Result.INTERNAL_ERROR, {
            reason = Reason.UNKNOWN
        }
    end

    return result, resolution
end
