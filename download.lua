local url = "https://api.github.com/repos/xa1on/rblxguilib/contents/src"

local src = game:HttpGet(url)
local json = game:GetService("HttpService"):JSONDecode(req)

makefolder("vex")

for i = 1, #json do
	local file = json[i]
	local content = game:HttpGet(file.download_url)
	if (file.type == "file") then
		writefile(`vex/{file.name}`, content)
	end
end
