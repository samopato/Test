local HttpService = game:GetService("HttpService")
local CONFIG = {
	PATHS = {"vex", "vex/plugins", "vex/assets", "vex/saved"},
	APP_URL = "https://api.github.com/repos/samopato/Test/contents/src",
	VER_URL = "https://clientsettings.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE",
	RMD_URL = "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml",
	MANIFEST_PATH = "vex/manifest.json",
	ASSET_ROOT = "vex/assets"
}

-- Initialize base folders
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
-- Recursive Sync Logic
-----------------------------------

local function syncFolder(url, localPath, manifest, seenPaths)
	local response = game:HttpGet(url)
	if not response then return 0 end

	local remoteItems = HttpService:JSONDecode(response)
	local changes = 0

	for _, item in ipairs(remoteItems) do
		local itemLocalPath = `{localPath}/{item.name}`
		seenPaths[itemLocalPath] = true -- Mark as existing on GitHub

		if item.type == "dir" then
			-- Ensure subfolder exists
			if not isfolder(itemLocalPath) then
				makefolder(itemLocalPath)
			end
			-- Recurse into subfolder
			changes = changes + syncFolder(item.url, itemLocalPath, manifest, seenPaths)
		elseif item.type == "file" and item.download_url then
			-- Handle file update
			local storedHash = manifest[itemLocalPath]
			if not isfile(itemLocalPath) or storedHash ~= item.sha then
				print(`Updating: {itemLocalPath}`)
				local content = game:HttpGet(item.download_url)
				if content then
					writefile(itemLocalPath, content)
					manifest[itemLocalPath] = item.sha
					changes = changes + 1
				end
			end
		end
	end
	return changes
end

local function updateApp()
	print("Checking for App updates...")
	
	local localManifest = loadManifest()
	local seenPaths = {} -- Track what is currently on GitHub
	
	-- Start recursive sync from the root APP_URL into vex/assets
	local filesChanged = syncFolder(CONFIG.APP_URL, CONFIG.ASSET_ROOT, localManifest, seenPaths)

	-- Cleanup: Delete local files/folders in manifest that aren't on GitHub anymore
	-- We process this in reverse to ensure files are deleted before their parent folders
	local manifestKeys = {}
	for path in pairs(localManifest) do table.insert(manifestKeys, path) end
	
	for _, path in ipairs(manifestKeys) do
		if not seenPaths[path] then
			print(`Removing deprecated: {path}`)
			if isfile(path) then
				delfile(path)
			elseif isfolder(path) then
				delfolder(path)
			end
			localManifest[path] = nil
			filesChanged = filesChanged + 1
		end
	end

	if filesChanged > 0 then
		saveManifest(localManifest)
		print(`App sync complete ({filesChanged} changes).`)
		return true
	else
		print("App is up to date.")
		return false
	end
end

-----------------------------------
-- Data & Versioning
-----------------------------------

local function updateData()
	local success, verData = pcall(function() return game:HttpGet(CONFIG.VER_URL) end)
	if not success then return end
	
	local remoteVersion = verData:match("(version%-[%w]+)")
	local versionFile = `{CONFIG.ASSET_ROOT}/rbx_cli.dat`
	
	local localVersion = isfile(versionFile) and readfile(versionFile) or nil

	if localVersion ~= remoteVersion then
		print("Updating Roblox API Data...")
		local apiDumpUrl = `http://setup.roblox.com/{remoteVersion}-API-Dump.json`

		writefile(versionFile, remoteVersion)
		writefile(`{CONFIG.ASSET_ROOT}/rbx_api.dat`, game:HttpGet(apiDumpUrl))
		writefile(`{CONFIG.ASSET_ROOT}/rbx_rmd.dat`, game:HttpGet(CONFIG.RMD_URL))
		return true
	end
end

-----------------------------------
-- Execution
-----------------------------------
local dataUpdated = updateData()
local isUpdated = updateApp()
local initPath = `{CONFIG.ASSET_ROOT}/init.lua`

if isfile(initPath) then
	local initScript = readfile(initPath)
	-- Pass the update status to the init script
	task.spawn(loadstring(initScript), isUpdated)
else
	error("VEX Critical Error: 'init.lua' not found in assets. Update failed.")
end
