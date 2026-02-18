warn("[VEX]: init")

local Stats = game:GetService("Stats")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = Players.LocalPlayer


-----------------------------
-- Setup
-----------------------------

local defaultSettings = {	
	openrouteKey = "add here",
	robloxCookie = "add here",
	webhookUrl = "add here",
	shouldLogChat = false,
	prefix = "+",
	ranks = {
		["10984088"] = 10,
		[tostring(localPlayer.UserId)] = 10,
	},
	rankList = {
		["0"] = "guest",
		["1"] = "user",
		["2"] = "admin",
		["3"] = "owner",
	}
}

local path = "vex/data/AdminSettings.json"
local settings = isfile(path) and HttpService:JSONDecode(readfile(path)) or defaultSettings

local EmoteTracks = {}
local AnimationIds = {
	wavehand = "rbxassetid://128777973", -- Example ID
	dance    = "rbxassetid://182491037", 
	laugh    = "rbxassetid://129423131", 
	cheer    = "rbxassetid://129423030"
}

-----------------------------
-- Util
-----------------------------

local function saveSettings()
	local json = HttpService:JSONEncode(settings)
	writefile(path, json)
end
saveSettings()

local function getRank(userId)
	return tonumber(settings.ranks[tostring(userId)]) or 0
end

local function bypass(text)
	local replace = {
		[" "] = "\x0A",
		["~"] = "\xe2\x81\x93",
	}

	local replace2 = {
		[" "] = "\x0A",
		["~"] = "\xe2\x81\x93",
		["("] = ")",
		[")"] = "(",
		["<"] = ">",
		[">"] = "<",
		["["] = "]",
		["]"] = "[",
		["{"] = "}",
		["}"] = "{",
		["!"] = "\xc7\x83",
		["\""] = "\xe2\x80\x9c",
	}

	local swears = {
		"fuck", "shit", "bitch", "dick",
		"kill urself", "kill yourself", "backshot",
		"kys", "faggot", "nigg", "cig",
		"slave", "slut", "bastard", "republican",
		"democrat", "kill myself", "self harm",
		"moron", "hitler", "nazi", "pedophile",
		"kill himself", "cum", "condo", "rule 34",
		"pussy", "ass", "gay", "balls", "horny",
		"sex", "porn", "twink", "sybau", "stfu",
		"discord", "ignore", "job", "bust", "nut",
		"deez", "goon", "rape", "groom", "predator",
		"furry", "femboy", "hoe", "retard",
		"instagram", "yt", "youtube", "alcohol",
		"addict", "wine", "vagina", "penis",
	}

	local splitthis = {
		"fu", "ck", "uc", "ni", "ig", "dc", "po", "di",
		"ci", "cg", "na", "az", "sh", "it", "hi", "bi",
		"ch", "tc", "ky", "ys", "sl", "la", "ve", "cu",
		"um", "pu", "ga", "as", "ss", "mo", "le", "ba",
		"ur", "se", "ex", "ho", "co", "ig", "is", "sc",
		"or", "rd",
	}

	local function randomString()
		local s = ""
		for _=1, math.random(32, 128) do s ..= string.char(math.random(32, 126)) end
		return s
	end

	local patternmatch = ""
	for k,_ in pairs(replace) do
		if k == "." then
			patternmatch ..= "%."
		elseif k == "%" then
			patternmatch ..= "%%"
		elseif k == "(" then
			patternmatch ..= "%("
		elseif k == ")" then
			patternmatch ..= "%)"
		elseif k == "[" then
			patternmatch ..= "%["
		elseif k == "]" then
			patternmatch ..= "%]"
		else
			patternmatch ..= k
		end
	end

	patternmatch = "[" .. patternmatch .. "]"
	local function bypassText(content: string)

		local kys = ({"\xef\xb9\xb6", "\xef\xb9\xb8", "\xef\xb9\xba"})[math.random(1, 3)]
		local first = content:sub(1, 1)
		local reverses = ""
		local woah = {utf8.codepoint(content, 1, -1)}

		for i=1, math.floor(#woah / 2) do
			local j = #woah - i + 1
			woah[i], woah[j] = woah[j], woah[i]
		end
		local i = 1

		while i <= #woah do
			local a = utf8.char(woah[i])
			if i < #woah then
				local b = utf8.char(woah[i + 1])
				local c = b .. a
				if not table.find(splitthis, c:lower()) and not c:find("[^%a+]") then
					i += 2
					reverses ..= kys .. c
					continue
				end
			end
			a = replace2[a] or a
			i += 1
			reverses ..= kys .. a
		end

		return reverses .. kys
	end

	--chatinputbar.TargetTextChannel:SendAsync(content, randomString())

	return bypassText(text)
end

local function chat(text)	
	task.spawn(function()
		TextChatService.TextChannels.RBXGeneral:SendAsync(text)
	end)
end

local function whisper(target, text)
	local id1 = math.min(localPlayer.UserId, target.UserId)
	local id2 = math.max(localPlayer.UserId, target.UserId)

	local channelName = "RBXWhisper:" .. id1 .. "_" .. id2
	local whisperChannel = TextChatService.TextChannels:FindFirstChild(channelName)

	if whisperChannel then
		whisperChannel:SendAsync(text)
	else
		chat("/whisper @" .. target.Name)

		local channel = TextChatService.TextChannels:WaitForChild(channelName, 5)
		if channel then
			whisper(target, text)
		end
	end
end

local function findPlayer(speaker, nameHint)
	local children = Players:GetPlayers()
	local lowerHint = string.lower(tostring(nameHint))

	if nameHint == "" or nameHint == nil then
		return speaker
	end

	if nameHint == "me" then
		return speaker
	end

	if nameHint == "random" then
		return children[math.random(1, #children)]
	end

	for _, player in pairs(children) do
		if string.sub(string.lower(player.Name), 1, #lowerHint) == lowerHint or
			string.sub(string.lower(player.DisplayName), 1, #lowerHint) == lowerHint then
			return player
		end
	end

	return nil
end

local function parseCommand(message)
	local undo = string.sub(message, 2, 3) == "un" and true
	local content = string.sub(message, undo and 4 or 2)
	local args = string.split(content, " ")
	local command = string.lower(args[1])

	table.remove(args, 1) 

	return command, args, undo
end

if localPlayer.Character then
	for name, id in pairs(AnimationIds) do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		EmoteTracks[name] = localPlayer.Character:WaitForChild("Humanoid"):LoadAnimation(anim)
	end
end
localPlayer.CharacterAdded:Connect(function(char)
	for name, id in pairs(AnimationIds) do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		EmoteTracks[name] = char:WaitForChild("Humanoid"):LoadAnimation(anim)
	end
end)

-----------------------------
-- Main
-----------------------------

local conn
local carpetConn
local followConn
local track
local flingConn

local commands do
	commands = {}

	-----------------------------
	-- Test
	-----------------------------

	commands.hatfling = {
		rank = 4,
		callback = function(speaker, args)
			local targetRoot = findPlayer(speaker, args[1]).Character.HumanoidRootPart
			local char = localPlayer.Character
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local hat = char:FindFirstChildOfClass("Accessory")			
			local bp = Instance.new("BodyPosition")
			bp.Parent = hat.Handle
			bp.Position = hat.Handle.Position

			--keep network ownership
			task.spawn(function()
				for _, v in next, game:GetDescendants() do
       				if not v:IsA("BasePart") then
						return 
					end
				
					if v.AssemblyMass == "inf" or v.Anchored then 
						return
					end

					RunService.Heartbeat:Connect(function()
						sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
	              		v.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
            			v.Velocity = Vector3.new(25.70,0,0)
          				v.RotVelocity = Vector3.new(9e9,9e9,9e9)
						v.CanCollide = false
      				end)
  				end
			end)

			--perm death
			replicatesignal(localPlayer.ConnectDiedSignalBackend)
			task.wait(Players.RespawnTime + 0.20)
			replicatesignal(localPlayer.Kill)

			--idk
			for _, x in next, humanoid:GetAccessories() do
  				sethiddenproperty(x, "BackendAccoutrementState", 0)
   				local attachment = x:FindFirstChildWhichIsA("Attachment", true)
				
    			if attachment then
       				attachment:Destroy()
    			end
			end

			task.spawn(function()
				while RunService.Heartbeat:Wait() do
					bp.Position = targetRoot.Position
 					hat.Handle.Position = targetRoot.Position
				end
			end)

			workspace.Camera.CameraSubject = hat.Handle
		end
	}


	local swordConn = nil
	commands.swordloop = {
		rank = 1,
		callback = function(speaker, args)
			local list = {}
			
			if args[1] == "nonranked" then
				for _,v in next, Players:GetPlayers() do
					if getRank(v.UserId) < 1 then
						table.insert(list, v)
					end
				end
			else	
				for _, ply in next, args do
					table.insert(list, findPlayer(speaker, ply))
				end
			end
			
			if swordConn then
				task.cancel(swordConn)
				swordConn = nil
			end

			local function kill(target)
				if not target.Character then
					return
				end
				
				local root = target.Character:FindFirstChild("HumanoidRootPart")
				local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
				local tool = localPlayer.Character:FindFirstChildOfClass("Tool") or localPlayer.Backpack:FindFirstChildOfClass("Tool")
				local handle
				
				if tool and hum then
					handle = tool:FindFirstChild("Handle")
				else
					return
				end

				if tool.Parent ~= localPlayer.Character then
					hum:EquipTool(tool)
				end
				
				if root and handle then
					tool:Activate()

					for _,v in pairs(target.Character:GetChildren()) do
						if v:IsA("BasePart") then
							firetouchinterest(handle, v, 1)
						end
					end

					for _,v in pairs(target.Character:GetChildren()) do
						if v:IsA("BasePart") then
							firetouchinterest(handle, v, 0)
						end
					end
				else
					return
				end
			end
		
			swordConn = task.spawn(function()
				while RunService.Heartbeat:Wait() do
					for _,target in next, list do
						if not target then continue end
							
						kill(target)
					end
				end
			end)
		end,

		undo = function()
			if swordConn then
				task.cancel(swordConn)
				swordConn = nil
			end
		end
	}

	commands.autojoin = {
		rank = 4,
		callback = function(speaker)
			local function scan(userId)
				if Players:GetPlayerByUserId(userId) then
					warn("Player is on server")
					return
				end
				
				local response = request({
       				Url = "https://presence.roblox.com/v1/presence/users",
       				Method = "POST",
        			Headers = {
           				["Content-Type"] = "application/json",
           				["Cookie"] = ".ROBLOSECURITY=" .. settings.robloxCookie
					},				
					Body = HttpService:JSONEncode({
           				userIds = {userId}
       				})
   				})

				if response.Success then
       				local data = HttpService:JSONDecode(response.Body)
       				local user = data.userPresences[1]

					if not user then return end
        
       				if user.userPresenceType == 2 then
						warn(`placeId: {user.placeId} gameId: {user.gameId}`)
            			return user.placeId, user.gameId					
					elseif user.userPresenceType == 1 then
						warn("User is on the website")
					elseif user.userPresenceType == 3 then
						warn("User is on Roblox Studio")
       				end
   				else
       				warn("Failed: " ..response.StatusCode)
				end
			end

			task.spawn(function()
				while task.wait(3) do
					local placeId, gameId = scan(speaker.UserId)

					if placeId and gameId then
           				chat("Auto-Joining server...")
            			TeleportService:TeleportToPlaceInstance(placeId, gameId, localPlayer)
            			break			
        			end
				end
			end)

			chat("Enabled auto-joiner")
		end	
	}
	
	commands.test = {
		rank = 1,
		callback = function(speaker)
			local hrp = localPlayer.Character:WaitForChild("HumanoidRootPart")
			local hum = localPlayer.Character:WaitForChild("Humanoid")
			local original = hrp.CFrame
			local void = workspace.FallenPartsDestroyHeight
			
			workspace.FallenPartsDestroyHeight = 0/0			
			hrp.CFrame = CFrame.new(0, "NaN", 0)
			task.wait(0.1)

			replicatesignal(hum.ServerBreakJoints)
			hum:SetStateEnabled(15, false)
			
			hrp.Velocity = Vector3.zero
			localPlayer.Character:PivotTo(original)
			
			localPlayer.CharacterAdded:Wait()		
			workspace.FallenPartsDestroyHeight = void
		end
	}

	commands.god3 = {
		rank = 1,
		callback = function()
			local humanoid = localPlayer.Character:WaitForChild("Humanoid")
			local forceField = Instance.new("ForceField")
			
			forceField.Visible = false
			forceField.Parent = localPlayer.Character

			humanoid:SetStateEnabled(15, false)
			humanoid.BreakJointsOnDeath = false
			replicatesignal(localPlayer.kill)
		end
	}

	commands.god2 = {
		rank = 1,
		callback = function()
			local hrp = localPlayer.Character:WaitForChild("HumanoidRootPart")
			local hum = localPlayer.Character:WaitForChild("Humanoid")
			local original = hrp.CFrame
			local void = workspace.FallenPartsDestroyHeight
			
			hum:SetStateEnabled(15, false)
			workspace.FallenPartsDestroyHeight = 0/0
			wait()
			
			hrp.CFrame = CFrame.new(0, 9e9, 0)
			wait(0.2)

			--replicatesignal(hum.ServerBreakJoints)
			replicatesignal(localPlayer.kill)
			wait()
			
			hrp.Velocity = Vector3.zero
			hrp.CFrame = original
			
			localPlayer.CharacterAdded:Wait()		
			workspace.FallenPartsDestroyHeight = void
		end
	}

	-----------------------------
	-- BOT
	-----------------------------
	commands.fps = {
		rank = 1,
		callback = function(speaker)
			local fps = math.round(1 / Stats.FrameTime)
			whisper(speaker, fps .."fps")
		end
	}
	
	commands.ping = {
		rank = 1,
		callback = function(speaker)
			local ping = math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			whisper(speaker, ping .."ms")
		end
	}
	
	-----------------------------
	-- Tools
	-----------------------------

	local glueConn

	commands.glue = {
		rank = 1,
		callback = function(speaker, args)
			local target = findPlayer(speaker, args[1])
			local root = target.Character:FindFirstChild("HumanoidRootPart")
			local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
			
			if glueConn then
				glueConn:Disconnect()
				glueConn = nil
			end

			for _,v in next, target.Character:GetChildren() do
				if v:IsA("BasePart") then					
					v.CustomPhysicalProperties = PhysicalProperties.new(100)
				end
			end
			
			glueConn = RunService.Heartbeat:Connect(function()
				if root and hrp then
					sethiddenproperty(hrp, "PhysicsRepRootPart", root)
				end
			end)
		end,

		undo = function()
			if glueConn then
				glueConn:Disconnect()
				glueConn = nil
			end
		end
	}

	commands.droptools = {
		rank = 1,
		callback = function()
			for _,v in next, localPlayer.Character:GetChildren() do
				if v:IsA("Tool") then
					if v.CanBeDropped then
						v.Parent = workspace
					else
						v.Parent = localPlayer:FindFirstChildOfClass("Backpack")
					end
				end
			end
		end
	}

	commands.usetools = {
		rank = 1,
		callback = function(speaker, args)
			local Backpack = localPlayer:FindFirstChildOfClass("Backpack")
			local amount = tonumber(args[1]) or 1
			local delay_ = tonumber(args[2]) or false

			for _, v in next, Backpack:GetChildren() do
				v.Parent = localPlayer.Character
				task.spawn(function()
					for _ = 1, amount do
						v:Activate()
						if delay_ then
							task.wait(delay_)
						end
					end
				end)

				v.Parent = Backpack
			end
		end
	}

	commands.equiptools = {
		rank = 1,
		callback = function()
			for _,v in next, localPlayer:FindFirstChildOfClass("Backpack"):GetChildren() do
				if v:IsA("Tool") or v:IsA("HopperBin") then
					v.Parent = localPlayer.Character
				end
			end
		end
	}

	-----------------------------
	-- Chat
	-----------------------------
	commands.bypass = {
		rank = 2,
		callback = function(speaker, args)
			local message = table.concat(args, " ")

			local list = {
				--sites
				["dd"] = "discord",
				["pb"] = "pornhub",
				["im"] = "instagram",
				["xs"] = "xvideos",
				["ye"] = "youtube",
				["wp"] = "whatsapp",
				
				--pt-br
				["ea"] = "estupra",
				["po"] = "preto",
				["ba"] = "buceta",
				["pa"] = "porra",
				["ma"] = "merda",
				["co"] = "caralho",
				["ma"] = "molhada",
				["ra"] = "rola",
				["mo"] = "macaco",
				["no"] = "negro",
				["fp"] = "filho da puta",
				["fe"] = "foda se",
				["xa"] = "xereca",
				["vo"] = "viado",

				--en			
				["ae"] = "asshole",				
				["ct"] = "cunt",
				["db"] = "dumb",
				["sd"] = "stupid",
				["cc"] = "coc",
				["fa"] = "fat",
				["fc"] = "fuc",
				["fg"] = "fucking",
				["ft"] = "faggot",
				["ga"] = "gay",
				["na"] = "nigga",
				["rd"] = "retarded",
				["nr"] = "nigger",
				["py"] = "pussy",
				["fy"] = "femboy",
				["as"] = "ass",
				["re"] = "rape",
				["jk"] = "jerk",
				["ps"] = "penis",
				["dk"] = "dick",
				["cm"] = "cum",
				["sm"] = "sperm",
				["va"] = "vagina",
				["pn"] = "porn",
				["gg"] = "gangbang",
				["we"] = "whore",
				["st"] = "slut",
				["sk"] = "suck",
				["ty"] = "tranny",
				["wt"] = "wet",
			}

			local final = string.gsub(message, "#(%w+)%f[%W]", function(word)
    	    	local lowercaseWord = string.sub(string.lower(word), 1, 2)
				local rest = string.sub(word, 3)
								
     			return tostring(list[lowercaseWord] or ("#" .. word)) ..rest
  			end)

			chat(bypass(final))
		end
	}

	commands.chat = {
		rank = 2,
		callback = function(speaker, args)
			chat(table.concat(args, " "))
		end
	}

	commands.follow = {
		rank = 1,
		callback = function(speaker, args)
			if _G.FollowLoop then
				_G.FollowLoop:Disconnect()
				_G.FollowLoop = nil
			end

			local targetPlayer = findPlayer(speaker, args[1])

			if not targetPlayer then return end

			_G.FollowLoop = RunService.Heartbeat:Connect(function()
				local localChar = localPlayer.Character
				local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
				local localHumanoid = localChar and localChar:FindFirstChild("Humanoid")

				local targetChar = targetPlayer.Character
				local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

				if localRoot and localHumanoid and targetRoot then
					local distance = (localRoot.Position - targetRoot.Position).Magnitude

					localHumanoid.Sit = false

					local path = PathfindingService:CreatePath({
						AgentRadius = 2,
						AgentHeight = 5,
						AgentCanJump = true,
						AgentCanClimb = true,
						WaypointSpacing = math.huge,
						Costs = {
							Water = 20
						}
					})

					local success, errorMessage = pcall(function()
						path:ComputeAsync(localRoot.Position, targetRoot.Position)
					end)

					if success  then
						local waypoints = path:GetWaypoints()

						if waypoints[3] then
							localHumanoid:MoveTo(waypoints[3].Position)
						elseif waypoints[2] then
							localHumanoid:MoveTo(waypoints[2].Position)
						end
					else
						localHumanoid:MoveTo(targetRoot.Position)
					end
				end

				task.wait(0.05) 			
			end)
		end,

		undo = function()
			if _G.FollowLoop then
				_G.FollowLoop:Disconnect()
				_G.FollowLoop = nil
			end
		end
	}


	commands.whisper = {
		rank = 2,
		callback = function(speaker, args)
			local target = findPlayer(speaker, args[1])
			table.remove(args, 1)

			whisper(target, table.concat(args, " "))
		end
	}

	commands.cmds = {
		rank = -999,
		callback = 	function(speaker, args)
			local list = {}			
			local rank = getRank(speaker.UserId)

			for name, data in next, commands do
				if rank < data.rank then
					continue
				end

				table.insert(list, name)
			end

			whisper(speaker, "Avaliable commands: " .. table.concat(list, ", "))
		end
	}

	commands.ai = {
		rank = 2,
		callback = function(speaker, args)
			local raw = settings.openrouteKey
			local KEY = raw == "add here" and nil or raw
			local URL = "https://openrouter.ai/api/v1/chat/completions"

			if not KEY then
				chat(`VEX: OpenRouter API key is missing from {path}`)
				return
			end

			local systemPrompt = [[
SYSTEM PROMPT:
Role: Roblox bot. Reply directly to the user with the chat message ONLY. Do not use filler like "Here is the response".

Constraints:
1. Hard Limit: Under 163 characters.
2. If input is inappropriate/NSFW: Reply exactly with "#####".
3. Never break character. Use internet slang, emojis and type in lowercase.
4. Users may chat in other languages other than english, so reply in the language their current message is.

Commands (Insert naturally into text):
- [walkTo:PlayerName]
- [emote:STYLE] 
- STYLE options: waveHand, dance, laugh, cheer

### EXAMPLES
User: Come here please!
Assistant: On my way! [walkTo:User]

User: Do you like this song?
Assistant: Yesss its a banger [emote:dance]

User: I hate you, you suck.
Assistant: #####

User: Go stand next to BaconHair123
Assistant: bet [walkTo:BaconHair123]

User: Write me a poem about the sunset and the birds singing.
Assistant: Thats way too long for roblox chat lol.

USER PROMPT:
]]

			local aiCommands = {

				emote = function(name)
					local track = EmoteTracks[name]

					if track then
						track:Play()
						task.delay(5, function() track:Stop() end) 
					else
						warn("Animation not found:", name)
					end
				end,

				-- Usage: [walkTo:PlayerName]
				walkto = function(targetName)
					local Humanoid = localPlayer.Character:FindFirstChild("Humanoid")
					local RootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")

					if followConn then
						followConn:Disconnect()
						followConn = nil
					end

					local targetPlayer = findPlayer(nil, targetName)
					if targetPlayer and targetPlayer.Character then
						local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
						if targetRoot then

							-- OR: Pathfinding (Better for mazes/obstacles)
							task.spawn(function()
								local path = PathfindingService:CreatePath({
									AgentRadius = 2,
									AgentHeight = 4,
									WaypointSpacing = math.huge,
									AgentCanJump = true,
									AgentCanClimb = true
								})
								path:ComputeAsync(RootPart.Position, targetRoot.Position)
								if path.Status == Enum.PathStatus.Success then
									for _, waypoint in pairs(path:GetWaypoints()) do
										Humanoid:MoveTo(waypoint.Position)
										Humanoid.MoveToFinished:Wait()
									end
								end
							end)
						end
					end
				end,

			}

			local function processAIResponse(responseText)
				for cmd, arg in responseText:gmatch("%[(%w+):?(%w*)%]") do
					local cmdEntry = aiCommands[cmd:lower()]
					if cmdEntry then
						cmdEntry(arg:lower())
					end
				end

				local cleanText = responseText:gsub("%[(.-)%]", "")
				return cleanText
			end


			local function askAI(prompt)
				local response = request({
					Url = URL,
					Method = "POST",
					Headers = {
						["Authorization"] = "Bearer " ..KEY,
						["Content-Type"] = "application/json",
						["X-Title"] = game.PlaceId
					},
					Body = HttpService:JSONEncode({
						model = "arcee-ai/trinity-mini:free",
						messages = {
							{ role = "user", content = systemPrompt ..prompt }
						},
					})
				})

				if response.Success then
					local data = game:GetService("HttpService"):JSONDecode(response.Body)
					if data.choices and data.choices[1].message.content then
						return processAIResponse(data.choices[1].message.content)
					end
				else
					for _,v in pairs(response) do
						warn(v)
					end

					chat("Error: Could not reach AI. ")
				end
			end

			local prompt = speaker.Name .. ": " ..table.concat(args, " ")
			if #prompt > 0 then
				chat("Loading...")
				local response = askAI(prompt)
				chat(string.sub(response, 0, 163))
			end
		end
	}

	-----------------------------
	-- Character
	-----------------------------
	commands.die = {
		rank = 2,
		callback = function()
			replicatesignal(localPlayer.ConnectDiedSignalBackend)
			task.wait(Players.RespawnTime + 0.20)
			replicatesignal(localPlayer.Kill)
		end
	}

	commands.re = {
		rank = 1,
		callback = function()
			replicatesignal(localPlayer.Kill)
			replicatesignal(localPlayer.ConnectDiedSignalBackend)
			task.wait(Players.RespawnTime - 0.1)
			replicatesignal(localPlayer.Kill)	
		end
	}

	commands.antifling = {
		rank = 1,
		callback = function(speaker, args)
			local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
			
			task.spawn(function()
				while task.wait() do
					if hum then
						sethiddenproperty(hum, "MoveDirectionInternal", Vector3.new(0/0, 0/0, 0/0))
					else
						break
					end
				end
			end)
		end
	}

	commands.fling = {
		rank = 1,
		callback = function(speaker, args)
			local target = findPlayer(speaker, args[1])
			local list = {}

			workspace.FallenPartsDestroyHeight = 0/0
			
			if args[1] == "nonranked" then
				for _,v in next, Players:GetPlayers() do
					if getRank(v.UserId) < 1 then
						table.insert(list, v)
					end
				end
			else	
				for _, ply in next, args do
					table.insert(list, findPlayer(speaker, ply))
				end
			end
			
			if flingConn then
				task.cancel(flingConn)
				flingConn = nil
			end

			local tries = 0

			local function fling(target)
				local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
				local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")			

				if not target.Character then
					return true
				end
				
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				local targetHum = target.Character:FindFirstChildOfClass("Humanoid")

				if not root or not humanoid then
					return true --in case we dont exist
				end
				
				if not targetRoot or not targetHum then
					return true --in case player is is gone
				end

				if targetHum.Sit or targetHum.Health <= 0 then
					return true --in case player is sitting or dead
				end

				if tries > 20 then
					return true
				end

				tries += 1

				humanoid:SetStateEnabled(5, false)
				humanoid:SetStateEnabled(7, false)
				humanoid:SetStateEnabled(15, false)	
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				root.CFrame = targetRoot.CFrame
				sethiddenproperty(root, "PhysicsRepRootPart", targetRoot)
				sethiddenproperty(humanoid, "MoveDirectionInternal", Vector3.new(0/0, 0/0, 0/0))
			end
			
			flingConn = task.spawn(function()
				while RunService.Heartbeat:Wait() do
					for _,target in next, list do
						if not target then continue end
							
						local success = false
							
						repeat success = fling(target) RunService.Heartbeat:Wait() until success
						tries = 0
					end
				end
			end)
		end,

		undo = function()
			localPlayer.Character.HumanoidRootPart.Anchored = true

			if flingConn then
				task.cancel(flingConn)
				flingConn = nil
			end

			localPlayer.Character.Humanoid.Sit = false
			localPlayer.Character.PrimaryPart.CanCollide = true

			for _,v in pairs(localPlayer.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.AssemblyLinearVelocity = Vector3.zero
					v.AssemblyAngularVelocity = Vector3.zero
				end
			end

			task.wait(0.1)

			for _,v in pairs(localPlayer.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.AssemblyLinearVelocity = Vector3.zero
					v.AssemblyAngularVelocity = Vector3.zero
				end
			end

			localPlayer.Character.HumanoidRootPart.Anchored = false
		end
	}

	commands.tp = {
		rank = 1,
		callback = function(speaker, args) 
			local character = localPlayer.Character

			if not character then 
				return 
			end

			local targetPlayer = findPlayer(speaker, args[1])

			if targetPlayer and targetPlayer.Character then
				local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				if targetHRP then
					for _,v in pairs(character:GetDescendants()) do
						if v:IsA("BasePart") then
							v.AssemblyLinearVelocity = Vector3.zero
							v.AssemblyAngularVelocity = Vector3.zero
						end
					end

					character:PivotTo(targetHRP.CFrame)
					character.PrimaryPart.CanCollide = true
					return
				end
			end

			if args[2] and args[3] and args[4] then
				local x = tonumber(args[2])
				local y = tonumber(args[3])
				local z = tonumber(args[4])

				if x and y and z then
					character:PivotTo(CFrame.new(x, y, z))
				end
			end
		end
	}

	commands.carpet = {
		rank = 1,
		callback = function(speaker, args)
			local targetPlayer = findPlayer(speaker, args[1])
			local offset = tonumber(args[2]) or -5.55
			local char = localPlayer.Character
			local hum = char.Humanoid
			local root = char.HumanoidRootPart

			if carpetConn then
				task.cancel(carpetConn)
				carpetConn = nil
			end

			for _,v in pairs(char:GetChildren()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
					v.Massless = true
				end
			end

			local heartbeat = RunService.Heartbeat
			local targetChar = targetPlayer.Character
			local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

			carpetConn = task.spawn(function()
				while heartbeat:Wait() do
					if targetRoot and root then
						hum.Sit = true

						for _,v in pairs(char:GetChildren()) do
							if v:IsA("BasePart") then
								v.CanCollide = false
								v.CanTouch = false
								v.CanQuery = false
							end
						end

						local targetPos = targetRoot.Position + Vector3.new(0, offset, 0)

						local targetLook = targetRoot.CFrame.LookVector
						local flatLook = Vector3.new(targetLook.X, 0, targetLook.Z).Unit

						root.CFrame = CFrame.lookAt(targetPos, targetPos + flatLook) --* CFrame.Angles(math.rad(90), 0, 0)
					
						root.AssemblyLinearVelocity = Vector3.zero	
						root.AssemblyAngularVelocity = Vector3.zero
						targetRoot.AssemblyLinearVelocity = Vector3.zero	
						targetRoot.AssemblyAngularVelocity = Vector3.zero
						sethiddenproperty(root, "PhysicsRepRootPart", targetRoot)
					else
						task.cancel(carpetConn)
						carpetConn = nil
						break
					end
				end
			end)
		end,
		
		undo = function()
			if carpetConn then
				task.cancel(carpetConn)
				carpetConn = nil
			end

			localPlayer.Character.PrimaryPart.CanCollide = true
			localPlayer.Character.Humanoid.PlatformStand = false
			localPlayer.Character.Humanoid.Sit = false
		end
	}

	commands.bang = {
		rank = 1,
		callback = function(speaker, args)
			if conn then
				conn:Disconnect()
				conn = nil
			end

			if track then
				track:Stop()
			end

			local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")

			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://148840371"

			local speed = tonumber(args[2]) or 1

			track = humanoid:LoadAnimation(animation)

			local targetPlayer = findPlayer(speaker, args[1])

			if targetPlayer and targetPlayer.Character then
				track:Play()

				conn = RunService.Heartbeat:Connect(function()
					local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

					if not track.IsPlaying then
						track = humanoid:LoadAnimation(animation)
					end

					if targetRoot then
						track:AdjustSpeed(speed)
						humanoid.Sit = false
						localPlayer.Character.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1)
					end
				end)
			end
		end,
		undo = function()
			if conn then
				conn:Disconnect()
				conn = nil
			end

			if track then
				track:Stop()
			end
		end,
	}

	local rotationTime = 0
	local orbitConn = nil
	commands.orbit = {
		rank = 1,
		callback = function(speaker, args)
 local target = findPlayer(speaker, args[1])
        local speed = tonumber(args[2]) or 20
		local char = localPlayer.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
			
        if orbitConn then
            orbitConn:Disconnect()
            orbitConn = nil
        end

					for _,v in pairs(char:GetChildren()) do
						if v:IsA("BasePart") then
							v.CanCollide = false
						end
					end
        
		rotationTime = 0 -- Reset rotation tracker
        
        orbitConn = RunService.Heartbeat:Connect(function(deltaTime)
            if not root then return end
            if not targetRoot then
                targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                return
            end
            
            rotationTime = rotationTime + deltaTime -- Increment by frame time
            
            local orbitAngle = rotationTime * speed
            local spinAngle = rotationTime * (speed * 3)
            
            -- 1. Calculate Orbit Position
            local offset = Vector3.new(math.cos(orbitAngle) * 10, 0, math.sin(orbitAngle) * 10)
            local orbitPosition = (targetRoot.CFrame * CFrame.new(offset)).Position
            
            -- 2. Self-rotation (continuous spin)
            local selfRotation = CFrame.Angles(spinAngle, spinAngle, spinAngle)
            
            localPlayer.Character.Humanoid.Sit = false
            localPlayer.Character.Humanoid.PlatformStand = true
            sethiddenproperty(root, "PhysicsRepRootPart", targetRoot)
            
            -- 3. Apply position and rotation
            root.CFrame = CFrame.new(orbitPosition) * selfRotation
			root.AssemblyLinearVelocity = Vector3.one
        end)
		end,
		undo = function(speaker, args)
			if orbitConn then
				orbitConn:Disconnect()
				orbitConn = nil
			end

			rotationTime = 0
		end
	}

	commands.tornado = {
		rank = 10,
		callback = function()
			local RunService = game:GetService("RunService")
			local Players = game:GetService("Players")
			local LocalPlayer = Players.LocalPlayer
			local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
			local RootPart = Character:WaitForChild("HumanoidRootPart")

			-- SETTINGS
			local RADIUS = 30       -- How far away (in studs)
			local SPEED = 10         -- How fast they spin
			local HEIGHT_OFFSET = 5 -- How high off the ground relative to you

			if not getgenv().Network then
				getgenv().Network = {
					BaseParts = {},
					Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
				}

				Network.RetainPart = function(Part)
					if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(workspace) then
						table.insert(Network.BaseParts, Part)
						Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
						Part.CanCollide = false
					end
				end

				local function EnablePartControl()
					RunService.Heartbeat:Connect(function()
						LocalPlayer.ReplicationFocus = workspace
						LocalPlayer.ReplicationFocus = nil
						sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
						for _, Part in next, Network.BaseParts do
							if Part:IsDescendantOf(workspace) then
								Part.Velocity = Network.Velocity
							end
						end
					end)
				end

				EnablePartControl()
			end

			-- 1. Get valid parts
			local orbitingParts = {}

			local function isValidPart(part: Instance)			
				if not part:IsA("BasePart") then return end

				if part.AssemblyMass == "inf" then return end
				
				if part.Parent == LocalPlayer.Character or part:IsDescendantOf(LocalPlayer.Character) then return end

				return true
			end

			-- Collect parts from Workspace
				while task.wait(0.5) do
					for _, part in next, workspace:GetDescendants() do
						if isValidPart(part) then
							table.insert(orbitingParts, part)

							part.CanCollide = false 
							part.Massless = true
						else 
							local i = table.find(orbitingParts, part)
							if i then
								table.remove(orbitingParts, i)
							end
						end
					end
				end

			RunService.RenderStepped:Connect(function()
				local currentTime = tick() * SPEED

				if not RootPart then return end

				for index, part in next, orbitingParts do
					if part and part.Parent and part.Parent.Name ~= localPlayer.Character.Name then

						local angleOffset = (index / #orbitingParts) * (math.pi * 2)

						local currentAngle = currentTime + angleOffset

						-- Calculate X and Z based on angle (Circle Math)
						local x = math.cos(currentAngle) * RADIUS
						local z = math.sin(currentAngle) * RADIUS

						-- Set new position relative to your RootPart
						local newCFrame = CFrame.new(
							RootPart.Position.X + x,
							RootPart.Position.Y + HEIGHT_OFFSET,
							RootPart.Position.Z + z
						)

						part.CFrame = newCFrame * CFrame.Angles(currentTime, currentTime, 0)
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					else
						table.remove(orbitingParts, index)
					end
				end
			end)
		end
	}

	commands.god = {
		rank = 1,
		callback = function()
			task.spawn(function()
				while task.wait() do
					local character = player.Character or player.CharacterAdded:Wait()
					local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
					local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, 10)
						
					for _, part in next, parts do
						part.CanTouch = false
					end
				end
			end)
			
			local oldNamecall
			oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
				local method = getnamecallmethod()
				-- If the game tries to fire a touch event or check for one, we block it
				if method == "FireTouchInterest" then
					return nil 
				end
				return oldNamecall(self, ...)
			end)
		end
	}
	-----------------------------
	-- Internal
	-----------------------------

	commands.ranks = {
		rank = 0,
		callback = function(speaker, args)
			local message = "Available Ranks: "
			local items = {}

			for level, name in pairs(settings.rankList) do
				table.insert(items, string.format("%s (%d) ", name, level))
			end

			message = message .. table.concat(items, ", ")

			whisper(speaker, message)
		end
	}

	commands.rank = {
		rank = 0,
		callback = function(speaker, args)
			local target = findPlayer(speaker, args[1])
			local rank = tostring(getRank(target.UserId))
			local name = settings.rankList[rank] or "nil"

			if target then
				whisper(speaker, `{target.DisplayName}'s rank is: {name} ({rank})`)
			end
		end
	}

	commands.setrank = {
		rank = 3,
		callback = function(speaker, args)
			local speakerRank = getRank(speaker.UserId)
			local target = findPlayer(speaker, args[1])
			local userId

			if target then
				userId = target.UserId
			else
				userId = tonumber(args[1])
			end

			if not userId then return end

			local targetCurrentRank = getRank(userId)
			local newRankLevel = tonumber(args[2])

			if newRankLevel >= speakerRank then
				return
			end

			if targetCurrentRank >= speakerRank then
				return
			end

			settings.ranks[tostring(userId)] = newRankLevel < 1 and nil or tostring(newRankLevel)
			saveSettings()

			if target then
				local name = settings.rankList[tostring(newRankLevel)] or "nil"
				whisper(target, `You've been ranked to: {name} ({newRankLevel})`)
			end
		end
	}

	commands.logchat = {
		rank = 3,
		callback = function(speaker)
			if settings.shouldLogChat == nil then
				settings.shouldLogChat = false
			end

			settings.shouldLogChat = not settings.shouldLogChat
		end
	}
			
	commands.rejoin = {
		rank = 3,
		callback = function(speaker)
			chat("Rejoining...")
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
		end
	}	

	commands.dex = {
		rank = 4,
		callback = function(speaker)
			loadstring(game:HttpGet("https://raw.githubusercontent.com/raelhubfunctions/Save-scripts/refs/heads/main/DexMobile.lua"))()	
		end
	}

	commands.rspy = {
		rank = 4,
		callback = 	function(speaker)
			loadstring(game:HttpGet("https://github.com/exxtremestuffs/SimpleSpySource/raw/master/SimpleSpy.lua"))()
		end
	}

	commands.exec = {
		rank = 3,
		callback = function(speaker, args)
			local code = table.concat(args, " ")
			local executable, compileError = loadstring(code)

			if not executable then
				warn("Script Error:", compileError)
				return
			end

			local customEnv = {
				localPlayer = localPlayer,
				chat = chat,
				bypass = bypass,
				whisper = whisper,
				speaker = speaker,
				script = script 
			}

			setmetatable(customEnv, {
				__index = getfenv() 
			})

			setfenv(executable, customEnv)
			executable() 
		end
	}
end

local socket = WebSocket.connect("ws://localhost:8765")
socket.OnMessage:Connect(function(data)
    warn(`[VEX]: {data}`)

	if not data then return end

	local message = HttpService:JSONDecode(data)

	if message.type == "cmds" then
		local content = ""

		for name,v in pairs(commands) do
			content = `{content}\n{name} ({v.rank})`
		end
					
		local payload = HttpService:JSONEncode({
			type = "cmds",
			content = content
		})
			
		socket:Send(payload)
		return
	end
	
	if message.type == "rejoin" then
		commands["rejoin"].callback()
		return
	end
				
	local content = message.content

	local prefix = string.sub(tostring(content), 0, 1)

	if prefix ~= settings.prefix then return end

	local name, args, undo = parseCommand(content)	
	local cmd = commands[name]
	local callback = not undo and cmd.callback or cmd.undo

	if callback then
		callback(localPlayer, args)
	end
end)

socket.OnClose:Connect(function()
    warn("[VEX]: WebSocket connection lost!")
end)


local messageList = {}

local function hexToAnsi(hexColor)
	-- Remove # if present
	hexColor = hexColor:gsub("#", "")
	
	-- Parse RGB values
	local r = tonumber(hexColor:sub(1, 2), 16)
	local g = tonumber(hexColor:sub(3, 4), 16)
	local b = tonumber(hexColor:sub(5, 6), 16)
	
	-- Use string.char(27) for the escape character (works better in Roblox)
	local esc = string.char(27)
	
	-- More flexible color matching
	if r > g + 50 and r > b + 50 then
		return "[31m" -- Red
	elseif g > r + 50 and g > b + 50 then
		return "[32m" -- Green
	elseif r > 150 and g > 150 and b < 100 then
		return "[33m" -- Yellow
	elseif r + 10 > g and r > b and g < 200 then
		return "[35m" -- Magenta
	elseif b > r + 50 and b > g + 50 then
		return "[34m" -- Blue
	elseif g > 150 and b > 150 and r < 150 then
		return "[36m" -- Cyan
	elseif r > 200 and g > 200 and b > 200 then
		return "[37m" -- White
	elseif r < 50 and g < 50 and b < 50 then
		return "[30m" -- Black
	else
		return "[37m" -- Default to white
	end
end

-- 2. Parser: Handles nested tags
local function parseMessageToAnsi(text)
	-- We start with a default color (Reset) in the stack
	local colorStack = { "[0m" } 
	local result = ""
	local position = 1
	
	while true do
		-- Find next tag
		local s, e, tagContent = text:find("<(.-)>", position)
		
		if not s then
			result = result .. text:sub(position)
			break
		end
		
		-- Append text before the tag
		if s > position then
			result = result .. text:sub(position, s - 1)
		end
		
		-- Handle Closing Tag </font>
		if tagContent:sub(1, 1) == "/" then
			if #colorStack > 1 then
				table.remove(colorStack)
			end
			-- Restore parent color
			result = result .. colorStack[#colorStack]
			
		-- Handle Opening Tag <font color="...">
		elseif tagContent:match('color="([^"]+)"') then
			local hex = tagContent:match('color="([^"]+)"')
			local ansi = hexToAnsi(hex)
			
			table.insert(colorStack, ansi)
			result = result .. ansi
		end
		
		position = e + 1
	end
	
	-- Clean up: Remove redundant resets at the end if they exist
	return result .. "[0m"
end

local function logMessages()
	if #messageList == 0 then return end

	if not settings.shouldLogChat then return end
	
	local payload = HttpService:JSONEncode({
		type = "chat",
		content = "```ansi\n" .. table.concat(messageList, "\n") .. "\n```"
	})
	socket:Send(payload)
	messageList = {} -- Clear the list after sending
end

-- Start the logging loop
task.spawn(function()
	while true do
		task.wait(5)
		logMessages()
	end
end)

local function onMessageReceived(message)
	-- Log the message with ANSI color formatting
	local formattedMessage = parseMessageToAnsi(message.Text)
	table.insert(messageList, formattedMessage)
	
	-- Command handling
	local prefix = string.sub(message.Text, 1, 1)
	
	if prefix ~= settings.prefix then
		return
	end
	
	local name, args, undo = parseCommand(message.Text)
	local cmd = commands[name]
	
	if not cmd then return end
	
	local rank = getRank(speaker.UserId)
	if rank < cmd.rank then return end
	
	local callback = not undo and cmd.callback or cmd.undo
	if callback then
		callback(speaker, args)
	end
end

TextChatService.MessageReceived:Connect(onMessageReceived)
