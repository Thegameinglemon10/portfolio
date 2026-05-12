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

File Name: DialogService.lua
Written By: JestaLemon
Creation Date: 12/17/2025
Version: 1.0.0

-- Last Edit --
Editor: JestaLemon
Date: 04/05/2026

-- Description --
Provides a object orientated API for parsing Dialog modules.

-- Changelog --
[04/04-05/2026] v2.0.0: Rewritten for Defold

-- END HEADER --
]]--!strict

--@ // TYPE DECLARATIONS \\ @--
---@alias DialogTree {number: DialogBranch}
---@alias RawDialogTree {number: RawDialogBranch}
---@alias DialogBranch {Label: string, [string]: DialogNode}
---@alias RawDialogBranch {Label: string, [string]: RawDialogNode}

---@class (exact) DialogData_AudioData
---@field ResourceLocation string Defines where the audio file is stored. For example: "[DialogName].[SpeakerName]"
---@field AudioStart number This is where the audio will start playing. Expects a number of seconds from the start of the audio file.
---@field AudioEnd number This is where the audio will stop playing. Expects a number of seconds from the start of the audio file.

---@class (exact) RawDialogNode
---@field Label string A unique indentifer.
---@field Text string The raw text to display in subtitles. Includes formatting tags.
---@field Speaker string The name of who's currently speaking. Will be used as the header on the subtitles.
---@field SpeakerColor string Used to color the header text.
---@field CleanText string Text with formatting tags removed.
---@field Audio DialogData_AudioData Defines audio data.
---@field Next string Defines which DialogNode to use next.

---@class (exact) DialogNode: RawDialogNode
---@field TextSegments {Text: string, Length: number?}

---@class (exact) DialogParser
---@field DialogTree DialogTree?
---@field CurrentBranch DialogBranch
---@field CurrentNode DialogNode
---@field NodeChanged ScriptSignal<DialogNode>
---@field NodeCompleted ScriptSignal<DialogNode>
---@field BranchChanged ScriptSignal<DialogBranch>
---@field __index DialogParser
local DIALOG_PARSER = {}
DIALOG_PARSER.__index = DIALOG_PARSER

---@class (exact) DialogManager
---@field IsPlaying boolean
---@field DialogTree DialogTree
---@field SpeakerURL string
---@field DialogParser DialogParser
---@field NodeBeganPlaying ScriptSignal<DialogNode>
---@field NodeFinishedPlaying ScriptSignal<DialogNode>
---@field __index DialogManager
local DIALOG_MANAGER = {}
DIALOG_MANAGER.__index = DIALOG_MANAGER

---@class (exact) DialogManager_Internal: DialogManager
---@field __RunningThread thread?

--@ // DEPENDENCIES \\ @--
local signalService = require("example.services.SignalService")
local NEW_SIGNAL = signalService.new

local utilities = require("example.modules.Utilities")
local splitString = utilities.SplitString
local WAIT = utilities.Wait

--@ // GLOBALS \\ @--
local INSERT = table.insert

--@ // CONSTANTS \\ @--
local DIALOG_REGISTRY_PATH = "/example/modules/dialog/"
local AUDIO_STORAGE_PATH = "/example/assets/audio/"

--@ // VARIABLES \\ @--
local SOUND_BUFFERS = {}
local DIALOG_TREES = {}
local FONT_TAGS = {
    ["<bi>"] = "<font=text_bold_italic>";
    ["<b>"] = "<font=text_bold>";
    ["<i>"] = "<font=text_italic>";
}

--@ // FUNCTIONS \\ @--

---Takes raw DialogTree data and parses the nodes.
---@param myDialogTree DialogTree
---@return DialogTree
function SETUP_DIALOG_TREE(myDialogTree)
    for _, myBranch in pairs(myDialogTree) do
        for _, myNode in pairs(myBranch) do
            if (type(myNode) == "table") then
                --> Register Sound Buffers
                local myAudioData = myNode.Audio
                if myAudioData then
                    local mySoundName = myAudioData.ResourceLocation
                    if (SOUND_BUFFERS[mySoundName] == nil) then
                        local mySoundPath = (AUDIO_STORAGE_PATH..mySoundName)
                        local mySoundBuffer, err = sys.load_resource(mySoundPath)
                        if not mySoundBuffer then
                            SOUND_BUFFERS[mySoundName] = false
                            print("[DIALOG_PARSER] Failed to register SoundBuffer ("..mySoundPath.."): "..(err or "UNKOWN ERROR"))

                        else SOUND_BUFFERS[mySoundName] = mySoundBuffer end
                    end
                end

                --> Split Text into Segments
                local myRawText = myNode.Text
                local myRawTextIndex = 1
                
                local myTextSegments = {}
                local mySegmentStart, mySegmentEnd, mySegmentLength = myRawText:find("<S(%d+)>")
                while mySegmentStart do
                    local myParsedText = PARSE_TAGS(myRawText:sub(myRawTextIndex, mySegmentStart-1))

                    INSERT(myTextSegments, {
                        Text = myParsedText;
                        Length = tonumber(mySegmentLength);
                    })

                    myRawTextIndex = (mySegmentEnd + 1)
                    mySegmentStart, mySegmentEnd, mySegmentLength = myRawText:find("<S(%d+)>", myRawTextIndex)
                end

                --> Insert trailing text and non-segmented text.
                INSERT(myTextSegments, {Text = PARSE_TAGS(myRawText:sub(myRawTextIndex))})
                myNode.TextSegments = myTextSegments
            end
        end
    end

    return myDialogTree
end

---Loads a dialog tree module by load_resource and loadstring.
---@param modulePath string
---@return DialogTree
function GET_DIALOG_TREE(modulePath)
    local existingTree = DIALOG_TREES[modulePath]
    if existingTree then return existingTree end

   local moduleSource, err = sys.load_resource(modulePath)
   if not moduleSource then error("Failed to load DialogTree at ("..modulePath.."). Error: "..err, 2) end

   local loadModule, err = loadstring(moduleSource)
   if loadModule then return SETUP_DIALOG_TREE(loadModule()) end

   error("Failed to load DialogTree at ("..modulePath.."). Error: "..err, 2)
end

---Parses a node path into a valid node.
---@param myDialogTree DialogTree
---@param myBranch DialogBranch
---@param myNodePath string
---@return DialogBranch?, DialogNode?
function GET_NODE_FROM_PATH(myDialogTree, myBranch, myNodePath)
    if (myNodePath == "<END>") then return nil, nil end -- We've reached the end of the tree.

    if (myNodePath:sub(1, 1) == "^") then --> Parse Branch Jump ("^<BRANCH_NAME>.<NODE_NAME>")
        local trimmedPath = myNodePath:sub(2, -1)
        local pathComponents = splitString(trimmedPath, ".")
        
        myNodePath = pathComponents[2]
        myBranch = (myDialogTree[pathComponents[1]] or {})
    end
    
    local myNode = myBranch[myNodePath]
    if (type(myNode) ~= "table") then
        print("[DIALOG_PARSER] Node path ("..myNodePath..") resulted in missing or invalid node.")
        return nil, nil
    end

    return myBranch, myNode
end

---Replaces custom tags with proper Druid rich text tags.
---@param text string
---@return string result, number count
function PARSE_TAGS(text)
    return text:gsub("<[/]?[%a]+>", function(capture)
        if (capture:sub(2, 2) == "/") then return "</font>" end
        return (FONT_TAGS[capture] or "")
    end)
end


--@ // DIALOG_PARSER CLASS \\ @--

---Progresses down the dialog tree.
---@return DialogNode?, DialogBranch?
function DIALOG_PARSER:NextNode()
    local myDialogTree = self.DialogTree
    if not myDialogTree then print("[DIALOG_PARSER] Must select a DialogTree before attempting to use :NextNode().") return end

    local currentBranch = self.CurrentBranch
    local currentNode = self.CurrentNode

    local nextBranch, nextNode = GET_NODE_FROM_PATH(myDialogTree, currentBranch, currentNode.Next)
    if not (nextBranch and nextNode) then return end

    self.CurrentNode = nextNode
    self.CurrentBranch = nextBranch
    if (nextBranch ~= currentBranch) then
        self.BranchChanged:Fire(nextBranch)
    end

    self.NodeChanged:Fire(nextNode)
    return nextNode, nextBranch
end

---@param treeName string The name of the dialog tree. Must be present in the "modules.Dialog" folder to be considred valid.
---@param firstBranch string? The name of the starting Branch. If nil, it will default to "Root".
---@param firstNode string? The name of the starting node. If nil, it will default to "Root".
function DIALOG_PARSER:SetDialogTree(treeName, firstBranch, firstNode)
    ---@type DialogTree
    local myDialogTree = GET_DIALOG_TREE(DIALOG_REGISTRY_PATH..treeName)

    --> Validate Parameters
    assert((type(myDialogTree) == "table"), "DialogTree module must return a table!")
    firstBranch = (firstBranch or "Root"); firstNode = (firstNode or "Root")
    
    local myBranch = myDialogTree[firstBranch]
    assert((myBranch ~= nil), "Unable to find branch with name ("..firstBranch..")!")

    local myNode = myBranch[firstNode]
    assert((myNode ~= nil), "Unable to find node with name ("..firstNode..") in the ("..firstBranch..") branch!")

    self.DialogTree = myDialogTree
    self.CurrentBranch = myBranch
    self.CurrentNode = myNode

    self.BranchChanged:Fire(myBranch)
    self.NodeChanged:Fire(myNode)
end

--@ // DIALOG_PARSER CONSTRUCTOR \\ @--
---Constructs a new DialogParser object.
---@param treeName string The name of the dialog tree. Must be present in the "modules.Dialog" folder to be considred valid.
---@param firstBranch string? The name of the starting Branch. If nil, it will default to "Root".
---@param firstNode string? The name of the starting node. If nil, it will default to "Root".
---@return DialogParser
function NEW_DIALOG_PARSER(treeName, firstBranch, firstNode)
    --> Construct Object
    local myParser = setmetatable({
        CurrentBranch = "UNKOWN";
        CurrentNode = "UNKOWN";

        NodeChanged = NEW_SIGNAL();
        NodeCompleted = NEW_SIGNAL();
        BranchChanged = NEW_SIGNAL();
    }, DIALOG_PARSER)

    --> Set DialogTree
    if treeName then
        myParser:SetDialogTree(treeName, firstBranch, firstNode)
    end
    
    --> Return
    return myParser
end

--@ // DIALOG_MANAGER \\ @--
function DIALOG_MANAGER:Play() ---@cast self DialogManager_Internal
    local myParser = self.DialogParser
    if not myParser.DialogTree then print("[DIALOG_MANAGER] Unable to play. No DialogTree selected.") end

    if self.IsPlaying then return end
    self.IsPlaying = true

    local mySpeakerURL = self.SpeakerURL
    local mySoundResourcePath = go.get(mySpeakerURL, "sound")

    local playingSignal = self.NodeBeganPlaying
    local finishedSignal = self.NodeFinishedPlaying
    
    ---@cast mySoundResourcePath userdata
    self.__RunningThread = coroutine.wrap(function()
        
        ---@type DialogNode?
        local myNode = myParser.CurrentNode
        while (self.IsPlaying and myNode) do
            playingSignal:Fire(myNode)

            --> Play Speech
            local myAudioData = myNode.Audio
            local mySoundBuffer = SOUND_BUFFERS[myAudioData.ResourceLocation]
            
            local mySoundEnd = myAudioData.AudioEnd
            local mySoundStart = myAudioData.AudioStart
            if mySoundBuffer then
                resource.set_sound(mySoundResourcePath, mySoundBuffer)
                sound.play(mySpeakerURL, {start_time = mySoundStart})
            end
            
            --> Wait for Speech to End & Reset
            WAIT(mySoundEnd - mySoundStart);
            finishedSignal:Fire(myNode)
            sound.stop(mySpeakerURL)

            if not self.IsPlaying then return end

            myNode = myParser:NextNode()
            if not myNode then self.IsPlaying = false; break end
        end
    end)()
end

function DIALOG_MANAGER:Stop() ---@cast self DialogManager_Internal
    self.IsPlaying = false
end

--@ // MAIN \\ @--
return {
    SoundBuffers = SOUND_BUFFERS;
    newParser = NEW_DIALOG_PARSER;

    ---Constructs a new DialogManager object.
    ---@param speakerURL string The URL of a sound object. Will be used to play speech.
    ---@param dialogName string The name of the dialog tree. Must be present in the "modules.Dialog" folder to be considred valid.
    ---@param firstBranch string? The name of the starting Branch. If nil, it will default to "Root".
    ---@param firstNode string? The name of the starting node. If nil, it will default to "Root".
    ---@return DialogManager
    newManager = function(speakerURL, dialogName, firstBranch, firstNode)
        --> Validate Speaker
        assert(go.exists(speakerURL), "[DIALOG_MANAGER] Invalid Dialog Speaker URL. Game Object does not exist at ("..tostring(speakerURL)..").")

        --> Construct Object
        return setmetatable({
            
            IsPlaying = false;
            SpeakerURL = speakerURL;
            DialogParser = NEW_DIALOG_PARSER(dialogName, firstBranch, firstNode);
            
            NodeBeganPlaying = NEW_SIGNAL();
            NodeFinishedPlaying = NEW_SIGNAL();

        }, DIALOG_MANAGER)
    end;
}