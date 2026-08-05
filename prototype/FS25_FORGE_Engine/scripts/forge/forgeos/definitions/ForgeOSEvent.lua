---=============================================================================
--- FORGE ForgeOS Event Definitions
---
--- Authoritative event identifiers emitted by ForgeOS.
---
--- Responsibilities:
---     • Define stable ForgeOS event identifiers.
---     • Identify completed registration and state changes.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.ForgeOSEvent = {

    REGISTRATION_OPENED =
        "forge.os.registration.opened",

    REGISTRATION_FROZEN =
        "forge.os.registration.frozen",

    DEVICE_REGISTERED =
        "forge.os.device.registered",

    DEVICE_ACTIVATED =
        "forge.os.device.activated",

    DEVICE_DEACTIVATED =
        "forge.os.device.deactivated",

    DEVICE_VISIBILITY_CHANGED =
        "forge.os.device.visibilityChanged",

    APP_REGISTERED =
        "forge.os.app.registered",

    APP_PRESENTATION_RESOLVED =
        "forge.os.app.presentationResolved",

    APP_AVAILABILITY_CHANGED =
        "forge.os.app.availabilityChanged",

    APP_OPENED =
        "forge.os.app.opened",

    APP_ACTIVATED =
        "forge.os.app.activated",

    APP_BACKGROUNDED =
        "forge.os.app.backgrounded",

    APP_CLOSED =
        "forge.os.app.closed",

    NAVIGATION_CHANGED =
        "forge.os.navigation.changed",

    NOTIFICATION_CREATED =
        "forge.os.notification.created",

    NOTIFICATION_READ =
        "forge.os.notification.read",

    NOTIFICATION_DISMISSED =
        "forge.os.notification.dismissed",

    STARTED =
        "forge.os.started",

    STOPPED =
        "forge.os.stopped"
}
