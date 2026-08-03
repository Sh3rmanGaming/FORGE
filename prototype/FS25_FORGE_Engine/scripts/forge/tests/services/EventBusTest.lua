---=============================================================================
--- FORGE Event Bus Tests
---
--- Manual test harness for the FORGE Event Bus service.
---
--- Responsibilities:
---     • Verify subscription behaviour.
---     • Verify publication metrics.
---     • Verify callback failure isolation.
---     • Verify safe subscription changes during publication.
---     • Verify listener cleanup.
---
--- This file must restore all shared state changed during testing.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runEventBusTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local previousListeners =
        FORGE.EventBus.listeners

    FORGE.EventBus.listeners = {}

    local success, errorMessage = pcall(
        function()
            local testEvent = "forge.test.event"
            local selfRemovalEvent = "forge.test.selfRemoval"

            local listenerA = {
                calls = 0
            }

            local listenerB = {
                calls = 0
            }

            local failingListener = {}

            local selfRemovingListener = {
                calls = 0
            }

            function listenerA:onEvent(value)
                self.calls = self.calls + value
            end

            function listenerB:onEvent(value)
                self.calls = self.calls + value
            end

            function failingListener:onEvent()
                error("Intentional Event Bus test failure")
            end

            function selfRemovingListener:onEvent()
                self.calls = self.calls + 1

                FORGE.EventBus:unsubscribe(
                    selfRemovalEvent,
                    self,
                    self.onEvent
                )
            end

            FORGE.Logger:setDevelopmentMode(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            local firstSubscription =
                FORGE.EventBus:subscribe(
                    testEvent,
                    listenerA,
                    listenerA.onEvent
                )

            local duplicateSubscription =
                FORGE.EventBus:subscribe(
                    testEvent,
                    listenerA,
                    listenerA.onEvent
                )

            local secondSubscription =
                FORGE.EventBus:subscribe(
                    testEvent,
                    listenerB,
                    listenerB.onEvent
                )

            local failingSubscription =
                FORGE.EventBus:subscribe(
                    testEvent,
                    failingListener,
                    failingListener.onEvent
                )

            local firstResult =
                FORGE.EventBus:publish(
                    testEvent,
                    2
                )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Event Bus subscription results: first=%s duplicate=%s second=%s failing=%s",
                FORGE.Logger:safeToString(
                    firstSubscription,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    duplicateSubscription,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    secondSubscription,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    failingSubscription,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Event Bus publication metrics: called=%d succeeded=%d failed=%d",
                firstResult.called,
                firstResult.succeeded,
                firstResult.failed
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Listener values: A=%d B=%d",
                listenerA.calls,
                listenerB.calls
            )

            local removedListenerA =
                FORGE.EventBus:unsubscribe(
                    testEvent,
                    listenerA,
                    listenerA.onEvent
                )

            local secondResult =
                FORGE.EventBus:publish(
                    testEvent,
                    3
                )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Unsubscribe result=%s; second publication called=%d succeeded=%d failed=%d",
                FORGE.Logger:safeToString(
                    removedListenerA,
                    "false"
                ),
                secondResult.called,
                secondResult.succeeded,
                secondResult.failed
            )

            FORGE.EventBus:subscribe(
                selfRemovalEvent,
                selfRemovingListener,
                selfRemovingListener.onEvent
            )

            local selfRemovalFirstResult =
                FORGE.EventBus:publish(
                    selfRemovalEvent
                )

            local selfRemovalSecondResult =
                FORGE.EventBus:publish(
                    selfRemovalEvent
                )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Self-removal results: calls=%d firstCalled=%d secondCalled=%d",
                selfRemovingListener.calls,
                selfRemovalFirstResult.called,
                selfRemovalSecondResult.called
            )

            local emptyResult =
                FORGE.EventBus:publish(
                    "forge.test.noListeners"
                )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Empty publication metrics: called=%d succeeded=%d failed=%d",
                emptyResult.called,
                emptyResult.succeeded,
                emptyResult.failed
            )

            local clearedTestEvent =
                FORGE.EventBus:clear(testEvent)

            local clearedEventCount =
                FORGE.EventBus:clearAll()

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Cleanup results: eventCleared=%s remainingEventGroups=%d",
                FORGE.Logger:safeToString(
                    clearedTestEvent,
                    "false"
                ),
                clearedEventCount
            )
        end
    )

    FORGE.EventBus.listeners =
        previousListeners

    FORGE.Logger:setDevelopmentMode(
        previousDevelopmentMode
    )

    FORGE.Logger:setMinimumLevel(
        previousMinimumLevel
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Event Bus test harness failed unexpectedly: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false
    end

    return true
end