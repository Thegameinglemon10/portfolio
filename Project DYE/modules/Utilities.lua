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

File Name: Utilities.lua
Written By: JestaLemon
Creation Date: 11/10/2024
Version: 3.0.1

-- Last Edit --
Editor: JestaLemon
Date: 04/04/2026

-- Description --
An implementation of the "Linked List" data structure.

-- Changelog --
[10/08/2025] v2.0.0: Rewritten.
[01/17/2026] v3.0.0: Rewritten for Defold
[04/04/2026] v3.0.1: Added EmmyLua type annotations.

-- END HEADER --
]]--

--@ // GLOBALS \\ --
local INSERT = table.insert
local THREAD_RESUME = coroutine.resume

--@ // CONSTANTS \\ @--
local TYPE_EXCEPTION = 'Expected %s. Got %s instead.'

--@ // FUNCTIONS \\ @--

---Checks if the provided value is the expectedType.
---@param value any The value to check.
---@param expectedType string The type the value should be. For example: "table".
---@return boolean isValid Returns true if type(value) == expectedType.
---@return string? exception Returns an error message including the expected type and the actual type if they're not equal. If they are equal, this will be nil.
function AssertType(value, expectedType)
	local valueType = type(value); local isValidType = (valueType == expectedType);
	return isValidType, ((not isValidType) and string.format(TYPE_EXCEPTION, expectedType, valueType) or nil)
end;

--@ // MAIN \\ @--
return {
	AssertType = AssertType;

	---Returns a number between min and max, inclusive.
	---Short for math.max( math.min(x, maximum), minimum )
	---@param x number The number to clamp.
	---@param min number The lower bound. If x is less than min, then it'll return min. Ex: x = -1; min = 0; output = 0. 
	---@param max number The upper bound. If x is greater than max, then it'll return max. Ex: x = 11; max = 10; output = 10.
	---@return number
	Clamp = function(x, min, max) return math.max(math.min(x, max), min) end;

	---Similar to AssertType, but explicitly for strings hash representations of strings.
	---@param value any
	---@param allowHashes boolean? Determines if hashes are allowed. If true, then isValid if the value is a string OR hash. Otherwise (default), isValid will only be true if the value is a string.
	---@return boolean isValid
	---@return string? exception Returns an error message including the expected type and the actual type if they're not equal. If they are equal, this will be nil.
	AssertString = function(value, allowHashes)
		if (allowHashes and types.is_hash(value)) then return true, nil end
		local valueType = type(value); local isValidString = (valueType == "string");
		return isValidString, ((not isValidString) and string.format(TYPE_EXCEPTION, (allowHashes and "string or hash" or "string"), valueType) or nil)
	end;

	---Splits the provided string at every instance of the delimiter.
	---@param text string The string to split.
	---@param delimiter string Determines where the spling will be split. Ex: text = "hello.world"; delimiter = "."; output = {"hello", "world"}
	---@return {number: string}
	SplitString = function(text, delimiter)
		local segments, textIndex = {}, 1
		local delimStart, delimEnd = text:find(delimiter, textIndex, true)

		while delimStart do
			INSERT(segments, text:sub(textIndex, (delimStart-1)))
			textIndex = (delimEnd + 1)

			delimStart, delimEnd = text:find(delimiter, textIndex, true)
		end
		
		INSERT(segments, text:sub(textIndex)); return segments
	end;

	---Pauses the running thread for the specified amount of seconds. 
	---<br><br><b>!! WILL NOT WORK ON THE MAIN THREAD !!</b><br>
	---The main thread can not be yielded, thus this function won't work unless you run it in a coroutine.
	---@param seconds number The time to wait before resuming.
	Wait = function(seconds)
		local myThread = coroutine.running()

		timer.delay(seconds, false, function()
			if (coroutine.status(myThread) == "suspended") then
				coroutine.resume(myThread)
			end
		end)

		coroutine.yield(myThread)
	end;

	---Trims values from an array (source) at the specified indices in targetIndices.
	---This function handles the re-indexing issue that occurs when using `table.remove`
	---repeatedly within a loop by adjusting the target index based on the number of
	---prior removals. Alternatively, it can set values to `nil` instead of removing them.
	---<br><br><b>!! WARNING !!</b><br>
	---Modifying the source table (e.g., adding/removing values) while this function is running will likely cause unexpected behavior. Use with caution.
	---@param source table The source array to modify.
	---@param targetIndices table A table containing the 1-based indices to remove or nil out.
	---@param markAsNil boolean? If true, values at target indices are set to nil. Otherwise (default), they are removed using `table.remove`.
	---@return table result The modified source table.
	TrimTable = function(source, targetIndices, markAsNil)
		local amountRemoved = 0
		for _, myTargetIndex in pairs(targetIndices) do
			if (markAsNil ~= true) then
				table.remove(source, (myTargetIndex - amountRemoved))
				amountRemoved = (amountRemoved + 1)
				
			else source[myTargetIndex] = nil; end
		end
		
		return source
	end;
}