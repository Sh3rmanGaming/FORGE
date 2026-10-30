---=============================================================================
--- FORGE Notification Activation Definitions
---
--- Layered stages and terminal outcomes for notification deep-link activation.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.NotificationActivationStage = {
    NONE = "none",
    PREFLIGHT = "preflight",
    OPEN = "open",
    ACTIVATE = "activate",
    NAVIGATE = "navigate",
    MARK_READ = "markRead",
    COMPLETE = "complete"
}

FORGE.Definitions.NotificationActivationResult = {
    VALIDATION_FAILED = "validationFailed",
    OPEN_FAILED = "openFailed",
    ACTIVATION_FAILED = "activationFailed",
    NAVIGATION_FAILED = "navigationFailed",
    READ_UPDATE_FAILED = "readUpdateFailed",
    SUCCESS = "success"
}
