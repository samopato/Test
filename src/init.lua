local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = Players.LocalPlayer

local prefix = "+"

local whiteListEnabled = true
local whiteList = {10984088, 4912844218}
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
	local lowerHint = string.lower(nameHint)

	if nameHint == "" or nil then
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
		EmoteTracks[name] = localPlayer.Character.Humanoid:LoadAnimation(anim)
	end
end
localPlayer.CharacterAdded:Connect(function(char)
	for name, id in pairs(AnimationIds) do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		EmoteTracks[name] = char.Humanoid:LoadAnimation(anim)
	end
end)

-----------------------------
-- Main
-----------------------------

local conn
local carpetConn
local track
local flingConn

local commands do

	commands = {}
	local conn
	local track
	local flingConn

	commands.droptools = {function()
		for _,v in next, localPlayer.Character:GetChildren() do
			if v:IsA("Tool") then
				if v.CanBeDropped then
					v.Parent = workspace
				else
					v.Parent = localPlayer:FindFirstChildOfClass("Backpack")
				end
			end
		end
	end}

	commands.usetools = {function(speaker, args)
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
	end}

	commands.equiptools = {function()
		for _,v in next, localPlayer:FindFirstChildOfClass("Backpack"):GetChildren() do
			if v:IsA("Tool") or v:IsA("HopperBin") then
				v.Parent = localPlayer.Character
			end
		end
	end}

	commands.orbit = {function()
		loadstring(game:HttpGet("https://pastebin.com/raw/aZjaAr6F"))()
	end}

	commands.chat = {function(speaker, args)
		chat(table.concat(args, " "))
	end}

	commands.whisper = {function(speaker, args)
		local target = findPlayer(speaker, args[1])
		table.remove(args, 1)

		whisper(target, table.concat(args, " "))
	end}

	commands.help = {function(speaker, args)
		local list = {}
		for name, data in next, commands do
			table.insert(list, prefix .. name)
		end
		whisper(speaker, "VEX: all commands: " .. table.concat(list, ", "))
	end}

	commands.ai = {function(speaker, args)
		local KEY = isfile("vex/plugins/key.lua") and readfile("vex/plugins/key.lua")
		local URL = "https://openrouter.ai/api/v1/chat/completions"

		if not KEY then
			chat("VEX: OpenRouter API key is missing from vex/plugins/key.lua")
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
			chat("/e cheer ")
			local response = askAI(prompt)
			chat(string.sub(response, 0, 163))
		end
	end}

	commands.die = {function()
		replicatesignal(localPlayer.ConnectDiedSignalBackend)
		task.wait(Players.RespawnTime + 0.20)
		replicatesignal(localPlayer.Kill)
	end}

	commands.re = {function()
		replicatesignal(localPlayer.Kill)
		replicatesignal(localPlayer.ConnectDiedSignalBackend)
		task.wait(Players.RespawnTime - 0.1)
		replicatesignal(localPlayer.Kill)	
	end}

	commands.fling = {function(speaker, args)
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
	end, function()
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
	end}

	commands.tp = {function(speaker, args) 
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

				character.Torso.CanCollide = true
				character:PivotTo(targetHRP.CFrame)
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
	end}

	commands.carpet = {function(speaker, args)
		local targetPlayer = findPlayer(speaker, args[1])
		local char = localPlayer.Character
		local hum = char.Humanoid
		local root = char.HumanoidRootPart

		local SETTINGS = {
			OFFSET = Vector3.new(0, -4, 0),
			PREDICTION_TIME = 0.12,
		}

		-- Inside your +carpet elseif:
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
					end
				end

				local predictedPos = targetRoot.Position + (targetRoot.AssemblyLinearVelocity * SETTINGS.PREDICTION_TIME)
				local finalPos = predictedPos + SETTINGS.OFFSET

				local rawLook = targetRoot.CFrame.LookVector
				local flattenedLook = Vector3.new(rawLook.X, 0, rawLook.Z).Unit


				root.CFrame = CFrame.lookAt(finalPos, finalPos + flattenedLook) 
					* CFrame.Angles(math.rad(90), 0, 0)

				root.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
			end
		end)
	end, function(speaker, args)
		if carpetConn then
			carpetConn:Disconnect()
			carpetConn = nil
		end

		char.Torso.CanCollide = true
		hum.PlatformStand = false
	end}

	commands.bang = {function(speaker, args)
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
	function()
		if conn then
			conn:Disconnect()
			conn = nil
		end

		if track then
			track:Stop()
		end
	end,
	}

	-----------------------------
	-- Internal
	-----------------------------

	commands.rejoin = {function(speaker)
		if speaker.UserId == 10984088 or speaker.UserId == 4912844218 then
			chat("Rejoining...")
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
		end
	end}	

	commands.dex = {function(speaker)
		if speaker.UserId == 10984088 then
			loadstring(game:HttpGet("https://raw.githubusercontent.com/raelhubfunctions/Save-scripts/refs/heads/main/DexMobile.lua"))()	
		end
	end}

	commands.rspy = {function(speaker)
		if speaker.UserId == 10984088 then
			loadstring(game:HttpGet("https://github.com/exxtremestuffs/SimpleSpySource/raw/master/SimpleSpy.lua"))()
		end
	end}

	commands.whitelist = {function(speaker, args)
		if speaker.UserId == 10984088 then
			local arg = tostring(args[1]):lower()

			if arg == "true" or arg == "false" then
				whiteListEnabled = arg == "true" and true or false
				return
			end


			local target = findPlayer(speaker, args[1])

			if target then
				table.insert(whiteList, target.UserId)
			end
		end
	end}

	commands.exec = {function(speaker, args)
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
	end}
end

local function onMessageReceived(message)
	if string.sub(message.Text, 0, 1) ~= prefix then
		return
	end

	local speaker = Players:GetPlayerByUserId(message.TextSource and message.TextSource.UserId)
	local command, args, undo = parseCommand(message.Text)

	if whiteListEnabled and not table.find(whiteList, speaker.UserId) then
		return
	end

	local callback = not undo and commands[command][1] or commands[command][2]

	if callback then
		callback(speaker, args)
	end
end

TextChatService.MessageReceived:Connect(onMessageReceived)
