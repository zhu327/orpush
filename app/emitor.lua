local json = require("cjson")
local dispatcher = require("dispatcher")

local method = ngx.req.get_method()
if method ~= 'POST' then
    return ngx.exit(ngx.HTTP_NOT_ALLOWED)
end

ngx.req.read_body()
local body = ngx.req.get_body_data()

local ok, data = pcall(json.decode, body)
if not ok then
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local session_id = data.session_id
local message = data.message

if not session_id or not message then
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

if type(message) == 'table' then
    message = json.encode(message)
end

dispatcher:dispatch(session_id, message)

ngx.exit(ngx.HTTP_NO_CONTENT)