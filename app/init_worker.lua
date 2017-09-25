local ngx_timer_at = ngx.timer.at
local require = require

local dispatcher = require("dispatcher")

ngx_timer_at(0, dispatcher.loop_message)