-- Deterministic Lua literals for generated data, including class comparisons.
local function serialize(value)
    if type(value)=='string' then return string.format('%q', value):gsub('\r','\\r'):gsub('\n','\\n') end
    if type(value)=='number' then return string.format('%.17g', value) end
    if type(value)=='boolean' then return tostring(value) end
    assert(type(value)=='table', 'Unsupported export value')
    local keys, out = {}, {'{'}
    for key in pairs(value) do keys[#keys+1] = key end
    table.sort(keys, function(a,b) if type(a)==type(b) then return a<b end return type(a)<type(b) end)
    for _, key in ipairs(keys) do out[#out+1] = '['..serialize(key)..']='..serialize(value[key])..',' end
    out[#out+1] = '}'
    return table.concat(out)
end
return serialize
