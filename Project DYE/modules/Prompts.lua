---@class PromptInput
---@field Key hash
---@field Title string
---@field Description string?

---@class PromptContext
---@field MaxDistance number
---@field NodeURLs {number: string}
---@field Triggered fun(nodeURL: string, inputIndex: number)
---@field Verify fun(nodeURL: string): (boolean)?
---@field Inputs {number: PromptInput}

return function(promptController)
	return {
		{
			MaxDistance = 1;
			NodeURLs = {"t1"};
			
			Triggered = function(nodeURL, inputIndex)
				if (inputIndex == 1) then msg.post(promptController.PromptBoardURL, "color")
				else print("THEY PRESSED THE BUTTON!!") end
			end;
			
			Inputs = {
				[1] = {
					Title = "Change Color";
					Key = hash("key_f");
				};

				[2] = {
					Title = "Don't Press This Button!";
					Description = "Seriously, don't";
					Key = hash("key_g");
				};
			};
		};

		{
			MaxDistance = 1;
			NodeURLs = {"t2", "t3"};
			
			Triggered = function(nodeURL, inputIndex)
				msg.post(promptController.PromptBoardURL, "color")
			end;
			
			Inputs = {
				[1] = {
					Title = "Change Color";
					Key = hash("key_f");
				};
			};
		};
	}
end