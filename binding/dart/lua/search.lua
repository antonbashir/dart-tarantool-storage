search = function(request)
  return box.atomic(function()
      local offset = request.offset
      local limit = request.limit
      local object = request.object
      local key = request.key
      local predicate = request.predicate
      local mapper = request.mapper
      local getLast = request.getLast

      local entities = {}

      local count = 0
      local index = 0

      if getLast ~= nil then
          local found = {}
          for _, entity in object:pairs(key) do
              if index >= offset then
                  if count >= limit then
                      break
                  end
                  if not found[entity.id:str()] then
                      entity = getLast(entity[1])
                      if (predicate == nil or predicate(entity)) then
                          if mapper ~= nil then
                              entity = mapper(entity)
                          end
                          table.insert(entities, entity)
                          found[entity[1]:str()] = true
                          count = count + 1
                      end
                  end
              end
              index = index + 1
          end
          return entities
      end

      for _, entity in object:pairs(key) do
          if index >= offset then
              if count >= limit then
                  break
              end
              if predicate == nil or predicate(entity) then
                  if mapper ~= nil then
                      entity = mapper(entity)
                  end
                  table.insert(entities, entity)
                  count = count + 1
              end
          end
          index = index + 1
      end

      return entities
  end)
end
