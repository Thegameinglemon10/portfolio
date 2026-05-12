local NAME_USER = "Unit 4";
local NAME_HANDLER = "The Handler";

local RGB = vmath.vector3
local COLOR_USER = RGB(0, 170, 255) / 255
local COLOR_HANDLER = RGB(255, 90, 0) / 255

local AUDIO_USER = "Prologue/Leandre.wav"
local AUDIO_HANDLER = "Prologue/Cassian.wav"

return {
	Root = {
		Label = "Root";

		Root = {
			Label = "Root";
			Text = "[garbled] UNIT FOUR! Do you read?! Telemetry went dead. Respond!";

			Speaker = NAME_HANDLER;
			SpeakerColor = COLOR_HANDLER;

			Audio = {
				ResourceLocation = AUDIO_HANDLER;
				AudioStart = 0;
				AudioEnd = 8;
			};

			Next = "Root2";
		};

		Root2 = {
			Label = "Root2";
			Text = "I- I'm here.. Rough landing, w-where am I?";

			Speaker = NAME_USER;
			SpeakerColor = COLOR_USER;

			Audio = {
				ResourceLocation = AUDIO_USER;
				AudioStart = 8;
				AudioEnd = 13;
			};

			Next = "^Professional.P1_H";
		};
	};

	Professional = {
		Label = "Professional";

		P1_H = {
			Label = "P1_H";
			Text = "You tell me, dumbass. You need to keep moving. I can't get a read on the Grouper. What'd you do to her?!";
			
			Speaker = NAME_HANDLER;
			SpeakerColor = COLOR_HANDLER;
			
			Audio = {
				ResourceLocation = AUDIO_HANDLER;
				AudioStart = 13;
				AudioEnd = 20;
			};

			Next = "P2_L";
		};

		P2_L = {
			Label = "P2_L";
			Text = "It's dark out here, my damn light broke... But from what I <i>can</i> see, I think she's done for.";
			
			Speaker = NAME_USER;
			SpeakerColor = NAME_USER;
			
			Audio = {
				ResourceLocation = AUDIO_USER;
				AudioStart = 20;
				AudioEnd = 28;
			};

			Next = "P3_H";
		};

		P3_H = {
			Label = "P3_H";
			Text = "Ughhh... That was our <bi>last</bi> operational vessel! It's coming out of your paycheck.";
			
			Speaker = NAME_HANDLER;
			SpeakerColor = COLOR_HANDLER;
			
			Audio = {
				ResourceLocation = AUDIO_HANDLER;
				AudioStart = 29;
				AudioEnd = 36.5;
			};

			Next = "^Establish_Objective.OBJ1_L";
		};
	};

	Establish_Objective = {
		Label = "Establish_Objective";

		OBJ1_L = {
			Label = "OBJ1_L";
			Text = "Look- I don't know where I am, I can barely see, and oxygen reserves are critical. I need a top-up. Where's the nearest depot?";
			
			Speaker = NAME_USER;
			SpeakerColor = COLOR_USER;
			
			Audio = {
				ResourceLocation = AUDIO_USER;
				AudioStart = 36.5;
				AudioEnd = 45;
			};

			Next = "OBJ2_H";
		};

		OBJ2_H = {
			Label = "OBJ2_H";
			Text = "Stop whining, and give me less things to worry about. [Sigh] Hold on... [Keyboard Clacking]<S18>Depot 7's signal is still operational. Looks about 150 meters North-West of your little \"incident\". The terrain is jagged, and it's a bit of a detour, so move quickly, but watch your footing.";

			Speaker = NAME_HANDLER;
			SpeakerColor = COLOR_HANDLER;
			
			Audio = {
				ResourceLocation = AUDIO_HANDLER;
				AudioStart = 45;
				AudioEnd = 79;
			};

			--Options = {"^Ending.Romantic1_L", "^Ending.Professional1_L"}

			Next = "^Ending.Romantic1_L";
		};
	};

	Ending = {
		Label = "Ending";

		--- ROMANTIC ---

		Romantic1_L = {
			Label = "Romantic1_L";
			Text = "Aww, don't want me getting hurt? You really <bi>do</bi> care.";

			Speaker = NAME_USER;
			SpeakerColor = COLOR_USER;
			
			Audio = {
				ResourceLocation = AUDIO_USER;
				AudioStart = 79;
				AudioEnd = 84;
			};

			Next = "Romantic2_H";
		};

		Romantic2_H = {
			Label = "Romantic2_H";
			Text = "[Silence] Replacing you would be more hassle than your life is worth. Get your oxygen, then get to the worksite. And with haste, we're already late.";

			Speaker = NAME_HANDLER;
			SpeakerColor = COLOR_HANDLER;
			
			Audio = {
				ResourceLocation = AUDIO_HANDLER;
				AudioStart = 85;
				AudioEnd = 98;
			};

			Next = "<END>";
		};

		--- PROFESSIONAL ---

		Professional1_L = {
			Label = "Professional1_L";
			Text = "Copy that. Moving out.";

			Speaker = NAME_USER;
			SpeakerColor = COLOR_USER;
			
			--[[Audio = {
				ResourceLocation = AUDIO_HANDLER;
				AudioStart = 85;
				AudioEnd = 98;
			};]]--
			
			Next = "Professional2_H";
		};

		Professional2_H = {
			Label = "Professional2_H";
			Text = "Don't dawdle. Oxygen is money, Unit 4... And you're wasting both.";

			Speaker = NAME_HANDLER;
			SpeakerColor = COLOR_HANDLER;
			
			--[[
			Audio = {
				ResourceLocation = AUDIO_USER;
				AudioStart = 79;
				AudioEnd = 84;
			};]]--

			Next = "<END>";
		};
	};
}