local lapis = require("lapis")
local config = require("lapis.config").get()

local app = lapis.Application()

app:get("/", function()
  return "Some text to test"
end)

return app
