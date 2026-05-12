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
Creation Date: 04/05/2026
Version: 1.0.0

-- Last Edit --
Editor: JestaLemon
Date: 04/05/2026

-- Description --
Handles character movement and initializes the PromptController.
Will be broken down into a bootstrap architecture at a later point.
Based on the Defold 3D Movement Template.

-- Changelog --

-- END HEADER --
]]--!strict

--@ // OBJECT PROPERTIES \\ @--
go.property("PromptInterfaceURL", msg.url("/gui#Prompt"))
go.property("CameraURL", msg.url("/character#camera"))

go.property("DialogSpeakerURL", msg.url("/SoundScape#Dialog"))
go.property("SubtitlesInterfaceURL", msg.url("/gui#Subtitles"))

go.property("LookSensitivity", 0.15) -- degrees of camera rotation per 1 pixel of mouse movement
go.property("MoveSpeed", 0.5) -- world units per second for camera movement on XZ plane
go.property("MoveLimit", 1.25) -- bounds (half-size) for camera movement on XZ to keep it in a square area. Hard coded for 

--@ // TYPE DECLARATIONS \\ @--
---@class (exact) MovementInfo Data structure that represents the movement state.
---@field Yaw number The Y plane. Looking up/down.
---@field Pitch number The X/Z plane. Looking left/right.
---@field Changed boolean Determines if the movement solver needs to move the camera or not.
---@field MouseLocked boolean Mouse movement rotates camera when true.
---@field Directions {Forward: boolean, Backward: boolean, Left: boolean, Right: boolean} Input states for WASD movement.

---@class (exact) CharacterController
---@field Movement MovementInfo
---@field LookSensitivity number How fast the camera moves.
---@field MoveSpeed number How fast the character bean moves.
---@field MoveLimit number Provides a temporary square bounding box. Simulated collision.
---@field CameraURL string Points to the camera object.
---@field DialogSpeakerURL string Points to the object container the sounds that plays dialog audio.
---@field PromptInterfaceURL string Points to the interface object that handles interaction prompts.
---@field SubtitlesInterfaceURL string Points to the interface object that handles subtitles.
---@field PromptController PromptController See: example.services.PromptController

--@ // DEPENDENCIES \\ @--
local Aperture = require("example.libraries.Aperture")
local DialogService = require("example.services.DialogService")
local InputBindingService = require("example.services.InputBindingService")
local PromptControllerComponent = require("example.services.PromptController")

local Utilities = require("example.modules.Utilities")
local CLAMP = Utilities.Clamp

--@ // GLOBALS \\ @--

--@ // CONSTANTS \\ @--
local KEY_MOUSE_CLICK = hash("mouse_button_1")
local KEY_ESCAPE = hash("key_esc")

local DIRECTION_KEYS = {
    [hash("key_w")] = "Forward";
    [hash("key_s")] = "Backward";
    [hash("key_a")] = "Left";
    [hash("key_d")] = "Right";
}

--@ // VARIABLES \\ @--

--@ // FUNCTIONS \\ @--

--@ // MAIN \\ @--

---@param self CharacterController
function init(self)
	msg.post(".", "acquire_input_focus") --> Acquire input focus to receive input events from the engine

    local yaw = go.get(".", "euler.y")
    local pitch = go.get(".", "euler.x");
    
    ---@cast yaw number
    ---@cast pitch number
    self.Movement = {
        Yaw = yaw;
        Pitch = pitch;

        Changed = false;
        MouseLocked = false;

        Directions = {
            Forward = false;
            Backward = false;

            Left = false;
            Right = false;
        };
    };

    --> Initialize PromptController
    self.PromptController = PromptControllerComponent.new(go.get_id(), self.PromptInterfaceURL)

    --> Initialize DialogManager
    local myDialogManager = DialogService.newManager(self.DialogSpeakerURL, "Prologue.lua")
    myDialogManager.NodeBeganPlaying:Connect(function(myNode)
        msg.post(self.SubtitlesInterfaceURL, hash("Set"), myNode)
    end)

    myDialogManager:Play()
end

---@param self CharacterController
---@param DELTA_TIME number
function update(self, DELTA_TIME)
    local myMovementInfo = self.Movement
    if not myMovementInfo.Changed then return end

    --> Prevent the camera from flipping upside down & rotate camera
    if (myMovementInfo.Pitch > 89) then myMovementInfo.Pitch = 89 end
    if (myMovementInfo.Pitch < -89) then myMovementInfo.Pitch = -89 end
    go.set(".", "euler", vmath.vector3(myMovementInfo.Pitch, myMovementInfo.Yaw, 0))

    --> Calculate movement direction
    local inputStates = myMovementInfo.Directions
    local velocityX = ((inputStates.Right and 1 or 0) - (inputStates.Left and 1 or 0))
    local velocityZ = ((inputStates.Backward and 1 or 0) - (inputStates.Forward and 1 or 0))

    --> Move camera
    if ((velocityX ~= 0) or (velocityZ ~= 0)) then
        local velocity = vmath.vector3(velocityX, 0, velocityZ)
        local velocityMagnitude = math.sqrt((velocityX^2) + (velocityZ^2))

        if (velocityMagnitude > 0) then
           velocity = (velocity / velocityMagnitude) --> Normalize diagonal speed
           
           --> Convert velocity to world movement
           local worldRotation = vmath.quat_rotation_y(math.rad(myMovementInfo.Yaw))
           local worldDirection = vmath.rotate(worldRotation, velocity)

           --> Apply movement to position
           local newPosition = go.get_position()
           newPosition = (newPosition + (worldDirection * self.MoveSpeed * DELTA_TIME))

           --> Clamp to temporary world bounds
           local limit = self.MoveLimit
           newPosition.x = CLAMP(newPosition.x, -limit, limit)
           newPosition.z = CLAMP(newPosition.z, -limit, limit)

           --> Update position
           go.set_position(newPosition)
        end
    end

    myMovementInfo.Changed = false

    --> Update prompt
    local closestNodeURL, closestNodeContext = self.PromptController:GetClosestValidPrompt()
    if not (closestNodeURL and closestNodeContext) then msg.post(self.PromptInterfaceURL, "SetVisibility", {IsVisible = false}) return end

    local nodeWorldPosition = go.get_world_position(closestNodeURL)
    local normalizedCoordinates = Aperture.newNDC(self.CameraURL, nodeWorldPosition)

    --> Move prompt board into place if closest node is visible
    local isVisible = normalizedCoordinates.IsVisible
    if isVisible then
        msg.post(self.PromptInterfaceURL, "MoveBoard", {
            ScreenPosition = normalizedCoordinates:ToScreenSpace();
            Text = closestNodeURL;
        })

        for myInputIndex, myInput in ipairs(closestNodeContext.Inputs) do
            local myKey = myInput.Key
            local myBinding = InputBindingService:BindAction("Prompt_"..hash(myKey), {Key = myKey; MustHoldKey = false})
            myBinding.Activated:Connect(function() closestNodeContext.Triggered(closestNodeURL, myInputIndex) end)
        end
        
    --> Hide board & unbind inputs when not visible
    else
        msg.post(self.PromptInterfaceURL, "SetVisibility", {IsVisible = false}) 

        for _, myInput in ipairs(closestNodeContext.Inputs) do
            InputBindingService:UnbindAction("Prompt_"..hash(myInput.Key))
        end
    end
end

---@param self CharacterController
function on_input(self, pressedKey, actionInfo)
    InputBindingService.on_input(pressedKey, actionInfo)
    
    local wasPressed = actionInfo.pressed
    local wasReleased = actionInfo.released

    local myMovementInfo = self.Movement
    myMovementInfo.Changed = true

    --> Rotate camera while mouse is locked.
    local lookDeltaX, lookDeltaY = actionInfo.dx, actionInfo.dy
    if (myMovementInfo.MouseLocked and (lookDeltaX or lookDeltaY)) then
        myMovementInfo.Yaw = (myMovementInfo.Yaw - ((lookDeltaX or 0) * self.LookSensitivity))
        myMovementInfo.Pitch = (myMovementInfo.Pitch + ((lookDeltaY or 0) * self.LookSensitivity))
    end

    --> Lock mouse when screen is clicked
    if ((not myMovementInfo.MouseLocked) and wasPressed and (pressedKey == KEY_MOUSE_CLICK)) then
        window.set_mouse_lock(true); myMovementInfo.MouseLocked = true;
    end

    --> Handle movement states
    if (wasPressed or wasReleased) then
        local direction = DIRECTION_KEYS[pressedKey]
        if direction then myMovementInfo.Directions[direction] = wasPressed end
    end

    --> Unlock mouse with ESC
    if ((pressedKey == KEY_ESCAPE) and wasPressed) then
        window.set_mouse_lock(false); myMovementInfo.MouseLocked = false
    end
end