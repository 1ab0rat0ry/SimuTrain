---@class SignalState
---@field CLEAR number
---@field WARNING number
---@field BLOCKED number
local SignalState = {
    CLEAR = 0,
    WARNING = 1,
    BLOCKED = 2
}

---@class SignalMessage
---@field RESET_SIGNAL_STATE number
---@field INITIALISE_SIGNAL_TO_BLOCKED number
---@field JUNCTION_STATE_CHANGE number
---@field INITIALISE_TO_PREPARED number
---@field REQUEST_TO_PASS_DANGER number
---@field OCCUPATION_INCREMENT number
---@field OCCUPATION_DECREMENT number
local SignalMessage = {
    RESET_SIGNAL_STATE = 0,
    INITIALISE_SIGNAL_TO_BLOCKED = 1,
    JUNCTION_STATE_CHANGE = 2,
    INITIALISE_TO_PREPARED = 3,
    REQUEST_TO_PASS_DANGER = 4,
    OCCUPATION_INCREMENT = 10,
    OCCUPATION_DECREMENT = 11
}

---@class SignalApi
---@field State SignalState Game defined signal states.
---@field Message SignalMessage Game defined signal messages.
local SignalApi = {
    State = SignalState,
    Message = SignalMessage
}

local call = Call

--TODO verify
---Send a message along the track to the next/previous signal link on the track (ignoring links of the same signal).
---See Signal Message Types for a description of messages.
---@param message number The message type.
---@param argument string An optional string argument passed with the message. When is set to the special value `DoNotForward` the receiving signal is expected not to pass forward the message.
---@param direction number The direction the script sends the message relative to the link. `1` = forwards, `-1` = backwards.
---@param link number The direction of the link that the message should be sent to, relative to the link.
---@param index number The index of the link to send the message from.
---@return number Was signal found = `Signal Found`, was the end of the track encountered (rather than a circuit) = `End Of Track`.
function SignalApi.sendSignalMessage(message, argument, direction, link, index) return call("SendSignalMessage", message, argument, direction, link, index) end

---Send a message to passing consists. See consist message types for a list of valid types.
---Only safe to use from **OnConsistPassed**. Used to indicate SPADs, AWS, TPWS, etc.
---Custom messages are passed on to the engine script using the script method **OnCustomSignalMessage** passing the argument to the engine script,
---while the other message types are handled directly by the app.
---@param message number The message type.
---@param argument string An optional string argument passed with the message.
function SignalApi.sendConsistMessage(message, argument) call("SendConsistMessage", message, argument or "") end

---Get the contents of the ID field.
---@return string
function SignalApi.getId() return call("GetId") end

---Get the number of links in the signal. Blueprint::NumberOfTrackLinks.
---@return number The number of links the signal has in the range of 1 to 10.
function SignalApi.getLinkCount() return call("GetLinkCount") end

---Get the index of the link currently connected by the track network to the link.
---This is used as a method for testing which path ahead is set, usually in response to a junction change message or when initialising.
---If no link is connected then `-1` is returned. Only finds links owned by the same signal. For slips and crossings (where the junction has two simultaneous legal paths)
---the dispatcher holds an internal state for the junction and as such a signal will get `-1` as with a converging junction.
---In Free roam and for slips set to the player's path, the state is always set for the player's route.
---@param argument string Not used.
---@param direction number Not used.
---@param index number The index of the next link within the same signal connected via the track network, if a converging junction set against the direction of the start link is found or the end of track then `-1` is returned.
function SignalApi.getConnectedLink(argument, direction, index) return call("GetConnectedLink", argument, direction, index) end

---Get contents of `"Name of Route"` field (only the first character).
---@param index number The index of the signal link.
---@return number ASCII code of the first character.
function SignalApi.getLinkFeatherChar(index) return call("GetLinkFeatherChar", index) end

---Get contents of `"Speed of Route"` field.
---@param index number The index of the signal link.
---@return number Integer.
function SignalApi.getLinkSpeedLimit(index) return call("GetLinkSpeedLimit", index) end

---Get the state of checkbox `"Approach control"`.
---@param index number The index of the signal link.
---@return number If checked = `1`, if not = `0`.
function SignalApi.getLinkApproachControl(index)  return call("GetLinkApproachControl", index) end

---Get the state of checkbox `"Limited aspect"`.
---@param index number The index of the signal link.
---@return number If checked = `1`, if not = `0`.
function SignalApi.getLinkLimitedToYellow(index)  return call("GetLinkLimitedToYellow", index) end

---Get the track speed limit at the link. Used to test for speeding conditions in TPWS like systems.
---@param index number The index of the signal link.
---@return number The speed in metres per second.
function SignalApi.getTrackSpeedLimit(index) return call("GetTrackSpeedLimit", index) end

--TODO verify
---Get the signal state of the next/previous signal up/down the line.
---@param argument number An optional string argument passed with the message (nor used).
---@param direction number The direction from the link. `1` = forwards, `-1` = backwards.
---@param link number The direction of the signal link `0` to look for.
---@param index number The index of the link to start the search from.
---@return SignalState The state of the next signal along the line. Where no signal is found `GO` is returned.
function SignalApi.getNextSignalState(argument, direction, link, index) return call("GetNextSignalState", argument, direction, link, index) end

--TODO verify
---Sets the 2D map displayed state of the signal.
---@param state SignalState The state to set from.
function SignalApi.set2dMapSignalState(state) call("Set2DMapSignalState", state) end

---Get the speed of the consist currently passing the signal link.
---Only safe to use from OnConsistPassed. Typically used for TPWS like systems.
---@return number The speed in metres per second.
function SignalApi.getConsistSpeed() return call("GetConsistSpeed") end

return SignalApi