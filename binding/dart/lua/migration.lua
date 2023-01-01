getVersion = function()
  return box.space.version:get("current").value
end

setVersion = function(version)
  return box.space.version:put({ "current", version })
end

migrate = function(newVersion, migrations)
    if box.info.ro then
        return
    end

    local current = getVersion()

    if current == newVersion then
        return
    end

    if newVersion > current then
        for id, migration in ipairs(migrations) do
            if id > current and id <= newVersion then
                migration.upgrade(id)
                setVersion(id)
            end
        end
        return
    end

    if newVersion < current then
        local id = current
        while id > newVersion do
            migrations[id].rollback(id)
            setVersion(id)
            id = id - 1
        end
    end
end

initializeVersion = function()
  box.once("initialize-version", function()
    local version = box.schema.create_space("version", {
        format = { { 'current', type = 'string' }, { 'value', type = 'number' } }
    })
    version:create_index("current", { unique = true, parts = { { 1, "string" } } })
    version:insert({"current", 1})
    end)
end
  