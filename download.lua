local url = "https://api.github.com/repos/samopato/Test/contents/src"

local src = game:HttpGet(url)
local json = game:GetService("HttpService"):JSONDecode(src)

makefolder("vex")

for i = 1, #json do
	local file = json[i]
	local content = game:HttpGet(file.download_url)
	if (file.type == "file") then
		writefile(`vex/{file.name}`, content)
	end
end

local init = readfile("vex/Test.lua")
if init then loadstring(init)() else error("VEX is missing init file") end
