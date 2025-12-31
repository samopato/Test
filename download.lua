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
	print("Checking for App updates...")
	
	local response = safeHttpGet(CONFIG.APP_URL)
	if not response then return false end

	local remoteFiles = HttpService:JSONDecode(response)
	local localManifest = loadManifest(CONFIG.FILES.MANIFEST)
	local filesChanged = 0
	
	local remoteFileNames = {}

	for _, file in ipairs(remoteFiles) do
		if file.type == "file" and file.download_url then
			remoteFileNames[file.name] = true -- Track what exists on GitHub
			local localPath = `{CONFIG.FOLDERS.ASSETS}/{file.name}`
			local storedHash = localManifest[file.name]

			if not isfile(localPath) or storedHash ~= file.sha then
				print(`Updating: {file.name}`)
				local content = safeHttpGet(file.download_url)
				if content then
					writefile(localPath, content)
					localManifest[file.name] = file.sha
					filesChanged = filesChanged + 1
				end
			end
		end
	end

	-- Cleanup: Delete local files that are no longer on GitHub
	for fileName, _ in pairs(localManifest) do
		if not remoteFileNames[fileName] then
			print(`Removing deprecated file: {fileName}`)
			local localPath = `{CONFIG.FOLDERS.ASSETS}/{fileName}`
			
			if isfile(localPath) then
				delfile(localPath)
			end
			
			localManifest[fileName] = nil
			filesChanged = filesChanged + 1
		end
	end

	if filesChanged > 0 then
		saveManifest(CONFIG.FILES.MANIFEST, localManifest)
		print(`App sync complete ({filesChanged} changes).`)
		return true
	else
		print("App is up to date.")
		return false
	end
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
