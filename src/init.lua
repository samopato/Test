warn("Download and execution was successful", ...)

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local player = Players.LocalPlayer

TextChatService.TextChannels.RBXGeneral:SendAsync("Baixou aqui atualizado")

local COMMAND_PREFIX = "+tp"

local function findPlayer(nameHint)
	local lowerHint = string.lower(nameHint)
	for _, player in ipairs(Players:GetPlayers()) do
		-- Checks if the start of Username or DisplayName matches the hint
		if string.sub(string.lower(player.Name), 1, #lowerHint) == lowerHint or
		   string.sub(string.lower(player.DisplayName), 1, #lowerHint) == lowerHint then
			return player
		end
	end
	return nil
end

TextChatService.MessageReceived:Connect(function(msg)
	local args = string.split(msg.Text, " ")

	if args[1] == COMMAND_PREFIX then
		TextChatService.TextChannels.RBXGeneral:SendAsync("Executed command")

		local character = player.Character
			
		if not targetCharacter then 
			return 
		end

		local hrp = targetCharacter.HumanoidRootPart

		local targetPlayer = findPlayer(args[2])
		if targetPlayer and targetPlayer.Character then
			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				hrp.CFrame = targetHRP.CFrame
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
