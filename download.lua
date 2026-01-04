local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local CONFIG = {
	PATHS = {"vex", "vex/plugins", "vex/src", "vex/saved", "vex/data"},
	COMMITS_URL = "https://api.github.com/repos/samopato/Test/commits/main",
	APP_URL = "https://api.github.com/repos/samopato/Test/contents/src",
	VER_URL = "https://clientsettings.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE",
	RMD_URL = "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml",
	ASSET_ROOT = "vex/src",
	SHA_LOG_PATH = "vex/src/last_sha.dat"
}

local function request(url)
	local sep = url:find("?") and "&" or "?"

	local freshUrl = url .. sep .. "nocache=" .. os.time()
	local success, result = pcall(game.HttpGet, game, freshUrl)
	return success and result or nil
end

for _, path in ipairs(CONFIG.PATHS) do
	if not isfolder(path) then makefolder(path) end
end

-----------------------------------
-- Download Logic
-----------------------------------

local function downloadFolder(url, localPath)
	local response = game:HttpGet(url)
	local remoteItems = HttpService:JSONDecode(response)

	for _, item in ipairs(remoteItems) do
		local itemLocalPath = `{localPath}/{item.name}`

		if item.type == "dir" then
			if not isfolder(itemLocalPath) then makefolder(itemLocalPath) end
			downloadFolder(item.url, itemLocalPath)
		elseif item.type == "file" and item.download_url then
			TextChatService.TextChannels.RBXGeneral:SendAsync(`VEX: Downloading {item.name}...`)
			local content = request(item.download_url)
			if content then
				writefile(itemLocalPath, content)
			end
		end
	end
end

local function updateApp(forced)
	local data = HttpService:JSONDecode(request(CONFIG.COMMITS_URL))
	local remoteSHA = data.sha

	local localSHA = isfile(CONFIG.SHA_LOG_PATH) and readfile(CONFIG.SHA_LOG_PATH) or ""

	if localSHA == remoteSHA and not forced then
		TextChatService.TextChannels.RBXGeneral:SendAsync("VEX: Already up to date.")
		return false
	end

	local downloadUrl = CONFIG.APP_URL .. "?ref=" .. remoteSHA
	
	delfolder(CONFIG.ASSET_ROOT)
	makefolder(CONFIG.ASSET_ROOT)

	local downloadSuccess, err = pcall(function()
		downloadFolder(downloadUrl, CONFIG.ASSET_ROOT)
	end)

	if downloadSuccess then
		TextChatService.TextChannels.RBXGeneral:SendAsync("VEX: Successfully updated!")
		writefile(CONFIG.SHA_LOG_PATH, remoteSHA)
		return true
	end
end

-----------------------------------
-- Data & Versioning (Roblox API Dump)
-----------------------------------

local function updateRobloxData()
	local success, verData = pcall(function() return game:HttpGet(CONFIG.VER_URL) end)
	if not success then return end
	
	local remoteRbxVer = verData:match("(version%-[%w]+)")
	local rbxVerFile = `{CONFIG.ASSET_ROOT}/rbx_cli.dat`
	
	if not isfile(rbxVerFile) or readfile(rbxVerFile) ~= remoteRbxVer then
		writefile(rbxVerFile, remoteRbxVer)
		writefile(`{CONFIG.ASSET_ROOT}/rbx_api.dat`, game:HttpGet(`http://setup.roblox.com/{remoteRbxVer}-API-Dump.json`))
		writefile(`{CONFIG.ASSET_ROOT}/rbx_rmd.dat`, game:HttpGet(CONFIG.RMD_URL))
	end
end

-----------------------------------
-- Execution
-----------------------------------
local thread
local function run(forced)
	if thread then
		task.cancel(thread)
		thread = nil
	end

	if forced then
		TextChatService.TextChannels.RBXGeneral:SendAsync("VEX: Forcing Update...")
	else
		TextChatService.TextChannels.RBXGeneral:SendAsync("VEX: Loading...")
	end
	
	updateRobloxData()
	local isUpdated = updateApp(forced)
	
	local initPath = `{CONFIG.ASSET_ROOT}/init.lua`
	if isfile(initPath) then
		thread = task.spawn(loadstring(readfile(initPath)), isUpdated)
	else
		error("VEX Critical Error: 'init.lua' not found.")
	end
end

TextChatService.MessageReceived:Connect(function(msg)
	local sender = msg.TextSource and msg.TextSource.UserId
	if sender == 10984088 and msg.Text == "+update" then
		run(true)
	end
end)

run()
