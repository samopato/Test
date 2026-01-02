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
local flingConn

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
	elseif args[1] == "+rejoin" then
		chat("Rejoining...")
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
	elseif args[1] == "+death" then
		replicatesignal(localPlayer.ConnectDiedSignalBackend)
		task.wait(Players.RespawnTime + 0.20)
		replicatesignal(localPlayer.Kill)
	elseif args[1] == "+respawn" then
		replicatesignal(localPlayer.Kill)
		replicatesignal(localPlayer.ConnectDiedSignalBackend)
		task.wait(Players.RespawnTime - 0.1)
		replicatesignal(localPlayer.Kill)		
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

		local targetPlayer = findPlayer(speaker, args[2])

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
	elseif args[1] == "+unbang" then
		if conn then
			conn:Disconnect()
			conn = nil
		end

		if track then
			track:Stop()
		end
	elseif args[1] == "+chat" then

		local replacements = {
			["n"] = "nigga",
			["nr"] = "nigger",
			["f"] = "fuck",
			["fn"] = "fucking",
			["p"] = "pussy",
			["c"] = "cunt",
			["h"] = "horny"
		}

		local function translate(text)
			return (text:gsub("@(%a+)", replacements))
		end

		chat()

		local unicode = "ê"

		chat(string.gsub("nigga", ".", "%1" .. unicode))

		--local text = translate(args[2]):lower()
		--chat(args[2], args[3], args[4])
		--chat(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(text,"fuc","Ø£fu"..unicode.."c"),"shit","Ø£sh"..unicode.."it"),"bitch","Ø£bi"..unicode.."tch"),"fag","f"..unicode.."ag"),"hitler","hi"..unicode.."tler"),"Ø£fu"..unicode.."cking","Ø£fu"..unicode.."ckingØ£"),"di","d"..unicode.."i"),"pus","Ø£pus"..unicode..""),"assh","Ø£as"..unicode.."sh"),"coc","Ø£c"..unicode.."oc"),"cunt","Ø£Ø£cu"..unicode.."nt"),"tit","t"..unicode.."it"),"pedo","p"..unicode.."edo"),"peni","p"..unicode.."eni"),"vagin","v"..unicode.."agin"),"d"..unicode.."ickh","Ø£d"..unicode.."ickh"),"sperm","Ø£sp"..unicode.."erm"),"bull","Ø£bull"),"dum","Ø£dum"),"hore","h"..unicode.."ore"),"slut","Ø£slu"..unicode.."t"),"porn","p"..unicode.."orn"),"sex","Ø£s"..unicode.."ex"),"dyke","dy"..unicode.."ke"),"d"..unicode.."ip","Ø£dip"),"nig","Ø£Ø£n"..unicode.."ig"),"rap","Ø£ra"..unicode.."p"),"cum","Ø£cu"..unicode.."m"),"rap","Ø£ra"..unicode.."p"),"kik","ki"..unicode.."k"),"jizz","jiz"..unicode.."z"),"retarded","Ø£re"..unicode.."tarded"),"d"..unicode.."ildo","Ø£d"..unicode.."ildo"),"boobies","bo"..unicode.."obies"),"nude","Ø£Ø£nu"..unicode.."de"),"biatch","bi"..unicode.."atch"),"hentai","h"..unicode.."entai"),"testicl","t"..unicode.."esticl"),"genatalia","g"..unicode.."enatalia"),"boner","b"..unicode.."oner"),"clit","c"..unicode.."lit"),"cooch","c"..unicode.."ooch"),"blowjob",""..unicode.."blo"..unicode.."wjob"),"v"..unicode.."aginas","va"..unicode.."ginas"),"pube","p"..unicode.."ube"),"Ø£c"..unicode.."ocaine","Ø£co"..unicode.."caine"),"mierda","m"..unicode.."ierda"),"perra","p"..unicode.."erra"),"gilipollas","g"..unicode.."ilipollas"),"merde","m"..unicode.."erde"),"connard","c"..unicode.."onnard"),"coÃ±o","c"..unicode.."oÃ±o"),"Fu","Ø£Fu"..unicode..""),"Shit","Ø£Sh"..unicode.."it"),"Bitch","Ø£Bi"..unicode.."tch"),"Fag","F"..unicode.."ag"),"Hitler","Hi"..unicode.."tler"),"Ø£Fu"..unicode.."cking","Ø£Fu"..unicode.."ckingØ£"),"Di","D"..unicode.."i"),"Pus","Ø£Pus"..unicode..""),"Assh","Ø£As"..unicode.."sh"),"Coc","Ø£C"..unicode.."oc"),"Cunt","Ø£Ø£Cu"..unicode.."nt"),"Tit","T"..unicode.."it"),"Pedo","P"..unicode.."edo"),"Peni","P"..unicode.."eni"),"Vagin","V"..unicode.."agin"),"Dickh","Ø£D"..unicode.."ickh"),"Sperm","Ø£Sp"..unicode.."erm"),"Bull","Ø£Bull"),"Dum","Ø£Dum"),"Hore","H"..unicode.."ore"),"Slut","Ø£Slu"..unicode.."t"),"Porn","P"..unicode.."orn"),"Sex","Ø£S"..unicode.."ex"),"Dyke","Dy"..unicode.."ke"),"D"..unicode.."ip","Ø£Dip"),"Nig","Ø£Ø£N"..unicode.."ig"),"Rap","Ø£Ra"..unicode.."p"),"Cum","Cu"..unicode.."m"),"Kik","Ki"..unicode.."k"),"Jizz","Jiz"..unicode.."z"),"Retarded","Ø£Re"..unicode.."tarded"),"D"..unicode.."ildo","Ø£D"..unicode.."ildo"),"Boobies","Bo"..unicode.."obies"),"Nude","N"..unicode.."ude"),"Biatch","Bi"..unicode.."atch"),"Hentai","H"..unicode.."entai"),"Testicl","T"..unicode.."esticl"),"Genatalia","G"..unicode.."enatalia"),"Boner","B"..unicode.."oner"),"Blowjob","B"..unicode.."lowjob"),"Pube","P"..unicode.."ube"),"Clit","C"..unicode.."lit"),"Cooch","C"..unicode.."ooch"),"Ø£C"..unicode.."ocaine","Ø£Co"..unicode.."caine"),"Mierda","M"..unicode.."ierda"),"Perra","P"..unicode.."erra"),"Gilipollas","G"..unicode.."ilipollas"),"Merde","M"..unicode.."erde"),"Connard","C"..unicode.."onnard"),"CoÃ±o","C"..unicode.."oÃ±o"),"FUC","Ø£FU"..unicode.."C"),"SHIT","Ø£SH"..unicode.."IT"),"BITCH","Ø£BI"..unicode.."TCH"),"FAG","F"..unicode.."AG"),"HITLER","HI"..unicode.."TLER"),"Ø£FU"..unicode.."CKING","Ø£FU"..unicode.."CKINGØ£"),"DI","D"..unicode.."I"),"PUS","Ø£PUS"..unicode..""),"ASSH","Ø£AS"..unicode.."SH"),"COC","Ø£C"..unicode.."OC"),"CUNT","Ø£Ø£CU"..unicode.."NT"),"TIT","T"..unicode.."IT"),"PEDO","P"..unicode.."EDO"),"PENI","P"..unicode.."ENI"),"VAGIN","V"..unicode.."AGIN"),"D"..unicode.."ICKH","Ø£D"..unicode.."ICKH"),"SPERM","Ø£SP"..unicode.."ERM"),"BULL","Ø£BULL"),"DUM","Ø£DUM"),"HORE","H"..unicode.."ORE"),"SLUT","Ø£SLU"..unicode.."T"),"PORN","P"..unicode.."ORN"),"SEX","Ø£S"..unicode.."EX"),"DYKE","DY"..unicode.."KE"),"D"..unicode.."IP","Ø£DIP"),"NIG","Ø£Ø£N"..unicode.."IG"),"RAP","Ø£RA"..unicode.."P"),"CUM","CU"..unicode.."M"),"RAP","Ø£RA"..unicode.."P"),"KIK","KI"..unicode.."K"),"JIZZ","JIZ"..unicode.."Z"),"RETARDED","Ø£RE"..unicode.."TARDED"),"D"..unicode.."ILDO","Ø£D"..unicode.."ILDO"),"BOOBIES","BO"..unicode.."OBIES"),"NUDE","Ø£Ø£NU"..unicode.."DE"),"BIATCH","BI"..unicode.."ATCH"),"HENTAI","H"..unicode.."ENTAI"),"TESTICL","T"..unicode.."ESTICL"),"GENATALIA","G"..unicode.."ENATALIA"),"BONER","B"..unicode.."ONER"),"CLIT","C"..unicode.."LIT"),"COOCH","C"..unicode.."OOCH"),"BLOWJOB","B"..unicode.."LOWJOB"),"Ø£C"..unicode.."OCAINE","Ø£CO"..unicode.."CAINE"),"PUBE","P"..unicode.."UBE"),"MIERDA","M"..unicode.."IERDA"),"PERRA","P"..unicode.."ERRA"),"GILIPOLLAS","G"..unicode.."ILIPOLLAS"),"MERDE","M"..unicode.."ERDE"),"CONNARD","C"..unicode.."ONNARD"),"COÃO","C"..unicode.."OÃO"),"1","â1â"),"2","â2â"),"3","â3â"),"4","â4â"),"5","â5â"),"6","â6â"),"7","â7â"),"8","â8â"),"9","â9â"),"0","â0â"),"6â9","6â9Ø£"),"4â2â0","4â2â0Ø£")," ","Ø£").."Ø£Ø£","All")
	elseif args[1] == "+exec" then
		local a = table.remove(args[1])

	elseif args[1] == "+test" then
		local targetPlayer = findPlayer(speaker, args[2])

		local NetworkAccess = coroutine.create(function()
			settings().Physics.AllowSleep = false
			while true do 
				RunService.RenderStepped:Wait()
				local TBL = Players:GetChildren()

				for i = 1,#TBL do local Players = TBL[i]
					if Players ~= game:GetService("Players").LocalPlayer then
						Players.MaximumSimulationRadius = 0.1 Players.SimulationRadius = 0
					end
				end

				game:GetService("Players").LocalPlayer.MaximumSimulationRadius = math.pow(math.huge,math.huge)
				game:GetService("Players").LocalPlayer.SimulationRadius = math.huge*math.huge 
			end 
		end)
		coroutine.resume(NetworkAccess)

		RunService.Heartbeat:Connect(function()
			localPlayer.Character.Head:PivotTo(targetPlayer.Character.Head.CFrame)
		end)
	elseif args[1] == "+test2" then
		loadstring(game:HttpGet("https://scriptblox.com/raw/Universal-Script-Fe-Silly-animation-V4-16636"))()
	elseif args[1] == "+dex" then
		loadstring(game:HttpGet("https://raw.githubusercontent.com/raelhubfunctions/Save-scripts/refs/heads/main/DexMobile.lua"))()	
	elseif args[1] == "+test3" then
		localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -69000, 0)
	elseif args[1] == "+carpet" then		
		local targetPlayer = findPlayer(speaker, args[2])
		local char = localPlayer.Character
		local hum = char.Humanoid
		local root = char.HumanoidRootPart

		local SETTINGS = {
			OFFSET = Vector3.new(0, -4, 0),
			PREDICTION_TIME = 0.12, -- Adjust based on your ping (0.1 to 0.2 is sweet spot)
		}

		-- Inside your +carpet elseif:
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local targetChar = targetPlayer.Character
			local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

			if targetRoot and root then
				hum.Sit = false

				local predictedPos = targetRoot.Position + (targetRoot.AssemblyLinearVelocity * SETTINGS.PREDICTION_TIME)
				local finalPos = predictedPos + SETTINGS.OFFSET

				local rawLook = targetRoot.CFrame.LookVector
				local flattenedLook = Vector3.new(rawLook.X, 0, rawLook.Z).Unit


				root.CFrame = CFrame.lookAt(finalPos, finalPos + flattenedLook) 
					* CFrame.Angles(math.rad(90), 0, 0)

				root.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
			end
		end)
	elseif args[1] == '+fling' then	
		local vel
		local movel = 10
		local target = findPlayer(speaker, args[2])

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
	elseif args[1] == "+unfling" then		
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
	elseif args[1] == "+ai" then
		local HttpService = game:GetService("HttpService")
		local rawKey = isfile("vex/plugins/key.lua") and readfile("vex/plugins/key.lua")
local KEY = rawKey and string.gsub(rawKey, "%s+", "") 

if not KEY or KEY == "" then
    chat("VEX: API key is missing or empty in vex/plugins/key.lua")
    return
end
			
		local URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" ..tostring(KEY)

		if not KEY then
			chat("VEX: API key is missing from vex/plugins/")
			return
		end

		local function askGemini(prompt)
			
			chat("Asking gemini...")
			
			-- Using the global 'request' instead of HttpService
			local response = request({
				Url = URL,
				Method = "POST",
				Headers = {
          			["Content-Type"] = "application/json"
      			 },
				Body = game:GetService("HttpService"):JSONEncode({
					contents = {{
						parts = {{ text = prompt }}
					}}
				})
			})

			if response.Success then
				local data = game:GetService("HttpService"):JSONDecode(response.Body)
				if data.candidates and data.candidates[1].content.parts[1].text then
					return data.candidates[1].content.parts[1].text
				end
			else
				warn("Request Failed! Status: " .. response.StatusMessage)
			end
			
			return "Error: Could not reach Gemini. "..response.StatusMessage
		end

		chat(askGemini("Hello"))
	end
end)
