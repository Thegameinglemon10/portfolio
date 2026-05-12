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

File Name: CharacterController.script
Written By: JestaLemon
Creation Date: 01/17/2026
Version: 1.0.0

-- Last Edit --
Editor: JestaLemon
Date: 01/17/2026

-- Description --
Provides utility functions for the camera.

-- Changelog --

-- END HEADER --
]]--!strict

--@ // TYPE DECLARATIONS \\ @--

--@ // DEPENDENCIES \\ @--

--@ // GLOBALS \\ @--

--@ // CONSTANTS \\ @--

--@ // VARIABLES \\ @--

--@ // FUNCTIONS \\ @--

--@ // NORMALIZED DEVICE COORDINATE (NDC) \\ @--
local NDC = {}
NDC.__index = NDC

-- Converts the NDC to a screen space Vector3.
function NDC:ToScreenSpace()
	--> Get window dimensions & NDC Vector
	local windowWidth, windowHeight = window.get_size()
	local myNDCVector = self.Vector
	
	--> Map NDC (-1 to 1) to screen space (0 to width/height)
	local screenX = (((myNDCVector.x + 1) * 0.5) * windowWidth)
	local screenY = (((myNDCVector.y + 1) * 0.5) * windowHeight)
	
	--> Construct screen space vector & return
	return vmath.vector3(screenX, screenY, 0)
end

--@ // APERATURE \\ @--
local Aperture = {}

---Constructs a Vector3 that represents a "Normalized Device Coordinates" (NDC) vector.
---An NDC normalizes coordinates to a range of -1 to 1.
---Wherein, if NDC.x is equal to 0, the postion is on the very left of the screen, and a value
---of 1 is on the very right. Anything less than 0 or greater than 1 is outside of 
---the area visible by the camera.
---@param cameraURL url|string The camera component URL to use for the transformation.
---@param worldPosition vector3 The world position to convert.
---@return {}
function Aperture.newNDC(cameraURL, worldPosition)
	--> Get matrices from the camera component
	local projectionMatrix = camera.get_projection(cameraURL)
	local modelMatrix = vmath.vector4(worldPosition.x, worldPosition.y, worldPosition.z, 1)
	local viewMatrix = camera.get_view(cameraURL)

	--> Transform the world position to clip space
	local PV_Matrix = (projectionMatrix * viewMatrix) -- Projection-View Matrix
	local MVP_Matrix = (PV_Matrix * modelMatrix) -- Model-View-Projection Matrix

	--> Perspective divide (convert to Normalized Device Coordinates)
	local NDC_Vector = vmath.vector3((MVP_Matrix.x / MVP_Matrix.w), (MVP_Matrix.y / MVP_Matrix.w), (MVP_Matrix.z / MVP_Matrix.w))

	--> Check if coordinates are within the [-1, 1] range
	-- X: Left/Right, Y: Top/Bottom, Z: Near/Far planes
	local withinRangeX = (NDC_Vector.x >= -1 and NDC_Vector.x <= 1)
	local withinRangeY = (NDC_Vector.y >= -1 and NDC_Vector.y <= 1)
	local withinRangeZ = (NDC_Vector.z >= -1 and NDC_Vector.z <= 1)
	local isWithinRange = (withinRangeX and withinRangeY and withinRangeZ)
	
	--> Construct NDC Object
	return setmetatable({
		Vector = NDC_Vector;
		IsVisible = isWithinRange;
	}, NDC)
end

---Converts a position within the world to a position on the screen.
---This doesn't properly account for whether the position is infront or behind the camera.
---If the visibility of the position is important, create an NDC object with Aperture.newNDC, 
---use NDC.IsVisible, then convert the position using NDC:ToScreenSpace().
---@param cameraURL url|string The camera component URL to use for the transformation.
---@param worldPosition vector3 The world position to convert.
---@return vector3
function Aperture.worldToScreen(targetCamera, worldPosition)
	local myNDC = Aperture.newNDC(targetCamera, worldPosition)
	return myNDC:toScreenSpace()
end

--@ // MAIN \\ @--
return Aperture