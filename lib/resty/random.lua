local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local C = ffi.C

ffi.cdef[[
int RAND_pseudo_bytes(unsigned char *buf, int num);
int __stdcall CryptAcquireContextW(int *phProv, int pszContainer, int pszProvider, int dwProvType, int dwFlags);
int __stdcall CryptGenRandom(int hProv, int dwLen, char *pbBuffer);
int __stdcall CryptReleaseContext(int hProv, int dwFlags);
]]

local function bytes(len)
    local buf
    if ffi.os == "Windows" then
        local p = ffi.new("int[?]", 1)
        local b = ffi.new("char[?]", len + 2)
        local a = ffi.load("Advapi32")
        a.CryptAcquireContextW(p, 0, 0, 1, -268435456)
        a.CryptGenRandom(p[0], len, b)
        buf = ffi.string(b, len)
        a.CryptReleaseContext(p[0], 0)
    else
        local random = io.open("/dev/urandom", "rb")
        if random then
            buf = random:read(len)
            random:close()
        end
    end
    if not buf then
        local b = ffi_new("char[?]", len)
        C.RAND_pseudo_bytes(b, len)
        buf = ffi_str(b, len)
    end
    return buf
end

return {
    bytes = bytes
}
