local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local ffi_load = ffi.load
local OS = ffi.os
local C = ffi.C
local random = math.random
local char = string.char

ffi.cdef[[
int RAND_pseudo_bytes(unsigned char *buf, int num);
int __stdcall CryptAcquireContextW(int *phProv, int pszContainer, int pszProvider, int dwProvType, int dwFlags);
int __stdcall CryptGenRandom(int hProv, int dwLen, char *pbBuffer);
int __stdcall CryptReleaseContext(int hProv, int dwFlags);
]]

local reseed = true

local function bytes(len)
    local buf
    if OS == "Windows" then
        local p = ffi_new("int[?]", 1)
        local b = ffi_new("char[?]", len + 2)
        local a = ffi_load("Advapi32")
        a.CryptAcquireContextW(p, 0, 0, 1, -268435456)
        a.CryptGenRandom(p[0], len, b)
        buf = ffi_str(b, len)
        a.CryptReleaseContext(p[0], 0)
    else
        local r = io.open("/dev/urandom", "rb")
        if r then
            buf = r:read(len)
            r:close()
        end
    end
    if not buf then
        local b = ffi_new("char[?]", len)
        C.RAND_pseudo_bytes(b, len)
        buf = ffi_str(b, len)
    end
    return buf
end

local function number(min, max, seed)
    if (seed or reseed) then
        local a,b,c,d = bytes(4):byte(1, 4)
        math.randomseed(a * 0x1000000 + b * 0x10000 + c * 0x100 + d)
        -- Warmup, not sure if this is neccessary.
        for i=1,6 do random() end
        reseed = false
    end
    if (min and max) then
        return random(min, max)
    elseif (min) then
        return random(min)
    end
    return random()
end

local function token(len)
    local str = ""
    for i=1,len do
        local a = number(1,3)
        if (a == 1) then
            str = str .. char(number(48, 57))
        elseif (a == 2) then
            str = str .. char(number(65, 90))
        else
            str = str .. char(number(97, 122))
        end
    end
    return str
end

return {
    bytes  = bytes,
    number = number,
    token  = token
}
