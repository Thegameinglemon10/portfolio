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
Copyright, Polarity 2026



-- FILE INFORMATION --

	File Name: SignalService.lua
	Written By: stravant
	Creation Date: 07/31/2021
	Version: 3.0.1

	-- Last Edit --
	Editor: JestaLemon
	Date: 04/04/2026

	-- Description --
	A rewritten implemenation of Slietnick's signal module.

	-- LICENSE: PROPRIETARY --
	All rights reserved for all proprietary modifications.
	
	-- THIRD PARTY ATTRIBUTION --
	This software is a derivative work based on the signal module by stravant and sleitnick.
	The original source is licensed under the MIT License, provided below for attribution purposes.

	Permission is hereby granted, free of charge, to any person obtaining a copy of 
	this software and associated documentation files (the “Software”), to deal 
	in the Software without restriction, including without limitation the 
	rights to use, copy, modify, merge, publish, distribute, sublicense, 
	and/or sell copies of the Software, and to permit persons to whom 
	the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice 
	shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
	INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
	PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
	DEALINGS IN THE SOFTWARE.

	-- Old Changelog --
	[08/03/2021] (slietnick): Modified for Knit.

	-- Changelog --
	[11/07/2024] (JestaLemon) v1.0.0: Rewritten with strict typing. (Paused)
	[11/10/2024] (JestaLemon) v1.0.0: Finished rewrite.
	[11/11/2024] (JestaLemon) v1.1.0: Added the "Connections" property and "ListenForConnectionsChanged" method.
	[10/08/2025] (JestaLemon) v2.0.0: Rewritten with proxy system.

	[10/20/2025] (JestaLemon) v2.1.0: Added the ":OnDisconnected" and ":WaitForDisconnection" mockSignals.
	With this, ability to pass arguments to the :Connect() and :Disconnect()/:DisconnectAll() 
	functions that'll be passed through to the connected/disconnected listeners respectively.

	[12/13/2025] (JestaLemon) v2.1.1: Updated license, fixed/silenced some type warnings.
	[01/17/2026] (JestaLemon) v3.0.0: Rewritten for Defold.
	[04/04/2026] (JestaLemon) v3.0.1: Added EmmyLua type annotations and cleaned up.
	
-- END HEADER --
]]--!strict

--@ // TYPE DECLARATIONS \\ @--
---@alias ConnectionsList<T...> LinkedList<ScriptConnectionInternal<T..., any>>
---@alias MockSignalConnectionsList<Handler> LinkedList<{Connected: boolean, __internal: {Handler: Handler}}>;

---@class ScriptConnection
---@field Connected boolean States whether the connection is active or not.
local SCRIPT_CONNECTION = {}
SCRIPT_CONNECTION.__index = SCRIPT_CONNECTION

---@class ScriptSignal<T..., C...>
---@field Connections number Holds the current amount of active connections.
local SCRIPT_SIGNAL = {}
SCRIPT_SIGNAL.__index = SCRIPT_SIGNAL

---@class ScriptConnectionInternal<T..., C...>: ScriptConnection
---@field __internal {Handler: fun(T...), Signal: ScriptSignal<T..., C...>}

---@class MockSignalConnections
---@field Changed MockSignalConnectionsList<fun(connections: number)>
---@field Connected MockSignalConnectionsList<fun(newConnection: ScriptConnection)>;
---@field Disconnected MockSignalConnectionsList<fun()>;

---@class SS_INTERNALS<T...>
---@field YieldedThreads {thread: true?} -- A list of threads waiting for the signal to fire;
---@field ConnectionsList ConnectionsList<T...> -- A linked list of connections;
---@field HandlerThreadPool ThreadPool -- A list of pooled threads. Used for firing.
---@field MockSignalConnections MockSignalConnections

---@class ScriptSignalInternal<T..., C...>: ScriptSignal
---@field __internal SS_INTERNALS<T...>

--// Globals
local INSERT = table.insert
local THREAD_YIELD = coroutine.yield
local THREAD_RESUME = coroutine.resume
local THREAD_RUNNING = coroutine.running

--// Dependencies
local idleThreadPool = require("example.libraries.IdleThreadPool")
local NEW_THREAD_POOL = idleThreadPool.new

local linkedList = require("example.libraries.LinkedList")
local NEW_LINKED_LIST = linkedList.new

--// Variables

--// Functions

---Pauses a thread for one resumption cycle.
---@generic T...
---@param callback fun(...: T...)
---@param ... T...
local function THREAD_DEFER(callback, ...)
	local arguments = {...}
	timer.delay(0, false, function()
		callback(unpack(arguments))
	end)
end
 
---Utility function for firing a signal.
---@generic T...
---@generic C...
---@param mySignal ScriptSignalInternal<T..., C...>
---@param mySignalConnections LinkedList<ScriptConnectionInternal>
---@param ... T...
local function FIRE_SIGNAL(mySignal, mySignalConnections, ...)
	local mySignalInternals = mySignal.__internal
	local handlerThreadPool = mySignalInternals.HandlerThreadPool
	for myConnectionNode in mySignalConnections:ForEachNode() do
		local myConnectionObject = myConnectionNode.Value
		if not myConnectionObject.Connected then return end

		handlerThreadPool:RunHandler(myConnectionObject.__internal.Handler, ...)
	end
end

---Creates a listener for mock signals.
---@generic T...
---@generic C...
---@param mySignal ScriptSignalInternal<T..., C...>
---@param mySignalConnections LinkedList<ScriptConnectionInternal>
---@param callback fun(T...)
---@param runOnce boolean?
---@return function
local function ON_MOCK_SIGNAL(mySignal, mySignalConnections, callback, runOnce)
	local mySignalInternals = mySignal.__internal
	local handlerThreadPool = mySignalInternals.HandlerThreadPool
	local myConnection = {Connected = true, MockSignal = true; __internal = {}}

	local function disconnect()
		if not myConnection.Connected then return end
		myConnection.Connected = false; mySignalConnections:Remove(myConnection)
	end

	myConnection.__internal.Handler = function(...)
		handlerThreadPool:RunHandler(callback, ...)
		if runOnce then disconnect() end
	end

	mySignalConnections:Insert(myConnection); return disconnect
end

---Creates a listener for mock signals that yields until the signal is fired.
---@generic T...
---@generic C...
---@param mySignal ScriptSignalInternal<T..., C...>
---@param mySignalConnections LinkedList<ScriptConnectionInternal>
---@return T...
---@return C...?
local function WAIT_FOR_MOCK_SIGNAL(mySignal, mySignalConnections)
	local mySignalInternals = mySignal.__internal
	local myYieldedThreads = mySignalInternals.YieldedThreads
	local myThread = THREAD_RUNNING()
	
	---@cast myThread thread
	myYieldedThreads[myThread] = true
	mySignal:OnConnected(function(...)
		myYieldedThreads[myThread] = nil
		local success, response = THREAD_RESUME(myThread, ...)
		if not success then print("THREAD_EXECUTION_ERROR:", response, debug.traceback(myThread)) end
	end, true)

	return THREAD_YIELD()
end

--@ // SCRIPT_CONNECTION CLASS \\ @--
---Disconects the function, preventing it from being fired again.
---@param ... any
function SCRIPT_CONNECTION:Disconnect(...)
	if not self.Connected then return end

	---@cast self ScriptConnectionInternal
	local myConnectionInternals = self.__internal
	self.Connected = false

	--\\ Unhook the node, but don't clear it.
	---\\ The node will be garbage collected once all fire calls have been processed.
	local mySignal = myConnectionInternals.Signal

	---@cast mySignal ScriptSignalInternal
	local mySignalInternals = mySignal.__internal
	local mySignalConnections = mySignalInternals.ConnectionsList
	local mySignalMockConnections = mySignalInternals.MockSignalConnections
	mySignalConnections:Remove(self)

	--\\ Update Connections & Fire Mock Signals
	local newConnections = (mySignal.Connections - 1); mySignal.Connections = newConnections; 
	FIRE_SIGNAL(mySignal, mySignalMockConnections.Changed, newConnections)
	FIRE_SIGNAL(mySignal, mySignalMockConnections.Disconnected, self, ...)
end

--@ // SCRIPT_SIGNAL CLASS \\ @--

---Immediately fires all connected threads with the provided arguments.
---@generic T...
---@param ... T... 
function SCRIPT_SIGNAL:Fire(...) ---@cast self ScriptSignalInternal
	FIRE_SIGNAL(self, self.__internal.ConnectionsList, ...)
end

---Fires all connected threads with the provided arguments at the end of the current resumption cycle.
---@generic T...
---@param ... T... 
function SCRIPT_SIGNAL:FireDeferred(...) ---@cast self ScriptSignalInternal
	local mySignalInternals = self.__internal
	local mySignalConnections = mySignalInternals.ConnectionsList
	local function fire(myConnection, ...)
		if myConnection.Connected then 
			myConnection.__internal.Handler(...)
		end
	end

	for connectionNode in mySignalConnections:ForEachNode() do
		THREAD_DEFER(fire, connectionNode.Value, ...)
	end
end

--[[ CONNECTING ]]--

---Connects the given function to the event and returns a ScriptConnection that represents it.
---Any additional arguments will be passed along to the "OnConnected" listeners.
---@generic C...
---@param callback fun(...: C...)
---@param ... C...
---@return ScriptConnection
function SCRIPT_SIGNAL:Connect(callback, ...) ---@cast self ScriptSignalInternal
	local mySignalInternals = self.__internal
	local mySignalConnections = mySignalInternals.ConnectionsList
	local myMockSignalConnections = mySignalInternals.MockSignalConnections

	local myConnection = setmetatable({
		__internal = {Handler = callback; Signal = self};
		Connected = true;
		
	}, SCRIPT_CONNECTION)

	self.Connections = (self.Connections + 1);
	mySignalConnections:Insert(myConnection)
	FIRE_SIGNAL(self, myMockSignalConnections.Changed, self.Connections)
	FIRE_SIGNAL(self, myMockSignalConnections.Connected, myConnection, ...)

	return myConnection
end

---Connects the given function to the event and returns a ScriptConnection that is immediately disconnected.
---@generic T...
---@param callback fun(...: T...)
---@return ScriptConnection
function SCRIPT_SIGNAL:Once(callback)
	local isStillConnected = true
	local myConnection
	
	myConnection = self:Connect(function(...)
		if not isStillConnected then return end

		isStillConnected = false
		myConnection:Disconnect()
		callback(...)
	end)

	return myConnection
end

---Yields the current thread until the signal fires and returns the arguments provided by the signal.
---@generic T...
---@return T...
function SCRIPT_SIGNAL:Wait() ---@cast self ScriptSignalInternal
	local mySignalInternals = self.__internal
	local myYieldedThreads = mySignalInternals.YieldedThreads
	local myThread = THREAD_RUNNING()

	---@cast myThread thread
	myYieldedThreads[myThread] = true
	self:Once(function(...)
		if myYieldedThreads[myThread] then
			myYieldedThreads[myThread] = nil
			local success, response = THREAD_RESUME(myThread, ...)
			if not success then print("THREAD_EXECUTION_ERROR:", response, debug.traceback(myThread)) end
		end
	end)
	
	return THREAD_YIELD()
end

--[[ MOCK CONNECTION SIGNAL ]]--

---Fires when the signal is connected to.
---Returns a function to disconnect from the mock signal.
---Always fires after "OnConnectionsChanged"
---@generic C...
---@param callback fun(newConnection: ScriptConnection, ...: C...)
---@param runOnce boolean? If false, the connection will disconnect after the first time it's called.
---@return function Disconnect Disconnects the mock function.
function SCRIPT_SIGNAL:OnConnected(callback, runOnce) ---@cast self ScriptSignalInternal
	return ON_MOCK_SIGNAL(self, self.__internal.MockSignalConnections.Connected, callback, runOnce)
end

---Yields the current thread until the signal is connected to. Returns the connection.
---@generic C...
---@return ScriptConnection
---@return C...
function SCRIPT_SIGNAL:WaitForConnection() ---@cast self ScriptSignalInternal
	return WAIT_FOR_MOCK_SIGNAL(self, self.__internal.MockSignalConnections.Connected)
end

--[[ MOCK CONNECTIONS CHANGED SIGNAL ]]--

---Fires when the amount of connections changes.
---Returns a function to disconnect from the mock signal.
---Always fires before "OnConnected"
---@param callback fun(Connections: number)
---@param runOnce boolean? If false, the connection will disconnect after the first time it's called.
---@return function Disconnect Disconnects the mock function.
function SCRIPT_SIGNAL:OnConnectionsChanged(callback, runOnce) ---@cast self ScriptSignalInternal
	return ON_MOCK_SIGNAL(self, self.__internal.MockSignalConnections.Changed, callback, runOnce)
end

---Yields the current thread until the number of connections changes. Returns the new amount of connections.
---@return number
function SCRIPT_SIGNAL:WaitForConnectionsChanged() ---@cast self ScriptSignalInternal
	return WAIT_FOR_MOCK_SIGNAL(self, self.__internal.MockSignalConnections.Changed)
end

--[[ MOCK DISCONNECT SIGNAL ]]--

---Fires when a connection is disconnected.
---Returns a function to disconnect from the mock signal.
---Always fires after disconnection and "OnConnectionsChanged"
---@generic C...
---@param callback fun(oldConnection: ScriptConnection, C...)
---@param runOnce boolean? If false, the connection will disconnect after the first time it's called.
---@return function Disconnect Disconnects the mock function.
function SCRIPT_SIGNAL:OnDisconnected(callback, runOnce) ---@cast self ScriptSignalInternal
	return ON_MOCK_SIGNAL(self, self.__internal.MockSignalConnections.Disconnected, callback, runOnce)
end

---Yields the current thread until a connection is disconnected. Returns the connection.
---@return ScriptConnection
function SCRIPT_SIGNAL:WaitForDisconnection() ---@cast self ScriptSignalInternal
	return WAIT_FOR_MOCK_SIGNAL(self, self.__internal.MockSignalConnections.Disconnected)
end

--[[ MISC ]]--

---Disconnects all connections.
---@generic C...
---@param ... C...
function SCRIPT_SIGNAL:DisconnectAll(...) ---@cast self ScriptSignalInternal
	local mySignalInternals = self.__internal
	local myYieldedThreads = mySignalInternals.YieldedThreads
	local mySignalConnections = mySignalInternals.ConnectionsList
	local myMockSignalConnections = mySignalInternals.MockSignalConnections

	--// Build List of Connections for the Disconnect Signal
	local myConnectionNodes = {}
	for myConnectionNode in mySignalConnections:ForEachNode() do
		INSERT(myConnectionNodes, myConnectionNode.Value)
	end

	--// Clear Connections
	mySignalConnections:ClearNodes(); self.Connections = 0;
	FIRE_SIGNAL(self, myMockSignalConnections.Changed, 0)

	--// Fire Disconnect Signal
	for _, myConnectionNode in ipairs(myConnectionNodes) do
		FIRE_SIGNAL(self, myMockSignalConnections.Disconnected, myConnectionNode, ...)
	end; myConnectionNodes = {};

	--// Clear Yielded Threads
	for myThread in pairs(myYieldedThreads) do
		myYieldedThreads[myThread] = nil
	end
end

---Sets all properties to nil and disconnects all connections.
function SCRIPT_SIGNAL:Destroy() ---@cast self ScriptSignalInternal
	local mySignalInternals = self.__internal
	self:DisconnectAll() --> Clear Connections
	setmetatable(self, {})
end;

---Returns all connections.
---@return {number: ScriptConnection}
function SCRIPT_SIGNAL:GetConnections() ---@cast self ScriptSignalInternal 
	return self.__internal.ConnectionsList:GetAllNodes()
end;

--// Main
return {
	---Creates a new ScriptSignal
	---@generic T..., C...
	---@return ScriptSignal<T..., C...>
	new = function()
		return setmetatable({
			Connections = 0;
			__internal = {
				YieldedThreads = {};
				ConnectionsList = NEW_LINKED_LIST();
				HandlerThreadPool = NEW_THREAD_POOL();

				MockSignalConnections = {
					Changed = NEW_LINKED_LIST();
					Connected = NEW_LINKED_LIST();
					Disconnected = NEW_LINKED_LIST();
				};
			};
		}, SCRIPT_SIGNAL)
	end;

	---Checks if the provided object is a valid ScriptSignal.
	---@param object any
	---@return boolean
	IsASignal = function(object)
		if (type(object) ~= "table") then return false end

		local objectMeta = getmetatable(object)
		if not objectMeta then return false end

		local objectInternals = objectMeta.__internal
		if not objectInternals then return false end

		return (objectInternals.ConnectionsList ~= nil)
	end,
}