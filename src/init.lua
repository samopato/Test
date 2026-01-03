local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local localPlayer = Players.LocalPlayer

local prefix = "+"

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
			chat("VEX: OpenAI API key is missing from vex/plugins/")
			return
		end

		local systemPrompt = [[
You are a helpful Roblox bot. You can talk to players and perform actions. 
RULES:
1. If a player asks you to move, use: [moveTo:PlayerName]
2. If a player asks you to dance, use: [dance]
3. If a player asks you to kill someone, use: [kill:PlayerName]
4. You can combine text and commands. Example: "On it! [kill:Builderman]"
5. If a player asks you to teleport to someone, use: [tp:PlayerName]
Messages should stay under 163 characters!
]]

		local function processAIResponse(responseText)
			for cmd, arg in responseText:gmatch("%[(%w+):?(%w*)%]") do
				warn("AI wants to run command: " .. cmd .. " with arg: " .. arg)

				local cmdEntry = commands[cmd:lower()]
				if cmdEntry then
					pcall(function() 
						cmdEntry[1]({arg})
					end)
				end
			end

			local cleanText = responseText:gsub("%[(.-)%]", "")
			return cleanText
		end


		local function askGemini(prompt)
			local response = request({
				Url = URL,
				Method = "POST",
				Headers = {
					["Authorization"] = "Bearer " ..KEY,
					["Content-Type"] = "application/json",
					["X-Title"] = game.PlaceId
				},
				Body = HttpService:JSONEncode({
					model = "google/gemini-2.0-flash-exp:free",
					messages = {
          				{ role = "user", content = prompt }
					},
				})
			})

			if response.Success then
				local data = game:GetService("HttpService"):JSONDecode(response.Body)
				if data.candidates and data.candidates[1].content.parts[1].text then
					return processAIResponse(data.choices[1].message.content)
				end
			else
				for _,v in pairs(response) do
					warn(v)
				end
			end

			return "Error: Could not reach AI. "
		end

		local prompt = table.concat(args, " ")
		if #prompt > 0 then
			local response = askGemini(prompt)
			chat(string.sub(response, 0, 163))
		end
	end}

	commands.rejoin = {function()
		chat("Rejoining...")
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
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

			hrp.CFrame = target.CFrame * CFrame.new(0, 0, 1)
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

	commands.dex = {function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/raelhubfunctions/Save-scripts/refs/heads/main/DexMobile.lua"))()	
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

end

local function onMessageReceived(message)
	if string.sub(message.Text, 0, 1) ~= prefix then
		return
	end


	local speaker = Players:GetPlayerByUserId(message.TextSource and message.TextSource.UserId)
	local command, args, undo = parseCommand(message.Text)

	local callback = undo and commands[command][2] or commands[command][1]

	if callback then
		callback(speaker, args)
	end
end

TextChatService.MessageReceived:Connect(onMessageReceived)
