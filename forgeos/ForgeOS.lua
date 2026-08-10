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

local DeviceId = FORGE.Definitions.DeviceId
local Capability = FORGE.Definitions.DeviceCapability
local HOST_ORDER = { DeviceId.PHONE, DeviceId.LAPTOP }
local HOST_ID_BY_DEVICE = {
    [DeviceId.PHONE] = "phoneHost",
    [DeviceId.LAPTOP] = "laptopHost"
}
local runtimeHosts = {}
local runtimeHostFaultReported = {}

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

    local hostResult =
        FORGE.ForgeOSRegistrationCoordinator
        :installParticipant(
            FORGE.DeviceHostRegistry
        )

    if hostResult ~= Result.SUCCESS then
        return hostResult
    end

    local appResult = FORGE.ForgeOSRegistrationCoordinator
        :installParticipant(
            FORGE.AppRegistry
        )

    if appResult ~= Result.SUCCESS then
        return appResult
    end

    local phoneResult = FORGE.DeviceRegistry:registerDevice({
        id = DeviceId.PHONE,
        displayName = "Phone",
        hostId = "phoneHost",
        capabilities = {
            [Capability.FULL_SCREEN_APPS] = true,
            [Capability.WINDOWED_APPS] = false,
            [Capability.TOUCH_INPUT] = true,
            [Capability.POINTER_INPUT] = true,
            [Capability.KEYBOARD_INPUT] = true,
            [Capability.NOTIFICATIONS] = true,
            [Capability.BACKGROUND_APPS] = true,
            [Capability.MULTI_APP] = false,
            [Capability.MODALS] = true,
            [Capability.NAVIGATION_HISTORY] = true
        }
    })

    if phoneResult ~= Result.SUCCESS then
        return phoneResult
    end

    local phoneHostResult = FORGE.DeviceHostRegistry:registerHost({
        id = "phoneHost",
        deviceId = DeviceId.PHONE,
        createInstance = FORGE.PhoneHost.create
    })
    if phoneHostResult ~= Result.SUCCESS then
        return phoneHostResult
    end

    local laptopResult = FORGE.DeviceRegistry:registerDevice({
        id = DeviceId.LAPTOP,
        displayName = "Laptop",
        hostId = "laptopHost",
        capabilities = {
            [Capability.FULL_SCREEN_APPS] = true,
            [Capability.WINDOWED_APPS] = false,
            [Capability.TOUCH_INPUT] = false,
            [Capability.POINTER_INPUT] = true,
            [Capability.KEYBOARD_INPUT] = true,
            [Capability.NOTIFICATIONS] = true,
            [Capability.BACKGROUND_APPS] = true,
            [Capability.MULTI_APP] = false,
            [Capability.MODALS] = true,
            [Capability.NAVIGATION_HISTORY] = true
        }
    })
    if laptopResult ~= Result.SUCCESS then
        return laptopResult
    end

    return FORGE.DeviceHostRegistry:registerHost({
        id = "laptopHost",
        deviceId = DeviceId.LAPTOP,
        createInstance = FORGE.LaptopHost.create
    })
end

local function isHigherPriorityUiActive()
    return g_gui ~= nil and g_gui.currentGui ~= nil
end

local function hasUsableHost(deviceId)
    local instance = runtimeHosts[deviceId]
    return instance ~= nil and instance:isOperational()
end

local function createHostContext(deviceId)
    return {
        getVisibility = function()
            return FORGE.DeviceStateService
                :getDeviceVisibility(deviceId)
        end,
        show = function()
            return FORGE.ForgeOS:showDevice(deviceId)
        end,
        hide = function()
            return FORGE.ForgeOS:hideDevice(deviceId)
        end,
        getActiveAppId = function()
            return FORGE.ForgeOS:getActiveAppId(deviceId)
        end,
        getRegisteredAppIds = function()
            return FORGE.ForgeOS:getRegisteredAppIds()
        end,
        getAppDefinition = function(appId)
            return FORGE.ForgeOS:getAppDefinition(appId)
        end,
        resolvePresentation = function(appId)
            return FORGE.ForgeOS:resolvePresentation(
                appId,
                deviceId
            )
        end,
        getCurrentRoute = function(appId)
            return FORGE.ForgeOS:getCurrentRoute(
                deviceId,
                appId
            )
        end,
        getValidatedResumeDestination = function()
            return FORGE.NavigationService
                :getValidatedResumeDestination(deviceId)
        end,
        openApp = function(appId)
            return FORGE.ForgeOS:openApp(deviceId, appId)
        end,
        activateApp = function(appId)
            return FORGE.ForgeOS:activateApp(deviceId, appId)
        end,
        navigate = function(appId, routeId, parameters)
            return FORGE.ForgeOS:navigate(
                deviceId,
                appId,
                routeId,
                parameters
            )
        end,
        closeApp = function(appId)
            return FORGE.ForgeOS:closeApp(deviceId, appId)
        end,
        getNotifications = function()
            return FORGE.ForgeOS:getNotifications(
                deviceId,
                false
            )
        end,
        markNotificationRead = function(notificationId)
            return FORGE.ForgeOS
                :markNotificationRead(notificationId)
        end,
        dismissNotification = function(notificationId)
            return FORGE.ForgeOS:dismissNotification(notificationId)
        end,
        isUiBlocked = isHigherPriorityUiActive
    }
end

local function shutdownStagedHosts(stagedHosts)
    for index = #HOST_ORDER, 1, -1 do
        local instance = stagedHosts[HOST_ORDER[index]]
        if instance ~= nil and type(instance.shutdown) == "function" then
            pcall(instance.shutdown, instance)
        end
    end
end

local function initialiseRuntimeHosts()
    local stagedHosts = {}
    for _, deviceId in ipairs(HOST_ORDER) do
        local createResult, instance =
            FORGE.DeviceHostRegistry:createHostInstance(
                HOST_ID_BY_DEVICE[deviceId], createHostContext(deviceId))
        if createResult ~= Result.SUCCESS then
            shutdownStagedHosts(stagedHosts)
            FORGE.DeviceStateService:clearRuntimeState()
            return createResult
        end
        stagedHosts[deviceId] = instance
        local callSucceeded, initializeResult =
            pcall(instance.initialize, instance)
        if not callSucceeded or initializeResult ~= Result.SUCCESS then
            shutdownStagedHosts(stagedHosts)
            FORGE.DeviceStateService:clearRuntimeState()
            return callSucceeded and type(initializeResult) == "string"
                and initializeResult or Result.INTERNAL_ERROR
        end
        local stateResult = FORGE.DeviceStateService:initialiseDevice(deviceId)
        if stateResult ~= Result.SUCCESS then
            shutdownStagedHosts(stagedHosts)
            FORGE.DeviceStateService:clearRuntimeState()
            return stateResult
        end
    end
    runtimeHosts = stagedHosts
    runtimeHostFaultReported = {}
    return Result.SUCCESS
end

local function reportRuntimeHostFailure(deviceId, operationName, failure)
    if runtimeHostFaultReported[deviceId] then
        return
    end
    runtimeHostFaultReported[deviceId] = true
    FORGE.Logger:error(
        deviceId == DeviceId.PHONE
            and FORGE.Definitions.LogSource.PHONE_HOST
            or FORGE.Definitions.LogSource.LAPTOP_HOST,
        "Device Host '%s' runtime operation '%s' failed: %s",
        deviceId,
        operationName,
        FORGE.Logger:safeToString(failure, "<unprintable error>")
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

    local hostCleanupResult = Result.SUCCESS
    for index = #HOST_ORDER, 1, -1 do
        local deviceId = HOST_ORDER[index]
        local instance = runtimeHosts[deviceId]
        if instance ~= nil then
            local callSucceeded, result = pcall(instance.shutdown, instance)
            if not callSucceeded or result ~= Result.SUCCESS then
                hostCleanupResult = Result.INTERNAL_ERROR
            end
        end
    end
    runtimeHosts = {}
    runtimeHostFaultReported = {}

    local deviceStateCleanupResult =
        FORGE.DeviceStateService:clearRuntimeState()

    local lifecycleCleanupResult =
        FORGE.AppLifecycleService:clearRuntimeState()

    local navigationCleanupResult =
        FORGE.NavigationService:clearRuntimeState()

    local notificationCleanupResult =
        FORGE.NotificationService:clearRuntimeState()

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

    if hostCleanupResult ~= Result.SUCCESS then
        return hostCleanupResult
    end

    if deviceStateCleanupResult ~= Result.SUCCESS then
        return deviceStateCleanupResult
    end

    if lifecycleCleanupResult ~= Result.SUCCESS then
        return lifecycleCleanupResult
    end

    if navigationCleanupResult ~= Result.SUCCESS then
        return navigationCleanupResult
    end

    if notificationCleanupResult ~= Result.SUCCESS then
        return notificationCleanupResult
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

    FORGE.DeviceStateService:setHostAvailabilityResolver(
        hasUsableHost
    )

    local hostResult = initialiseRuntimeHosts()

    if hostResult ~= Result.SUCCESS then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.FORGE_OS,
            "Production Host startup failed with result '%s'",
            FORGE.Logger:safeToString(hostResult, "<unknown>")
        )
        completeShutdown()
        return hostResult
    end

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

function FORGE.ForgeOS:showDevice(deviceId)
    local result = FORGE.DeviceStateService:showDevice(deviceId)

    local instance = runtimeHosts[deviceId]
    if result == Result.SUCCESS and instance ~= nil then
        local callSucceeded, resumeResult =
            pcall(instance.resume, instance)
        if not callSucceeded then
            FORGE.Logger:warning(
                FORGE.Definitions.LogSource.FORGE_OS,
                "Device '%s' resume orchestration failed; displaying Home surface",
                deviceId
            )
        elseif resumeResult ~= Result.SUCCESS then
            FORGE.Logger:warning(
                FORGE.Definitions.LogSource.FORGE_OS,
                "Device '%s' resume returned '%s'; displaying Home surface",
                deviceId,
                FORGE.Logger:safeToString(resumeResult, "<unknown>")
            )
        end
    end

    return result
end

function FORGE.ForgeOS:hideDevice(deviceId)
    return FORGE.DeviceStateService:hideDevice(deviceId)
end

function FORGE.ForgeOS:getDeviceVisibility(deviceId)
    return FORGE.DeviceStateService:getDeviceVisibility(deviceId)
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

function FORGE.ForgeOS:openApp(deviceId, appId)
    return FORGE.AppLifecycleService:openApp(deviceId, appId)
end

function FORGE.ForgeOS:activateApp(deviceId, appId)
    return FORGE.AppLifecycleService:activateApp(deviceId, appId)
end

function FORGE.ForgeOS:backgroundApp(deviceId, appId)
    return FORGE.AppLifecycleService:backgroundApp(deviceId, appId)
end

function FORGE.ForgeOS:closeApp(deviceId, appId)
    return FORGE.AppLifecycleService:closeApp(deviceId, appId)
end

function FORGE.ForgeOS:getAppLifecycleState(deviceId, appId)
    return FORGE.AppLifecycleService
        :getAppLifecycleState(deviceId, appId)
end

function FORGE.ForgeOS:getActiveAppId(deviceId)
    return FORGE.AppLifecycleService:getActiveAppId(deviceId)
end

function FORGE.ForgeOS:navigate(
    deviceId,
    appId,
    routeId,
    routeParameters
)
    return FORGE.NavigationService:navigate(
        deviceId,
        appId,
        routeId,
        routeParameters
    )
end

function FORGE.ForgeOS:goBack(deviceId, appId)
    return FORGE.NavigationService:goBack(deviceId, appId)
end

function FORGE.ForgeOS:getCurrentRoute(deviceId, appId)
    return FORGE.NavigationService:getCurrentRoute(deviceId, appId)
end

function FORGE.ForgeOS:getNavigationHistory(deviceId, appId)
    return FORGE.NavigationService
        :getNavigationHistory(deviceId, appId)
end

function FORGE.ForgeOS:createNotification(definition)
    return FORGE.NotificationService:createNotification(definition)
end

function FORGE.ForgeOS:markNotificationRead(notificationId)
    return FORGE.NotificationService
        :markNotificationRead(notificationId)
end

function FORGE.ForgeOS:dismissNotification(notificationId)
    return FORGE.NotificationService
        :dismissNotification(notificationId)
end

function FORGE.ForgeOS:getNotification(notificationId)
    return FORGE.NotificationService:getNotification(notificationId)
end

function FORGE.ForgeOS:getNotifications(deviceId, includeDismissed)
    return FORGE.NotificationService:getNotifications(
        deviceId,
        includeDismissed
    )
end

function FORGE.ForgeOS:updateRuntimeHost(dt)
    if FORGE.ForgeOSCore:getPhase() == Phase.RUNTIME_ACTIVE then
        for _, deviceId in ipairs(HOST_ORDER) do
            local instance = runtimeHosts[deviceId]
            if instance ~= nil then
                local succeeded, failure =
                    pcall(instance.update, instance, dt)
                if not succeeded then
                    reportRuntimeHostFailure(deviceId, "update", failure)
                end
            end
        end
    end
end

function FORGE.ForgeOS:drawRuntimeHost()
    if FORGE.ForgeOSCore:getPhase() == Phase.RUNTIME_ACTIVE then
        for _, deviceId in ipairs(HOST_ORDER) do
            local instance = runtimeHosts[deviceId]
            if instance ~= nil then
                local succeeded, failure =
                    pcall(instance.draw, instance)
                if not succeeded then
                    reportRuntimeHostFailure(deviceId, "draw", failure)
                end
            end
        end
    end
end

function FORGE.ForgeOS:dispatchHostInput(action, value, ...)
    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return false
    end
    for _, deviceId in ipairs(HOST_ORDER) do
        local instance = runtimeHosts[deviceId]
        if instance ~= nil then
            local call = { pcall(instance.onInput, instance, action, value, ...) }
            if not call[1] then
                reportRuntimeHostFailure(deviceId, "input", call[2])
            elseif call[2] == true then
                return true
            end
        end
    end
    return false
end

function FORGE.ForgeOS:dispatchHostPointer(posX, posY, ...)
    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return false
    end
    for _, deviceId in ipairs(HOST_ORDER) do
        local instance = runtimeHosts[deviceId]
        if instance ~= nil and instance:containsPoint(posX, posY) then
            local call = { pcall(instance.onPointer, instance,
                posX, posY, ...) }
            if not call[1] then
                reportRuntimeHostFailure(deviceId, "pointer", call[2])
            elseif call[2] == true then
                return true
            end
        end
    end
    return false
end

function FORGE.ForgeOS:hasVisibleRuntimeHost()
    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return false
    end
    for _, deviceId in ipairs(HOST_ORDER) do
        if FORGE.DeviceStateService:getDeviceVisibility(deviceId)
            == FORGE.Definitions.DeviceVisibility.VISIBLE then
            return true
        end
    end
    return false
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
