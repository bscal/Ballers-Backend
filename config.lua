-- config.lua
local config = require("lapis.config")
local credentials = require("credentials")

config("development", {
  port = 9090,
  mysql = credentials.mysql
})
