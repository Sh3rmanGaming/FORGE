---=============================================================================
--- FORGE Log Levels
---
--- Authoritative severity definitions used by the FORGE Logging Service.
---
--- Responsibilities:
---     • Define supported logging levels.
---     • Provide numeric severity values for filtering and comparison.
---     • Provide readable labels for formatted log output.
---
--- This file must not contain logging behaviour.
---=============================================================================

FORGE.Definitions.LogLevel = {
    TRACE = {
        severity = 10,
        label = "TRACE"
    },

    DEBUG = {
        severity = 20,
        label = "DEBUG"
    },

    INFO = {
        severity = 30,
        label = "INFO"
    },

    WARNING = {
        severity = 40,
        label = "WARNING"
    },

    ERROR = {
        severity = 50,
        label = "ERROR"
    },

    FATAL = {
        severity = 60,
        label = "FATAL"
    }
}