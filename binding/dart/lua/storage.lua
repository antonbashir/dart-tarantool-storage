getVersion = function()
    return box.space.version:get("current").value
end

setVersion = function(version)
    return box.space.version:put({ "current", version })
end