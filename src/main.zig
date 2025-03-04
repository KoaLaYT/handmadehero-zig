const std = @import("std");
const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").system.system_services;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").graphics.gdi;
};

fn wndProc(
    hWnd: win32.HWND,
    uMsg: u32,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
) callconv(.winapi) win32.LRESULT {
    var result: win32.LRESULT = 0;

    switch (uMsg) {
        win32.WM_SIZE => {},
        win32.WM_DESTROY => {},
        win32.WM_CLOSE => {},
        win32.WM_PAINT => {
            var paint: win32.PAINTSTRUCT = undefined;
            const device_ctx = win32.BeginPaint(hWnd, &paint);
            const x = paint.rcPaint.left;
            const y = paint.rcPaint.top;
            const width = paint.rcPaint.right - paint.rcPaint.left;
            const height = paint.rcPaint.bottom - paint.rcPaint.top;
            _ = win32.PatBlt(device_ctx, x, y, width, height, win32.BLACKNESS);
            _ = win32.EndPaint(hWnd, &paint);
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
            while (true) {
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
