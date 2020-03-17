-- config.lua
local config = require("lapis.config")
local credentials = require("credentials")

if credentials.mysql.password == "password" then
  print("[Warning] If you a receiving mysql errors you might have forgotten to change credentials.lua values!")
end

config("development", {
  port = 9090,
  mysql = credentials.mysql
})
