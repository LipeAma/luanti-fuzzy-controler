local function kill()
  core.clear_objects()
end

---@type ChatCommandDefinition
local commandDefinition = {
  params = "",
  privs = {},
  description = "",
  func = kill,
}

core.register_chatcommand("killall", commandDefinition)
