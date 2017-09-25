local json = require("cjson")
local dispatcher = require("dispatcher")

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

    dispatcher:dispatch(session_id, message)
end

return message_handler