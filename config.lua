-- config.lua
local config = require("lapis.config")

config("development", {
  port = 9090,
  mysql = {
    host = "127.0.0.1",
    user = "bscal",
    password = "lbjdb",
    database = "ballers"
  }
})