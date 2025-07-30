--Scenario manager: The core scenario scripting module.

---Triggers the failure of the scenario.
---@param message string The message to show indicating why the scenario failed.
function ApiUtil.triggerScenarioFailure(message) sysCall("ScenarioManager:TriggerScenarioFailure", message) end

---Triggers the successful completion of the scenario.
---@param message string The message to show indicating why the scenario succeeded.
function ApiUtil.triggerScenarioComplete(message) sysCall("ScenarioManager:TriggerScenarioComplete", message) end

---Triggers a deferred event. Only one event per update may be triggered, two events with the same expiry time will be triggered in successive frames.
---@param event string The name of the event.
---@param time number The time in seconds until the event should trigger.
---@return boolean If the event was already scheduled `false`, otherwise `true`.
function ApiUtil.triggerDeferredEvent(event, time) return sysCall("ScenarioManager:TriggerDeferredEvent", event, time) end

---Cancels a deferred event.
---@param event string The name of the event.
---@return boolean If the event was no longer scheduled `false`, otherwise `true`.
function ApiUtil.cancelDeferredEvent(event) return sysCall("ScenarioManager:CancelDeferredEvent", event) end

---Begins testing of a condition. As soon as the condition is completed as either `CONDITION_SUCCEEDED(1)` or `CONDITION_FAILED(2)`,
---the condition will cease to be tested. If the condition was already complete at the time of the call, no `CheckCondition` will be generated.
---@param condition string The name of the condition.
---@return boolean If the condition was already scheduled `false`, otherwise `true`.
function ApiUtil.beginConditionCheck(condition) return sysCall("ScenarioManager:BeginConditionCheck", condition) end

---Removes a condition from checking per frame. Cannot be called from within `TestCondition`.
---@param condition string The name of the condition.
---@return boolean If the condition was no longer scheduled `false`, otherwise `true`.
function ApiUtil.endConditionCheck(condition) return sysCall("ScenarioManager:EndConditionCheck", condition) end

---Get the status of a script condition. The call only tests the saved status of a condition, it does not generate a call to `CheckCondition`.
---@param condition string The name of the condition.
---@return number The status of the condition: `CONDITION_NOT_YET_MET(0)`, `CONDITION_SUCCEEDED(1)` or `CONDITION_FAILED(2)`.
function ApiUtil.getConditionStatus(condition) return sysCall("ScenarioManager:GetConditionStatus", condition) end

---Shows a dialogue box with a message.
---If `title` or `message` are in UUID format, then they are used as keys into the language table.
---@param title string
---@param message string
---@param alert number Optional, defaults to `ALERT`. The type of message box `INFO(0)` or `ALERT(1)`.
function ApiUtil.showMessage(title, message, alert)
    sysCall("ScenarioManager:ShowMessage", title, message, alert or 1)
end

--TODO verify
---Shows an info dialogue box with a message and extended attributes.
---If `title` or `message` are in UUID format, then they are used as keys into the language table.
---@param title string
---@param message string
---@param time number The time to show the message, set to `0` for indefinite.
---@param pos number The position of the message box: `MSG_TOP(1)`, `MSG_VCENTRE(2)`, `MSG_BOTTOM(4)`, `MSG_LEFT(8)`, `MSG_CENTRE(16)`, `MSG_RIGHT(32)`.
---@param size number The size of the message box: `MSG_SMALL(0)`, `MSG_REG(1)`, `MSG_LRG(2)`.
---@param pause boolean If `true` pause the game while the message is shown.
function ApiUtil.showInfoMessageExt(title, message, time, pos, size, pause)
    sysCall("ScenarioManager:ShowInfoMessageExt", title, message, time, pos, size, pause)
end

---Shows an alert dialogue box with a message and extended attributes.
---If `title` or `message` are in UUID format, then they are used as keys into the language table.
---@param title string
---@param message string
---@param time number The time to show the message, set to `0` for indefinite.
---@param event string Event name triggered on click of message.
function ApiUtil.showAlertMessageExt(title, message, time, event)
    sysCall("ScenarioManager:ShowAlertMessageExt", title, message, time, event)
end

--TODO find info
---isAtDestination
---@param service string
---@param destination string
function ApiUtil.isAtDestination(service, destination) sysCall("ScenarioManager:IsAtDestination", service, destination) end

---Get the time since the scenario start in seconds.
---@return number The time since the scenario start in seconds.
function ApiUtil.getScenarioTime() return sysCall("ScenarioManager:GetScenarioTime") end

---Get the time since midnight in seconds.
---@return number The time since midnight in seconds.
function ApiUtil.getTimeOfDay() return sysCall("ScenarioManager:GetTimeOfDay") end

---Locks out controls and keyboard.
function ApiUtil.lockControls()
    sysCall("ScenarioManager:LockControls")
end

---Unlocks controls and keyboard.
function ApiUtil.unlockControls()
    sysCall("ScenarioManager:UnlockControls")
end
--TODO check constants SEASON_SPRING = 0, SEASON_SUMMER = 1, SEASON_AUTUMN = 2, SEASON_WINTER = 3
---Get the season.
---@return number Season: spring = `0`, summer = `1`, autumn = `2`, winter = `3`.
function ApiUtil.getSeason() return sysCall("ScenarioManager:GetSeason") end
