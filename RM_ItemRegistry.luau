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

𝗗𝗲𝘃𝗲𝗹𝗼𝗽𝗺𝗲𝗻𝘁 𝗧𝗲𝗮𝗺
Founder > Thegameinglemon10 [Thegaminglemon10#0076]

-- 𝗙𝗜𝗟𝗘 𝗜𝗡𝗙𝗢𝗥𝗠𝗔𝗧𝗜𝗢𝗡 --

	File Name: RM_ItemRegistry.luau
	Written By: Thegameinglemon10
	Creation Date: 02/15/2026
	Version: 1.0.0
	
	-- Last Edit --
	Editor: Thegameinglemon10
	Date: 02/15/2026
	
	-- Description --
	Handles roles/group creation, deletion, and reordering.
	
	-- Changelog --
	
-- 𝗘𝗡𝗗 𝗢𝗙 𝗛𝗘𝗔𝗗𝗘𝗥 --
]]--!strict


--@ // SERVICES \\ @--
local httpService = game:GetService("HttpService")
local tweenService = game:GetService("TweenService")

--@ // ENUMS \\ @--

--@ // GLOBALS \\ @--
local DELAY_TASK = task.delay
local THREAD_NEW = task.spawn
local THREAD_CANCEL = task.cancel
local THREAD_STATUS = coroutine.status

local V2 = Vector2.new
local V2_ZERO = Vector2.zero

local UDIM2 = UDim2.new
local UDIM2_OFFSET = UDim2.fromOffset

local CLEAR = table.clear
local REMOVE = table.remove
local INSERT = table.insert

local ABS = math.abs
local MAX = math.max
local HUGE = math.huge
local CLAMP = math.clamp
local ROUND = math.round

-- TEMP --> Replace in final Prod
local polStorage = game.ReplicatedStorage.PolarityStorage
local modStorage = polStorage.Modules
local libraries = polStorage.Libraries

local proxyLibrary = require(libraries.Proxy)
local newProxy = proxyLibrary.new


--@ // CONSTANTS \\ @--
local RMC_Root = script.Parent
local RT_PanelUI = RMC_Root.Parent.Parent
local hoverHolder = RT_PanelUI.Hover

local hoverItem = hoverHolder.RM_HOVER_ITEM
local hoverLabel = hoverItem.Label

local mainFrame = RT_PanelUI.Main
local document = mainFrame.Document
local body = document.Body

local pages = body.Pages
local managerPage = pages.RolesManager.Content

local rolesPanel = managerPage.Roles
local groupDivider = rolesPanel.GroupDivider
local actionButtons = rolesPanel.Actions

local viewingActions = actionButtons.Viewing
local newGroupButton = viewingActions.New
local editButton = viewingActions.Edit

local editingActions = actionButtons.Editing
local saveEditsButton = editingActions.Save
local deleteItemButton = actionButtons.DeleteItem
local discardEditsButton = editingActions.Discard

local TEMPLATES = RT_PanelUI.TEMPLATES
local GROUP_TEMPLATE = TEMPLATES.RM_ROLE_GROUP
local ROLE_TEMPLATE = TEMPLATES.RM_ROLE

--@ // CUSTOM MODULES \\ @--
local RM_Helper = require(RMC_Root.RM_Helper)
local isPointInBounds = RM_Helper.IsPointInBounds
local getMousePosition = RM_Helper.GetMousePosition

--@ // CUSTOM SERVICES \\ @--

--@ // CUSTOM LIBRARIES \\ @--

--@ // EXTERNAL TYPES \\ @--

--@ // UTILITY TYPES \\ @--

--@ // INTERNAL TYPES \\ @--
type RoleGroupFrame = typeof(GROUP_TEMPLATE)
type RoleFrame = typeof(ROLE_TEMPLATE)

type BasicItemInfo = RM_Helper.BasicItemInfo
type DraggableItem = RM_Helper.DraggableItem

type RolesMap = RM_Helper.RolesMap
type RoleUI = RM_Helper.RoleUI
type Role = RM_Helper.Role

type RoleGroupsMap = RM_Helper.GroupsMap
type RoleGroupUI = RM_Helper.RoleGroupUI
type RoleGroup = RM_Helper.RoleGroup

export type RM_ItemRegistry = {
	ConfirmGroupDeletionThreads: {[string]: thread}; --[GROUP_ID]
	TargetScrollPosition: number;
	DeleteItemSelected: boolean;

	LastDivider: Frame?;
	ActiveDrag: (Role | RoleGroup)?;
	DragOffset: Vector2;
	IsEditing: boolean;

	GroupIDs: {string}; -- [INDEX]: [GROUP_ID]
	Groups: RoleGroupsMap; 
	Roles: RolesMap; 

	--[[ UTILITY ]]--
	GetClosestItem: (
		(self: RM_ItemRegistry, myItems: RolesMap, myOriginItem: DraggableItem) -> (Role?, number) & 
		(self: RM_ItemRegistry, myItems: RoleGroupsMap, myOriginItem: DraggableItem) -> (RoleGroup?, number)
	);

	--[[ EDITING & SETUP ]]--
	NewRole: (self: RM_ItemRegistry, itemInfo: BasicItemInfo, parentGroup: RoleGroup) -> (Role);
	NewRoleGroup: (self: RM_ItemRegistry, itemInfo: BasicItemInfo) -> (RoleGroup);
	ToggleEditing: (self: RM_ItemRegistry, isEditing: boolean) -> ();
	DeleteRoleGroup: (self: RM_ItemRegistry, myGroup: RoleGroup) -> (boolean);

	--[[ DRAGGING ]]--
	ItemDragged: (self: RM_ItemRegistry, item: DraggableItem) -> ();
	StopDraggingItem: (self: RM_ItemRegistry, item: DraggableItem) -> ();
	BeginDraggingItem: (self: RM_ItemRegistry, item: DraggableItem) -> ();

	--[[ MISC ]]--
	Initialize: (self: RM_ItemRegistry) -> ();
}

--@ // VARIABLES \\ @--
local NEW_ROLE_NAME = "New Role" -- The placeholder name for new roles.
local NEW_GROUP_NAME = "New Role Group" -- The placeholder name for new roles.

local ROLE_DRAG_TAG = "RTP_RoleButtonHighlight" -- Keeps the button highlighted while being dragged.
local ROLE_GROUP_DRAG_TAG = "RTP_RoleGroupDragging" -- Highlights the role group while being dragged.
local ROLE_DELETE_HOVER_TAG = "RTP_ButtonWarningHover" -- Highlights the delete role button when hovered over. Has to be implemented manually due to UIDragDetectors sinking input.

local GROUP_DELETE_CANCEL_TIMER = 5 -- How many seconds after clicking the delete button once before deletion is cancelled.

local SMOOTH_SCROLL_SPEED = 0.2 -- Smooths the scrolling so that it's not jumpy
local PIXELS_PER_SCROLL_STEP = 100 -- How many pixels the scrolling frame should scroll per "step" of the scroll wheel.
local SMOOTH_SCROLL_TWEEN_INFO = TweenInfo.new(
	SMOOTH_SCROLL_SPEED,
	Enum.EasingStyle.Circular, -- Makes the scroll bar suddenly accelerate, then gradually slow down.
	Enum.EasingDirection.Out
)

local ROLE_DATA = {
	[1] = {
		Name = "Executives";
		ID = "123";

		Roles = {
			[1] = {Name = "Owner"; ID = "123A"};
			[2] = {Name = "CoOwner"; ID = "123B"};
		};
	};

	[2] = {
		Name = "Administration";
		ID = "456";

		Roles = {
			[1] = {Name = "Admin"; ID = "456A"};
			[2] = {Name = "Sr. Moderator"; ID = "456B"};
			[3] = {Name = "Jr. Moderator"; ID = "456C"};
			[4] = {Name = "Trial Moderator"; ID = "456D"};
		};
	};

	[3] = {
		Name = "Empty";
		ID = "789";

		Roles = {};
	};
} :: RM_Helper.Data_Roles

--@ // FUNCTIONS \\ @--


--- This functions returns a barebones, placeholder, draggableItem.
--- This should never be called when dragging groups.
--- Allows roles to be dragged into empty groups.
function getHoveredEmptyGroup(myGroups: RoleGroupsMap, myMousePosition: Vector2): (DraggableItem?)
	for _, myGroup in myGroups do
		if (#myGroup.Roles ~= 0) then continue end

		local myGroupUI = myGroup.UI
		local myBaseFrame = myGroupUI.BaseElement

		local myFramePosition = myBaseFrame.AbsolutePosition
		local myFrameSize = myBaseFrame.AbsoluteSize
		if isPointInBounds(myMousePosition, myFramePosition, (myFramePosition + myFrameSize)) then 
			return ({
				LayoutOrder = 1; Index = 1;
				GroupID = myGroup.GroupID;
			} :: any)
		end
	end

	return nil
end

function relistItems(myItems: (RolesMap | RoleGroupsMap), myItemIDs: {string})
	for myItemIndex, myItemID in myItemIDs do
		local myItem: DraggableItem = myItems[myItemID]
		if not myItem then continue end

		local layoutOrder = ((myItemIndex * 2) - 1)
		myItem.LayoutOrder = layoutOrder
		myItem.Index = myItemIndex

		local myItemUI = myItem.UI :: any
		local myItemBase = myItemUI.BaseElement
		myItemBase.LayoutOrder = layoutOrder
	end
end

function toggleRoleContainers(myGroups: RoleGroupsMap, isVisible: boolean, isEditing: boolean)
	for _, myGroup in myGroups do
		local myGroupUI = myGroup.UI
		local myContainer = myGroupUI.RolesContainer
		myContainer.Visible = (isVisible and (not myGroup.IsCollapsed) or false)
	end
end

function destroyItem(myItem: DraggableItem)
	local myItemUI = myItem.UI
	local baseUIElement = myItemUI.BaseElement
	if baseUIElement then baseUIElement:Destroy() end

	CLEAR(myItemUI); CLEAR(myItem)
end

function cancelGroupDeletion(self: RM_ItemRegistry, myGroup: RoleGroup)
	local confirmationThreads = self.ConfirmGroupDeletionThreads
	local myConfirmationThread = confirmationThreads[myGroup.GroupID]
	if not myConfirmationThread then return end

	confirmationThreads[myGroup.GroupID] = nil
	local myThreadStatus = THREAD_STATUS(myConfirmationThread)
	if ((myThreadStatus == "normal") or (myThreadStatus == "suspended")) then
		THREAD_CANCEL(myConfirmationThread) --> Cancel Thread
	end

	local myGroupUI = myGroup.UI
	myGroupUI.IdentityFrame.Visible = true
	myGroupUI.NewRoleButton.Visible = self.IsEditing
	myGroupUI.DeletionWarningLabel.Visible = false
end

--@ // ITEM REGISTRY \\ @--
local RM_ItemRegistry = {
	ConfirmGroupDeletionThreads = {};
	TargetScrollPosition = 0;
	DeleteItemSelected = false;

	DragOffset = V2();
	IsEditing = false;
	GroupIDs = {};
	Groups = {};
	Roles = {};

	--[[ UTILITY ]]--
	GetClosestItem = function(self: RM_ItemRegistry, myItems: (RolesMap | RoleGroupsMap), myDraggedItem: DraggableItem): (DraggableItem?, number)
		local panelSize = rolesPanel.AbsoluteSize
		local panelPosition = rolesPanel.AbsolutePosition
		local mousePosition = getMousePosition()

		local panelBottomRight = (panelPosition + panelSize)
		local mouseIsWithinPanel = isPointInBounds(mousePosition, panelPosition, panelBottomRight)
		if not mouseIsWithinPanel then return nil, 0 end

		local isDraggingRole = ((myDraggedItem :: any).RoleID ~= nil)
		if isDraggingRole then
			local closestItem = getHoveredEmptyGroup(self.Groups, mousePosition)
			if closestItem then return closestItem, 0 end	
		end

		local closestDistance = (panelSize.Y / 4)
		local closestItem = nil
		local direction = 0

		local myDraggedGroupID = myDraggedItem.GroupID
		local myDraggedItemBase = myDraggedItem.UI.BaseElement
		local myDraggedItemSizeY = myDraggedItemBase.AbsoluteSize.Y
		local myDraggedItemPositionY = myDraggedItemBase.AbsolutePosition.Y
		local myDraggedItemMidPointY = (myDraggedItemPositionY + (myDraggedItemSizeY / 2))

		for _, myItem in myItems do
			if (myItem == myDraggedItem) then continue end --> Skip self

			--> Distance Check
			--| Based on the Y position to prevent flickering
			--| when mouse is moved horizontally.
			local myItemUI = myItem.UI
			local measureTarget = myItemUI.BaseElement
			if not isDraggingRole then measureTarget = (myItemUI :: RoleGroupUI).HeaderFrame end

			local myItemPosition = measureTarget.AbsolutePosition
			local myItemSize = measureTarget.AbsoluteSize
			local midPointY = (myItemPosition.Y + (myItemSize.Y / 2))

			local verticalDistance = ABS(mousePosition.Y - midPointY)
			if (verticalDistance >= closestDistance) then continue end

			--> Update Variables
			closestItem = myItem; 
			closestDistance = verticalDistance;

			--> Mouse-Based Direction Logic
			--| If the item being dragged is a role and the closest item is 
			--| in a different group, then fallback to comparing the mousePosition.Y 
			--| to the closest item's position.Y This allows for roles to 
			--| be placed at the start and end of other groups. Otherwise,
			--| you'd only be able to place a role in the 2nd or 2nd to last position.
			if (isDraggingRole and (myItem.GroupID ~= myDraggedGroupID)) then
				direction = ((mousePosition.Y > midPointY) and 1 or -1)

				--> Discord-Style Direction Logic
				--| If the item being hovered over is below the starting (dragged) item
				--| then the divider well be placed after (1) the closest item.
				--| Otherwise, the divider will be placed before (-1) the closest item.
			else direction = ((myDraggedItemMidPointY > midPointY) and -1 or 1) end
		end

		return closestItem, direction
	end;

	ToggleEditing = function(self: RM_ItemRegistry, isEditing: boolean)
		isEditing = ((isEditing ~= nil) and isEditing or (not self.IsEditing))

		self.IsEditing = isEditing
		for _, myGroup: RoleGroup in self.Groups do
			local myGroupUI = myGroup.UI
			local myDragHandle = myGroupUI.DragHandle
			local myDeleteButton = myGroupUI.DeleteButton
			local myNewRoleButton = myGroupUI.NewRoleButton
			local myCollapseButton = myGroupUI.CollapseButton
			local myRolesContainer = myGroupUI.RolesContainer

			myDragHandle.Visible = isEditing
			--myDeleteButton.Visible = isEditing
			myNewRoleButton.Visible = isEditing
			myCollapseButton.Visible = (not isEditing)
			myRolesContainer.Visible = (isEditing and true or (not myGroup.IsCollapsed))
			if (self.ConfirmGroupDeletionThreads[myGroup.GroupID] ~= nil) then cancelGroupDeletion(self, myGroup) end
		end

		for _, myRole in self.Roles do
			local myRoleUI = myRole.UI
			local myDragDetector = myRoleUI.DragDetector

			myDragDetector.Enabled = isEditing
		end

		editingActions.Visible = isEditing
		viewingActions.Visible = (not isEditing)
	end;

	--[[ DRAGGING ]]--
	BeginDraggingItem = function(self: RM_ItemRegistry, myItem: DraggableItem)
		local isRole = ((myItem :: any).RoleID ~= nil)

		local myItemUI = myItem.UI
		local myItemBase = myItemUI.BaseElement
		local myMousePosition = getMousePosition()

		local hoverPosition = myMousePosition
		self.ActiveDrag = myItem :: any
		deleteItemButton.Visible = true

		if isRole then
			local myBasePosition = myItemBase.AbsolutePosition
			self.DragOffset = (myMousePosition - myBasePosition)
			hoverPosition = myBasePosition

		else self.DragOffset = V2_ZERO end	

		--> Position & Setup Hover Item
		local myBaseSize = myItemBase.AbsoluteSize
		hoverItem.Position = UDIM2_OFFSET(hoverPosition.X, hoverPosition.Y);
		hoverItem.Size = UDIM2_OFFSET(myBaseSize.X, myBaseSize.Y)
		hoverLabel.Text = myItem.Name; hoverItem.Visible = true;

		--> Handle Item Visuals
		myItemBase:AddTag(isRole and ROLE_DRAG_TAG or ROLE_GROUP_DRAG_TAG); 

		--> Handle Group Visuals
		if not isRole then 
			local myGroup = myItem :: RoleGroup
			local myGroupUI = myItemUI :: RoleGroupUI
			--myGroupUI.RolesContainer.Visible = false
			myGroupUI.ControlsFrame.Visible = false
			myGroupUI.DragHandle.Visible = false

			toggleRoleContainers(self.Groups, false, true)
		end
	end;

	ItemDragged = function(self: RM_ItemRegistry, myItem: DraggableItem)
		if (self.ActiveDrag ~= myItem) then return end

		--> Reposition HoverItem Frame
		local myMousePosition = getMousePosition()
		local myDragPosition = (myMousePosition - self.DragOffset)
		hoverItem.Position = UDIM2_OFFSET(myDragPosition.X, myDragPosition.Y)

		--> Find Closest Item
		local isRole = ((myItem :: any).RoleID ~= nil)
		local searchMap = (isRole and self.Roles or self.Groups) 
		local closestItem, itemDirection = self:GetClosestItem((searchMap :: RolesMap), myItem)

		local lastDivider = self.LastDivider
		if not closestItem then
			if lastDivider then lastDivider.Visible = false end
			return
		end

		--> Indentify Target Group & Divider
		local targetGroupID = closestItem.GroupID
		local targetGroup = self.Groups[targetGroupID]

		local myDivider = groupDivider
		if isRole then myDivider = targetGroup.UI.RoleDivider end

		--> Hide Old Divider if Changed
		if (lastDivider and (lastDivider ~= myDivider)) then 
			lastDivider.Visible = false 
		end

		--> Update Divider Position
		self.LastDivider = myDivider; myDivider.Visible = true
		myDivider.LayoutOrder = (closestItem.LayoutOrder + itemDirection)
	end;

	StopDraggingItem = function(self: RM_ItemRegistry, myItem: DraggableItem)
		if (self.ActiveDrag ~= myItem) then return end
		if self.LastDivider then self.LastDivider.Visible = false end
		self.ActiveDrag = nil; self.LastDivider = nil; hoverItem.Visible = false;

		local myGroups, myRoles = self.Groups, self.Roles
		local myItemIsARole = ((myItem :: any).RoleID ~= nil)

		--> Get Closest Item & Handle Item Deletion
		local closestItem, itemDirection
		if self.DeleteItemSelected then
			deleteItemButton.Visible = false;

			if myItemIsARole then
				local myRole = myItem :: Role
				myRoles[myRole.RoleID] = nil

				local myRoleGroup = myGroups[myItem.GroupID]
				if myRoleGroup then REMOVE(myRoleGroup.Roles, myItem.Index) end
				myItem:Destroy(); return

			else
				toggleRoleContainers(self.Groups, true, self.IsEditing)
				if self:DeleteRoleGroup(myItem :: RoleGroup) then myItem:Destroy(); return end
			end

			--> Specifically ONLY get closest item if no deletion is pending.
			--| This allows visuals to be restored without attempting to reorder items.
		else 
			local searchMap = (myItemIsARole and myRoles or myGroups)
			closestItem, itemDirection = self:GetClosestItem((searchMap :: RolesMap), myItem)
		end

		--> Restore Visuals
		--| This is done AFTER running getClosestItem, so that any changes
		--| made to the UI won't affect distance caluclations.
		--| For example, uncollapsing the groups.
		local myRoleGroup: RoleGroup
		if myItemIsARole then
			local myRole = myItem :: Role
			myRole.UI.BaseElement:RemoveTag(ROLE_DRAG_TAG)
			deleteItemButton.Visible = false

			myRoleGroup = myGroups[myRole.GroupID]
			if not myRoleGroup then return end --> This should never happen.

		else
			myRoleGroup = myItem :: RoleGroup

			local myGroupUI = myRoleGroup.UI
			myGroupUI.DragHandle.Visible = self.IsEditing
			myGroupUI.ControlsFrame.Visible = true
			myGroupUI.BaseElement:RemoveTag(ROLE_GROUP_DRAG_TAG)
			toggleRoleContainers(self.Groups, true, self.IsEditing)
		end

		if not closestItem then return end
		local myTargetRoleGroup = myGroups[closestItem.GroupID]
		if not myTargetRoleGroup then return end --> This should never happen.

		--> Define Lists & Context
		local currentItemsList: {string}
		local newItemsList: {string}

		local closestGroup: RoleGroup
		local mapToRelist: (RoleGroupsMap | RolesMap)
		local myItemID: string

		if myItemIsARole then
			local myRole = myItem :: Role
			closestGroup = myGroups[closestItem.GroupID]

			currentItemsList = myRoleGroup.Roles; 
			newItemsList = myTargetRoleGroup.Roles;
			mapToRelist = myRoles;
			myItemID = myRole.RoleID;

			if (myRole.GroupID ~= myTargetRoleGroup.GroupID) then
				myRole.GroupID = myTargetRoleGroup.GroupID
				myRole.UI.BaseElement.Parent = myTargetRoleGroup.UI.RolesContainer
			end

		else
			currentItemsList = self.GroupIDs
			newItemsList = self.GroupIDs
			closestGroup = myItem :: RoleGroup
			mapToRelist = myGroups
			myItemID = myItem.GroupID
		end

		--> Calculate Target Index
		--| Below (1): Insert at Next Index
		--| Above (-1): Insert at Current Index
		local isAppending = (itemDirection == 1)
		local insertOffset = (isAppending and 1 or 0)
		local targetIndex = (closestItem.Index + insertOffset)

		--> Adjust for Removal Shift
		--| If we are in the same list and the item is moving DOWN (Old < New),
		--| removing the old item shifts our target index down by 1.
		local isSameList = (currentItemsList == newItemsList)
		if (isSameList and isAppending) then targetIndex -= 1 end

		--> Reorder Arrays
		REMOVE(currentItemsList, myItem.Index); 
		INSERT(newItemsList, targetIndex, myItemID)

		--> Update Item Positions
		relistItems(mapToRelist, currentItemsList)
		if not isSameList then relistItems(self.Roles, newItemsList) end
	end;

	--[[ INITIALIZATION & UI SETUP ]]--
	NewRole = function(self: RM_ItemRegistry, itemInfo: BasicItemInfo, myRoleGroup: RoleGroup): (Role)

		--> Define References
		local myRoleIndex = itemInfo.Index
		local myRoleName = itemInfo.Name
		local myRoleID = itemInfo.ID

		local myGroupUI = myRoleGroup.UI
		local myGroupID = myRoleGroup.GroupID
		local myRolesContainer = myGroupUI.RolesContainer
		local layoutOrder = ((myRoleIndex * 2) - 1)

		--> Create Role Object
		local myRole = {
			LayoutOrder = layoutOrder;
			IsSelected = false;
			Index = myRoleIndex;

			GroupID = myGroupID;
			RoleID = myRoleID;
			Name = myRoleName;

			Destroy = destroyItem;
		} :: Role

		(myRole :: any).__index = myRole;
		setmetatable({}, myRole)

		--> Setup UI
		local myRoleButton = ROLE_TEMPLATE:Clone()
		local myRoleDragger = myRoleButton.UIDragDetector
		local myRoleNameLabel = myRoleButton.Label
		myRoleButton.LayoutOrder = layoutOrder --> Roles are spaced by 2 (1, 3, 5) to allow dividers to be placed at (0, 2, 4)
		myRoleNameLabel.Text = myRoleName
		myRoleButton.Parent = myRolesContainer
		myRoleButton.Name = myRoleName

		myRoleDragger.DragEnd:Connect(function() self:StopDraggingItem(myRole) end)
		myRoleDragger.DragStart:Connect(function() self:BeginDraggingItem(myRole) end)
		myRoleDragger:SetDragStyleFunction(function() self:ItemDragged(myRole) end)

		--> Finalize & Return
		myRole.UI = {
			BaseElement = myRoleButton;
			DragDetector = myRoleDragger;
			RoleNameLabel = myRoleNameLabel;
		}

		myRoleGroup.Roles[myRoleIndex] = myRoleID;
		self.Roles[myRoleID] = myRole; return myRole;	
	end;

	DeleteRoleGroup = function(self: RM_ItemRegistry, myGroup: RoleGroup)
		local myGroupID = myGroup.GroupID
		local confirmationThreads = self.ConfirmGroupDeletionThreads
		local myConfirmationThread = confirmationThreads[myGroupID]

		if myConfirmationThread then
			confirmationThreads[myGroupID] = nil
			THREAD_CANCEL(myConfirmationThread)

			self.Groups[myGroupID] = nil;
			REMOVE(self.GroupIDs, myGroup.Index)

		else
			local myGroupUI = myGroup.UI
			myGroupUI.NewRoleButton.Visible = false
			myGroupUI.IdentityFrame.Visible = false
			myGroupUI.DeletionWarningLabel.Visible = true
			confirmationThreads[myGroupID] = DELAY_TASK(GROUP_DELETE_CANCEL_TIMER, cancelGroupDeletion, self, myGroup)
		end

		return (myConfirmationThread ~= nil)
	end,

	NewRoleGroup = function(self: RM_ItemRegistry, itemInfo: BasicItemInfo): (RoleGroup)

		--> Define References
		local myGroupIndex = itemInfo.Index
		local myGroupName = itemInfo.Name
		local myGroupID = itemInfo.ID

		local myGroupFrame = GROUP_TEMPLATE:Clone()
		local myGroupContentFrame = myGroupFrame.GroupContent

		local myDragHandleFrame = myGroupFrame.GroupDragHandle
		local myGroupDragger = myDragHandleFrame.Overlay.UIDragDetector

		local myGroupHeaderFrame = myGroupContentFrame.GroupHeader
		local myGroupIdentityFrame = myGroupHeaderFrame.GroupIdentity
		local myDeletionWarningLabel = myGroupHeaderFrame.DeleteWarning

		local myGroupControlsFrame = myGroupHeaderFrame.GroupControls
		local myNewRoleButton = myGroupControlsFrame.New;
		local myDeleteButton = myGroupControlsFrame.Delete;

		local myCollapseButton = myGroupControlsFrame.Collapse
		local myCollapseButtonIcon = myCollapseButton.Icon

		local myGroupNameLabel = myGroupIdentityFrame.TitleLabel
		local myGroupLayoutOrder = ((myGroupIndex * 2) - 1)
		local myGroupRolesContainer = myGroupContentFrame.RolesList

		--> Create Group Object
		local myRoleGroup = {
			IsCollapsed = false;
			LayoutOrder = myGroupLayoutOrder;
			Index = myGroupIndex;

			GroupID = myGroupID;
			Name = myGroupName;

			UI = {
				BaseElement = myGroupFrame;
				HeaderFrame = myGroupHeaderFrame;
				GroupNameLabel = myGroupNameLabel;

				IdentityFrame = myGroupIdentityFrame;
				DeletionWarningLabel = myGroupHeaderFrame.DeleteWarning;

				DragHandle = myDragHandleFrame;
				DragDetector = myGroupDragger;

				ControlsFrame = myGroupControlsFrame;
				DeleteButton = myDeleteButton;
				NewRoleButton = myNewRoleButton;
				CollapseButton = myCollapseButton;

				RoleDivider = myGroupRolesContainer.RoleDivider;
				RolesContainer = myGroupRolesContainer;
			};

			Roles = {};
			Destroy = destroyItem;
		} :: RoleGroup

		(myRoleGroup :: any).__index = myRoleGroup;
		setmetatable({}, myRoleGroup)

		--> Setup UI
		myGroupFrame.LayoutOrder = myGroupLayoutOrder
		myGroupNameLabel.Text = myGroupName
		myGroupFrame.Parent = rolesPanel
		myGroupFrame.Name = myGroupName

		myCollapseButton.MouseButton1Click:Connect(function()
			local wasCollapsed = myRoleGroup.IsCollapsed
			myRoleGroup.IsCollapsed = (not wasCollapsed)

			myGroupRolesContainer.Visible = wasCollapsed
			myCollapseButtonIcon.Rotation = (wasCollapsed and 90 or 0)
		end)

		myNewRoleButton.MouseButton1Click:Connect(function()
			local myRole = self:NewRole({
				Index = (#myRoleGroup.Roles + 1);
				Name = NEW_ROLE_NAME;
				ID = httpService:GenerateGUID();
			}, myRoleGroup)

			local myRoleUI = myRole.UI
			myRoleUI.DragDetector.Enabled = self.IsEditing
		end)

		myGroupDragger.DragEnd:Connect(function() self:StopDraggingItem(myRoleGroup) end)
		myGroupDragger.DragStart:Connect(function() self:BeginDraggingItem(myRoleGroup) end)
		myGroupDragger:SetDragStyleFunction(function() self:ItemDragged(myRoleGroup) end)

		--> Finalize & Return
		self.GroupIDs[myGroupIndex] = myGroupID;
		self.Groups[myGroupID] = myRoleGroup; 
		return myRoleGroup
	end;

	Initialize = function(self: RM_ItemRegistry)
		--> Convert Data Format to RunTime Format
		local GROUPS = self.Groups
		local ROLES = self.Roles

		for myGroupIndex, myGroupData in ROLE_DATA do
			local myRoleGroup = self:NewRoleGroup({
				Index = myGroupIndex;
				Name = myGroupData.Name;
				ID = myGroupData.ID;
			})

			for myRoleIndex, myRoleData in myGroupData.Roles do
				local myRole = self:NewRole({
					Index = myRoleIndex;
					Name = myRoleData.Name;
					ID = myRoleData.ID;
				}, myRoleGroup)
			end
		end

		--> Setup Actions
		editButton.MouseButton1Click:Connect(function()
			self:ToggleEditing(true)
		end)

		discardEditsButton.MouseButton1Click:Connect(function()
			self:ToggleEditing(false)
		end)

		saveEditsButton.MouseButton1Click:Connect(function()
			self:ToggleEditing(false)
		end)

		newGroupButton.MouseButton1Click:Connect(function()
			self:NewRoleGroup({
				Index = (#self.GroupIDs + 1);
				Name = NEW_GROUP_NAME;
				ID = httpService:GenerateGUID();
			})
		end)

		--> Handle Manual Scrolling
		--| Annoying that this is required, but UIDragDetectors
		--| sink all input. So we have to manually scroll the
		--| scrollingframe when dragging an item.
		local function scroll(direction: number)
			if not self.ActiveDrag then return end

			local canvasSizeY = rolesPanel.AbsoluteCanvasSize.Y
			local amountToScroll = (PIXELS_PER_SCROLL_STEP * direction)

			local currentScrollY = self.TargetScrollPosition
			local newScrollY = CLAMP((currentScrollY + amountToScroll), 0, canvasSizeY)

			tweenService:Create(rolesPanel, SMOOTH_SCROLL_TWEEN_INFO, {
				CanvasPosition = V2(0, newScrollY)
			}):Play()
		end

		rolesPanel.MouseWheelBackward:Connect(function() scroll(1) end)
		rolesPanel.MouseWheelForward:Connect(function() scroll(-1) end)
		rolesPanel:GetAttributeChangedSignal("CanvasPosition"):Connect(function()
			if not self.ActiveDrag then 
				self.TargetScrollPosition = rolesPanel.CanvasPosition.Y
			end
		end)

		--> Delete Item Button Highlighting
		--| Done for the same reason above.
		deleteItemButton.MouseEnter:Connect(function() self.DeleteItemSelected = true; deleteItemButton:AddTag(ROLE_DELETE_HOVER_TAG) end)
		deleteItemButton.MouseLeave:Connect(function() self.DeleteItemSelected = false; deleteItemButton:RemoveTag(ROLE_DELETE_HOVER_TAG) end)
	end,
};

--@ // MAIN \\ @--
return {
	new = function(): (RM_ItemRegistry)
		return newProxy("RM_ItemRegistry", RM_ItemRegistry) :: RM_ItemRegistry
	end,
}
