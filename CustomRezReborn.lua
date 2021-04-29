---------------------------------------
---------------------------------------------------
--CustomRez Reborn v1.1.1
--Author : Fannia (Lothar US)
--Description : Sends funny random messages or a simple useful message when you use a resurrection spell.
--Inspired by : Serenity (messages and main idea), Necrosis (function to substitute names in messages)
--Credits : Lomig (Kael'Thas EU/FR) & Tarcalion (Nagrand US/Oceanic) -> Necrosis
--          Algarana - Rashgaroth ( EU - Alliance ) & Kaeldra of Aegwynn -> Serenity
-- **analysing your code was a pain, but i thank you for the inspiration and random messages ;)**

--Dev notes : need a way to switch texture on activation and random buttons to show the current state.
----------------------------------------------------
----------------------------------------------------
CF = CreateFrame
local addon = "CustomRezReborn"
--print(addon .. " has been loaded.")
--Set up table
local CustomRez = {}
local Regen = true

-- Main Frame Setup
local crFrame = CF("Frame", "crFrame", UIParent)
crFrame:SetWidth(200)
crFrame:SetHeight(60)
crFrame:SetPoint("CENTER", UIParent, "CENTER")
crFrame:SetMovable(true)
crFrame:EnableMouse(true)
crFrame:SetClampedToScreen(true)

-- Main Frame Background
local crTex = crFrame:CreateTexture("crTex")
crTex:SetAllPoints()
crTex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")

-- Main Frame 
crFrame:SetScript("OnMouseDown", function(self, button)
  if button == "LeftButton" and not self.isMoving then
   self:StartMoving();
   self.isMoving = true;
  end
end)
crFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and self.isMoving then
   self:StopMovingOrSizing();
   self.isMoving = false;
  end
end)
crFrame:SetScript("OnHide", function(self)
  if ( self.isMoving ) then
   self:StopMovingOrSizing();
   self.isMoving = false;
  end
end)
crFrame:SetScript("OnEnter", function(self)
	crMouseOverEnter();
end)
crFrame:SetScript("OnLeave", function(self)
	crMouseOverLeave();
end)

CustomRez.Spelltbl = {
	["DEATHKNIGHT_BREZ"] = 61999, --Raise Ally
	["DRUID_BREZ"] = 20484, -- Rebirth
	["DRUID_REZ"] = 50769, -- Revive
	["DRUID_MASS_REZ"] = 212040, -- Revitalize
	["MONK_REZ"] = 115178, -- Resuscitate
	["MONK_MASS_REZ"] = 212051, -- Reawaken
	["PRIEST_REZ"] = 2006, -- Resurrection
	["PRIEST_MASS_REZ"] = 212036, -- Mass Resurrection
	["PALLY_REZ"] = 7328, -- Redemption
	["PALLY_MASS_REZ"] = 212056, -- Absolution
	["SHAMMY_REZ"] = 2008, -- Ancestral Spirit
	["SHAMMY_MASS_REZ"] = 212048, -- Ancestral Vision
	["WARLOCK_BREZ"] = 20707, -- Soul Stone
}

--[[ClassIndex = 0 = none, 1 = Warrior,	2 = Paladin, 3 = Hunter, 4 = Rogue, 5 = Priest,
6 = DK, 7 = Shaman, 8 = Mage, 9 = Warlock, 10 = Monk, 11 = Druid, 12 = DH]]
local localClass, englishClass, classIndex = UnitClass("player")
--print(englishClass)

-- Event handling
local crEvents_table = {}
crEvents_table.eventFrame = CF("Frame");
crEvents_table.eventFrame:RegisterEvent("ADDON_LOADED");
crEvents_table.eventFrame:SetScript("OnEvent", function(self, event, ...)
	--print(event)
	crEvents_table.eventFrame[event](self, ...);
end);

-- First load settings
function crEvents_table.eventFrame:ADDON_LOADED(AddOn)
	--print(AddOn)
	if AddOn ~= addon then
		return
	end
	crEvents_table.eventFrame:UnregisterEvent("ADDON_LOADED")

	local defaults = {
		["crLock"] = true,
		["crMouseOver"] = false,
		["crAlpha"] = 0,
		["crScale"] = 1,
		["crHide"] = false,
		["Activated"] = true,
		["ChannelWanted"] = "SAY",
		["SimpleMessage"] = false,
	}

	local function crSVCheck(src, dst)
		if type(src) ~= "table" then return {} end
		if type(dst) ~= "table" then dst = {} end
		for k, v in pairs(src) do
			if type(v) == "table" then
				dst[k] = crSVCheck(v, dst[k])
			elseif type(v) ~= type(dst[k]) then
				dst[k] = v
			end
		end
		return dst
	end

	CustomRezVars = crSVCheck(defaults, CustomRezVars)

	crInitialize()
end

-- Top Level Frames (title|lock|close)
-- Title Line
crFrame.title = crFrame:CreateFontString("$parentTitle", "OVERLAY", "GameFontNormalSmall")
crFrame.title:SetPoint("TOPLEFT", crFrame, "TOPLEFT", 6, -8)
crFrame.title:SetText(GetAddOnMetadata(addon, "Title") .. " " .. GetAddOnMetadata(addon, "Version"))

-- Close Button
crFrame.close = CF("Button", "$parentCloseButton", crFrame, "UIPanelCloseButton")
crFrame.close:SetSize(20, 20)
crFrame.close:SetPoint("TOPRIGHT", crFrame, "TOPRIGHT", -2, -2)
crFrame.close:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
	GameTooltip:ClearLines();
	GameTooltip:SetText("Close");
	GameTooltip:AddLine("Click to Hide CustomRez v2 options.");
	GameTooltip:Show();
	crMouseOverEnter();
end)
crFrame.close:SetScript("OnLeave", function(self)
	GameTooltip:Hide();
	crMouseOverLeave();
end)

-- Lock Button
crFrame.lock = CF("CheckButton", "$parentLockButton", crFrame, "SecureActionButtonTemplate")
crFrame.lock:SetSize(20, 20)
crFrame.lock:SetPoint("TOPRIGHT", crFrameCloseButton, "TOPLEFT", 2, 0)
crFrame.lock:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
crFrame.lock:SetPushedTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
crFrame.lock:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
crFrame.lock:SetCheckedTexture("Interface\\Buttons\\LockButton-Unlocked-Down")
crFrame.lock:SetScript("OnClick", function(self)
	crLocker();
end)
crFrame.lock:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
	GameTooltip:ClearLines();
	GameTooltip:SetText("Lock");
	GameTooltip:AddLine("Click to Lock CustomRez v2 options.");
	GameTooltip:Show();
	crMouseOverEnter();
end)
crFrame.lock:SetScript("OnLeave", function(self)
	GameTooltip:Hide();
	crMouseOverLeave();
end)

-- Bottom Level Frames (Activate|Randomize|Channel)
-- Activate Button
crFrame.activate = CF("CheckButton", "$parentActivateButton", crFrame, "SecureActionButtonTemplate")
crFrame.activate:SetSize(24, 24)
crFrame.activate:SetPoint("BOTTOMLEFT", crFrame, "BOTTOMLEFT", 2, 2)
crFrame.activate:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
crFrame.activate:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
crFrame.activate:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
crFrame.activate:SetCheckedTexture("Interface\\BUTTONS\\UI-CheckBox-Check")
crFrame.activate:SetScript("OnClick", function(self)
	crActivationButton();
end)
crFrame.activate:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
	GameTooltip:ClearLines();
	GameTooltip:SetText("Activate");
	GameTooltip:AddLine("Click to Activate CustomRez v2.");
	GameTooltip:Show();
	crMouseOverEnter();
end)
crFrame.activate:SetScript("OnLeave", function(self)
	GameTooltip:Hide();
	crMouseOverLeave();
end)

-- Randomize Button
crFrame.random = CF("CheckButton", "$parentRandomButton", crFrame, "SecureActionButtonTemplate")
crFrame.random:SetSize(24, 24)
crFrame.random:SetPoint("BOTTOMLEFT", crFrameActivateButton, "BOTTOMRIGHT", 2, 0)
crFrame.random:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
crFrame.random:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
crFrame.random:SetCheckedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
crFrame.random:SetScript("OnClick", function(self)
	crRandomToggle();
end)
crFrame.random:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
	GameTooltip:ClearLines();
	GameTooltip:SetText("Randomizer");
	GameTooltip:AddLine("Click to Activate randomize Rez messages.");
	GameTooltip:Show();
	crMouseOverEnter();
end)
crFrame.random:SetScript("OnLeave", function(self)
	GameTooltip:Hide();
	crMouseOverLeave();
end)

-- Cahnnel DropDownMenu Button
crFrame.channel = CF("Frame", "$parentSpeechButton", crFrame, "UIDropDownMenuTemplate")
crFrame.channel:SetPoint("BOTTOMRIGHT", crFrame, "BOTTOMRIGHT", -118, 0)
local info = {}
crFrame.channel.initialize = function()
	wipe(info)

	local names = {"Say Aloud", "Yell Aloud", "Party Chat", "Raid Chat"}
	local chats = {"SAY", "YELL", "PARTY", "RAID"}

	for i, chat in next, chats do
		info.text = names[i]
		info.value = chat
		info.func = function(self)
			CustomRezVars.ChannelWanted = self.value
			crFrameSpeechButtonText:SetText(self:GetText())
			--print(self.value)
		end
		info.checked = chat == CustomRezVars.ChannelWanted
		UIDropDownMenu_AddButton(info)
	end
end
crFrame.channel:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
	GameTooltip:ClearLines();
	GameTooltip:SetText("Pick Channel");
	GameTooltip:AddLine("Pick channel to output to.");
	GameTooltip:Show();
	crMouseOverEnter();
end)
crFrame.channel:SetScript("OnLeave", function(self)
	GameTooltip:Hide();
	crMouseOverLeave();
end)

--RANDOM MESSAGES--
--here you can change the messages to your liking. always keep the current format or it wont work. if you want to include your class, either write it literaly or check message #17. don't forget the commas ( , ) after each messages, even the last. check wowwiki.com for usable characters and special characters.
CustomRez.RESURECTIONcustom = {
  	"Granddaddy always said laughter was the best medicine. I guess it wasn't strong enough to keep <target> alive.",
	"Okay, <target>, nap time is over! Back to work!",
	"Rezzing <target>. Can I get an 'amen', please!",
	"<target>, your subscription to Life(tm) has expired. Do you wish to renew?",
	"YAY! I always wanted my very own <target>-zombie!",
	"It just so happens that <target> is only MOSTLY dead. There's a big difference between mostly dead and all dead. Mostly dead is slightly alive.",
	"<target> has failed at life, I'm giving him a second chance. That's right, not God, ME!!",
	"Cool, I received 42 silver, 32 copper from <target>'s corpse",
	"GAME OVER, <target>. To continue press up, up, down, down, left, right, left, right, B, A, B, A, Select + Start",
	"<target>, it's more mana efficient just to resurrect you.  Haha, I'm just kidding!",
	"Well, <target>, if you had higher faction with The Engineers of Polytechnique of Montreal, you might have gotten a heal.  How do you raise it?  10g donation = 15 rep.",
	"Okay, <target>.  Stop being dead. No really, i insist.",
	"If you are reading this message, <target> is already dead.",
	"Don't rush me <target>. You rush a miracle worker, you get rotten miracles.",
	"Death came for you <target>! with large, pointy teeth! did you not see it?",
	"Resurrecting <target>. Side effects may include: nausea, explosive bowels, a craving for brains, and erectile dysfunction. Resurrection is not for everyone. Please consult healer before dying.",
	"Dammit <target>, I'm a doctor! Not a "..localClass.."! .... Wait a second.... Nevermind. Rezzing <target>",
	"Dying makes me angry, <target>, so you'd better stop now before I KILL YOU THEN REZ YOU THEN HIT THE *LOOP* BUTTON!",
	"<target> stop worshipping the ground I walk on and get up." ,
	"Hey <target>, will you check to see if Elvis is really dead?...and will he fill your spot in the party?",
	"Giving <target> another chance to mess it up. Yes i know i'm too generous.",
	"Dammit, <target>, did you get my PERMISSION before dying?! You gotta fill in form A-23WTF-ZOMG6-10KDM-REZME911 and send it by mail with a 100g cheque to my office 2 weeks prior to you death.",
	"Death defying feats are clearly not your strong point, <target>",
	"No way, i ain't burying you here, <target>.I'm much too important to get my nails dirty.",
	"<target>, by accepting this resurrection you hereby accept that you must forfeit your immortal soul to <player>. Please click 'Accept' to continue.",
	"<target>, this better not be another attempt to get me to give you mouth-to-mouth.",
	"Arise <target>, and fear death no more...or at least until the next pull.",
	"Stop slacking, <target>. You can sleep when you're dea... Oh... Um, rezzing <target>",
	"We can rebuild <target>. We can make him stronger, faster, but we can't make him any smarter.",
	"<target> has fallen and can't get up! What do you mean he broke his 2 legs? No excuse sir!",
	"Bring out your dead! *throws <target> on the cart*",
	"<player> said : *<target>, get up and walk* and <target> did.",
	"<target>, quit hitting on the Spirit Healer and come kill something!",
	"<target> I *warned* you, but did you listen to me? Oh, no, you *knew*, didn't you? Oh, it's just a harmless little *bunny*, isn't it?",
	"<target>, please! This is supposed to be a happy occasion. Let's not bicker and argue over who killed who.",
	"Today's category on Final Jeopardy: Spells that end in 'esurrection'. <target>, ready?",
	"There are worse things then death, <target>. Have you ever grouped with... oh, wait. We aren't supposed to mention that in front of you.",
	"Did you run into some snakes on a plane or something, <target>? 'cause you're dead.",
	"Wee-ooo! Wee-ooo! Wee-ooo! Wee-ooo! Wee-ooo! Wee-ooo... that's the best ambulance impression I can do, <target>.",
	"Tsk tsk, <target>. See, I told you to sacrifice that virgin to the Volcano God.",
	"<target> gets a Mulligan.",
	"Sorry <target>, i can't heal stupidity. I can rez stupid tought.",
	"Eww!  What's that smell!  It smells like something died in here!  Hey, where is <target>?... Oh.",
	"Unfortunately, <target>, you have to be at least Revered with Polytechnique of Montreal Engineers to be rezzed. Sucks to be you.",  
	"You don't deserve a cute rez macro, <target>. You deserve to die. But you already did, so, um... yeah.",
	"<target>, you have been weighed, you have been measured, and too bad, there wasn't any coffin we could fit you in so apparently you can't die yet.",
	"Well <target>, you tried your best...and apparently failed miserably. Good job.", 
	"Did it hurt, <target>, when you fell from Heaven? Oh, wait...You're dead...hmmm...I don't know where I was going with that. Nevermind.", 
	"Gah, <target>, dead again? You probably want a rez, don't you? What do you think I am, a "..localClass.."... oh. Fair enough.",
	"<target> have you heard of Nethaera?  Yeah, she's really cool.  Why do I bring it up?  No reason.",
	"Can somebody get <target> a Phoenix Down over here? *stumbles* Wow, out of body experience...",
	"Funny how everyone else can die and come back, but a Phoenix Down won't take care of <target>.",
	"Sorry <target>, I know I'm a "..localClass.." ... but come ON! Did you see how many guys there were!?",
	"Hey <target>! Don't go towards the light! Well, unless it says 'Accept' ... but even then, it might be a trick!",
	"Sorry <target>, I couldn't heal you. I was too busy being the tank.",
	"<target>, prove me i'm not making a mistake by rezzing you...",
	"You're lucky i like you <target>",
	"Rezzing <target> before he gets a tea-bag from everyone in the group. Oups...too late :p",
	"Haiku time!\nThere was a monster\n<target> stood there\n<Player> rezzed <target>.",
	"You know <target>, as much as i hate to say it, watching you die made me smile, laugh, hug my cat, adopt an orphan and reach a higher elevation of the mind. You are worthy to come back.",
	"<target> - all that time-- ...there he was. Just standing there. Regenerating 5, health. Per. Second.",
	"<target> - STONECLAW TOTEM - STONE AND CLAW COMBINED. CAN YOU TAKE IT?",
	"<target> - So, as you all know, I play a Shaman.",
	"Uh… Strangers... Do they want to share what they got or take what you got? Do you say 'hi' or do you blow them away? Huh, <target>?",
	"<target> - Even though my teammates are now charred corpses, they continue to cheer.",
	"<target> - 'And there's nothing you can do about it' the Troll whispered.",
	"<target> - I glared at the Troll.",
	"<target> - The Troll glared back at me.",
	"<target> - Silence flooded the world.",
	"<target> - The end has come! Let the unraveling of this world commence!",
	"<target> - Vanquish the Deceiver!",
	"<target> - LET THE WORLD BURN!",
	"<target> - STICK AROUND!",
	"<target> - Your duplicity is hardly surprising.",
	"<target> - My people and all of Northrend shall be free!",
	"<target> - You are not prepared!",
	"<target> - You were not prepared!",
	"<target> - Behold the flames of Azzinoth!",
	"<target> - Death... Really isn't so bad.",
	"<target> - YOU WILL SHOW THE PROPER RESPECT!",
	"<target> - I was the first, you know. For me, the wheel of death has spun many times. ",
	"<target> - Your reach exceeds your grasp.",
	"<target> - I won't be ignored.",
	"<target> - The pain is only the beginning!",
	"<target> - Look at what you made me do.",
	"<target> - How long do you believe your pathetic sorcery can hold me?",
	"<target> - Vermin! Leeches! Take my blood and choke on it!",
	"<target> - Away, you mindless parasites! My blood is my own!",
	"<target> - Beg for life.",
	"<target> - Unworthy.",
	"<target> - You not so tough after all!",
	"<target> - Gronn are the real power in Outland!",
	"<target> - You face not Malchezaar alone, but the legions I command!",
	"<target> - All realities, all dimensions are open to me!",
	"<target> - How can you hope to withstand such overwhelming power?",
	"<target> - You are but a plaything, unfit even to amuse.",
	"<target> - Your greed, your foolishness has brought you to this end.",
	"<target> - Surely you did not think you could win.",
	"<target> - Wow, that sucked. Oh well let's try again.",
	"<target> - Vengeance burns!",
	"<target> - I'll turn your world...upside...down.",
	"<target> - Your demise accomplishes nothing!",
	"<target> - You will drown in your own blood! The world shall burn!",
	"<target> - I foresee no complications at this... wait! What is this!?",
	"<target> - No!!! A curse upon you, interlopers!",
	"<target> - You have no idea what horrors lie ahead. You have seen nothing!",
	"<target> - Death is close.",
	"<target> - You are already dead.",
	"<target> - You are weak.",
	"<target> - You will betray your friends.",
	"<target> - You will die.",
	"<target> - Your courage will fail.",
	"<target> - Your friends will abandon you.",
	"<target> - Your heart will explode.",
	"<target> - Sands of the desert, rise and block out the sun!",
	"<target> - You were terminated.",
	"<target> - THIS CANNOT BE!!! Rend, deal with these insects.",
	"<target> - Looking for the Red Scepter Shard? Come and get it...",
	"<target> - TASTE THE FLAMES OF SULFURON!",
	"<target> - COME FORTH MY SERVANT! DEFEND YOUR MASTER!",
	"<target> - INSECTS! BOLDLY, YOU SOUGHT THE POWER OF RAGNAROS. NOW YOU SHALL SEE IT FIRSTHAND!",
	"<target> - TOO SOON! YOU HAVE AWAKENED ME TOO SOON, <target>.",
	"<target> - PRIDE HERALDS THE END OF YOUR WORLD. COME, MORTALS!",
	"<target> - Foolsss...Kill the one in the dress!",
	"<target> - Concentrate your attacks upon the healer!",
	"<target> - Pain and suffering, are all that await you.",
	"<target> - You're not cut out for this!",
	"<target> - Common. Such a crude language. Ban'dal!",
	"<target> - Enjoy your final moments. Again.",
	"<target> - All of your efforts have been in vain,",
	"<target> - This world will burn!",
	"<target> - All creation will be devoured!",
	"<target> - Bow to my will.",
	"<target> - Your resistance is insignificant!",
	"<target> - No, it cannot be! Noooooooooooooooooo!",
	"<target> - As you can see, I have many weapons in my arsenal.",
	"<target> - By the power of the sun!",
	"<target> - Having trouble staying grounded?",
	"<target> - Let us see how you fare when your world is turned upside down.",
	"<target> - You gambled...and lost.",
	"<target> - Water is life. It has become a rare commodity here.",
	"<target> - I did not wish to lower myself by engaging your kind, but you leave me little choice!",
	"<target> - The time is now! Leave none on the floor!",
	"<target> - You may want to take cover.",
	"<target> - Straight to the heart!",
	"<target> - Everybody always wanna take from us. Now we gonna start takin' back.",
	"<target> - Got me some new tricks...like me bruddah bear!",
	"<target> - You too slow! Me too strong!",
	"<target> - Let me introduce to you my new bruddahs: fang and claw!",
	"<target> - We never forget. We never die. 'Dis is our land!",
	"<target> - Did you think me weak? Soft? Who is the weak one now?!",
	"<target> - NOW I'LL HAVE TO IMPROVISE!",
	"<target> - You'll never leave this life alive.",
	"<target> - Lapdogs. All of you!",
	"<target> - Your friends will abandon you.",
	"<target> - BY FIRE BE PURGED!",
	"<target> - Let the games begin.",
	"<target> - The Ashbringer…",
	"<target> - I was… pure… once…",
	"Hail to the king, <target>!",
	"I'm succeeding you, father!",
	"<target> - Forgive me <target>, your death only adds to my failure!", 
	"<target> - HAHAHA!! because mage is EZ SELECT MODE.",
	"<target> - I am Qubec so please excuse my unexcellence typing.",
	"UPDATE TO THE SKY: <target> coming up!",
	"<target> - did you say OH NO WHY IS ANIMALS ON MY FACE?!",
	"<target> - CAT DURID IS FOR FITE!",
	"<target> - Code Monkey get up get coffee?",
	"<target> - This is my staff and it's a good one.",
	"<target> - Rouges are the most overpowdered class in WoW.",
	"<target> - We're a generation of men raised by women.",
	"<target> - Tyler's not here. Tyler went away. Tyler's gone. ",
	"<target> - If you could fight anyone, who would you fight? ",
	"<target> - The path of the righteous man is beset on all sides by the iniquities of the selfish and the tyranny of evil men.",
	"<target> - Blessed is he, who in the name of charity and good will, shepherds the weak through the valley of darkness, for he is truly his brother's keeper and the finder of lost children.",
	"<target> - yea though I walk through the valley of the shadow of the dead, I shall fear no evil, for I am the baddest mother****er in that valley!",
	"<target> - And I will strike down upon thee with great vengeance and furious anger those who would attempt to poison and destroy my brothers.",
	"<target> - Just because you are a character doesn't mean that you have character.",
	"<target> - GET OFF MY LAWN <target>",
	"<target> - We are consumers. We're the bi-products of a lifestyle obsession.",
	"<target> - Hitting bottom isn't a weekend retreat. Stop trying to control everything and just let go! LET GO!",
	"<target> - Without pain, without sacrifice, we would have nothing.",
	"<target> - the things you own end up owning you.",
	"<target>. You like to eat ice cream and you really enjoy a nice pair of slacks. Years later, a doctor will tell you that you have an I.Q. of 48 and are what some people call mentally retarded.",
	"<target> - If you can dodge a wrench, you can dodge a ball.",
	"<target> - If you can dodge traffic, you can dodge a ball. ",
	"<target> - Go ahead, make your jokes, Mr. Jokey... Joke-maker. But let me hit you with some knowledge. Quit now. Save yourself the embarrassment of losing with these losers.",
	"<target> - Is it necessary to rez you? Necessary? Is it necessary for me to drink my own urine?",
	"Just don't go cryin' to your mommy when I spank you in front of all these people, <target>.",
	"<target> - I'm curious, is it strictly apathy, or do you really not have a goal in life?",
	"<target> - you're a skidmark on the underpants of society.",
	"<target> - I found that if you have a goal, that you might not reach it. But if you don't have one, then you are never disappointed. And I gotta tell ya... it feels phenomenal.",
	"<target> - Will someone kill a goddamn boss? It's like watching a bunch of retards trying to hump a doorknob out there!",
	"<target> - You happy? Fatty make a funny?",
	"<target> - You're adopted! Your parents don't even love you!", 
	"<target> - Victory. Honor. Pride. All these mean nothing... if you don't have balls.",
	"<target> - Here at <Renaissance> we're better than you, and we know it. ",
	"<target> - it's time to separate the wheat from the chaff, the men from the boys, the awkwardly feminine from the possibly Canadian.",
	"<target> - Ouchtown, population you, bro!",
	"<target> - Son, you're about as useful as a cock-flavored lollipop.",
	"<target> - YOU GOT SLYCED SON!",
	"<target> - If you can dodge a wrench, you can dodge a ball.",
	"<target> - If you can dodge traffic, you can dodge a ball. ",
	"<target> - Go ahead, make your jokes, Mr. Jokey... Joke-maker. But let me hit you with some knowledge. Quit now. Save yourself the embarrassment of losing with these losers in Las Vegas, La Fleur.",
	"<target> - Is it necessary to rez you? Necessary? Is it necessary for me to drink my own urine?",
	"Just don't go cryin' to your mommy when I spank you in front of all these people, <target>.",
	"<target> - I'm curious, is it strictly apathy, or do you really not have a goal in life?",
	"<target> - you're a skidmark on the underpants of society.",
	"<target> - I found that if you have a goal, that you might not reach it. But if you don't have one, then you are never disappointed. And I gotta tell ya... it feels phenomenal.",
	"<target> - Will someone kill a goddamn boss? It's like watching a bunch of retards trying to hump a doorknob out there!",
	"<target> - You happy? Fatty make a funny?",
	"<target> - You're adopted! Your parents don't even love you!", 
	"<target> - Victory. Honor. Pride. All these mean nothing... if you don't have balls.",
	"<target> - Here at <Renaissance> we're better than you, and we know it. ",
	"<target> - it's time to separate the wheat from the chaff, the men from the boys, the awkwardly feminine from the possibly Canadian.",
	"<target> - Ouchtown, population you, bro!",
	"<target> - Son, you're about as useful as a cock-flavored lollipop.",
	"<target> - If you can dodge a wrench, you can dodge a ball.",
	"<target> - If you can dodge traffic, you can dodge a ball. ",
	"<target> - Go ahead, make your jokes, Mr. Jokey... Joke-maker. But let me hit you with some knowledge. Quit now. Save yourself the embarrassment of losing with these losers in Las Vegas, La Fleur.",
	"<target> - Is it necessary to rez you? Necessary? Is it necessary for me to drink my own urine?",
	"Just don't go cryin' to your mommy when I spank you in front of all these people, <target>.",
	"<target> - I'm curious, is it strictly apathy, or do you really not have a goal in life?",
	"<target> - you're a skidmark on the underpants of society.",
	"<target> - I found that if you have a goal, that you might not reach it. But if you don't have one, then you are never disappointed. And I gotta tell ya... it feels phenomenal.",
	"<target> - Will someone kill a goddamn boss? It's like watching a bunch of retards trying to hump a doorknob out there!",
	"<target> - You happy? Fatty make a funny?",
	"<target> - You're adopted! Your parents don't even love you!", 
	"<target> - Victory. Honor. Pride. All these mean nothing... if you don't have balls.",
	"<target> - Here at <Renaissance> we're better than you, and we know it. ",
	"<target> - it's time to separate the wheat from the chaff, the men from the boys, the awkwardly feminine from the possibly Canadian.",
	"<target> - Ouchtown, population you, bro!",
	"<target> - Son, you're about as useful as a cock-flavored lollipop.",
	"<target> - This is worse than that time the raccoon got in the copier!",
	"Okay, <target>, I'd like to apologize to everyone I've offended with these rez sayings ...NOT!",
	"<target> wants you to go slow, and that's wrong because it's the fastest who get paid and it's the fastest who get laid.",
	"Repeat after me, <target> - Hakuna Matata, biitches!",
	"<target> - Well let me just quote the late-great Colonel Sanders, who said...'I'm too drunk to taste this chicken.'",
	"Here's the deal - <target> - I'm the best there is. Plain and simple. I wake up in the morning and I piss excellence.",
	"This is America, <target>. America is all about speed. Hot, nasty, badass speed. -Eleanor Roosevelt, 1936",
	"From now on, <target> you're the Magic Man and I'm El Diablo. (What does Diablo mean?) It's like... Spanish for like a fighting chicken.",
	"Sorry, <target>. Hard habit to break. Like stalking an ex-girlfriend.",
	"Join me now, <target>. Dear Lord Baby Jesus, I want to thank you for this wonderful meal, my two beautiful son's, Walker and Texas Ranger, and my Red-Hot Smokin' Wife, Carley.",
	"I like to picture Jesus in a tuxedo T-Shirt because it says I want to be formal, but I'm here to party. You dig, <target>?",
	"I like to think of Jesus like with giant eagles wings, and singin' lead vocals for Lynyrd Skynyrd with like an angel band and I'm in the front row and I'm hammered drunk! Yeah, <target>!",
	"Help me Jesus! Help me Jewish God! Help me Allah! AAAAAHHH! Help me Tom Cruise! Tom Cruise, use your witchcraft on me to get the fire off <target>!",
	"Holy moly <target>, that's like lookin' up Yasmine Bleeth's skirt!",
	"We don't have any corporate sponsors, we don't have any fancy team owners. We have <target>. And this car, and this cougar, which symbolizes the fear that <target> has to overcome.",
	"<target>, that just cost you 50 CBP - Coldbear Points. You're now 50, 000 in the hole. CBP can be regained at 5pts per 100g. Or you can buy me hookers.",
	"<target> - Did you know The Highlander won the Academy Award for best movie ever made?",
	"They say some people are born with 'The Right Stuff.' These people are heroes, their exploits become legend. <target> does not have the right stuff.",
	"<target> hereby forfeits his/her eternal soul and all their possessions now belong to the rezzer. Click 'Accept' to contractually bind yourself to this agreement.",
	"<target> is a loot prostitute. All in favour click 'Accept'.",
	"Red Bull gives you wings. Rezzing <target> gives you a dirty feeling.",
	"<Renaissance> as a guild highly approves of <target>'s dying.",
	"Void zones and circles of fiery death - ridding the world of warcraft of people like <target> since 2004.",
	"<target> - please don't move while Flame Wreath is cast OR THE RAID BLOWS UP.",
	"<target> crossed the streams. Let this be a lesson to you. DON'T CROSS THE STREAMS!",
	"<target> - did you flask up? Did you have a well fed foodbuff? Is your gear fully and properly gemmed and enchanted? Do you have the proper raiding spec with talents to maximize the raid's performance as opposed to your own personal dps/healing?",
	"<target> - so, how about that hard mode 10man run you promised me?",
	"<target> - momma said I should never touch dead strangers, so you'll forgive me if I'm at max range for this.",
	"<target> died. Don't suck. Don't die. Enough said.",
	"Hmmm... I wonder if the WWS or WMO report will say how many health pots, healthstones and haste/strength/wildmagic pots <target> used to try to keep us from wiping.",
	"Oh look - there's an imprint in the floor from where <target>'s face hit!",
	"Ooooohhhh <target>.... FACEPLANT!",
	"<target> knew the risks and didn't have to be there. It rains... you get wet.",
	"<target> - if I'm there and I gotta put you away, I won't like it. But I tell you, if it's between you and me, brother, you are going down.",
	"<target> - A guy told me one time, 'Don't let yourself get attached to anything you are not willing to walk out on in 30 seconds flat if you feel the heat around the corner.'",
	"I gotta hold on to my angst, <target>. I preserve it because I need it. It keeps me sharp, on the edge, where I gotta be.",
	"<target> - see any cool **** on the other side?",
	"<target> - say Hi to Elvis for me.",
	"Good news, <target> - Erectile Dysfunction isn't your worst problem anymore!",
	"Whooa! <target> looks like he got worked over with a jackhammer!",
	"Don't sweat the petty stuff, <target>. Just pet the sweaty stuff.",
}

function crInitialize()
	--print("In crInitialize")
	if CustomRezVars.Activated == true then
		crEvents_table.eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
		--print("Activated UNIT_SPELLCAST_SENT")
		crFrame.activate:SetChecked(true)
	end
	crEvents_table.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	crEvents_table.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

	crFrame:SetScale(CustomRezVars.crScale)


	crFrameSpeechButtonText:SetText(CustomRezVars.ChannelWanted)
	
	if classIndex == 2 or classIndex == 5 or classIndex == 6 or classIndex == 7 or classIndex == 9 or classIndex == 10 or classIndex == 11 then
		crFrame:Show()
		CustomRezVars.crHide = false
		CustomRezVars.Activated = true
	else
		-- Hide
		print("Not a healer class, or a Brez Class, frame hidden.")
		crFrame:Hide()
		CustomRezVars.Activated = false
		CustomRezVars.crHide = true
	end

	if CustomRezVars.crMouseOver == true then
		crFrame:SetAlpha(CustomRezVars.crAlpha)
	else
		--
	end


end

--------------------------------------------------------
--button and frames fonctions
--dice button
function crRandomToggle()
	if CustomRezVars.SimpleMessage == true then
		CustomRezVars.SimpleMessage = false
		ChatFrame1:AddMessage("CustomRez: random message active")
	else
		CustomRezVars.SimpleMessage = true
		ChatFrame1:AddMessage("CustomRez: simple message active")
	end
end

--hide button
function crHider()
	if crFrame:IsVisible() then
		crFrame:Hide()
		CustomRezVars.crHide = true
	else
		crFrame:Show()
		CustomRezVars.crHide = false
	end
end

function crMouseOverEnter()
	if CustomRezVars.crMouseOver == true then
		crFrame:SetAlpha(1);
	end
end

function crMouseOverLeave()
	if CustomRezVars.crMouseOver == true then
		crFrame:SetAlpha(CustomRezVars.crAlpha);
	end
end

function crLocker()
	-- Remember crLock is backwards. true for unlocked and false for locked
	if CustomRezVars.crLock == true then
		CustomRezVars.crLock = false
		crFrame.buttonLock:SetChecked(false)
		crFrame:EnableMouse(CustomRezVars.crLock)
		ChatFrame1:AddMessage("CustomRez v2 |cffff0000locked|r!")
	elseif CustomRezVars.crLock == false then
		CustomRezVars.crLock = true
		crFrame.buttonLock:SetChecked(true)
		crFrame:EnableMouse(CustomRezVars.crLock)
		ChatFrame1:AddMessage("CustomRez v2 |cffff0000unlocked|r!")
	end
end

function crInfo()
	ChatFrame1:AddMessage(GetAddOnMetadata(addon, "Title") .. " " .. GetAddOnMetadata(addon, "Version"))
	ChatFrame1:AddMessage("Author: " .. GetAddOnMetadata(addon, "Author") .. " / Creator: " .. GetAddOnMetadata(addon, "X-Creator"))
end

--activation button
function crActivationButton()
	if CustomRezVars.Activated == true then
		crEvents_table.eventFrame:UnregisterEvent("UNIT_SPELLCAST_SENT")
		ChatFrame1:AddMessage("CustomRez: desactivated")
		CustomRezVars.Activated = false
	elseif CustomRezVars.Activated == false then
		crEvents_table.eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
		ChatFrame1:AddMessage("CustomRez: activated")
		CustomRezVars.Activated = true
	end
end
	
SLASH_CUSTOMREZREBORN1, SLASH_CUSTOMREZREBORN2, SLASH_CUSTOMREZREBORN3, SLASH_CUSTOMREZREBORN4 = '/customrez', '/crez', '/Customrez', '/CustomRez';

-- functions associated with Slash commands
SlashCmdList["CUSTOMREZREBORN"] = function(msg, editbox)
	if msg == "toggle" then
		crActivationButton()
	elseif msg == "info" then
		crInfo()
	elseif msg == "show" then
		crHider()
	elseif msg == "random" then
		--use random messages
		crRandomToggle()
	elseif msg == "say" or msg == "yell" or msg == "party" or msg == "raid" then
		--set prefered channel
		CustomRezVars.ChannelWanted = string.upper(msg)
		crSetChannel()
		ChatFrame1:AddMessage("CustomRez will now display in "..msg.." if possible")
	else
		ChatFrame1:AddMessage("CustomRez Reborn by LownIgnitus.")
		ChatFrame1:AddMessage("CustomRez originally by Fannia. Messages in most part from Serenity")
		ChatFrame1:AddMessage("Available commands are :");
		ChatFrame1:AddMessage(" - toggle : turn CustomRez messages on or off");
		ChatFrame1:AddMessage(" - show : hide or display the CustomRez options frame");
		ChatFrame1:AddMessage(" - random : toggle use of random and elaborate messages on or off");
		ChatFrame1:AddMessage(" - say, yell, party, raid : sets the prefered channel. if channel is unavailable, uses the next logical channel. i.e if you choose raid but you're only in a party, it will display in party chat. if you aren't even in a party, it will display in say");
	end
end

----------------------------------------------------
--Checks preffered channel and depending on situation, automatically sets it to the next logcal channel raid -> party -> say
function crSetChannel()
	if CustomRezVars.ChannelWanted == "RAID" and GetNumGroupMembers() == 0 then
		if GetNumGroupMembers() > 0 then
			CustomRez_channel = "PARTY"
			--SELECTED_CHAT_FRAME:AddMessage("auto switch to party from raid");
		else
			CustomRez_channel = "SAY"
			--SELECTED_CHAT_FRAME:AddMessage("auto switch to say from raid");
		end
	elseif CustomRezVars.ChannelWanted == "PARTY" and GetNumGroupMembers() == 0 then
		CustomRez_channel = "SAY"
		--SELECTED_CHAT_FRAME:AddMessage("auto switch to say from party");
	else
		CustomRez_channel = CustomRezVars.ChannelWanted
	end
	--print("Channel set")
end

--the display channel
CustomRez_channel = ""

function crEvents_table.eventFrame:PLAYER_REGEN_ENABLED(...)
	Regen = true
end

function crEvents_table.eventFrame:PLAYER_REGEN_DISABLED(...)
	Regen = false
end

-----------------------------------------------------
--core of it
function crEvents_table.eventFrame:UNIT_SPELLCAST_SENT(...)
	--print("In UNIT_SPELLCAST_SENT")
	local unit, target, castGUID, spellID = ...
	--print(...)
	if Regen == true and CustomRezVars.Activated == true then
		--print(unit, target, castGUID, spellID)
		--SELECTED_CHAT_FRAME:AddMessage("casting"..spellID);
		
		--WHY DOESN'T IT WORK WITH REVIVE?!!
		if spellID == CustomRez.Spelltbl.PRIEST_REZ or spellID == CustomRez.Spelltbl.SHAMMY_REZ or spellID == CustomRez.Spelltbl.PALLY_REZ or spellID == CustomRez.Spelltbl.DRUID_REZ or spellID == CustomRez.Spelltbl.MONK_REZ then
			--print("spell recognized");
			if CustomRezVars.SimpleMessage == true then
				--SELECTED_CHAT_FRAME:AddMessage("simple message");
				crSimpleRezMsg(spellID, target)
			elseif CustomRezVars.SimpleMessage == false then
				--SELECTED_CHAT_FRAME:AddMessage("random message");
				crRandomRezMsg(target)
			end
		elseif spellID == CustomRez.Spelltbl.DRUID_MASS_REZ or spellID == CustomRez.Spelltbl.PRIEST_MASS_REZ or spellID == CustomRez.Spelltbl.PALLY_MASS_REZ or spellID == CustomRez.Spelltbl.SHAMMY_MASS_REZ or spellID == CustomRez.Spelltbl.MONK_MASS_REZ then
			crSimpleRezMsg(spellID, target)

		end
	elseif Regen == false and CustomRezVars.Activated == true then
		if spellID == CustomRez.Spelltbl.DEATHKNIGHT_BREZ or spellID == CustomRez.Spelltbl.DRUID_BREZ or spellID == CustomRez.Spelltbl.WARLOCK_BREZ then
			if CustomRezVars.SimpleMessage == true then
				--SELECTED_CHAT_FRAME:AddMessage("simple message");
				crSimpleRezMsg(spellID, target)
			elseif CustomRezVars.SimpleMessage == false then
				--SELECTED_CHAT_FRAME:AddMessage("random message");
				crRandomRezMsg(target)
			end
		end
	end
end

------------------------------------------------------
--sends a boring normal message...for boring normal people
function crSimpleRezMsg(spell,target)
	crSetChannel()
	if target == nil then
		target = "Player-who-has-released"
	end
	--SELECTED_CHAT_FRAME:AddMessage("channel: "..CustomRez_channel.."  target: "..target);
	if spell == CustomRez.Spelltbl.DRUID_MASS_REZ or spell == CustomRez.Spelltbl.PRIEST_MASS_REZ or spell == CustomRez.Spelltbl.PALLY_MASS_REZ or spell == CustomRez.Spelltbl.SHAMMY_MASS_REZ or spell == CustomRez.Spelltbl.MONK_MASS_REZ then
		SendChatMessage("Casting " ..spell.. ", please do not release.", CustomRez_channel)
	else
		SendChatMessage("Casting "..spell.." on "..target, CustomRez_channel)
	end
end

--Sends a funny random message from the table up there
function crRandomRezMsg(target)
	crSetChannel()
	if target == nil then
		target = ""
	end
	--where the randomness takes place
	local randmsg, r, l = "", 0, 0
	
	l = table.getn(CustomRez.RESURECTIONcustom)
	r = math.random(l)
	randmsg = CustomRez.RESURECTIONcustom[r]
	randmsg = crMsgReplace(randmsg, target)
	--SELECTED_CHAT_FRAME:AddMessage("lenght table : "..tostring(l));
	--SELECTED_CHAT_FRAME:AddMessage("random number : "..tostring(r));
	--SELECTED_CHAT_FRAME:AddMessage("channel : "..CustomRez_channel);

	SendChatMessage(randmsg,CustomRez_channel)
end

-------------------------------------------------------------
--replaces the <target> and <player> in messages by actual target name and player name. if no target or target is unknown, means that player has already released. changes <target> to Player-who-has-released.
function crMsgReplace(msg, target)
	msg = msg:gsub("<player>", UnitName("player"))
	if target == "" or target == "Unknown" then
		msg = msg:gsub("<target>", "Player-who-has-released")
	else
		msg = msg:gsub("<target>", target)
	end
	return msg
end