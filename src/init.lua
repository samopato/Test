warn("Download and execution was successful", ...)

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local localPlayer = Players.LocalPlayer

local TeleportService = game:GetService("TeleportService")


local COMMAND_PREFIX = "+tp"

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
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
	elseif args[1] == "+death" then
		replicatesignal(localPlayer.ConnectDiedSignalBackend)
		task.wait(Players.RespawnTime + 0.20)
		replicatesignal(localPlayer.Kill)
	elseif arg[1] == "+respawn" then
		replicatesignal(localPlayer.ConnectDiedSignalBackend)
	elseif arg[1] == "+execute" then
		loadstring(arg[2])
	end
end)
