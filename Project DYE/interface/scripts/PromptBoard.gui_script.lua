--[[ PROTOTYPE ]] --

local druidFramework = require("druid.druid")
local TITLE_TEMPLATE = "<b>%s</b>"
local DESCRIPTION_TEMPLATE = "\n<color=c8c8c8><size=0.9>%s</size></color>"

local inputs = {
	[1] = {
		Title = "Change Color";
		Key = "key_f";
	};

	[2] = {
		Title = "Don't Press This Button!";
		Description = "Seriously, don't.";
		Key = "key_g";
	};
};

function init(self)
	local druid = druidFramework.new(self)
	self.druid = druid

	--local myContainer = druid:new_container("root", "vertical")
	--myContainer:set_size()
	msg.post(".", "acquire_input_focus")
	
	local myContainer = druid:new_layout("root", "vertical")
	self.Root = myContainer

	local template = gui.get_node("ENTRY_TEMPLATE")
	self.t = {}

	print("init board")
	for myInputIndex, myInputInfo in ipairs(inputs) do
		local myEntryTable = gui.clone_tree(template)
		print("creating prompt:", myInputIndex)

		for i, v in pairs(myEntryTable) do
			print(i, v)
		end
		
		local myEntryNode = myEntryTable.ENTRY_TEMPLATE
		local myEntryLayout = druid:new_layout(myEntryNode)
		
		local myEntryLabel = myEntryTable.Label
		local myEntryKeycap = myEntryTable.Keycap
		
		local titleText = myInputInfo.Title
		local displayText = string.format(TITLE_TEMPLATE, titleText)
		local descriptionText = myInputInfo.Description
		if descriptionText then displayText = (displayText .. string.format(DESCRIPTION_TEMPLATE, descriptionText)) end
		
		local myRichTextParser = druid:new_rich_text(myEntryLabel, displayText)
		myEntryLayout:add(myEntryKeycap); myEntryLayout:add(myEntryLabel)
		--myEntryLayout:set_node_index(myEntryKeycap, 1); myEntryLayout:set_node_index(myEntryLabel, 2);
		myEntryLayout:set_padding(-50); self.t[myInputIndex] = myRichTextParser

		gui.set_text(myEntryTable.Key, string.upper(string.sub(myInputInfo.Key, -1, -1)))
		
		myContainer:add(myEntryNode); gui.set_enabled(myEntryNode, true);
		myContainer:set_node_index(myEntryNode, myInputIndex)
	end

	gui.set_alpha(template, 1)
end

function on_message(self, message_id, message, sender)
	self.druid:on_message(message_id, message, sender)

	if message_id == hash("SetVisibility") then
		gui.set_enabled(self.Root.node, message.IsVisible)

	elseif message_id == hash("MoveBoard") then
		local screenPosition = message.ScreenPosition
		local myRootNode = self.Root.node

		gui.set_enabled(myRootNode, true)
		gui.set_screen_position(myRootNode, screenPosition)

	elseif message_id == hash("color") then
		local r = math.random(0, 255) --(math.random(0, 100) / 100)
		local g = math.random(0, 255)--(math.random(0, 100) / 100)
		local b = math.random(0, 255)--(math.random(0, 100) / 100)
		local c = vmath.vector3(r, g, b)
		for _, wordSegment in pairs(self.t[1]:get_words()) do
			gui.set_visible(wordSegment.node, true)
			gui.set_color(wordSegment.node, c)
		end
	end
end

function on_input(self, action_id, action)
	return self.druid:on_input(action_id, action)
end

--// Druid Requirements
function final(self) self.druid:final() end
function update(self, dt) self.druid:update(dt) end