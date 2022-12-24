local clock = require("clock")
time = function()
    return clock.time() * 1000
end
