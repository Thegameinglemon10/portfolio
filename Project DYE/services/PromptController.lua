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

File Name: PromptController.lua
Written By: JestaLemon
Creation Date: 08/02/2021
Version: 9.0.1

-- Last Edit --
Editor: JestaLemon
Date: 04/05/2026

-- Description --
Connects to all interactions, displays the screen when the player 
is nearby and meets requirements. Fires an event when the player
hits the correct button.

--[=[ IH V.2 ]=]--
v2.0.0: Now supporting multiple interactions!!
v2.1.0: Sporting the new fancy, totally original, progress bar.
v2.1.1: Increased cooldown on remote events.
v2.2.0: Added IRCs to the base interaction. In short; I hate my self

--[=[ IH V.3-5 || God help me ]=]--
v3.0.0: (04/28/22) Complete rewrite. Lots of efficiency & bug fixing, hold interactions now retain progress.
v4.0.0: (06/04/22 - 06/06/22) Put aside my prejudices and finally used proximity prompts. 2nd rewrite.
v5.0.0: (06/11/22 - 06/13/22) Fuck proximity prompts, I'm using OOP. 3rd rewrite.

--[=[ VFS V.2 || IH V.6 ]=]--
[02/06-08/2023] v6.0.0 (VFS V.2): 4th rewrite. Everything is working except holding. Will add holding later.
v6.1.0: Added the capability to have interactions tied to the player's root.
v6.1.1: Added missing interaction requirement.

v6.2.0: When instantly swapping from one interaction to the next, old input text and binds would not be cleared. Now a check is ran
in the default loop. If the closest int is not the current registered int, we force unbind keys. Also fixed an error preventing 
addition inputs from being removed.

[08/20/2023] v6.2.1: Named rigs no longer interfere with interactions.
[08/28/2023] v6.2.2: Player interactions are now assigned additional distance
to give them a lower priority.

[09/07/2023] v6.3.0: Multiple close interactions are now fully supported. If the
closest interaction can't be used, it will now check the 2nd, 3rd, ect closest.
[02/08/2024] v6.3.1: Updated to handle new SoundManager.

--[=[ IH V.7 ]=]--
[05/12/2024] v7.0.0: 5th rewrite. Added support for mouse interactions. Switched to a
class based system. The interaction board can now be hidden.

[05/13/2024] v7.0.1: Fixed interaction boards not being properly hidden.
[05/29/2024] v7.0.2: Updated to handle new custom binding service.
[06/03/2024] v7.0.3: Interaction controls are now passed out for external use.
[06/22/2024] v7.1.0: Integrated live button changes.

--[=[ VSF v3 || IH v8 ]=]--
[11/05/2024] v8.0.0: WELCOME TO THE 3RD COMPLETE REWRITE OF VSF WOOOOOOOO!!! (UNFINISHED)
[11/07/2024] v8.0.0: Continued...
[11/10/2024] v8.0.0: Continued...
[04/05/2025] v8.0.1: Upgraded to the new RayKit library.

--[=[ DEFOLD - v9 ]=]--
[01/17/2026] v9.0.0: Rewritten for Defold. Welcome to Project D.Y.E!
[04/05/2026] v9.0.1: Added emmyLua type annotations.

-- END HEADER --
]]--!strict


--@ // TYPE DECLARATIONS \\ @--
---@class (exact) PromptController
---@field CharacterURL string
---@field Prompts {number: PromptContext}
---@field __index PromptController
local PROMPT_CONTROLLER = {}
PROMPT_CONTROLLER.__index = PROMPT_CONTROLLER

--@ // DEPENDENCIES \\ @--
local PromptsRegistry = require("example.modules.Prompts")

--@ // GLOBALS \\ @--

--@ // CONSTANTS \\ @--

--@ // VARIABLES \\ @--

--@ // FUNCTIONS \\ @--

--@ // PROMPT_CONTROLLER API \\ @--

---Returns the distance from the character to the provided node.
---@param myNodeURL string
---@return number
function PROMPT_CONTROLLER:GetDistance(myNodeURL)
	local myCharacterURL = self.CharacterURL

	--> Fetch world positions
	local myCharacterPosition = go.get_world_position(myCharacterURL)
	local myNodePosition = go.get_world_position(myNodeURL)

	--> Return Distance
	return vmath.length((myCharacterPosition - myNodePosition))
end

---Verifies if the player should be able to interact with the prompt.
---@param myNodeURL string
---@param myNodeContext PromptContext
---@return boolean
function PROMPT_CONTROLLER:Validate(myNodeURL, myNodeContext)
	-- TODO: ADD RAYCAST VISIBILITY CHECKS LATER

	return (myNodeContext.Verify and myNodeContext.Verify(myNodeURL) or true)
end

---Finds the closest prompt to the player that they're able to interact with.
---@return string?, PromptContext?
function PROMPT_CONTROLLER:GetClosestValidPrompt()
	--// List Nodes and Distances
	local nodeDistanceMap = {}
	local function mapNode(myNodeURL, myNodeContext)
		local nodeExists = go.exists(myNodeURL)
		if not nodeExists then return end
		
		local distanceFromCharacter = self:GetDistance(myNodeURL)
		if (distanceFromCharacter > myNodeContext.MaxDistance) then return end

		table.insert(nodeDistanceMap, {
			URL = myNodeURL;
			Context = myNodeContext;
			Distance = distanceFromCharacter;
		})
	end
	
	for _, myNodeContext in ipairs(self.Prompts) do
		for _, myNodeURL in ipairs(myNodeContext.NodeURLs) do
			mapNode(myNodeURL, myNodeContext)
		end
	end

	--// Sort Nodes By Distance
	table.sort(nodeDistanceMap, function(itemA, itemB)
		local distanceA, distanceB = itemA.Distance, itemB.Distance
		if (distanceA == distanceB) then return (itemA.URL < itemB.URL) end --> Prevent flicking in the edge case that the distances are equal.

		return distanceA < distanceB
	end)

	--// Find Valid Node, Starting With Closest
	for _, myNodeTable in ipairs(nodeDistanceMap) do
		local myNodeURL, myNodeContext = myNodeTable.URL, myNodeTable.Context
		if self:Validate(myNodeURL, myNodeContext) then return myNodeURL, myNodeContext end
	end

	return nil, nil --> No valid node found
end

--@ // MAIN \\ @--
return {
	new = function(characterURL, promptBoardURL)
		if not go.exists(characterURL) then error("Invalid CharacterURL") end
		if not go.exists(promptBoardURL) then error("Invalid PromptBoardURL") end

		local myController = setmetatable({
			CharacterURL = characterURL;
			PromptBoardURL = promptBoardURL;
		}, PROMPT_CONTROLLER)
		
		myController.Prompts = PromptsRegistry(myController)
		return myController
	end
}