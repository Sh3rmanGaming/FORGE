---=============================================================================
--- FORGE Log Sources
---
--- Authoritative identifiers for FORGE log message origins.
---
--- Responsibilities:
---     • Define supported log sources.
---     • Provide consistent identifiers for diagnostic output.
---
--- This file must not contain logging behaviour.
---=============================================================================

FORGE.Definitions.LogSource = {

    UNKNOWN = "Unknown",
    ENGINE = "Engine",
    LOGGER = "Logger",
    EVENT_BUS = "EventBus",
    STATE_STORE = "StateStore",
    SAVE_MANAGER = "SaveManager",
    XML_WRITER = "XMLWriter",
    XML_READER = "XMLReader",
    TEST = "Test",
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
