local HttpService = game:GetService("HttpService")
local CONFIG = {
	PATHS = {"vex", "vex/plugins", "vex/assets", "vex/saved"},
	APP_URL = "https://api.github.com/repos/samopato/Test/contents/src",
	VER_URL = "https://clientsettings.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE",
	RMD_URL = "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml",
	MANIFEST_PATH = "vex/manifest.json"
}

for _, path in ipairs(CONFIG.PATHS) do
	if not isfolder(path) then makefolder(path) end
end

-----------------------------------
-- Helpers
-----------------------------------
local function loadManifest()
	if isfile(CONFIG.MANIFEST_PATH) then
		local success, result = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG.MANIFEST_PATH))
		end)
		if success then return result end
	end
	
	return {}
end

local function saveManifest(data)
	writefile(CONFIG.MANIFEST_PATH, HttpService:JSONEncode(data))
end

-----------------------------------
-- Auto-update Logic
-----------------------------------

local function updateApp()
	print(`[VEX]: Loading...`)
	
	local remoteFiles = HttpService:JSONDecode(game:HttpGet(CONFIG.APP_URL))
	local localManifest = loadManifest()
	local updatedCount = 0
	local hasChanges = false

	for _, file in ipairs(remoteFiles) do
		if file.type == "file" and file.download_url then
			local filePath = `vex/assets/{file.name}`

			if not isfile(filePath) or localManifest[file.name] ~= file.sha then
				print(`[VEX]: Updating {file.name}...`)

				local content = game:HttpGet(file.download_url)
				writefile(filePath, content)

				localManifest[file.name] = file.sha
				updatedCount = updatedCount + 1
				hasChanges = true
			end
		end
	end

	if hasChanges then
		saveManifest(localManifest)
	end

	return hasChanges
end

local function updateData()
	local verData = game:HttpGet(CONFIG.VER_URL)
	local remoteVersion = verData:match("(version%-[%w]+)")
	
	local localVersion = nil
	if isfile("vex/assets/rbx_cli.dat") then
		localVersion = readfile("vex/assets/rbx_cli.dat")
	end

	if localVersion ~= remoteVersion then
		local apiDumpUrl = `http://setup.roblox.com/{remoteVersion}-API-Dump.json`

		writefile("vex/assets/rbx_cli.dat", remoteVersion)
		writefile("vex/assets/rbx_api.dat", game:HttpGet(apiDumpUrl))
		writefile("vex/assets/rbx_rmd.dat", game:HttpGet(CONFIG.RMD_URL))

		return true
	else
		return false
	end
end

-----------------------------------
-- Execution
-----------------------------------
local dataUpdated = updateData()
local isUpdated = updateApp()
local initPath = "vex/assets/Test.lua"

if isfile(initPath) then
	local initScript = readfile(initPath)
	loadstring(initScript)(isUpdated)
else
	error("VEX Critical Error: 'init.lua' not found in assets. Update failed.")
end
