warn("Download and execution was successful", ...)

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local player = Players.LocalPlayer

local COMMAND_PREFIX = "+tp"

TextChatService.MessageReceived:Connect(function(msg)
	local args = string.split(msg.Text, " ")

	TextChatService.TextChannels.RBXGeneral:SendAsync("Executed command")

	if args[1] == COMMAND_PREFIX then
		local targetCharacter = player.Character
		if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return end

		local hrp = targetCharacter.HumanoidRootPart

		-- OPTION 1: Teleport to a Player Name
		-- Usage: !tp Username
		local targetPlayer = Players:FindFirstChild(args[2])
		if targetPlayer and targetPlayer.Character then
			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3) -- Offset slightly so you don't merge
				print("Teleported to player: " .. targetPlayer.Name)
				return
			end
		end


		if args[2] and args[3] and args[4] then
			local x = tonumber(args[2])
			local y = tonumber(args[3])
			local z = tonumber(args[4])

			if x and y and z then
				hrp.CFrame = CFrame.new(x, y, z)
			end
		end
	end
end)
