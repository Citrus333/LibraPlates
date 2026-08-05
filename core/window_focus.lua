local ffi = require('ffi');

ffi.cdef[[
    typedef void* HWND;
    typedef int BOOL;
    typedef long LPARAM;
    typedef unsigned long DWORD;
    typedef int (__stdcall *lp_enum_windows_proc_t)(HWND hWnd, LPARAM lParam);

    HWND __stdcall GetForegroundWindow(void);
    HWND __stdcall GetActiveWindow(void);
    BOOL __stdcall EnumWindows(lp_enum_windows_proc_t lpEnumFunc, LPARAM lParam);
    BOOL __stdcall IsWindowVisible(HWND hWnd);
    DWORD __stdcall GetWindowThreadProcessId(HWND hWnd, DWORD* lpdwProcessId);
    BOOL __stdcall BringWindowToTop(HWND hWnd);
    BOOL __stdcall SetForegroundWindow(HWND hWnd);
    HWND __stdcall SetActiveWindow(HWND hWnd);
    HWND __stdcall SetFocus(HWND hWnd);
    DWORD __stdcall GetCurrentProcessId(void);
]];

local windowFocus = {};

local user32 = nil;
local kernel32 = nil;
local cachedGameWindow = nil;

local function GetUser32()
    if (user32 ~= nil) then
        return user32;
    end

    local ok, loaded = pcall(function()
        return ffi.load('user32');
    end);

    if (ok == true and loaded ~= nil) then
        user32 = loaded;
    end

    return user32;
end

local function GetKernel32()
    if (kernel32 ~= nil) then
        return kernel32;
    end

    local ok, loaded = pcall(function()
        return ffi.load('kernel32');
    end);

    if (ok == true and loaded ~= nil) then
        kernel32 = loaded;
    end

    return kernel32;
end

local function GetWindowProcessId(window)
    local lib = GetUser32();

    if (lib == nil or window == nil or window == ffi.NULL) then
        return nil;
    end

    local pid = ffi.new('DWORD[1]', 0);
    local ok = pcall(function()
        lib.GetWindowThreadProcessId(window, pid);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(pid[0]);
end

local function IsCurrentProcessWindow(window)
    local k32 = GetKernel32();

    if (k32 == nil or window == nil or window == ffi.NULL) then
        return false;
    end

    local currentPid = nil;
    local ok = pcall(function()
        currentPid = tonumber(k32.GetCurrentProcessId());
    end);

    return ok == true and currentPid ~= nil and GetWindowProcessId(window) == currentPid;
end

local function FindGameWindow()
    local lib = GetUser32();

    if (lib == nil) then
        return nil;
    end

    if (cachedGameWindow ~= nil and cachedGameWindow ~= ffi.NULL and IsCurrentProcessWindow(cachedGameWindow) == true) then
        return cachedGameWindow;
    end

    local found = nil;
    local callback;
    callback = ffi.cast('lp_enum_windows_proc_t', function(window, _)
        if (window ~= nil and window ~= ffi.NULL and IsCurrentProcessWindow(window) == true) then
            local visible = false;
            pcall(function()
                visible = lib.IsWindowVisible(window) ~= 0;
            end);

            if (visible == true) then
                found = window;
                return 0;
            end
        end

        return 1;
    end);

    pcall(function()
        lib.EnumWindows(callback, 0);
    end);

    callback:free();

    if (found ~= nil and found ~= ffi.NULL) then
        cachedGameWindow = found;
    end

    return cachedGameWindow;
end

function windowFocus.IsGameWindowFocused()
    local lib = GetUser32();

    if (lib == nil) then
        return nil;
    end

    local foreground = nil;
    local ok = pcall(function()
        foreground = lib.GetForegroundWindow();
    end);

    if (ok ~= true or foreground == nil or foreground == ffi.NULL) then
        return nil;
    end

    if (IsCurrentProcessWindow(foreground) == true) then
        cachedGameWindow = foreground;
        return true;
    end

    FindGameWindow();
    return false;
end

function windowFocus.FocusGameWindow()
    local lib = GetUser32();
    local window = FindGameWindow();

    if (lib == nil or window == nil or window == ffi.NULL) then
        return false;
    end

    pcall(function()
        lib.BringWindowToTop(window);
    end);

    pcall(function()
        lib.SetForegroundWindow(window);
    end);

    pcall(function()
        lib.SetActiveWindow(window);
    end);

    pcall(function()
        lib.SetFocus(window);
    end);

    return true;
end

return windowFocus;
