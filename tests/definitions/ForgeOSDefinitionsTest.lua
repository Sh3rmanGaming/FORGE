---=============================================================================
--- FORGE ForgeOS Definitions Tests
---
--- Manual test harness for the authoritative ForgeOS definition package.
---
--- Responsibilities:
---     • Verify every approved ForgeOS definition table and value.
---     • Reject missing, unexpected, or duplicate identifiers.
---     • Verify ForgeOS additions without changing existing engine definitions.
---     • Report manual test execution results through the FORGE Logger.
---
--- This manual harness is invoked by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSDefinitionsTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Definitions test harness started"
    )

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
        PresentationModelVersion = {
            LEGACY = 1,
            DECLARATIVE = 2
        },
        PresentationComponent = {
            STACK = "layout.stack",
            ROW = "layout.row",
            SPLIT = "layout.split",
            SCROLL = "layout.scroll",
            TEXT = "content.text",
            ICON = "content.icon",
            DIVIDER = "content.divider",
            EMPTY_STATE = "content.emptyState",
            BUTTON = "control.button",
            ICON_BUTTON = "control.iconButton",
            NAVIGATION_ITEM = "control.navigationItem",
            LIST_ROW = "control.listRow",
            BADGE = "indicator.badge",
            STATUS = "indicator.status"
        },
        PresentationNodeField = {
            COMPONENT = "component",
            ID = "id",
            PROPERTIES = "properties",
            CHILDREN = "children"
        },
        PresentationProperty = {
            TEXT = "text",
            ICON_ID = "iconId",
            ACCESSIBLE_LABEL = "accessibleLabel",
            ACTION_REFERENCE = "actionReference",
            DIRECTION = "direction",
            ALIGNMENT = "alignment",
            DISTRIBUTION = "distribution",
            SPACING = "spacing",
            PADDING = "padding",
            GAP = "gap",
            WIDTH_MODE = "widthMode",
            HEIGHT_MODE = "heightMode",
            MINIMUM_WIDTH = "minimumWidth",
            MAXIMUM_WIDTH = "maximumWidth",
            MINIMUM_HEIGHT = "minimumHeight",
            MAXIMUM_HEIGHT = "maximumHeight",
            GROW = "grow",
            SURFACE = "surface",
            BORDER = "border",
            TEXT_ROLE = "textRole",
            TEXT_ALIGNMENT = "textAlignment",
            TEXT_WRAP = "textWrap",
            MAXIMUM_LINES = "maximumLines",
            TEXT_OVERFLOW = "textOverflow",
            CLIPPING = "clipping",
            OVERFLOW = "overflow",
            SELECTED = "selected",
            DISABLED = "disabled",
            SEMANTIC_STATE = "semanticState",
            COUNT = "count"
        },
        PresentationDirection = {
            VERTICAL = "vertical",
            HORIZONTAL = "horizontal"
        },
        PresentationAlignment = {
            START = "start",
            CENTER = "center",
            END = "end",
            STRETCH = "stretch"
        },
        PresentationDistribution = {
            START = "start",
            CENTER = "center",
            END = "end",
            SPACE_BETWEEN = "spaceBetween"
        },
        PresentationSizeMode = {
            AUTO = "auto",
            CONTENT = "content",
            FILL = "fill",
            WEIGHTED = "weighted"
        },
        PresentationSizeToken = {
            XS = "size.xs",
            SM = "size.sm",
            MD = "size.md",
            LG = "size.lg",
            XL = "size.xl",
            XXL = "size.xxl",
            VIEWPORT = "size.viewport"
        },
        PresentationGrowWeight = {
            ONE = 1,
            TWO = 2,
            THREE = 3,
            FOUR = 4
        },
        PresentationTextAlignment = {
            START = "start",
            CENTER = "center",
            END = "end"
        },
        PresentationClipping = {
            NONE = "none",
            BOUNDS = "bounds"
        },
        PresentationOverflow = {
            VISIBLE = "visible",
            HIDDEN = "hidden",
            SCROLL = "scroll"
        },
        PresentationTextWrap = {
            NONE = "none",
            WORD = "word"
        },
        PresentationTextOverflow = {
            CLIP = "clip",
            ELLIPSIS = "ellipsis"
        },
        PresentationToken = {
            SURFACE_BACKGROUND = "surface.background",
            SURFACE_PRIMARY = "surface.primary",
            SURFACE_SECONDARY = "surface.secondary",
            SURFACE_ELEVATED = "surface.elevated",
            SURFACE_SELECTED = "surface.selected",
            SURFACE_DISABLED = "surface.disabled",
            TEXT_PRIMARY = "text.primary",
            TEXT_SECONDARY = "text.secondary",
            TEXT_MUTED = "text.muted",
            TEXT_DISABLED = "text.disabled",
            TEXT_INVERSE = "text.inverse",
            ACCENT_PRIMARY = "accent.primary",
            ACCENT_SECONDARY = "accent.secondary",
            SEMANTIC_SUCCESS = "semantic.success",
            SEMANTIC_WARNING = "semantic.warning",
            SEMANTIC_ERROR = "semantic.error",
            SEMANTIC_INFORMATION = "semantic.information",
            SEMANTIC_UNREAD = "semantic.unread",
            SEMANTIC_ATTENTION = "semantic.attention",
            BORDER_SUBTLE = "border.subtle",
            BORDER_STANDARD = "border.standard",
            BORDER_ACTIVE = "border.active",
            BORDER_FOCUS = "border.focus",
            SPACING_XS = "spacing.xs",
            SPACING_SM = "spacing.sm",
            SPACING_MD = "spacing.md",
            SPACING_LG = "spacing.lg",
            SPACING_XL = "spacing.xl",
            SPACING_XXL = "spacing.xxl",
            TYPOGRAPHY_DISPLAY = "typography.display",
            TYPOGRAPHY_HEADING_1 = "typography.heading1",
            TYPOGRAPHY_HEADING_2 = "typography.heading2",
            TYPOGRAPHY_HEADING_3 = "typography.heading3",
            TYPOGRAPHY_BODY = "typography.body",
            TYPOGRAPHY_BODY_STRONG = "typography.bodyStrong",
            TYPOGRAPHY_LABEL = "typography.label",
            TYPOGRAPHY_CAPTION = "typography.caption",
            TYPOGRAPHY_NUMERIC = "typography.numeric",
            MOTION_ENTER = "motion.enter",
            MOTION_EXIT = "motion.exit",
            MOTION_STATE_CHANGE = "motion.stateChange"
        },
        PresentationEnvelopeField = {
            MODEL_VERSION = "modelVersion",
            APP_ID = "appId",
            PRESENTATION_ID = "presentationId",
            ROUTE_ID = "routeId",
            TITLE = "title",
            ATTENTION = "attention",
            VIEW = "view",
            ACTIONS = "actions"
        },
        PresentationActionField = {
            TARGET = "target",
            ACTION_ID = "actionId",
            PARAMETERS = "parameters"
        },
        AttentionField = {
            STATE = "state",
            COUNT = "count",
            ACCESSIBLE_LABEL = "accessibleLabel"
        },
        RouteSchemaField = {
            PARAMETERS = "parameters",
            ALLOW_ADDITIONAL_PARAMETERS = "allowAdditionalParameters",
            TYPE = "type",
            REQUIRED = "required"
        },
        PresentationActionTarget = {
            APPLICATION = "application",
            HOST = "host"
        },
        PresentationHostAction = {
            OS_HOME = "osHome",
            DEVICE_CLOSE = "deviceClose"
        },
        PresentationChildPolicy = {
            REQUIRED = "required",
            ALLOWED = "allowed",
            FORBIDDEN = "forbidden"
        },
        PresentationSemanticState = {
            NONE = "none",
            UNREAD = "unread",
            ATTENTION = "attention",
            SUCCESS = "success",
            WARNING = "warning",
            ERROR = "error",
            INFORMATION = "information"
        },
        AttentionState = {
            NONE = "none",
            UNREAD = "unread",
            ATTENTION = "attention",
            WARNING = "warning",
            ERROR = "error"
        },
        LegacyBadgeAttentionState = {
            ZERO = "none",
            POSITIVE = "unread"
        },
        RouteParameterType = {
            IDENTIFIER = "identifier",
            STRING = "string",
            BOOLEAN = "boolean",
            INTEGER = "integer",
            NUMBER = "number"
        },
        NotificationCueType = {
            PHONE_BANNER = "phoneBanner",
            LAPTOP_TOAST = "laptopToast",
            SOUND = "sound"
        },
        NotificationSoundCue = {
            INFORMATION = "information",
            SUCCESS = "success",
            WARNING = "warning",
            ERROR = "error",
            CRITICAL = "critical"
        },
        NotificationActivationStage = {
            NONE = "none",
            PREFLIGHT = "preflight",
            OPEN = "open",
            ACTIVATE = "activate",
            NAVIGATE = "navigate",
            MARK_READ = "markRead",
            COMPLETE = "complete"
        },
        NotificationActivationResult = {
            VALIDATION_FAILED = "validationFailed",
            OPEN_FAILED = "openFailed",
            ACTIVATION_FAILED = "activationFailed",
            NAVIGATION_FAILED = "navigationFailed",
            READ_UPDATE_FAILED = "readUpdateFailed",
            SUCCESS = "success"
        },
        PresentationLimit = {
            MAX_VIEW_DEPTH = 12,
            MAX_VIEW_NODES = 512,
            MAX_CHILDREN_PER_NODE = 64,
            MAX_TEXT_LENGTH = 8192,
            MAXIMUM_TEXT_LINES = 32,
            MAX_ACTIONS = 128,
            MAX_PARAMETER_DEPTH = 8,
            MAX_PARAMETER_ENTRIES = 128,
            MAX_ROUTE_PARAMETERS = 32
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
        PRESENTATION_PROTOCOL = "PresentationProtocol",
        NOTIFICATION_PRESENTATION = "NotificationPresentation",
        APP_AVAILABILITY = "AppAvailability",
        APP_LIFECYCLE = "AppLifecycle",
        NAVIGATION = "Navigation",
        NOTIFICATION = "Notification",
        PHONE_HOST = "PhoneHost",
        LAPTOP_HOST = "LaptopHost"
    }

    local expectedComponentContracts = {
        ["layout.stack"] = {
            allowed = "direction|alignment|distribution|spacing|padding|gap|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|clipping|overflow",
            required = "", childPolicy = "required", minimum = 1,
            maximum = 64, interactive = false, states = ""
        },
        ["layout.row"] = {
            allowed = "alignment|distribution|spacing|padding|gap|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|clipping|overflow",
            required = "", childPolicy = "required", minimum = 1,
            maximum = 64, interactive = false, states = ""
        },
        ["layout.split"] = {
            allowed = "direction|alignment|padding|gap|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|clipping|overflow",
            required = "", childPolicy = "required", minimum = 2,
            maximum = 2, interactive = false, states = ""
        },
        ["layout.scroll"] = {
            allowed = "direction|padding|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|clipping|overflow",
            required = "", childPolicy = "required", minimum = 1,
            maximum = 1, interactive = false, states = ""
        },
        ["content.text"] = {
            allowed = "text|accessibleLabel|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|textRole|textAlignment|clipping|overflow|textWrap|maximumLines|textOverflow|semanticState",
            required = "text", childPolicy = "forbidden", minimum = 0,
            maximum = 0, interactive = false,
            states = "none|unread|attention|success|warning|error|information"
        },
        ["content.icon"] = {
            allowed = "iconId|accessibleLabel|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|clipping|semanticState",
            required = "iconId", childPolicy = "forbidden", minimum = 0,
            maximum = 0, interactive = false,
            states = "none|unread|attention|success|warning|error|information"
        },
        ["content.divider"] = {
            allowed = "widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|border",
            required = "", childPolicy = "forbidden", minimum = 0,
            maximum = 0, interactive = false, states = ""
        },
        ["content.emptyState"] = {
            allowed = "text|iconId|accessibleLabel|padding|gap|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|textRole|textAlignment|semanticState",
            required = "", childPolicy = "allowed", minimum = 0,
            maximum = 4, interactive = false,
            content = "text|iconId|accessibleLabel|children", minimumContent = 1,
            states = "none|attention|success|warning|error|information"
        },
        ["control.button"] = {
            allowed = "text|iconId|accessibleLabel|actionReference|padding|gap|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|textRole|textAlignment|selected|disabled|semanticState",
            required = "actionReference", childPolicy = "allowed", minimum = 0,
            maximum = 4, interactive = true,
            content = "text|iconId|accessibleLabel|children", minimumContent = 1,
            states = "none|unread|attention|success|warning|error|information"
        },
        ["control.iconButton"] = {
            allowed = "iconId|accessibleLabel|actionReference|padding|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|selected|disabled|semanticState",
            required = "iconId|accessibleLabel|actionReference",
            childPolicy = "forbidden", minimum = 0, maximum = 0,
            interactive = true,
            states = "none|unread|attention|success|warning|error|information"
        },
        ["control.navigationItem"] = {
            allowed = "text|iconId|accessibleLabel|actionReference|count|padding|gap|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|textRole|textAlignment|selected|disabled|semanticState",
            required = "actionReference", childPolicy = "allowed", minimum = 0,
            maximum = 4, interactive = true,
            content = "text|iconId|accessibleLabel|children", minimumContent = 1,
            states = "none|unread|attention|warning|error"
        },
        ["control.listRow"] = {
            allowed = "accessibleLabel|actionReference|padding|gap|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|surface|border|selected|disabled|semanticState",
            required = "actionReference", childPolicy = "required", minimum = 1,
            maximum = 64, interactive = true,
            states = "none|unread|attention|warning|error"
        },
        ["indicator.badge"] = {
            allowed = "count|accessibleLabel|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|semanticState",
            required = "semanticState", childPolicy = "forbidden", minimum = 0,
            maximum = 0, interactive = false,
            states = "none|unread|attention|success|warning|error|information"
        },
        ["indicator.status"] = {
            allowed = "text|iconId|accessibleLabel|widthMode|heightMode|minimumWidth|maximumWidth|minimumHeight|maximumHeight|grow|textRole|textAlignment|semanticState",
            required = "semanticState", childPolicy = "forbidden", minimum = 0,
            maximum = 0, interactive = false,
            content = "text|iconId|accessibleLabel", minimumContent = 1,
            states = "none|unread|attention|success|warning|error|information"
        }
    }

    local function join(values)
        return table.concat(values, "|")
    end

    local function verifyComponentContracts()
        local actual = FORGE.Definitions.PresentationComponentContract
        if type(actual) ~= "table" or getmetatable(actual) ~= nil then
            error("PresentationComponentContract must be a plain table")
        end
        local approvedComponents = {}
        for _, value in pairs(FORGE.Definitions.PresentationComponent) do
            approvedComponents[value] = true
        end
        local approvedProperties = {}
        for _, value in pairs(FORGE.Definitions.PresentationProperty) do
            approvedProperties[value] = true
        end
        local approvedStates = {}
        for _, value in pairs(FORGE.Definitions.PresentationSemanticState) do
            approvedStates[value] = true
        end
        local approvedPolicies = {}
        for _, value in pairs(FORGE.Definitions.PresentationChildPolicy) do
            approvedPolicies[value] = true
        end
        for component, expected in pairs(expectedComponentContracts) do
            local contract = actual[component]
            if type(contract) ~= "table"
                or join(contract.allowedProperties or {}) ~= expected.allowed
                or join(contract.requiredProperties or {}) ~= expected.required
                or contract.childPolicy ~= expected.childPolicy
                or contract.minimumChildren ~= expected.minimum
                or contract.maximumChildren ~= expected.maximum
                or contract.interactive ~= expected.interactive
                or join(contract.contentSources or {})
                    ~= (expected.content or "")
                or (contract.minimumContentSources or 0)
                    ~= (expected.minimumContent or 0)
                or join(contract.allowedSemanticStates or {}) ~= expected.states then
                error(component .. " has an unexpected component contract")
            end
            if approvedComponents[component] ~= true
                or approvedPolicies[contract.childPolicy] ~= true
                or contract.maximumChildren
                    > FORGE.Definitions.PresentationLimit.MAX_CHILDREN_PER_NODE then
                error(component .. " references an unapproved contract value")
            end
            local allowed = {}
            for _, property in ipairs(contract.allowedProperties) do
                if approvedProperties[property] ~= true
                    or allowed[property] == true then
                    error(component .. " contains an invalid allowed property")
                end
                allowed[property] = true
            end
            for _, property in ipairs(contract.requiredProperties) do
                if allowed[property] ~= true then
                    error(component .. " requires a property it does not allow")
                end
            end
            for _, source in ipairs(contract.contentSources or {}) do
                if source ~= "children" and allowed[source] ~= true then
                    error(component .. " contains an invalid content source")
                end
            end
            for _, state in ipairs(contract.allowedSemanticStates) do
                if approvedStates[state] ~= true then
                    error(component .. " contains an invalid semantic state")
                end
            end
            for key in pairs(contract) do
                if key ~= "allowedProperties"
                    and key ~= "requiredProperties"
                    and key ~= "childPolicy"
                    and key ~= "minimumChildren"
                    and key ~= "maximumChildren"
                    and key ~= "interactive"
                    and key ~= "contentSources"
                    and key ~= "minimumContentSources"
                    and key ~= "allowedSemanticStates" then
                    error(component .. " contains an unknown contract field")
                end
            end
        end
        for component in pairs(actual) do
            if expectedComponentContracts[component] == nil then
                error(component .. " is not an approved component contract")
            end
        end
    end

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
                and tableName ~= "PresentationLimit"
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

            verifyComponentContracts()

            local identifierTables = {
                "PresentationComponent",
                "PresentationNodeField",
                "PresentationProperty",
                "PresentationToken",
                "PresentationActionTarget",
                "PresentationHostAction",
                "PresentationChildPolicy",
                "PresentationSemanticState",
                "PresentationTextWrap",
                "PresentationTextOverflow",
                "AttentionState",
                "RouteParameterType",
                "NotificationCueType",
                "NotificationSoundCue",
                "NotificationActivationStage",
                "NotificationActivationResult"
            }

            for _, tableName in ipairs(identifierTables) do
                for _, value in pairs(
                    FORGE.Definitions[tableName]
                ) do
                    if type(value) ~= "string"
                        or string.match(
                            value,
                            "^[%a][%w%.]*$"
                        ) == nil then
                        error(
                            tableName
                                .. " contains an invalid identifier"
                        )
                    end
                end
            end

            for key, value in pairs(
                FORGE.Definitions.PresentationLimit
            ) do
                if type(value) ~= "number"
                    or value < 1
                    or value ~= math.floor(value) then
                    error(
                        "PresentationLimit."
                            .. tostring(key)
                            .. " must be a positive integer"
                    )
                end
            end

            if FORGE.Definitions.LegacyBadgeAttentionState.ZERO
                    ~= FORGE.Definitions.AttentionState.NONE
                or FORGE.Definitions.LegacyBadgeAttentionState.POSITIVE
                    ~= FORGE.Definitions.AttentionState.UNREAD then
                error(
                    "Legacy badge attention mapping is invalid"
                )
            end

            for _, value in pairs(
                FORGE.Definitions.PresentationToken
            ) do
                if string.match(value, "#") ~= nil
                    or string.match(value, "rgb") ~= nil then
                    error(
                        "Presentation tokens must not freeze palette values"
                    )
                end
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
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Definitions test harness failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Definitions test harness passed"
    )

    return true
end
