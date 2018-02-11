--[[------------------------------------------------
    Basic backdoor blocker maintained by Crident
    Improvements welcome
------------------------------------------------]]--
if !bbloaded then bbloaded = true print(" > Backdoor Buster Loaded!") else return end -- reloading wont play nice with this

-- Prep
local bb = {}
bb.bad = {}
bb.temp = {}
bb.cache = {}
bb.original = {}
bb.nextpurge = 0
bb.bad.http = util.JSONToTable(file.Read("lua/autorun/sh_blocked-list.txt", true))

-- Set this to false if you DON'T trust Crident; false disables automatic blacklist updates.
bb.autoupdate = true
-- Set this to false if you DON'T trust Crident; false disables automatic blacklist updates.

-- HTTP detour setup
bb.original.httpFetch = http.Fetch
bb.original.httpPost = http.Post
bb.temp.fetch = {}
bb.temp.post = {}

-- Temp detour to queue all requests until blacklist is known
function http.Fetch(...)
	table.insert(bb.temp.fetch, {...})
end
function http.Post(...)
	table.insert(bb.temp.post, {...})
end

-- Utility function to quickly check URL's
local function CheckURL(url)
	-- Check cache
	if bb.cache[url] then return end

	-- Clean the URL
	url = url:lower()
	if string.StartWith(url, "https://") then -- Remove https:// shit
		url = string.TrimLeft(url, "https://")
	elseif string.StartWith(url, "http://") then
		url = string.TrimLeft(url, "http://")
	end

	-- Clean the URL cont.
	url = string.Explode( "/", url)[1] -- Remove trailing shit (/index.php etc)
	url = string.Explode( ".", url) -- Sub domain handling (www.domain.com etc)
	url = url[#url-1].."."..url[#url]

	-- Check if it's on the blacklist
	if bb.bad.http[url] then
		local msg = "\n\n > Backdoor Blocked: " .. url .. debug.traceback(" - find the source of this attempt below", 3) .. "\n\n"
		file.Append("backdoor_log.txt", msg) print(msg) -- Print & Log the error

		return true
	end
	
	-- If it isn't on the blacklist cache the URL to speed things up
	local curtime = CurTime()
	if curtime > bb.nextpurge then -- Purge the cache every 2 hours
		bb.cache = {}
		bb.nextpurge = curtime+7200
	end

	bb.cache[url] = true -- Cache the URL	
end

-- Implment full detour when we have the updated blacklist
function bb.http()
	function http.Fetch(url, ...)
		if CheckURL(url) then return end
		return bb.original.httpFetch(url, ...)
	end
	function http.Post(url, ...)
		if CheckURL(url) then return end
		return bb.original.httpPost(url, ...)
	end

	-- Process queue
	for k, v in pairs(bb.temp.fetch) do http.Fetch(v[1], v[2], v[3], v[4]) end
	for k, v in pairs(bb.temp.post) do http.Post(v[1], v[2], v[3], v[4], v[5]) end
	bb.temp.fetch = nil bb.temp.post = nil -- cleanup
end

-- Auto Update blocked list if enabled
if bb.autoupdate then
	timer.Simple(0, function()
		bb.original.httpFetch( "https://raw.githubusercontent.com/SnowboiTheGr8/backdoor-buster/master/lua/autorun/sh_blocked-list.txt", function(data)
			bb.bad.http = util.JSONToTable(data)
			bb.http()
		end, function() bb.http() end) -- Fail safe
	end)
else
	bb.http()
end