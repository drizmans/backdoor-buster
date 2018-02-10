--[[------------------------------------------------
	Basic backdoor blocker maintained by Crident
------------------------------------------------]]--
if !bbloaded then bbloaded = true print(" > Backdoor Buster Loaded!") else return end -- reloading wont play nice with this

-- Prep
local bb = {}
bb.bad = {}
bb.original = {}
bb.autoupdate = true -- Set this to false if you DON'T trust Crident
bb.bad.http = util.JSONToTable(file.Read("lua/autorun/sh_blocked-list.txt", true))

-- Auto Update blocked list if enabled
if bb.autoupdate then
	timer.Simple(0, function()
		http.Fetch( "https://raw.githubusercontent.com/SnowboiTheGr8/backdoor-buster/master/lua/autorun/sh_blocked-list.txt", function(data)
			bb.bad.http = util.JSONToTable(data)
		end)
	end)
end

-- Utility function to easily check URL's - improvements welcome
local function CheckURL(url)
	-- Clean the URL
	url = url:lower()
	if string.StartWith(url, "https://") then -- Remove HTTP shit
		url = string.TrimLeft(url, "https://")
	elseif string.StartWith(url, "http://") then
		url = string.TrimLeft(url, "http://")
	end

	-- Clean the URL cont.
	local tbl = string.Explode( "/", url) -- Remove trailing shit (/index.php etc)
	local tbl = string.Explode( ".", tbl[1]) -- Sub domain handling (www.domain.com etc)
	url = tbl[#tbl-1].."."..tbl[#tbl]

	-- Check if it's on the blacklist
	if bb.bad.http[url] then
		local msg = "\n\n > Backdoor Blocked: " .. url .. debug.traceback(" - find the source of this attempt below", 3) .. "\n\n"
		file.Append("backdoor_log.txt", msg) print(msg) -- Print & Log the error

		return true
	end
end

-- HTTP Detours
bb.original.httpFetch = http.Fetch
bb.original.httpPost = http.Post

function http.Fetch(url, ...)
	if CheckURL(url) then return end

	return bb.original.httpFetch(url, ...)
end

function http.Post(url, ...)
	if CheckURL(url) then return end

	return bb.original.httpPost(url, ...)
end
-- HTTP Detours