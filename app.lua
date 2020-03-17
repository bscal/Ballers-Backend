local lapis = require("lapis")
local config = require("lapis.config").get()
local util = require("lapis.util")
local Model = require("lapis.db.model").Model
local respond_to = require("lapis.application").respond_to

local app = lapis.Application()

local Users = Model:extend("users", {
    primary_key = "steamid"
})

local Characters = Model:extend("characters", {
    primary_key = "steamid",
    cid = "cid"
})

local CharacterStats = Model:extend("character_stats", {
    primary_key = "steamid",
    cid = "cid"
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

app:match("/character/:steamid[%d]/:cid[%d]", function(self)
    if not self.params.steamid then
        return LogErr("no steamid")
    end

    if not self.params.cid then
        return LogErr("no character id")
    end

    local char = Characters:find(self.params.steamid, self.params.cid)
    local charStats = CharacterStats:find(self.params.steamid, self.params.cid)

    if not char then return LogErr("No character!") end
    if not charStats then return LogErr("No character stats!") end

    print(self.params.steamid)
    print(self.params.cid)

    return { json = { char, charStats }}
end)

app:post("/character/create", function(self)
    -- Checks if character already exists
    if Characters:find(self.params.steamid, self.params.cid) then return { status = 200, redirect_to = "/" } end

    local user = Users:find(self.params.steamid)

    -- Checks if user does not exist
    if not user then return LogErr("User does exist") end

    local index = user.char_index;

    -- Creates character
    Characters:create({
        steamid = self.params.steamid,
        cid = index,
        position = self.params.position,
        height = self.params.height,
        wingspan = self.params.wingspan,
        weight = self.params.weight
    })

    CharacterStats:create({
        steamid = self.params.steamid,
        cid = index
    })

    -- Increments users character index
    user.char_index = user.char_index + 1
    user:update("char_index")


    print("[Success] Created Character")

    return { status = 200, redirect_to = "/" }
end)

function LogErr(msg)
    print("[Error]: " .. msg)
    return { status = 400, layout = false, "[Error]: " .. msg }
end

function app:handle_error(err, trace)
    print ("[Error]: " .. err .. " | " .. trace)
    return { render = {status = 500, layout = false, "[Error]: " .. err .. " | " .. trace} }
  end

return app
