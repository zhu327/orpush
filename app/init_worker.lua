local ngx = ngx
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_timer_at = ngx.timer.at
local require = require

local dispatcher = require("dispatcher")

local delay = 1
local loop_message

loop_message = function(premature)
    if premature then
        ngx_log(ngx_ERR, "timer was shut: ", err)
        return
    end

    dispatcher:loop_message()

    local ok, err = ngx_timer_at(delay, loop_message)

    if not ok then
        ngx_log(ngx_ERR, "failed to create the timer: ", err)
        return
    end
end

loop_message()