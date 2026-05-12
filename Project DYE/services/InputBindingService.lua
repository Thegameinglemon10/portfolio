--[[
__/\\\\\\\\\\\\\________/\\\\\________/\\\______________/\\\\\\\\\________/\\\\\\\\\______/\\\\\\\\\\\__/\\\\\\\\\\\\\\\__/\\\________/\\\___
__\/\\\/////////\\\____/\\\///\\\_____\/\\\____________/\\\\\\\\\\\\\____/\\\///////\\\___\/////\\\///__\///////\\\/////__\///\\\____/\\\/___
___\/\\\_______\/\\\__/\\\/__\///\\\___\/\\\___________/\\\/////////\\\__\/\\\_____\/\\\_______\/\\\___________\/\\\_________\///\\\/\\\/____
____\/\\\\\\\\\\\\\/__/\\\______\//\\\__\/\\\__________\/\\\_______\/\\\__\/\\\\\\\\\\\/________\/\\\___________\/\\\___________\///\\\/_____
_____\/\\\/////////___\/\\\_______\/\\\__\/\\\__________\/\\\\\\\\\\\\\\\__\/\\\//////\\\________\/\\\___________\/\\\_____________\/\\\_____
______\/\\\____________\//\\\______/\\\___\/\\\__________\/\\\/////////\\\__\/\\\____\//\\\_______\/\\\___________\/\\\_____________\/\\\____
_______\/\\\_____________\///\\\__/\\\_____\/\\\__________\/\\\_______\/\\\__\/\\\_____\//\\\______\/\\\___________\/\\\_____________\/\\\___
________\/\\\_______________\///\\\\\/______\/\\\\\\\\\\\__\/\\\_______\/\\\__\/\\\______\//\\\__/\\\\\\\\\\\_______\/\\\_____________\/\\\__
_________\///__________________\/////________\///////////___\///________\///___\///________\///__\///////////________\///______________\///__
Copyright, Polarity 2025

-- FILE INFORMATION --

File Name: InputBindingService.lua
Written By: JestaLemon
Creation Date: 02/06/2023
Version: 2.0.1

-- Last Edit --
Editor: JestaLemon
Date: 04/05/2026

-- Description --
Binds a user input using a label. Supports long press inputs.

-- Changelog --
[01/17/2026] v2.0.0: Rewritten for Defold.
[04/05/2026] v2.0.1: Added emmyLua type annotations.

-- END HEADER --
]]--!strict

--@ // TYPE DECLARATIONS \\ @--

---@class InputOptions 
---@field Key string
---@field MustHoldKey boolean?
---@field HoldDuration number?

---@class InputBinding
---@field Key userdata
---@field Activated ScriptSignal
local INPUT_BINDING = {}
INPUT_BINDING.__index = INPUT_BINDING;

---@class IB_INTERNALS
---@field KeyHash userdata
---@field ActionName string
---@field HoldStart number
---@field HoldActive boolean
---@field HoldDuration number
---@field HoldCancelled boolean

---@class InputBinding_Internal: InputBinding
---@field __internal IB_INTERNALS
---@field __StartHold fun(self: InputBinding_Internal)
---@field __NextHoldTick fun(self: InputBinding_Internal)

---@class InputBindingService
---@field ActiveBindings {string: InputBinding}
local InputBindingService = {};

--@ // DEPENDENCIES \\ @--
local utilities = require("example.modules.Utilities")
local assertType = utilities.AssertType
local assertString = utilities.AssertString

local signalService = require("example.services.SignalService")
local newSignal = signalService.new

--@ // GLOBALS \\ @--

--@ // CONSTANTS \\ @--

--@ // VARIABLES \\ @--
local INPUT_LISTENERS = {}
local ACTIVE_BINDS = {}
local ACTIVE_KEYS = {}

--@ // FUNCTIONS \\ @--

---Validates the parameters provided to InputBindingService:BindAction()
---@param actionName string
---@param inputOptions InputOptions
local function validateParameters(actionName, inputOptions)
	local nameValid, exception = assertType(actionName, "string")
	if not nameValid then error(("Invalid action name. "..exception), 2) end
	
	local optionsValid, exception = assertType(inputOptions, "table")
	if not optionsValid then error(("Invalid input options. "..exception), 2) end

	local keyValid, exception = assertString(inputOptions.Key, true)
	if not keyValid then error(("Invalid input key. "..exception), 2) end

	local holdToggle = inputOptions.MustHoldKey
	if not holdToggle then return end
	
	local toggleValid, exception = assertType(holdToggle, "boolean")
	if not toggleValid then error(("Hold toggle parameter is invalid. "..exception), 2) end
	
	local durationValid, exception = assertType(inputOptions.HoldDuration, "number")
	if not durationValid then error(("Invalid hold duration. "..exception), 2) end
end

--@ // BOUND_INPUT CLASS \\ @--

---Progresses active hold by one tick (0.01s) until the button has been released
---or has been held for at least the required duration.
function INPUT_BINDING:__NextHoldTick() ---@cast self InputBinding_Internal
	local myInternals = self.__internal
	if myInternals.HoldCancelled then return end

	local myKeyHash = myInternals.KeyHash
	if (myInternals.HoldActive and ACTIVE_KEYS[myKeyHash]) then
		local holdStart = myInternals.HoldStart
		local holdStop = os.clock()

		local holdLength = (holdStop - holdStart)
		if (holdLength < myInternals.HoldDuration) then
			timer.delay(0.01, false, function() self:__NextHoldTick() end)
		else self.Activated:Fire(); myInternals.HoldActive = false; end
		
	else
		myInternals.HoldStart = 0;
		myInternals.HoldActive = false;
	end
end

---Begins a ticking timer when an input that must be held is pressed.
function INPUT_BINDING:__StartHold() ---@cast self InputBinding_Internal
	local myInternals = self.__internal
	if (myInternals.HoldActive or myInternals.HoldCancelled) then return end
	if not ACTIVE_KEYS[myInternals.KeyHash] then return end

	myInternals.HoldStart = os.clock()
	myInternals.HoldActive = true
	self:__NextHoldTick()
end

---Cancels any active hold timer and prevents the binding from being trigerred.
function INPUT_BINDING:Unbind() ---@cast self InputBinding_Internal
	local myInternals = self.__internal
	local myKeyHash = myInternals.KeyHash
	local myName = myInternals.ActionName

	myInternals.HoldCancelled = true
	myInternals.HoldActive = false
	ACTIVE_BINDS[myName] = nil;

	local myListenerCategory = INPUT_LISTENERS[myKeyHash]
	if myListenerCategory then myListenerCategory[self] = nil end
end

--@ // BINDING SERVICE API \\ @--
InputBindingService.ActiveBindings = ACTIVE_BINDS

---Binds a key with a given action name. Provides the option for requiring the button be held.
---@param actionName string
---@param inputOptions InputOptions
---@return InputBinding
function InputBindingService:BindAction(actionName, inputOptions)
	validateParameters(actionName, inputOptions)
	InputBindingService:UnbindAction(actionName)

	--// Create Input Bind
	local myKeyHash = hash(inputOptions.Key)
	local myInputBinding = setmetatable({
		Activated = newSignal();
		
		__internal = {
			ActionName = actionName;
			MustHold = inputOptions.MustHoldKey;
			KeyHash = myKeyHash;

			HoldStart = 0;
			HoldActive = false;
			HoldCancelled = false;
			HoldDuration = (inputOptions.HoldDuration or 0);
		};

	}, INPUT_BINDING)

	--// Store References
	if not INPUT_LISTENERS[myKeyHash] then INPUT_LISTENERS[myKeyHash] = {} end
	INPUT_LISTENERS[myKeyHash][myInputBinding] = true; ACTIVE_BINDS[actionName] = myInputBinding
		
	return myInputBinding
end

---Unbinds the action associated with the given name. Equivalent to InputBinding:Unbind().
---@param actionName string
function InputBindingService:UnbindAction(actionName)
	local activeBind = ACTIVE_BINDS[actionName]
	if activeBind then activeBind:Unbind() end
end

---Returns whether or not the provided key hash is associated with an active InputBinding.
---@param keyHash hash
---@return boolean
function InputBindingService:IsKeyBound(keyHash)
	local myListenerCategory = INPUT_LISTENERS[keyHash]
	if not myListenerCategory then return false end
	return (next(myListenerCategory) ~= nil)
end


---Call this function from an instantiating script. This is required to listen for key inputs.
---@param myKeyHash hash
---@param myActionInfo on_input.action
function InputBindingService.on_input(myKeyHash, myActionInfo)
	if not myKeyHash then return end
	
	ACTIVE_KEYS[myKeyHash] = (myActionInfo.pressed or (not myActionInfo.released))
	if not myActionInfo.pressed then return end

	local myInputListeners = INPUT_LISTENERS[myKeyHash]
	if not myInputListeners then return end

	for myInputBinding, _ in pairs(myInputListeners) do
		local myBindingInternals = myInputBinding.__internal
		local mustHoldToTrigger = myBindingInternals.MustHold
		if not mustHoldToTrigger then myInputBinding.Activated:Fire()
		else myInputBinding:__StartHold() end
	end
end

--@ // MAIN \\ @--
return InputBindingService