const std = @import("std");
const win32 = std.os.windows;

// Class Styles
pub const CS_HREDRAW: win32.UINT = 0x0002;
pub const CS_OWNDC: win32.UINT = 0x0020;
pub const CS_VREDRAW: win32.UINT = 0x0001;

// Window Notifications
pub const WM_DESTROY: win32.UINT = 0x0002;
pub const WM_SIZE: win32.UINT = 0x0005;
pub const WM_CLOSE: win32.UINT = 0x0010;
pub const WM_ACTIVATEAPP: win32.UINT = 0x001C;
pub const WM_PAINT: win32.UINT = 0x000F;

// Window Styles
pub const WS_OVERLAPPED: win32.DWORD = 0x00000000;
pub const WS_CAPTION: win32.DWORD = 0x00C00000;
pub const WS_SYSMENU: win32.DWORD = 0x00080000;
pub const WS_THICKFRAME: win32.DWORD = 0x00040000;
pub const WS_MINIMIZEBOX: win32.DWORD = 0x00020000;
pub const WS_MAXIMIZEBOX: win32.DWORD = 0x00010000;
pub const WS_OVERLAPPEDWINDOW: win32.DWORD = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
pub const WS_VISIBLE: win32.DWORD = 0x10000000;

pub const CW_USEDEFAULT: c_int = -2147483648;

// FormatMessage
pub const FORMAT_MESSAGE_ALLOCATE_BUFFER: win32.DWORD = 0x00000100;
pub const FORMAT_MESSAGE_FROM_SYSTEM: win32.DWORD = 0x00001000;
pub const FORMAT_MESSAGE_IGNORE_INSERTS: win32.DWORD = 0x00000200;

pub const WNDCLASSA = struct {
    style: win32.UINT,
    lpfnWndProc: ?*const WNDPROC,
    cbClsExtra: c_int,
    cbWndExtra: c_int,
    hInstance: ?win32.HINSTANCE,
    hIcon: ?win32.HICON,
    hCursor: ?win32.HCURSOR,
    hbrBackground: ?win32.HBRUSH,
    lpszMenuName: ?win32.LPSTR,
    lpszClassName: ?win32.LPCSTR,

    const Self = @This();
    const WNDPROC = fn (
        hWnd: win32.HWND,
        uMsg: win32.UINT,
        wParam: win32.WPARAM,
        lParam: win32.LPARAM,
    ) win32.LRESULT;

    pub fn initEmpty() Self {
        return .{
            .style = 0,
            .lpfnWndProc = null,
            .cbClsExtra = 0,
            .cbWndExtra = 0,
            .hInstance = null,
            .hIcon = null,
            .hCursor = null,
            .hbrBackground = null,
            .lpszMenuName = null,
            .lpszClassName = null,
        };
    }
};

pub const MSG = struct {
    hwnd: win32.HWND,
    message: win32.UINT,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
    time: win32.DWORD,
    pt: win32.POINT,
    lPrivate: win32.DWORD,
};

pub const PAINTSTRUCT = struct {
    hdc: win32.HDC,
    fErase: win32.BOOL,
    rcPaint: win32.RECT,
    fRestore: win32.BOOL,
    fIncUpdate: win32.BOOL,
    rgbReserved: [32]win32.BYTE,
};

pub extern "user32" fn MessageBoxA(
    hWnd: ?win32.HWND,
    lpText: ?win32.LPCSTR,
    lpCaption: ?win32.LPCSTR,
    uType: win32.UINT,
) callconv(.C) win32.INT;

pub extern "user32" fn DefWindowProcA(
    hWnd: win32.HWND,
    Msg: win32.UINT,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
) callconv(.C) win32.LRESULT;

pub extern "user32" fn RegisterClassA(
    WNDCLASSA: *const WNDCLASSA,
) callconv(.C) win32.ATOM;

pub extern "user32" fn CreateWindowExA(
    dwExStyle: win32.DWORD,
    lpClassName: ?win32.LPCSTR,
    lpWindowName: ?win32.LPCSTR,
    dwStyle: win32.DWORD,
    X: c_int,
    Y: c_int,
    nWidth: c_int,
    nHeight: c_int,
    hWndParent: ?win32.HWND,
    hMenu: ?win32.HMENU,
    hInstance: ?win32.HINSTANCE,
    lpParam: ?win32.LPVOID,
) callconv(.C) ?win32.HWND;

pub extern "user32" fn GetMessageA(
    lpMsg: *MSG,
    hWnd: ?win32.HWND,
    wMsgFilterMin: win32.UINT,
    wMsgFilterMax: win32.UINT,
) callconv(.C) win32.BOOL;

pub extern "user32" fn TranslateMessage(
    lpMsg: *const MSG,
) callconv(.C) win32.BOOL;

pub extern "user32" fn DispatchMessageA(
    lpMsg: *const MSG,
) callconv(.C) win32.LRESULT;

pub extern "user32" fn BeginPaint(
    hWnd: win32.HWND,
    lpPaint: *PAINTSTRUCT,
) callconv(.C) win32.HDC;

pub extern "user32" fn EndPaint(
    hWnd: win32.HWND,
    lpPaint: *const PAINTSTRUCT,
) callconv(.C) win32.BOOL;

pub extern "user32" fn PatBlt(
    hdc: win32.HDC,
    x: c_int,
    y: c_int,
    w: c_int,
    h: c_int,
    rop: win32.DWORD,
) callconv(.C) win32.BOOL;

pub extern "user32" fn GetLastError() callconv(.C) win32.DWORD;

pub extern "user32" fn FormatMessageA(
    dwFlags: win32.DWORD,
    lpSource: ?win32.LPCVOID,
    dwMessageId: win32.DWORD,
    dwLanguageId: win32.DWORD,
    lpBuffer: *win32.LPSTR,
    nSize: win32.DWORD,
    va_list: ?*anyopaque,
) callconv(.C) win32.DWORD;
