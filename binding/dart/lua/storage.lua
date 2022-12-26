require("checkers")
require("extensions")
require("migrate")
require("search")
require("time")
require("user")
require("version")

getVersion = function()
    return box.space.version:get("current").value
end

setVersion = function(version)
    return box.space.version:put({ "current", version })
end

box.once("initialize-version", function()
  local version = box.schema.create_space("version", {
      is_sync = true,
      format = { { 'current', type = 'string' }, { 'value', type = 'number' } }
  })
  version:create_index("current", { unique = true, parts = { { 1, "string" } } })
  version:insert({"current", 1})
end)