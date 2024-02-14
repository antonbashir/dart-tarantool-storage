
function validateCreatedSpace()
  if box.space["test-space"] == nil then return false end
  if box.space["test-space"].engine ~= 'memtx' then return false end
  if box.space["test-space"].field_count ~= 3 then return false end
  if box.space["test-space"].id ~= 3 then return false end
  if box.space["test-space"]:format() == nil then return false end
  if box.space["test-space"]:format()[1]['name'] ~= 'field-1' then return false end
  if box.space["test-space"]:format()[1]['type'] ~= 'string' then return false end
  if box.space["test-space"]:format()[2]['name'] ~= 'field-2' then return false end
  if box.space["test-space"]:format()[2]['type'] ~= 'boolean' then return false end
  if box.space["test-space"]:format()[3]['name'] ~= 'field-3' then return false end
  if box.space["test-space"]:format()[3]['type'] ~= 'integer' then return false end
  return true
end

function validateCreatedIndex()
  if box.space["test-space"].index["test-index"] == nil then return false end
  if box.space["test-space"].index["test-index"].id ~= 0 then return false end
  if box.space["test-space"].index["test-index"].type ~= 'HASH' then return false end
  if box.space["test-space"].index["test-index"].unique ~= true then return false end
  if box.space["test-space"].index["test-index"].parts[1].fieldno ~= 1 then return false end
  if box.space["test-space"].index["test-index"].parts[1].type ~= 'string' then return false end
  if box.space["test-space"].index["test-index"].parts[2].fieldno ~= 3 then return false end
  if box.space["test-space"].index["test-index"].parts[2].type ~= 'integer' then return false end
  return true
end
