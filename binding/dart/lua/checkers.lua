local function isEmptyString(string)
  return string == ""
end

local function isNotEmptyString(string)
  return string ~= ""
end

local function isEmptyTable(table)
  return next(table) == nil
end

local function isNotEmptyTable(table)
  return next(table) ~= nil
end

checkers = {
  isEmptyTable = isEmptyTable,
  isEmptyString = isEmptyString,
  isNotEmptyString = isNotEmptyString,
  isNotEmptyTable = isNotEmptyTable,
}
