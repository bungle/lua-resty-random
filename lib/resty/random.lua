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

local reseed = true
local alnum  = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    '0','1','2','3','4','5','6','7','8','9'
}

local srandom

if (OS == "Windows") then
    ffi_cdef[[
    int __stdcall CryptAcquireContextW(
        int *phProv,
        int pszContainer,
        int pszProvider,
        int dwProvType,
        int dwFlags);
    int __stdcall CryptGenRandom(int hProv, int dwLen, char *pbBuffer);
    int __stdcall CryptReleaseContext(int hProv, int dwFlags);
    ]]
    local a = ffi_load("Advapi32")
    local p = ffi_new("int[?]", 1)
    a.CryptAcquireContextW(p, 0, 0, 1, -268435456)
    srandom = function(len)
        local b = ffi_new("char[?]", len + 2)
        a.CryptGenRandom(p[0], len, b)
        return ffi_str(buf, len)
    end
else
    local r = open("/dev/urandom", "rb")
    srandom = function(len) return r:read(len) end
end

local function prandom(len)
    local b = ffi_new("char[?]", len)
    C.RAND_pseudo_bytes(b, len)
    return ffi_str(b, len)
end

local function bytes(len)
    return srandom(len) or prandom(len)
end

local function number(min, max, seed)
    if (seed or reseed) then
        local a,b,c,d = bytes(4):byte(1, 4)
        randomseed(a * 0x1000000 + b * 0x10000 + c * 0x100 + d)
        -- Warmup, not sure if this is neccessary.
        for i=1,6 do random() end
        reseed = false
    end
    if (min and max) then return random(min, max)
    elseif (min)     then return random(min)
    else                  return random() end
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

return {
    bytes  = bytes,
    number = number,
    token  = token
}
