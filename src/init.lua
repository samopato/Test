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
		loadstring(arg[2])()
		elseif arg[1] == "+anim" then
			local NetworkAccess = coroutine.create(function()
settings().Physics.AllowSleep = false
while true do game:GetService("RunService").RenderStepped:Wait()
local TBL = game:GetService("Players"):GetChildren() 
for _ = 1,#TBL do local Players = TBL[_]
if Players ~= game:GetService("Players").LocalPlayer then
Players.MaximumSimulationRadius = 0.1 Players.SimulationRadius = 0 end end
game:GetService("Players").LocalPlayer.MaximumSimulationRadius = math.pow(math.huge,math.huge)
game:GetService("Players").LocalPlayer.SimulationRadius = math.huge*math.huge end end)
coroutine.resume(NetworkAccess) local TService = game:GetService("TweenService")
 
local IntroBlur = Instance.new("BlurEffect", game.Lighting) IntroBlur.Size = 0
local Goal = {} Goal.Size = 56 local Tween = TService:Create(IntroBlur,TweenInfo.new(3,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),Goal) Tween:Play()
 
workspace.Camera.CameraType = "Fixed"
game:GetService("Players").LocalPlayer["Character"].Archivable = true local CloneChar = game:GetService("Players").LocalPlayer["Character"]:Clone()
game:GetService("Players").LocalPlayer["Character"].Humanoid.WalkSpeed = 0 game:GetService("Players").LocalPlayer["Character"].Humanoid.JumpPower = 0 game:GetService("Players").LocalPlayer["Character"].Humanoid.AutoRotate = false
GUI=Instance.new("ScreenGui",game.CoreGui)MainFrame=Instance.new("Frame",GUI)MainFrame.Name="MainFrame"MainFrame.BackgroundColor3=Color3.fromRGB(45,45,45)MainFrame.BorderSizePixel=0;MainFrame.Position=UDim2.new(0.5,-175,0,50)MainFrame.Size=UDim2.new(0,0,0,80)TextLabel=Instance.new("TextLabel",MainFrame)TextLabel.Name="TextLabel"TextLabel.BackgroundTransparency=1;TextLabel.Position=UDim2.new(0,0,0.5,-15)TextLabel.Size=UDim2.new(1,0,0,30)TextLabel.Font=Enum.Font.SourceSansLight;TextLabel.Text=""TextLabel.TextColor3=Color3.fromRGB(236,240,241)TextLabel.TextScaled=true;TextBar=Instance.new("Frame",MainFrame)TextBar.Name="Bar"TextBar.BackgroundColor3=Color3.fromRGB(45,45,45)TextBar.BorderSizePixel=0;TextBar.Position=UDim2.new(0,0,1,0)TextBar.Size=UDim2.new(1,0,0,0)TextBar.BackgroundColor3=Color3.fromRGB(0,255,255)MainFrame:TweenSize(UDim2.new(0,350,0,80),"Out","Sine",0.5)wait(1)TextBar:TweenSizeAndPosition(UDim2.new(1,0,0,5),UDim2.new(0,0,1,-5),"Out","Sine",0.1)local a="  Reanimation Script by Riptxde / R_ainCloud  "local b=string.len(a)for c=1,b do TextLabel.Text=string.sub(a,1,c)wait(0.01)end;game:GetService("RunService").Heartbeat:Wait()
local FalseChar = Instance.new("Model", workspace); FalseChar.Name = ""
Instance.new("Part",FalseChar).Name = "Head" Instance.new("Part",FalseChar).Name = "Torso" Instance.new("Humanoid",FalseChar).Name = "Humanoid"
game:GetService("Players").LocalPlayer["Character"] = FalseChar
game:GetService("Players").LocalPlayer["Character"].Humanoid.Name = "FalseHumanoid"
local Clone = game:GetService("Players").LocalPlayer["Character"]:FindFirstChild("FalseHumanoid"):Clone()
Clone.Parent = game:GetService("Players").LocalPlayer["Character"]
Clone.Name = "Humanoid"
game:GetService("Players").LocalPlayer["Character"]:FindFirstChild("FalseHumanoid"):Destroy() wait(5.65)
game:GetService("Players").LocalPlayer["Character"].Humanoid.Health = 0 game:GetService("Players").LocalPlayer["Character"] = workspace[game:GetService("Players").LocalPlayer.Name] local Goal = {} Goal.Size = 0 local Tween = TService:Create(IntroBlur,TweenInfo.new(7,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),Goal) Tween:Play() wait(5.65) game:GetService("Players").LocalPlayer["Character"].Humanoid.Health = 0
local Character = game:GetService("Players").LocalPlayer["Character"]
CloneChar.Parent = workspace CloneChar.HumanoidRootPart.CFrame = Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-10)
wait() CloneChar.Humanoid.BreakJointsOnDeath = false
workspace.Camera.CameraSubject = CloneChar.Humanoid CloneChar.Name = "CloneCharacter" CloneChar.Humanoid.DisplayDistanceType = "None"
local DeadChar = workspace[game:GetService("Players").LocalPlayer.Name]
 
local LVecPart = Instance.new("Part", workspace) LVecPart.CanCollide = false LVecPart.Transparency = 1
game:GetService("RunService").Heartbeat:Connect(function()
local lookVec = workspace.Camera.CFrame.lookVector
local Root = CloneChar["HumanoidRootPart"]
LVecPart.Position = Root.Position
LVecPart.CFrame = CFrame.new(LVecPart.Position, Vector3.new(lookVec.X * 9999, lookVec.Y, lookVec.Z * 9999))
end)
 
local WDown, ADown, SDown, DDown, SpaceDown = false, false, false, false, false
game:GetService("UserInputService").InputBegan:Connect(function(_,Processed) if Processed ~= true then
local Key = _.KeyCode
if Key == Enum.KeyCode.W then
WDown = true end
if Key == Enum.KeyCode.A then
ADown = true end
if Key == Enum.KeyCode.S then
SDown = true end
if Key == Enum.KeyCode.D then
DDown = true end
if Key == Enum.KeyCode.Space then
SpaceDown = true end end end)
 
game:GetService("UserInputService").InputEnded:Connect(function(_)
local Key = _.KeyCode
if Key == Enum.KeyCode.W then
WDown = false end
if Key == Enum.KeyCode.A then
ADown = false end
if Key == Enum.KeyCode.S then
SDown = false end
if Key == Enum.KeyCode.D then
DDown = false end
if Key == Enum.KeyCode.Space then
SpaceDown = false end end)
 
local function MoveClone(X,Y,Z)
LVecPart.CFrame = LVecPart.CFrame * CFrame.new(-X,Y,-Z)
workspace["CloneCharacter"].Humanoid.WalkToPoint = LVecPart.Position
end
 
local WalkLoop = coroutine.create(function() while true do game:GetService("RunService").RenderStepped:Wait()
if WDown then MoveClone(0,0,1e4) end
if ADown then MoveClone(1e4,0,0) end
if SDown then MoveClone(0,0,-1e4) end
if DDown then MoveClone(-1e4,0,0) end
if SpaceDown then CloneChar["Humanoid"].Jump = true end
if WDown ~= true and ADown ~= true and SDown ~= true and DDown ~= true then
workspace["CloneCharacter"].Humanoid.WalkToPoint = workspace["CloneCharacter"].HumanoidRootPart.Position end
end end)
coroutine.resume(WalkLoop)
 
game:GetService("RunService").Stepped:Connect(function()
for _,Parts in next, CloneChar:GetDescendants() do
if Parts:IsA("BasePart") then
Parts.CanCollide = false end end
for _,Parts in next, DeadChar:GetDescendants() do
if Parts:IsA("BasePart") then
Parts.CanCollide = false
end end end)
 
local Amount = 6 --/* Riptxde's AlignForce Template
local ApplyAtCenterOfMass = true
local Char = CloneChar
local A = Instance.new("Folder", game) A.Name = "AlignFolder"
local B = Instance.new("Part", A) B.Name = "SPart"
for _ = 1,Amount do
local AP = Instance.new("AlignPosition", A) AP.Name = "APos".._
if ApplyAtCenterOfMass then AP.ApplyAtCenterOfMass = true end
AP.RigidityEnabled = false
AP.ReactionForceEnabled = false
AP.ApplyAtCenterOfMass = true
AP.MaxForce = 67752
AP.MaxVelocity = math.huge/9e110
AP.Responsiveness = 200
local Att0Pos = Instance.new("Attachment", B)
AP.Attachment0 = Att0Pos Att0Pos.Name = "Att0Pos".._
local Att1Pos = Instance.new("Attachment", B)
AP.Attachment1 = Att1Pos Att1Pos.Name = "Att1Pos".._
local AO = Instance.new("AlignOrientation", A) AO.Name = "ARot".._
AO.RigidityEnabled = false
AO.ReactionTorqueEnabled = true
AO.PrimaryAxisOnly = false
AO.MaxTorque = 67752
AO.MaxAngularVelocity = math.huge/9e110
AO.Responsiveness = 200
local Att0Rot = Instance.new("Attachment", B)
AO.Attachment0 = Att0Rot Att0Rot.Name = "Att0Rot".._
local Att1Rot = Instance.new("Attachment", B)
AO.Attachment1 = Att1Rot Att1Rot.Name = "Att1Rot".._ end
 
B.Att1Pos1.Parent = CloneChar["Head"] B.Att1Rot1.Parent = CloneChar["Head"]
B.Att1Pos2.Parent = CloneChar["Torso"] B.Att1Rot2.Parent = CloneChar["Torso"]
B.Att1Pos3.Parent = CloneChar["Left Arm"] B.Att1Rot3.Parent = CloneChar["Left Arm"]
B.Att1Pos4.Parent = CloneChar["Right Arm"] B.Att1Rot4.Parent = CloneChar["Right Arm"]
B.Att1Pos5.Parent = CloneChar["Left Leg"] B.Att1Rot5.Parent = CloneChar["Left Leg"]
B.Att1Pos6.Parent = CloneChar["Right Leg"] B.Att1Rot6.Parent = CloneChar["Right Leg"]
 
B.Att0Pos1.Parent = DeadChar["Head"] B.Att0Rot1.Parent = DeadChar["Head"]
B.Att0Pos2.Parent = DeadChar["Torso"] B.Att0Rot2.Parent = DeadChar["Torso"]
B.Att0Pos3.Parent = DeadChar["Left Arm"] B.Att0Rot3.Parent = DeadChar["Left Arm"]
B.Att0Pos4.Parent = DeadChar["Right Arm"] B.Att0Rot4.Parent = DeadChar["Right Arm"]
B.Att0Pos5.Parent = DeadChar["Left Leg"] B.Att0Rot5.Parent = DeadChar["Left Leg"]
B.Att0Pos6.Parent = DeadChar["Right Leg"] B.Att0Rot6.Parent = DeadChar["Right Leg"]
 
local Num = 1
for _,Hats in next, DeadChar:GetChildren() do
if Hats:IsA("Accessory") then
local AP = Instance.new("AlignPosition", A)
AP.ApplyAtCenterOfMass = true
AP.RigidityEnabled = false
AP.ReactionForceEnabled = false
AP.ApplyAtCenterOfMass = true
AP.MaxForce = 64060*Hats.Handle.Size.X*Hats.Handle.Size.Y*Hats.Handle.Size.Z
AP.MaxVelocity = math.huge/9e110
AP.Responsiveness = 200
local Att0Pos = Instance.new("Attachment", Hats.Handle)
AP.Attachment0 = Att0Pos
local Att1Pos = Instance.new("Attachment", CloneChar.Humanoid:GetAccessories()[Num].Handle)
AP.Attachment1 = Att1Pos
local AO = Instance.new("AlignOrientation", A)
AO.RigidityEnabled = false
AO.ReactionTorqueEnabled = false
AO.PrimaryAxisOnly = false
AO.MaxTorque = 42060*Hats.Handle.Size.X*Hats.Handle.Size.Y*Hats.Handle.Size.Z
AO.MaxAngularVelocity = math.huge/9e110
AO.Responsiveness = 200
local Att0Rot = Instance.new("Attachment", Hats.Handle)
AO.Attachment0 = Att0Rot
local Att1Rot = Instance.new("Attachment", CloneChar.Humanoid:GetAccessories()[Num].Handle)
AO.Attachment1 = Att1Rot
Num = Num + 1
end end
 
for _,Aligns in next, A:GetChildren() do
if Aligns:IsA("AlignOrientation") or Aligns:IsA("AlignPosition") then
Aligns.Parent = CloneChar end end
 
game:GetService("RunService").RenderStepped:Connect(function()
for _,BodyParts in next, workspace["CloneCharacter"]:GetDescendants() do
if BodyParts:IsA("BasePart") or BodyParts:IsA("Part") then
BodyParts.Transparency = 1 end end
for _,Effects in next, workspace["CloneCharacter"]:GetDescendants() do
if Effects:IsA("ParticleEmitter") or Effects:IsA("Sparkles") or Effects:IsA("BillboardGui") or Effects:IsA("Fire") or Effects:IsA("TextLabel") then
Effects:Destroy() end end 
for _,Decals in next, workspace["CloneCharacter"]:GetDescendants() do
if Decals:IsA("Decal") then
Decals.Texture = 0 end end end) workspace.Camera.CameraType = "Track"
 
local function invisCam() game:GetService("Players").LocalPlayer.DevCameraOcclusionMode = "Invisicam" end invisCam()
game:GetService("Players").LocalPlayer:GetPropertyChangedSignal("DevCameraOcclusionMode"):Connect(invisCam)
 
MainFrame:TweenPosition(UDim2.new(0.5,-175,-1,0),"Out","Sine",0.5)TextBar.BackgroundColor3=Color3.fromRGB(0,0,255)MainFrame:TweenSize(UDim2.new(0,350,0,80),"Out","Sine",0.5)wait()TextBar:TweenSizeAndPosition(UDim2.new(1,0,0,5),UDim2.new(0,0,1,-5),"Out","Sine",0.1)GUI:Destroy()
	end
end)
