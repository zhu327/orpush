local redis = require("resty.redis")


local function subscribe(conf, handler)
    local red = redis:new()
    red:set_timeout(conf.timeout) -- 30 sec
    local ok, err = red:connect(conf.host, conf.port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect redis: ", err)
        return
    end

    local res, err = red:subscribe(conf.channel)
    if not res then
        ngx.log(ngx.ERR, "failed to sub redis: ", err)
        return
    end

    while true do
        local res, err = red:read_reply()
        if res then
            local message = res[3]
            handler(message)
        else
            local ok, err = red:ping()
            if not ok then
                ngx.log(ngx.ERR, "failed to ping redis: ", err)
                return
            end
        end
    end
end

return subscribe