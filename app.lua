local lapis = require("lapis")
local config = require("lapis.config").get()
local Model = require("lapis.db.model").Model

local app = lapis.Application()

local Users = Model:extend("users", {
    primary_key = "steamid"
})


app:get("/", function()
    --return { json = { hello = "test"}}
    return { layout = false, "This is a test"}
end)

app:match("/login/:steamid[%d]", function(self)
  	--return { json = { hello = "test"}}
    local user = Users:find(self.params.steamid)

    if not user then
		Users:create({steamid = self.params.steamid})
		print("Creating user...")
	else
		print("User exists...")
    end

    return { layout = false, self.params.steamid}
end)

return app
