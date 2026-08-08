---=============================================================================
--- FORGE ForgeOS Bootstrap and Public Facade
---
--- Coordinates the M2.003A ForgeOS startup and shutdown lifecycle.
---
--- Responsibilities:
---     • Expose lifecycle and compatibility queries.
---     • Request authoritative lifecycle changes from ForgeOS Core.
---     • Initialise ForgeOS state and persistence registration.
---     • Publish completed lifecycle events.
---     • Coordinate ForgeOS cleanup.
---
--- This component must never own phase state, registries, gameplay, or UI.
---=============================================================================

FORGE.ForgeOS = {}

local Phase =
    FORGE.Definitions.ForgeOSPhase

local Result =
    FORGE.Definitions.ForgeOSResult

local Event =
    FORGE.Definitions.ForgeOSEvent

local Namespace =
    FORGE.Definitions.ForgeOSNamespace.OS

local function createDefaultState()
    return {
        version =
            FORGE.Definitions.ForgeOSVersion.STATE,

        players = {
            [FORGE.Definitions.ForgeOSPlayerId.LOCAL] = {
                activeDeviceId = nil,
                devices = {},
                notifications = {},
                preferences = {}
            }
        }
    }
end

local function initialiseState()
    if not FORGE.StateStore:exists(Namespace) then
        local registered =
            FORGE.StateStore:register(Namespace)

        if not registered then
            return false
        end
    end

    local state, found =
        FORGE.StateStore:snapshot(Namespace)

    if not found then
        return false
    end

    if next(state) ~= nil then
        return true
    end

    return FORGE.StateStore:replaceNamespace(
        Namespace,
        createDefaultState()
    )
end

local function registerPersistence()
    if FORGE.SaveManager:isNamespaceRegistered(
        Namespace
    ) then
        return true
    end

    return FORGE.SaveManager:registerNamespace(
        Namespace
    )
end

local function publishRegistrationOpened()
    FORGE.EventBus:publish(
        Event.REGISTRATION_OPENED,
        {
            phase = Phase.REGISTRATION_OPEN,
            appApiVersion =
                FORGE.Definitions.ForgeOSVersion.APP_API
        }
    )

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.FORGE_OS,
        "ForgeOS registration opened"
    )
end

local function installProductionRegistries()
    local deviceResult =
        FORGE.ForgeOSRegistrationCoordinator
        :installParticipant(
            FORGE.DeviceRegistry
        )

    if deviceResult ~= Result.SUCCESS then
        return deviceResult
    end

    return FORGE.ForgeOSRegistrationCoordinator
        :installParticipant(
            FORGE.AppRegistry
        )
end

local function publishStopped()
    FORGE.EventBus:publish(
        Event.STOPPED,
        {
            phase = Phase.STOPPED
        }
    )

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.FORGE_OS,
        "ForgeOS stopped"
    )
end

local function publishStarted()
    FORGE.EventBus:publish(
        Event.STARTED,
        {
            phase = Phase.RUNTIME_ACTIVE,
            appApiVersion =
                FORGE.Definitions.ForgeOSVersion.APP_API
        }
    )

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.FORGE_OS,
        "ForgeOS runtime active"
    )
end

local function completeShutdown()
    local phase =
        FORGE.ForgeOSCore:getPhase()

    if phase ~= Phase.SHUTTING_DOWN then
        if not FORGE.ForgeOSCore:transitionPhase(
            Phase.SHUTTING_DOWN
        ) then
            return Result.INVALID_TRANSITION
        end
    end

    local participantCleanupResult =
        FORGE.ForgeOSRegistrationCoordinator
            :clearRegistrationParticipants()

    if FORGE.StateStore:exists(Namespace) then
        FORGE.StateStore:clear(Namespace)
    end

    if not FORGE.ForgeOSCore:transitionPhase(
        Phase.STOPPED
    ) then
        return Result.INTERNAL_ERROR
    end

    publishStopped()

    if participantCleanupResult
        ~= Result.SUCCESS then
        return participantCleanupResult
    end

    return Result.SUCCESS
end

local function start()
    local phase =
        FORGE.ForgeOSCore:getPhase()

    if phase == Phase.REGISTRATION_OPEN then
        return Result.SUCCESS
    end

    if phase ~= Phase.UNAVAILABLE
        and phase ~= Phase.STOPPED then
        return Result.INVALID_TRANSITION
    end

    if not FORGE.ForgeOSCore:transitionPhase(
        Phase.INITIALISING
    ) then
        return Result.INVALID_TRANSITION
    end

    local callSucceeded, operationResult =
        pcall(
            function()
                if not initialiseState() then
                    return Result.STATE_ERROR
                end

                if not registerPersistence() then
                    return Result.PERSISTENCE_ERROR
                end

                if not FORGE.ForgeOSCore:transitionPhase(
                    Phase.REGISTRATION_OPEN
                ) then
                    return Result.INTERNAL_ERROR
                end

                local installationResult =
                    installProductionRegistries()

                if installationResult
                    ~= Result.SUCCESS then
                    return installationResult
                end

                publishRegistrationOpened()

                return Result.SUCCESS
            end
        )

    if not callSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.FORGE_OS,
            "Unexpected ForgeOS startup failure: %s",
            FORGE.Logger:safeToString(
                operationResult,
                "<unprintable error>"
            )
        )

        operationResult =
            Result.INTERNAL_ERROR
    end

    if operationResult ~= Result.SUCCESS then
        completeShutdown()
    end

    return operationResult
end

local function shutdown()
    local phase =
        FORGE.ForgeOSCore:getPhase()

    if phase == Phase.UNAVAILABLE
        or phase == Phase.SHUTTING_DOWN
        or phase == Phase.STOPPED then
        return Result.SUCCESS
    end

    if phase ~= Phase.INITIALISING
        and phase ~= Phase.REGISTRATION_OPEN
        and phase ~= Phase.VALIDATING
        and phase ~= Phase.REGISTRATION_FROZEN
        and phase ~= Phase.RUNTIME_ACTIVE then
        return Result.INVALID_TRANSITION
    end

    return completeShutdown()
end

local function completeStartup()
    local phase =
        FORGE.ForgeOSCore:getPhase()

    if phase == Phase.RUNTIME_ACTIVE then
        return Result.SUCCESS
    end

    if phase ~= Phase.REGISTRATION_OPEN then
        return Result.INVALID_TRANSITION
    end

    local registrationResult =
        FORGE.ForgeOSRegistrationCoordinator
            :completeRegistration()

    if registrationResult ~= Result.SUCCESS then
        if FORGE.ForgeOSCore:getPhase()
            ~= Phase.REGISTRATION_OPEN then
            completeShutdown()
        end

        return registrationResult
    end

    if not FORGE.ForgeOSCore:transitionPhase(
        Phase.RUNTIME_ACTIVE
    ) then
        completeShutdown()

        return Result.INTERNAL_ERROR
    end

    publishStarted()

    return Result.SUCCESS
end

--- Returns the authoritative ForgeOS operating phase.
-- @return string phase
function FORGE.ForgeOS:getPhase()
    return FORGE.ForgeOSCore:getPhase()
end

--- Returns the supported ForgeOS application API version.
-- @return integer version
function FORGE.ForgeOS:getAppApiVersion()
    return FORGE.Definitions.ForgeOSVersion.APP_API
end

--- Returns whether one application API version is supported.
-- @param requiredVersion any
-- @return boolean supported
function FORGE.ForgeOS:supportsAppApiVersion(
    requiredVersion
)
    return type(requiredVersion) == "number"
        and requiredVersion >= 1
        and requiredVersion
            == math.floor(requiredVersion)
        and requiredVersion
            == self:getAppApiVersion()
end

--- Returns whether normal ForgeOS runtime operations are available.
-- @return boolean available
function FORGE.ForgeOS:isAvailable()
    return FORGE.ForgeOSCore
        :isRuntimeOperationPermitted()
end

--- Returns whether ForgeOS registration is open.
-- @return boolean open
function FORGE.ForgeOS:isRegistrationOpen()
    return FORGE.ForgeOSCore
        :isRegistrationOperationPermitted()
end

--- Returns whether ForgeOS runtime operations are active.
-- @return boolean active
function FORGE.ForgeOS:isRuntimeActive()
    return FORGE.ForgeOSCore
        :isRuntimeOperationPermitted()
end

--- Registers one device definition during the registration-open phase.
-- @param deviceDefinition any
-- @return string result
function FORGE.ForgeOS:registerDevice(
    deviceDefinition
)
    return FORGE.DeviceRegistry
        :registerDevice(deviceDefinition)
end

--- Returns whether a device identifier is registered.
-- @param deviceId any
-- @return boolean registered
function FORGE.ForgeOS:isDeviceRegistered(deviceId)
    return FORGE.DeviceRegistry
        :isDeviceRegistered(deviceId)
end

--- Returns a detached registered device definition.
-- @param deviceId any
-- @return table|nil definition
function FORGE.ForgeOS:getDeviceDefinition(deviceId)
    return FORGE.DeviceRegistry
        :getDeviceDefinition(deviceId)
end

--- Returns detached registered identifiers in lexical order.
-- @return table identifiers
function FORGE.ForgeOS:getRegisteredDeviceIds()
    return FORGE.DeviceRegistry
        :getRegisteredDeviceIds()
end

--- Registers one application definition during registration.
-- @param appDefinition any
-- @return string result
function FORGE.ForgeOS:registerApp(appDefinition)
    return FORGE.AppRegistry
        :registerApp(appDefinition)
end

--- Returns whether an application identifier is registered.
-- @param appId any
-- @return boolean registered
function FORGE.ForgeOS:isAppRegistered(appId)
    return FORGE.AppRegistry
        :isAppRegistered(appId)
end

--- Returns a detached declarative application snapshot.
-- @param appId any
-- @return table|nil definition
function FORGE.ForgeOS:getAppDefinition(appId)
    return FORGE.AppRegistry
        :getAppDefinition(appId)
end

--- Returns registered application identifiers in lexical order.
-- @return table identifiers
function FORGE.ForgeOS:getRegisteredAppIds()
    return FORGE.AppRegistry
        :getRegisteredAppIds()
end

--- Resolves a detached presentation for a registered app and device.
-- @param appId any
-- @param deviceId any
-- @return string result
-- @return table|nil resolution
function FORGE.ForgeOS:resolvePresentation(
    appId,
    deviceId
)
    return FORGE.PresentationResolver
        :resolvePresentation(appId, deviceId)
end

--- Starts or idempotently confirms the ForgeOS lifecycle.
-- @return string result
function FORGE.ForgeOS:start()
    return start()
end

--- Completes registration and enters the ForgeOS runtime-active phase.
-- @return string result
function FORGE.ForgeOS:completeStartup()
    return completeStartup()
end

--- Stops or idempotently confirms the ForgeOS lifecycle.
-- @return string result
function FORGE.ForgeOS:shutdown()
    return shutdown()
end
