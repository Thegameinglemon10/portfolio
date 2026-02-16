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

𝗗𝗲𝘃𝗲𝗹𝗼𝗽𝗺𝗲𝗻𝘁 𝗧𝗲𝗮𝗺
Founder < Thegameinglemon10 [Thegaminglemon10#0076]

-- 𝗙𝗜𝗟𝗘 𝗜𝗡𝗙𝗢𝗥𝗠𝗔𝗧𝗜𝗢𝗡 --

	File Name: InteractionController.lua
	Written By: Thegameinglemon10
	Creation Date: 08/02/2021
	Version: 8.0.0
	
	-- Last Edit --
	Editor: Thegameinglemon10
	Date: 011/05/2024
	
	-- Description --
	Connects to all interactions, displays the screen when the player 
	is nearby and meets requirements. Fires an event when the player
	hits the correct button.
	
	--[=[ IH V.2 ]=]--
	v2.0.0: Now supporting multiple interactions!!
	v2.1.0: Sporting the new fancy, totally original, progress bar.
	v2.1.1: Increased cooldown on remote events.
	v2.2.0: Added IRCs to the base interaction. In short; I hate my self
	
	--[=[ IH V.3-4-5 || God help me ]=]--
	v3.0.0: (04/28/22) Complete rewrite. Lots of efficiency & bug fixing, hold interactions now retain progress.
	v4.0.0: (06/04/22 - 06/06/22) Put aside my prejudices and finally used proximity prompts. 2nd rewrite.
	v5.0.0: (06/11/22 - 06/13/22) Fuck proximity prompts, I'm using OOP. 3rd rewrite.

	--[=[ VFS V.2 || IH V.6 ]=]--
	[02/06-08/2023] v6.0.0 (VFS V.2): 4th rewrite. Everything is working except holding. Will add holding later.
	v6.1.0: Added the capability to have interactions tied to the player's humanoid root part.
	v6.1.1: Removed the ability for cuffed players to use interactions.
	
	v6.2.0: When instantly swapping from one interaction to the next, old input text and binds would not be cleared. Now a check is ran
	in the default loop. If the closest int is not the current registered int, we force unbind keys. Also fixed an error preventing 
	addition inputs from being removed.
	
	[08/20/2023] v6.2.1: Named rigs no longer interfere with interactions.
	[08/28/2023] v6.2.2: Player interactions are now assigned additional distance
	to give them a lower priority in order to make interacting while grabbing a 
	suspect easier. Grabbed suspects also no longer block interaction visibility checks.
	
	[09/07/2023] v6.3.0: Multiple close interactions are now fully supported. If the
	closest interaction can't be used, it will now check the 2nd, 3rd, ect closest.
	[02/08/2024] v6.3.1: Updated to handle new SoundManager.
	
	--[=[ IH V.7 ]=]--
	[05/12/2024] v7.0.0: 5th rewrite. Added support for mouse interactions. Switched to a
	class based system. The interaction billboard can now be hidden. Integrated vehicles.

	[05/13/2024] v7.0.1: Fixed interaction billboards not being properly hidden.
	[05/29/2024] v7.0.2: Updated to handle new custom binding service.
	[06/03/2024] v7.0.3: Interaction controls are now passed out for external use.
	[06/22/2024] v7.1.0: Integrated live button changes.
	
	--[=[ VSF v3 || IH v8 ]=]--
	[11/05/2024] v8.0.0: WELCOME TO THE 3RD COMPLETE REWRITE OF VSF WOOOOOOOO!!! 😭 (UNFINISHED)
	[11/07/2024] v8.0.0: Continued...
	[11/10/2024] v8.0.0: Continued...
	[04/05/2025] v8.0.1: Upgraded to the new RayKit library.
	
-- 𝗘𝗡𝗗 𝗢𝗙 𝗛𝗘𝗔𝗗𝗘𝗥 --
]]--!strict

--// Services
local players = game:GetService("Players")
local repStorage = game:GetService("ReplicatedStorage")

--// Enums

--// Globals

--// Constants
local myPlayer = players.LocalPlayer :: Player
local controllers = script.Parent

local interactionBoard = script.InteractionBoard
local inputEntryHolder = interactionBoard.Holder
local boardTemplates = interactionBoard.TEMPLATES
local inputTemplate = boardTemplates.INPUT

local polStorage = repStorage.PolarityStorage
local libraries = polStorage.Libraries
local services = polStorage.Services

--// Custom Modules
local modStorage = polStorage.Modules
local octreeCacher = require(modStorage.OctreeCacher)
local componentHelper = require(script.IntHelper)

local utilities = require(modStorage.Utilities)
local getDistance = utilities.GetDistance
local checkBaseRequirements = utilities.CheckBaseInteractionRequirements

--// Custom Services
local trove = require(services.Trove)

--[[
local raycaster = require(services.Raycast)
local canSeeObject = raycaster.CanSeeObject
local RAYCAST = raycaster.Cast
]]--

local bindingService = require(services.ContextBindingService)
local bindAction = bindingService.BindAction

--// Custom Libraries
local globalTypes = require(libraries.GlobalTypes)
local octree = require(libraries.Octree)

local rayKit = require(libraries.RayKit)
local rayCast = rayKit.RayCast
local canSeeObject = rayKit.CanSeeObject
local rayCastParameters = rayKit.RayCastParameters

--// External Types
type Trove = trove.Trove;
type Octree<T> = octree.Octree<T>;
type Character = globalTypes.Character;
type BoundInput = bindingService.BoundInput;
type OctreesCache = octreeCacher.OctreesCache;
type OctreeNode<T> = octree.Node<T>;
type InteractionNode = OctreeNode<BasePart>;
type BasicClientInfo = globalTypes.BasicClientInfo;
type ScriptConnection = bindingService.ScriptConnection;

type InteractionInput = componentHelper.InteractionInput;
type InteractionContext = componentHelper.InteractionContext;
type InteractionComponent = componentHelper.InteractionComponent;

--// Utility Types

--// Internal Types
type ConnectionLike = {
	[any]: any;
	
	Disconnect: (
		self: ConnectionLike,
		...any
	) -> (...any);
}

type CurrentInteraction = (Trove & {
	Source: BasePart?;
	Context: InteractionContext?;
	Component: InteractionComponent;
	
	InputBinds: {
		[Enum.KeyCode]: {
			Binding: BoundInput;
			Connection: ScriptConnection?;
		}?;
	};
})

type InteractionService = {
	InteractionTree: Octree<BasePart>;
	Compononents: {InteractionComponent};
	
	Character: Character;
	Humanoid: Humanoid;
	RootPart: BasePart;
	
	Current: CurrentInteraction;
	Debounce: boolean;
	
	--[[
	Current: {
		Source: BasePart;
		Connections: {ConnectionLike};
	};
	]]--
	
	ConnectInput: (
		self: InteractionService, 
		actionName: string, 
		inputIndex: number,
		inputKey: Enum.KeyCode
	) -> (BoundInput, ScriptConnection);
	
	ModifyUI: (
		self: InteractionService,
		context: (InteractionContext | false),
		component: InteractionComponent?
	) -> ();
	
	GetClosestValidInteraction: (
		self: InteractionService
	) -> (InteractionContext?, InteractionComponent?); -- InteractionNode?, 
	
	GetContext: (
		self: InteractionService, 
		mySource: Instance
	) -> (InteractionContext?, InteractionComponent?);
	
	Validate: (
		self: InteractionService, 
		myNode: InteractionNode
	) -> (boolean, InteractionContext?, InteractionComponent?);
};

--// Variables
local controllerTrove = trove.new()
local currentTrove = controllerTrove:Extend()
local MAX_DISTANCE = 20

local titleTemplate = "<b>%s</b>"
local INTERACTION_TAG = "Interaction"
local descriptionTemplate = "<br>%s</br>"

--// Functions

--// Main

--// Service API
local controller = {}
controller.__index = controller

function controller.GetContext(self: InteractionService, mySource: Instance)
	local category = mySource:GetAttribute("Category")
	local sourceID = mySource:GetAttribute("ID")
	if not category then return end
	
	local components = self.Compononents
	local myComponent = components[category]
	if not myComponent then return end
	
	return myComponent.new(mySource, sourceID), myComponent
end

function controller.Validate(self: InteractionService, myNode: InteractionNode): (boolean, InteractionContext?, InteractionComponent?)
	local myRootPart = self.RootPart
	if not myRootPart then return false, nil, nil end
	
	local myIntSource = myNode.Object
	if not checkBaseRequirements(myPlayer, myIntSource) then return false, nil, nil end
	
	local context, component = self:GetContext(myIntSource)
	if not (context and component) then return false, nil, nil end
	
	local maxIntDistance = context.Distance
	local intDistance = getDistance(myRootPart, myIntSource)
	if (intDistance > maxIntDistance) then return false, nil, nil end
	
	local myParameters = rayCastParameters.new()
	local instanceFilter = myParameters.InstanceFilter
	myParameters.MaxRange = MAX_DISTANCE
	
	for _, player in players:GetPlayers() do
		local character = player.Character
		if not character then continue end
		
		for _, object in character:GetDescendants() do
			if (object == myIntSource) then
				instanceFilter:Add(object)
			end
		end
	end
	
	local canSee = canSeeObject(myRootPart, myIntSource, myParameters)
	if not canSee then return false, nil, nil  end
	
	return component:Verify(context), context, component
end

function controller.GetClosestValidInteraction(self: InteractionService)
	local interactionTree = self.InteractionTree
	local myRootPart = self.RootPart
	
	local rootPivot = myRootPart:GetPivot()
	local closestNodes = interactionTree:GetNearest(rootPivot.Position, MAX_DISTANCE)
	
	local validContext
	local validComponent
	for _, closestNode in ipairs(closestNodes) do
		local isValid, context, component = self:Validate(closestNode)
		if not isValid then continue end
		
		validComponent = component;
		validContext = context; break;
	end
	
	return validContext, validComponent
end

function controller.ConnectInput(self: InteractionService, actionName, inputIndex, inputKey, connections)
	local inputBind = bindingService.BindAction(actionName, {Key = inputKey, MustHoldKey = false})
	
	return inputBind, inputBind.Activated:Connect(function()
		if self.Debounce then return end
		
		local currentInteraction = self.Current
		local currentComponent = currentInteraction.Component
		local currentContext = currentInteraction.Context
		
		if not (currentComponent and currentContext) then 
			inputBind:Unbind(); return;
		end; self.Debounce = true;
		
		currentComponent:Activate(currentContext, inputIndex, inputKey)
		self.Debounce = false;
	end)
end

function controller.ModifyUI(self: InteractionService, interactionContext: (InteractionContext | false), interactionComponent: InteractionComponent)
	local currentInteraction = self.Current
	local currentSource = currentInteraction.Source
	local inputBinds = currentInteraction.InputBinds
	local shouldShow = false
	
	local myContext = (interactionContext or {}) :: InteractionContext
	local mySource = myContext.Source
	
	if mySource then shouldShow = (not mySource:GetAttribute("HideUI")) end
	interactionBoard.Enabled = shouldShow;
	interactionBoard.Adornee = mySource;
	
	if shouldShow then
		if (mySource == currentSource) then return end
		if not mySource then return end
		
		local inputs = myContext.Inputs
		if not inputs then return end
		
		currentInteraction.Source = mySource :: any;
		currentInteraction.Context = myContext;
		currentInteraction.Component = interactionComponent
		
		local inputAmount = #inputs
		local existingFrames = {}
		
		for _, object: typeof(inputTemplate) in inputEntryHolder:GetChildren() do
			if object:IsA("UIListLayout") then continue end
			local inputIndex = object.LayoutOrder
			
			if (inputIndex > inputAmount) then
				object:Destroy(); continue;
			end
			
			existingFrames[inputIndex] = object;
		end
		
		for inputIndex, myInput in inputs do
			local existingFrame = existingFrames[inputIndex]
			
			local title = myInput.Title
			local inputKey = myInput.Key
			local description = myInput.Description
			if not (inputKey and title) then existingFrame:Destroy(); continue; end
			
			local myFrame = (existingFrame or inputTemplate:Clone())
			local keyHolder = myFrame.KeyHolder
			
			local longPressHolder = keyHolder.Hold
			local titleLabel = myFrame.Label
			local keyLabel = keyHolder.Label
			
			local formattedTitle = titleTemplate:format(title)
			local formattedDescription = (description and descriptionTemplate:format(description) or "")
			
			myFrame.Name = inputIndex
			myFrame.Parent = inputEntryHolder
			myFrame.LayoutOrder = inputIndex
			
			keyLabel.Text = inputKey.Name
			titleLabel.Text = (formattedTitle .. formattedDescription)
			if not existingFrame then controllerTrove:Add(myFrame) end
			
			local existingBind = inputBinds[inputKey]
			if not existingBind then
				local inputBind = bindingService.BindAction(title, {Key = inputKey, MustHoldKey = false})
				
			end
			
			--[[
			local connections = {}
			local inputBind = self:ConnectInput(title, inputIndex, inputKey, connections)
			
			inputBinds[inputBind] = connections
			]]--
		end
		
	else 
		currentInteraction:Clean();
		currentInteraction.Source = nil;
		currentInteraction.Context = nil;
		
		for _, bindInfo in inputBinds do
			(bindInfo :: any).Binding:Unbind()
		end; currentInteraction.InputBinds = {};
	end
end


--[~~[ Constructor ]~~]--
function controller.Initialize(self: InteractionService, basicInfo: BasicClientInfo)
	local myHostHumanoid = basicInfo.Humanoid
	local octreesCache = basicInfo.OctreesCache
	
	local interactionTreeInfo = octreesCache.Interaction
	local interactionTree = interactionTreeInfo.Octree :: Octree<BasePart>
	
	local rootPart = myHostHumanoid.RootPart
	if not rootPart then return end
	
	local currentInteraction = (currentTrove :: CurrentInteraction)
	currentInteraction.InputBinds = {}
	
	controllerTrove:Add(function()
		for _, bindInfo in currentInteraction.InputBinds do
			(bindInfo :: any).Binding:Unbind()
		end
	end)
	
	--// Initialize Interaction Handlers
	local handlers = {} :: {[string]: InteractionComponent}
	for _, myHandlerModule in script:GetChildren() do
		if not myHandlerModule:IsA("ModuleScript") then continue end
		if not myHandlerModule:GetAttribute("Enabled") then continue end
		
		local myHandler = require(myHandlerModule) :: any
		local hasInitializer = (myHandler.Initialize ~= nil)
		if (hasInitializer and (myHandler:Initialize() == false)) then return end
		handlers[myHandlerModule.Name] = myHandler
	end
	
	--// Validate Interactions
	local function validateInteraction(myNode)
		local mySource = myNode.Object
		local category = mySource:GetAttribute("Category")
		if not handlers[category] then 
			mySource:RemoveTag(INTERACTION_TAG) 
			warn(`[POLARITY INTERACTIONS] No handler found for "{category}"`)
		end
	end
	
	for _, myNode in interactionTree:GetAllNodes() do validateInteraction(myNode) end
	interactionTree.NodeAdded:Connect(validateInteraction)
	
	--// Construct Service
	self = ((setmetatable({
		InteractionTree = interactionTree;
		Compononents = handlers;
		
		Character = basicInfo.Character;
		Humanoid = myHostHumanoid;
		RootPart = rootPart;
		
		Current = currentTrove;
		Debounce = false;
	}, controller) :: any) :: InteractionService)
	
	--// Begin RunTime Loop
	local lastPart: BasePart?
	controllerTrove:BindToRenderStep("InteractionRunTime", 300, function()
		local closestContext, closestComponent = self:GetClosestValidInteraction()
		if not (closestContext and closestComponent) then self:ModifyUI(false) return end
		
		local currentInteraction = self.Current
		local currentSource = currentInteraction.Source
		local mySource = closestContext.Source
		if (currentSource ~= mySource) then currentInteraction:Clean() end
		
		self:ModifyUI(closestContext, closestComponent)
	end)
end
	
function controller:Destroy()
	controllerTrove:Clean()
end

return controller;
