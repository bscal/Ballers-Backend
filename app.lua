local lapis = require("lapis")
local config = require("lapis.config").get()
local util = require("lapis.util")
local Model = require("lapis.db.model").Model

local app = lapis.Application()

local Users = Model:extend("users", {
    primary_key = "steamid"
})

local Players = Model:extend("players", {
    primary_key = "steamid"
})


app:get("/", function()
    return { layout = false, "This is a test"}
end)

app:match("/login/:steamid[%d]", function(self)
    if not self.params.steamid then
        return LogErr("no steamid")
    end

    local user = Users:find(self.params.steamid)

    if not user then
		Users:create({steamid = self.params.steamid})
		print("Creating user...")
	else
		print("User exists...")
    end

    return { json = {user} }
end)

app:match("/player/:steamid[%d]/:cid[%d]", function(self)
    if not self.params.steamid then
        return LogErr("no steamid")
    end

    if not self.params.cid then
        return LogErr("no character id")
    end

    local player = Players:find(self.params.steamid, self.params.cid)

    if not player then print("No character") end

    print(self.params.steamid)
    print(self.params.cid)

    return { json = { player }}
end)

function LogErr(msg)
    print("[Error]: " .. msg)
    return { status = 400, layout = false, "[Error]: " .. msg }
end

return app
