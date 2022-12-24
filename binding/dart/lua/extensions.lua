tupleToMap = function(tuple)
  if (tuple == nil) then
      return {}
  end
  return tuple:tomap({ names_only = true })
end

nestedArrayToMap = function(array)
  local map = {}
  for _, value in pairs(array) do
      for _, nested in pairs(value) do
          table.insert(map, tupleToMap(nested))
      end
  end
  return map
end
