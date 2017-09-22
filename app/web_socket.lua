local server = require("resty.websocket.server")
local dispatcher = require("dispatcher")

local wbsocket, err = server:new{
    timeout = 30000,
    max_payload_len = 65535
}

if not wbsocket then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(ngx.HTTP_CLOSE)
end

local session_id = dispatcher:gen_session_id()
local send_semaphore = dispatcher:get_semaphore(session_id)
local close_flag = false

local function _push_thread_function()
    while not close_flag do
        local ok, err = send_semaphore:wait(300)

        if ok then
            local messages = dispatcher:get_messages(session_id)

            for i, message in ipairs(messages) do
                local bytes, err = wbsocket:send_text(message)
                if not bytes then
                    close_flag = true
                    ngx.log(ngx.DEBUG, 'send text failed session: '..session_id, err)
                    break
                end
            end
        end
    end

    dispatcher:destory(session_id)
end

local push_thread = ngx.thread.spawn(_push_thread_function)

while not close_flag do
    local data, typ, err = wbsocket:recv_frame()

    while err == "again" do
        local cut_data
        cut_data, typ, err = wbsocket:recv_frame()
        data = (data or '') .. cut_data
    end

    if not data then
        local bytes, err = wbsocket:send_ping()
        if not bytes then
            ngx.log(ngx.DEBUG, 'send ping failed session: '..session_id, err)
            close_flag = true
            send_semaphore:post(1)
            break
        end
    elseif typ == 'close' then
        close_flag = true
        send_semaphore:post(1)
        ngx.log(ngx.DEBUG, 'close session: '..session_id, err)
        break
    elseif typ == 'ping' then
        local bytes, err = wbsocket:send_pong(data)
        if not bytes then
            close_flag = true
            send_semaphore:post(1)
            ngx.log(ngx.DEBUG, 'send pong failed session: '..session_id, err)
            break
        end
    elseif typ == 'pong' then
    elseif typ == 'text' then
    -- your receive function handler
    elseif typ == 'continuation' then
    elseif typ == 'binary' then
    end

end

ngx.thread.wait(push_thread)
wbsocket:send_close()