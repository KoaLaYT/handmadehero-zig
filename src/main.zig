const std = @import("std");
const win32 = std.os.windows;

extern "user32" fn MessageBoxA(
    hWnd: ?win32.HWND,
    lpText: ?win32.LPCSTR,
    lpCaption: ?win32.LPCSTR,
    uType: win32.UINT,
) callconv(.C) win32.INT;

pub fn wWinMain(
    hInst: win32.HINSTANCE,
    hInstPrev: ?win32.HINSTANCE,
    cmdline: win32.LPWSTR,
    cmdshow: win32.INT,
) win32.INT {
    _ = hInst;
    _ = hInstPrev;
    _ = cmdline;
    _ = cmdshow;

    return MessageBoxA(null, "This is Handmade Hero.", "Handmade Hero", 0);
}
