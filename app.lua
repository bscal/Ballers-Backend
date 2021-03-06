local lapis = require("lapis")
local config = require("lapis.config").get()
local util = require("lapis.util")
local db = require("lapis.db")
local Model = require("lapis.db.model").Model
local app = lapis.Application()

-- ====================== Models ======================

local Users = Model:extend("users", {
    primary_key = "steamid"
})

local Characters = Model:extend("characters", {
    primary_key = { "steamid", "cid" }
})

local CharacterStats = Model:extend("character_stats", {
    primary_key = { "steamid", "cid" }
})

local CharacterSkills = Model:extend("character_skills", {
    primary_key = { "steamid", "cid" }
})

local AICharacters = Model:extend("ai_characters", {
    primary_key = { "id" }
})

-- ====================== Functions ======================

app:get("/", function()
    return { layout = false, "This is a test"}
end)

-- ====================== Login ======================
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
        user.last_login = db.format_date()
        user:update("last_login")
    end

    return { json = {user} }
end)

-- ====================== Gets Character ======================
app:get("/character/:steamid[%d]/:cid[%d]", function(self)
    if not self.params.steamid then
        return LogErr("no steamid")
    end

    if not self.params.cid then
        return LogErr("no character id")
    end

    local char = Characters:find(self.params.steamid, self.params.cid)
    local charStats = CharacterStats:find(self.params.steamid, self.params.cid)
    local charSkills = CharacterSkills:find(self.params.steamid, self.params.cid)

    if not char then return LogErr("No character!") end
    if not charStats then return LogErr("No character stats!") end
    if not charSkills then
        CharacterSkills:create({
            steamid = self.params.steamid,
            cid = self.params.cid,
            skills_json = "{}"
        })
        return LogErr("No character skills!")
    end

    print(self.params.steamid)
    print(self.params.cid)

    return { json = { char, charStats, charSkills }}
end)

app:get("/character/:steamid[%d]/all", function(self)
    if not self.params.steamid then
        return LogErr("no steamid")
    end

    local chars = Characters:select("where steamid = ?", self.params.steamid)
    local charStats = CharacterStats:select("where steamid = ?", self.params.steamid)
    local charSkills = CharacterSkills:select("where steamid = ?", self.params.steamid)

    if not chars then return LogErr("No character!") end
    if not charStats then return LogErr("No character stats!") end
    if not charSkills then return LogErr("No character skills!") end

    return { json = { #chars, chars, charStats, charSkills }}
end)

-- Getting ai player data
app:get("/character/ai/:ai_id[%d]", function(self)
    if not self.params.ai_id then return LogErr("no ai id") end
    print(self.params.ai_id)
    local aiChar = AICharacters:find(self.params.ai_id)

    if not aiChar then return LogErr("AI Char does not exist") end

    return { json = { aiChar } }
end)


-- ====================== POSTs ======================

-- ====================== Creates Character ======================
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
        first_name = self.params.first_name,
        last_name = self.params.last_name,
        class = self.params.class,
        position = self.params.position,
        height = self.params.height,
        wingspan = self.params.wingspan,
        weight = self.params.weight
    })

    -- Creates character stats
    local cStats = CharacterStats:create({
        steamid = self.params.steamid,
        cid = index
    })

    local stats = {}
    for k,v in pairs(self.params) do
        stats[k] = v;
    end
    cStats:update(stats)

    CharacterSkills:create({
        steamid = self.params.steamid,
        cid = index,
        skills_json = "{}"
    })

    -- Increments users character index
    user.char_index = user.char_index + 1
    user:update("char_index")


    print("[Success] Created Character")

    return { status = 200, redirect_to = "/" }
end)

-- ====================== Delete Character ======================
app:post("/character/delete", function(self)
    if not self.params.steamid or not self.params.cid then return LogErr("Not proper POST params!") end

    local character = Characters:find(self.params.steamid, self.params.cid)

    if not character then return LogErr("Character not found!") end

    if not character:delete() then
        LogErr("Character could not be deleted!")
    else
        return { status = 200, layout = false, "Character deleted" }
    end
end)

-- ====================== Save Character ======================
app:post("/character/save", function(self)
    if not self.params.steamid or not self.params.stats then return LogErr("Not proper POST params!") end

    local character = Characters:find(self.params.steamid, self.params.cid)
    if not character then return LogErr("Character not found!") end

    local cStats = CharacterStats:find(self.params.steamid, self.params.cid)
    if not cStats then return LogErr("Character Stats not found!") end

    local data = util.from_json(self.params.stats)
    local stats = {}
    for k,v in pairs(data) do
        stats[k] = v;
    end
    cStats:update(stats)

    if (self.params.skills) then
        local cSkills = CharacterStats:find(self.params.steamid, self.params.cid)
        if not cSkills then return LogErr("Character Stats not found!") end
        cSkills.skills_json = self.param.skills
        cSkills:update("skills_json");
    end

    return { status = 200, layout = false, "Character saved" }
end)

-- =============================================================
-- ======================   MatchMaking   ======================
-- =============================================================


-- =============================================================
-- ====================== Utils Functions ======================
-- =============================================================

-- Utility function that will print message to console and return an error response
function LogErr(msg)
    print("[Error]: " .. msg)
    return { status = 400, layout = false, "[Error]: " .. msg }
end

function LogErrCode(msg, code)
    print("[Error]: " .. msg)
    return { status = code, layout = false, "[Error]: " .. msg }
end

-- Overrides default handle_error
-- Since this app is primarily used as a backend the default renders
-- to a page. This will print to console the errors and send basic info as response.
function app:handle_error(err, trace)
    print ("[Error]: " .. err .. " | " .. trace)
    return {status = 500, layout = false, "[Error]: " .. err .. " | " .. trace}
end

return app
