local ngx_timer_at = ngx.timer.at
local require = require

local subscribe = require("subscribe")
local message_handler = require("handler")
local config = require("config")

local function loop_message()
    if premature then
        ngx.log(ngx.ERR, "timer was shut: ", err)
        return
    end

    while true do
        subscribe(config, message_handler)
        ngx.sleep(5) -- 连接中断时延时
    end
end

ngx_timer_at(0, loop_message)
