local semaphore = require("ngx.semaphore")

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


function _M:dispatch(session_id, message)
    _wake_up(session_id, message)
end

return _M