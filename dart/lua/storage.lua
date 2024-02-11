require("checkers")
require("extensions")
require("search")
require("time")
require("version")
require("reloader")
require("user")
require("migration")
safeRequire("module")


boot = function(user, password)
  if (user ~= nil and password ~= nil) then
      initializeUser(user, password)
  end
  initializeVersion()
end

-- You can add your own custom code here