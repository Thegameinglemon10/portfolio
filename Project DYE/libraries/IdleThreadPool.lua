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

	File Name: IdleThreadPool.lua
	Written By: JestaLemon
	Creation Date: 11/10/2024
	Version: 2.0.1

	-- Last Edit --
	Editor: JestaLemon
	Date: 01/17/2026

	-- Description --
	IdleThreadPool creates a single reusable thread with coroutines. 
	This thread can be used to handle sequential event functions efficiently.
	By only creating threads when the main thread is unavailable, this lightweight
	library's aproach minimizes resource consumption. 

	-- Changelog --
	[01/17/2026] v2.0.0: Rewritten for Defold
	[04/04/2026] v2.0.1: Added EmmyLua type annotations.

-- END HEADER --
]]--

--@ // DEPENDENCIES \\ @--

--@ // GLOBALS \\ @--
local THREAD_STATUS = coroutine.status
local THREAD_RESUME = coroutine.resume
local THREAD_YIELD = coroutine.yield
local THREAD_NEW = coroutine.create

--@ // CONSTANTS \\ @--

--@ // VARIABLES \\ @--

--@ // FUNCTIONS \\ @--

--@ // THREAD_POOL CLASS \\ @--

---@class ThreadPool Provides a pool of idle threads. Attempts to keep at least one thread idle at all times to reduce downtime and memory usage.
---@field IdleThread thread?
local THREAD_POOL = {}
THREAD_POOL.__index = THREAD_POOL

---Lock the currently idle thread and run the provided event handler on it.
---Once finished, the thread will be released and is ready to be used again.
---If a thread is actively being used, it will be disgarded and garbage collected.
---@generic T...
---@param eventHandler fun(...: T...)
---@param ... T...
function THREAD_POOL:__RunHandlerOnIdleThread(eventHandler, ...)
	local myThread = self.IdleThread; self.IdleThread = nil;
	eventHandler(...); self.IdleThread = myThread;
end

---Continually wait for functions to execute.
---Each function will be handled internally.
---This coroutine allows the thread to be kept alie for reusable thread processing.
---@generic T...
---@param ... T...
function THREAD_POOL:__IdleCoroutineHandler(...)
	self:__RunHandlerOnIdleThread(...)
	while true do self:__RunHandlerOnIdleThread(THREAD_YIELD) end
end

---Runs the provided event handler on the currently available thread.
---If no idle thread is available, a new one is created.
---If control over the coroutine is lost, it is safely replaced with a new thread.
---@generic T...
---@param ... T...
function THREAD_POOL:RunHandler(...)
	if ((not self.IdleThread) or (THREAD_STATUS(self.IdleThread) == "dead")) then
		self.IdleThread = THREAD_NEW(self.__IdleCoroutineHandler)
	end

	local success, response = THREAD_RESUME(self.IdleThread, self, ...)
	if not success then print("THREAD_EXECUTION_ERROR:", response, debug.traceback(self.IdleThread)) end
end

--// Main
return {
	---@return ThreadPool
	new = function()
		local myPool = setmetatable({}, THREAD_POOL)
		myPool.IdleThread = THREAD_NEW(myPool.__IdleCoroutineHandler)
		
		return myPool
	end
}