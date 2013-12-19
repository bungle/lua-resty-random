local ffi        = require "ffi"
local ffi_cdef   = ffi.cdef
local ffi_new    = ffi.new
local ffi_str    = ffi.string
local ffi_load   = ffi.load
local OS         = ffi.os
local C          = ffi.C
local type       = type
local random     = math.random
local randomseed = math.randomseed
local concat     = table.concat
local open       = io.open

ffi_cdef[[
int RAND_pseudo_bytes(unsigned char *buf, int num);
]]

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local alnum  = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    '0','1','2','3','4','5','6','7','8','9'
}
local function erandom(...) return nil,false end
local function prandom(len)
    local b = ffi_new("char[?]", len)
    local strong = C.RAND_pseudo_bytes(b, len)
    return ffi_str(b, len), strong == 1
end
local srandom

if pcall(prandom, 1) then
    srandom = prandom
else
    if (OS == "Windows") then
        ffi_cdef[[
        unsigned char __stdcall SystemFunction036(
            void *RandomBuffer,
            unsigned long RandomBufferLength);
        ]]
        local o,a = pcall(ffi_load, "Advapi32")
        if o then
            srandom = function(len)
                local b = ffi_new("char[?]", len)
                if a.SystemFunction036(b, len) == 1 then
                  return ffi_str(b, len),true
                else
                  return nil,false
                end
            end
        else
            srandom = erandom
        end
    else
        local r = open("/dev/urandom", "rb")
        if r then
            srandom = function(len) return r:read(len),false or nil,false end
        else
            srandom = erandom
        end
    end
end

local function bytes(len)
    return srandom(len)
end

local function seed()
    local a,b,c,d = bytes(4):byte(1, 4)
    return randomseed(a * 0x1000000 + b * 0x10000 + c * 0x100 + d)
end

local function number(min, max, reseed)
    if reseed then seed() end
    if min and max then return random(min, max)
    elseif min     then return random(min)
    else                return random() end
end

local function token(len, chars)
    chars = chars or alnum
    local count
    local token = new_tab(len, 0)
    if (type(chars) ~= "table") then
        chars = tostring(chars)
        count = #chars
        local n
        for i=1,len do
            n = number(1, count)
            token[i] = chars:sub(n, n)
        end
    else
        count = #chars
        for i=1,len do token[i] = chars[number(1, count)] end
    end
    return concat(token)
end

seed()

return {
    bytes  = bytes,
    number = number,
    token  = token
}
