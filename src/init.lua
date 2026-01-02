warn("Download and execution was successful", ...)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local localPlayer = Players.LocalPlayer

local TeleportService = game:GetService("TeleportService")

local COMMAND_PREFIX = "+tp"

local function chat(...)
	TextChatService.TextChannels.RBXGeneral:SendAsync(...)
end

local function findPlayer(speaker, nameHint)
	local lowerHint = string.lower(nameHint)

	if nameHint == "me" then
		return speaker
	end

	for _, player in pairs(Players:GetPlayers()) do
		if string.sub(string.lower(player.Name), 1, #lowerHint) == lowerHint or
			string.sub(string.lower(player.DisplayName), 1, #lowerHint) == lowerHint then
			return player
		end
	end

	return nil
end

local conn
local track

TextChatService.MessageReceived:Connect(function(msg)
	local speaker = Players:GetPlayerByUserId(msg.TextSource and msg.TextSource.UserId)
	local args = string.split(msg.Text, " ")

	if args[1] == COMMAND_PREFIX then
		local character = localPlayer.Character

		if not character then 
			return 
		end

		local targetPlayer = findPlayer(speaker, args[2])

		if targetPlayer and targetPlayer.Character then
			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
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
	elseif args[1] == "+rejoin" then
		chat("Rejoining...")
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
	elseif args[1] == "+death" then
		replicatesignal(localPlayer.ConnectDiedSignalBackend)
		task.wait(Players.RespawnTime + 0.20)
		replicatesignal(localPlayer.Kill)
	elseif args[1] == "+respawn" then
		replicatesignal(localPlayer.ConnectDiedSignalBackend)
	elseif args[1] == "+bang" then
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

		local speed = tonumber(args[3]) or 1

		track = humanoid:LoadAnimation(animation)
		track:Play()
 
		local targetPlayer = findPlayer(speaker, args[2])
		
		if targetPlayer and targetPlayer.Character then
			conn = RunService.Heartbeat:Connect(function()
				local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				
				if targetRoot then
					track:AdjustSpeed(speed)
					humanoid.Sit = false
					localPlayer.Character.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -1)
				end
			end)
		end
	end
end)
