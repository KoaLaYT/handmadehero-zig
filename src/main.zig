const std = @import("std");
const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").system.system_services;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").graphics.gdi;
};

var g_running = false;
var g_bitmap_info: win32.BITMAPINFO = undefined;
var g_bitmap_memory: ?*anyopaque = null;
var g_bitmap_handle: ?win32.HBITMAP = null;
var g_bitmap_device_ctx: ?win32.HDC = null;

fn resizeDIBSection(width: i32, height: i32) void {
    if (g_bitmap_handle != null) {
        _ = win32.DeleteObject(g_bitmap_handle);
    }

    if (g_bitmap_device_ctx == null) {
        g_bitmap_device_ctx = win32.CreateCompatibleDC(null);
    }

    g_bitmap_info = .{
        .bmiHeader = .{
            .biSize = @sizeOf(win32.BITMAPINFOHEADER),
            .biWidth = width,
            .biHeight = height,
            .biPlanes = 1,
            .biBitCount = 32,
            .biCompression = win32.BI_RGB,
            .biSizeImage = 0,
            .biXPelsPerMeter = 0,
            .biYPelsPerMeter = 0,
            .biClrUsed = 0,
            .biClrImportant = 0,
        },
        .bmiColors = std.mem.zeroes([1]win32.RGBQUAD),
    };

    g_bitmap_handle = win32.CreateDIBSection(
        g_bitmap_device_ctx,
        &g_bitmap_info,
        win32.DIB_RGB_COLORS,
        &g_bitmap_memory,
        null,
        0,
    );
}

fn updateWindow(device_ctx: ?win32.HDC, x: i32, y: i32, width: i32, height: i32) void {
    _ = win32.StretchDIBits(
        device_ctx,
        x,
        y,
        width,
        height,
        x,
        y,
        width,
        height,
        null,
        null,
        win32.DIB_RGB_COLORS,
        win32.SRCCOPY,
    );
}

fn wndProc(
    hWnd: win32.HWND,
    uMsg: u32,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
) callconv(.winapi) win32.LRESULT {
    var result: win32.LRESULT = 0;

    switch (uMsg) {
        win32.WM_SIZE => {
            var client_rect: win32.RECT = undefined;
            _ = win32.GetClientRect(hWnd, &client_rect);
            const width = client_rect.right - client_rect.left;
            const height = client_rect.bottom - client_rect.top;
            resizeDIBSection(width, height);
        },
        win32.WM_DESTROY => {
            g_running = false;
        },
        win32.WM_CLOSE => {
            g_running = false;
        },
        win32.WM_PAINT => {
            var paint: win32.PAINTSTRUCT = undefined;
            const device_ctx = win32.BeginPaint(hWnd, &paint);
            const x = paint.rcPaint.left;
            const y = paint.rcPaint.top;
            const width = paint.rcPaint.right - paint.rcPaint.left;
            const height = paint.rcPaint.bottom - paint.rcPaint.top;
            updateWindow(device_ctx, x, y, width, height);
        },
        else => {
            result = win32.DefWindowProcA(hWnd, uMsg, wParam, lParam);
        },
    }

    return result;
}

pub fn wWinMain(
    hInst: win32.HINSTANCE,
    hInstPrev: ?win32.HINSTANCE,
    cmdline: [*:0]u16,
    cmdshow: c_int,
) c_int {
    _ = hInstPrev;
    _ = cmdline;
    _ = cmdshow;

    const win_class = win32.WNDCLASSA{
        .style = .{ .OWNDC = 1, .HREDRAW = 1, .VREDRAW = 1 },
        .lpfnWndProc = wndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInst,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = "HandmadeHeroWindowClass",
    };

    if (win32.RegisterClassA(&win_class) > 0) {
        var style = win32.WS_OVERLAPPEDWINDOW;
        style.VISIBLE = 1;

        if (win32.CreateWindowExA(
            .{},
            win_class.lpszClassName,
            "Handmade Hero",
            style,
            win32.CW_USEDEFAULT,
            win32.CW_USEDEFAULT,
            win32.CW_USEDEFAULT,
            win32.CW_USEDEFAULT,
            null,
            null,
            hInst,
            null,
        )) |win_handle| {
            _ = win_handle;
            g_running = true;
            while (g_running) {
                var msg: win32.MSG = undefined;
                const rc = win32.GetMessageA(&msg, null, 0, 0);
                if (rc > 0) {
                    _ = win32.TranslateMessage(&msg);
                    _ = win32.DispatchMessageA(&msg);
                } else {
                    break;
                }
            }
        } else {
            // TODO log
            std.debug.print("CreateWindowExA failed\n", .{});
        }
    } else {
        // TODO log
        std.debug.print("RegisterClassA failed\n", .{});
    }

    return 0;
}
