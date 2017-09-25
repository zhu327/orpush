local json = require("cjson")
local redis = require("resty.redis")
local semaphore = require("ngx.semaphore")
local conf = require("config")

local _M = { _VERSION = '0.01' }

local ngx_worker_id = ngx.worker.id()

local _messages = {}
local _semaphores = {}
local _incr_id = 0
local _base_num = 100000


local function _gen_session_id()
    _incr_id = _incr_id + 1
    return (ngx_worker_id + 1) * _base_num + math.fmod(_incr_id, _base_num)
end

local function _get_shared_id(session_id)
    return math.floor(session_id/_base_num)
end

local function _get_message_key(message_id)
    return "message." .. message_id
end

local function _wake_up(session_id, message)
    if _messages[session_id] then
        table.insert(_messages[session_id], message)
        _semaphores[session_id]:post(1)
    else
        ngx.log(ngx.DEBUG, 'invalid session: '..session_id)
    end
end

function _M:gen_session_id()
    local session_id = _gen_session_id()
    while _messages[session_id] do
        session_id = _gen_session_id()
    end
    _messages[session_id] = {}
    ngx.log(ngx.DEBUG,'new session: '..session_id)
    return session_id
end

function _M:get_semaphore(session_id)
    if not _semaphores[session_id] then
        _semaphores[session_id] = semaphore.new(0)
    end
    return _semaphores[session_id]
end

function _M:get_messages(session_id)
    local messages = _messages[session_id]
    _messages[session_id] = {}
    return messages
end

function _M:destory(session_id)
    ngx.log(ngx.DEBUG,'destory session: '..session_id)
    _messages[session_id] = nil
    _semaphores[session_id] = nil
end

local function message_handler(message)
    local ok, data = pcall(json.decode, message)
    if not ok then
        return
    end
    
    local session_id = data.session_id
    local message = data.message
    
    if not session_id or not message then
        return
    end

    _wake_up(session_id, message)
end

local function subscribe(conf)
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
            message_handler(message)
        else
            local ok, err = red:ping()
            if not ok then
                ngx.log(ngx.ERR, "failed to ping redis: ", err)
                return
            end
        end
    end
end

function _M.loop_message(premature)
    while true do
        subscribe(conf)
    end
end

function _M:dispatch(session_id, message)
    _wake_up(session_id, message)
end

return _M