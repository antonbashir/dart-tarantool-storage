local function next(entity)
  if entity == nil then
      return 1
  end
  return entity.version + 1
end

version = {
  next = next
}