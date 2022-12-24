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
