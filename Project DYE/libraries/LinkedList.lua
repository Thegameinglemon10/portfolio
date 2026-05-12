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

File Name: LinkedList.lua
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

--// Services

--// Enums

--// Globals
local INSERT = table.insert

--@ // Constants \\ @--

--@ // Custom Services \\ @--

--@ // Custom Libraries \\ @--

--@ // Variables \\ @--

--@ // Functions \\ @--

--@ // LinkedList Class \\ @--

---@class LinkedListNode<T> Represents a value stored in a linked list.
---@field Next LinkedListNode<T>?
---@field Last LinkedListNode<T>?
---@field Value T

---@class LinkedList<T>
---@field Head LinkedListNode<T>? The first value in the list.
---@field Tail LinkedListNode<T>? The last value in the list.
local LINKED_LIST = {}
LINKED_LIST.__index = LINKED_LIST;

---Clears the list's meta table, leaving it to be garbage collected.
function LINKED_LIST:Destroy() setmetatable(self, {}) end;

---Sets the head and tail to nil, effectively clearing the list and leaving it to be garbage collected.
function LINKED_LIST:ClearNodes() self.Head = nil; self.Tail = nil; end;

---Places a value in the list.
---@generic T
---@param value T The value to store in the list
---@param atEnd boolean? if true, the new value will be placed at the end as the tail. Otherwise (default) it'll be made the first value as the head.
---@return LinkedListNode<T>
function LINKED_LIST:Insert(value, atEnd)
	local insertionPoint = (atEnd and "Tail" or "Head") -- The point at which the newNode is being placed
	local oppositePoint = (atEnd and "Head" or "Tail") -- The point opposite of the insertion point

	local outgoingLink  = (atEnd and "Next" or "Last") -- The link pointing out from the existing boundary node
	local incomingLink = (atEnd and "Last" or "Next") -- The link pointing in to the existing boundary node

	--> Create new node and the relink node at the insertion postion to the new node.
	local myNode = {Value = value;}
	local boundaryNode = self[insertionPoint]
	if boundaryNode then boundaryNode[outgoingLink] = myNode; myNode[incomingLink] = boundaryNode end

	--> Place node in list
	self[insertionPoint] = myNode
	if not self[oppositePoint] then self[oppositePoint] = myNode; end
	
	return myNode
end

---Removes the provided node from the list.
---@generic T
---@param myNode LinkedListNode<T>
function LINKED_LIST:Remove(myNode)

	--> Get nodes pointing into and out of the removing node. (boundary nodes)
	local lastNode, nextNode = myNode.Last, myNode.Next
	local currentHead, currentTail = self.Head, self.Tail

	--> Detatch and relink boundary nodes
	if nextNode then nextNode.Last = lastNode end
	if lastNode then lastNode.Next = nextNode end

	--> Reassign head & tail
	if (currentHead == myNode) then self.Head = nextNode end
	if (currentTail == myNode) then self.Tail = lastNode end
end

---Provides an iterator function, allowing the list to be looped through.
---@param reverseOrder boolean? If true, the iterator will return values starting at the tail and moving towards the head. Otherwise (default), it'll start at the head and move towards the tail.
---@return fun(): (LinkedListNode<T>)
function LINKED_LIST:ForEachNode(reverseOrder)
	local currentNode = (reverseOrder and self.Tail or self.Head)
	
	return function()
		if not currentNode then return nil end

		local nodeToReturn = currentNode
		currentNode = (reverseOrder and currentNode.Last or currentNode.Next)

		return nodeToReturn
	end
end

---Returns the linked list broken down into a standard array.
---@param reverseOrder boolean? If true, the list's 1st index will be the tail and Nth index, the head. Otherwise (default), the 1st index will be the head and the Nth index, the tail.
---@return {number: LinkedListNode<T>}
function LINKED_LIST:GetAllNodes(reverseOrder)
	local currentNode = (reverseOrder and self.Tail or self.Head)
	local nodeIndex = (reverseOrder and "Last" or "Next")

	local nodes = {}
	while currentNode do
		INSERT(nodes, currentNode)
		currentNode = currentNode[nodeIndex]
	end

	return nodes
end

--@ // Main \\ @--
return {

	---Constructs a new LinkedList object.
	---@return LinkedList
	new = function() return setmetatable({}, LINKED_LIST) end
};