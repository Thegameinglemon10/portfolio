--[[ PROTOTYPE ]] --

local druidFramework = require("druid.druid")

function resize_and_position(self)
	local width = window.get_size()
	
	gui.set_size(self.Root, vmath.vector3(width, 100, 0))
	gui.set_position(self.Root, vmath.vector3(width / 2, 50, 0))
	self.layout:refresh_layout()
end

function init(self)
	local druid = druidFramework.new(self)
	self.druid = druid

	local rootNode = gui.get_node("root")
	local speakerNode = gui.get_node("Speaker")
	local textNode = gui.get_node("Text")
	self.Root = rootNode

	self.RichTextLabel = druid:new_rich_text("Text")
	msg.post(".", "acquire_input_focus")
end

function wait_in_thread(callback, seconds, ...)
	local thread = coroutine.create(callback)
	local args = {...}

	timer.delay(seconds, false, function()
		coroutine.resume(thread, unpack(args))
	end)
end

function wait(seconds)
	local t = coroutine.running()

	timer.delay(seconds, false, function()
		coroutine.resume(t)
	end)

	coroutine.yield(t)
end

function on_message(self, message_id, message, sender)
	self.druid:on_message(message_id, message, sender)

	if message_id == hash("Set") then
		local speakerNode = gui.get_node("Speaker")
		gui.set_text(speakerNode, message.Speaker)
		gui.set_color(speakerNode, message.SpeakerColor)

		coroutine.wrap(function()
			for _, section in ipairs(message.TextSegments) do
				print(section.Text)
				self.RichTextLabel:set_text(section.Text)
				if section.Length then wait(section.Length) end
			end
		end)()
	end
end

function on_input(self, action_id, action)
	return self.druid:on_input(action_id, action)
end

--// Druid Requirements
function final(self) self.druid:final() end
function update(self, dt) self.druid:update(dt) end