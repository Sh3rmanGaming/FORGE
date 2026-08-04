---=============================================================================
--- FORGE ForgeOS Definitions Tests
---
--- Manual test harness for the authoritative ForgeOS definition package.
---
--- Responsibilities:
---     • Verify every approved ForgeOS definition table and value.
---     • Reject missing, unexpected, or duplicate identifiers.
---     • Verify ForgeOS additions without changing existing engine definitions.
---
--- This manual harness is not currently invoked by Engine.lua.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSDefinitionsTests()
    local expectedDefinitions = {
        ForgeOSVersion = {
            APP_API = 1,
            STATE = 1
        },
        ForgeOSNamespace = {
            OS = "forge.os"
        },
        ForgeOSPhase = {
            UNAVAILABLE = "unavailable",
            INITIALISING = "initialising",
            REGISTRATION_OPEN = "registrationOpen",
            VALIDATING = "validating",
            REGISTRATION_FROZEN = "registrationFrozen",
            RUNTIME_ACTIVE = "runtimeActive",
            SHUTTING_DOWN = "shuttingDown",
            STOPPED = "stopped"
        },
        ForgeOSPlayerId = {
            LOCAL = "player.local"
        },
        DeviceId = {
            PHONE = "phone",
            LAPTOP = "laptop"
        },
        DeviceCapability = {
            FULL_SCREEN_APPS = "fullScreenApps",
            WINDOWED_APPS = "windowedApps",
            TOUCH_INPUT = "touchInput",
            POINTER_INPUT = "pointerInput",
            KEYBOARD_INPUT = "keyboardInput",
            NOTIFICATIONS = "notifications",
            BACKGROUND_APPS = "backgroundApps",
            MULTI_APP = "multiApp",
            MODALS = "modals",
            NAVIGATION_HISTORY = "navigationHistory"
        },
        DeviceVisibility = {
            HIDDEN = "hidden",
            VISIBLE = "visible"
        },
        AppLifecycleState = {
            CLOSED = "closed",
            OPEN = "open",
            ACTIVE = "active",
            BACKGROUND = "background"
        },
        AppAvailabilityReason = {
            AVAILABLE = "available",
            APP_NOT_REGISTERED = "appNotRegistered",
            DEVICE_NOT_REGISTERED = "deviceNotRegistered",
            DEVICE_NOT_SUPPORTED = "deviceNotSupported",
            MISSING_CAPABILITY = "missingCapability",
            PRESENTATION_NOT_FOUND = "presentationNotFound",
            ROUTE_NOT_FOUND = "routeNotFound",
            ACTION_NOT_AVAILABLE = "actionNotAvailable",
            API_VERSION_UNSUPPORTED = "apiVersionUnsupported",
            APP_DISABLED = "appDisabled",
            POLICY_REJECTED = "policyRejected",
            INVALID_DEFINITION = "invalidDefinition",
            UNKNOWN = "unknown"
        },
        PresentationMatchType = {
            EXACT_DEVICE = "exactDevice",
            CAPABILITY = "capability",
            DEFAULT = "default"
        },
        NotificationPersistence = {
            TRANSIENT = "transient",
            SESSION = "session",
            SAVEGAME = "savegame"
        },
        NotificationSeverity = {
            INFO = "info",
            SUCCESS = "success",
            WARNING = "warning",
            ERROR = "error",
            CRITICAL = "critical"
        },
        NavigationLayer = {
            HOME = "home",
            APP = "app",
            ROUTE = "route",
            MODAL = "modal"
        },
        ForgeOSEvent = {
            REGISTRATION_OPENED = "forge.os.registration.opened",
            REGISTRATION_FROZEN = "forge.os.registration.frozen",
            DEVICE_REGISTERED = "forge.os.device.registered",
            DEVICE_ACTIVATED = "forge.os.device.activated",
            DEVICE_DEACTIVATED = "forge.os.device.deactivated",
            DEVICE_VISIBILITY_CHANGED =
                "forge.os.device.visibilityChanged",
            APP_REGISTERED = "forge.os.app.registered",
            APP_PRESENTATION_RESOLVED =
                "forge.os.app.presentationResolved",
            APP_AVAILABILITY_CHANGED =
                "forge.os.app.availabilityChanged",
            APP_OPENED = "forge.os.app.opened",
            APP_ACTIVATED = "forge.os.app.activated",
            APP_BACKGROUNDED = "forge.os.app.backgrounded",
            APP_CLOSED = "forge.os.app.closed",
            NAVIGATION_CHANGED = "forge.os.navigation.changed",
            NOTIFICATION_CREATED = "forge.os.notification.created",
            NOTIFICATION_READ = "forge.os.notification.read",
            NOTIFICATION_DISMISSED =
                "forge.os.notification.dismissed",
            STARTED = "forge.os.started",
            STOPPED = "forge.os.stopped"
        },
        ForgeOSResult = {
            SUCCESS = "success",
            INVALID_ARGUMENT = "invalidArgument",
            INVALID_DEFINITION = "invalidDefinition",
            ALREADY_REGISTERED = "alreadyRegistered",
            NOT_REGISTERED = "notRegistered",
            REGISTRATION_CLOSED = "registrationClosed",
            API_VERSION_UNSUPPORTED = "apiVersionUnsupported",
            NOT_AVAILABLE = "notAvailable",
            PRESENTATION_NOT_FOUND = "presentationNotFound",
            ROUTE_NOT_FOUND = "routeNotFound",
            ACTION_NOT_AVAILABLE = "actionNotAvailable",
            INVALID_TRANSITION = "invalidTransition",
            CAPABILITY_MISSING = "capabilityMissing",
            POLICY_REJECTED = "policyRejected",
            STATE_ERROR = "stateError",
            CALLBACK_FAILED = "callbackFailed",
            PERSISTENCE_ERROR = "persistenceError",
            INTERNAL_ERROR = "internalError"
        }
    }

    local expectedLogSources = {
        FORGE_OS = "ForgeOS",
        FORGE_OS_STATE = "ForgeOSState",
        DEVICE_REGISTRY = "DeviceRegistry",
        APP_REGISTRY = "AppRegistry",
        APP_PRESENTATION = "AppPresentation",
        APP_AVAILABILITY = "AppAvailability",
        APP_LIFECYCLE = "AppLifecycle",
        NAVIGATION = "Navigation",
        NOTIFICATION = "Notification",
        PHONE_HOST = "PhoneHost",
        LAPTOP_HOST = "LaptopHost"
    }

    local function verifyTable(tableName, actual, expected)
        if type(actual) ~= "table" then
            error(tableName .. " must be a table")
        end

        local observedValues = {}

        for key, expectedValue in pairs(expected) do
            if actual[key] ~= expectedValue then
                error(
                    tableName
                        .. "."
                        .. key
                        .. " has an unexpected value"
                )
            end

            if tableName ~= "ForgeOSVersion"
                and observedValues[expectedValue] ~= nil then
                error(
                    tableName
                        .. " contains duplicate value "
                        .. tostring(expectedValue)
                )
            end

            observedValues[expectedValue] = key
        end

        for key in pairs(actual) do
            if expected[key] == nil then
                error(
                    tableName
                        .. "."
                        .. tostring(key)
                        .. " is not an approved definition"
                )
            end
        end
    end

    local success, errorMessage = pcall(
        function()
            if type(FORGE.Definitions.ForgeOS) ~= "table" then
                error("ForgeOS definitions namespace must be a table")
            end

            for tableName, expected in pairs(expectedDefinitions) do
                verifyTable(
                    tableName,
                    FORGE.Definitions[tableName],
                    expected
                )
            end

            if type(FORGE.Definitions.LogSource) ~= "table" then
                error("LogSource must be a table")
            end

            for key, expectedValue in pairs(expectedLogSources) do
                if FORGE.Definitions.LogSource[key] ~= expectedValue then
                    error(
                        "LogSource."
                            .. key
                            .. " has an unexpected value"
                    )
                end
            end
        end
    )

    if not success then
        return false, errorMessage
    end

    return true
end
