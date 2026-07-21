local commands = {
  'w',
  'q',
  'wq',
  'e',
}

local suffixes = {
  '!'
}

local function variants(str)
  local n = #str
  local result = {}
  for i = 0, bit.lshift(1, n) - 1 do
    local chars = {}
    for j = 1, n do
      local c = str:sub(j, j)
      if bit.band(i, bit.lshift(1, j - 1)) ~= 0 then
        chars[j] = c:upper()
      else
        chars[j] = c
      end
    end
    local v = table.concat(chars)
    if v ~= str then
      table.insert(result, v)
    end
  end
  return result
end

for _, c in ipairs(commands) do
  for _, v in ipairs(variants(c)) do
    vim.cmd('cnoreabbrev ' .. v .. ' ' .. c)
  end
  for _, s in ipairs(suffixes) do
    for _, v in ipairs(variants(c .. s)) do
      vim.cmd('cnoreabbrev ' .. v .. ' ' .. c .. s)
    end
  end
end
