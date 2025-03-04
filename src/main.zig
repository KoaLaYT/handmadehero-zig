const std = @import("std");
const win32 = std.os.windows;
const user32 = @import("user32.zig");

fn winMainCallback(
    hWnd: win32.HWND,
    uMsg: win32.UINT,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
) win32.LRESULT {
    var result: win32.LRESULT = 0;

    switch (uMsg) {
        user32.WM_SIZE => {},
        user32.WM_DESTROY => {},
        user32.WM_CLOSE => {},
        user32.WM_PAINT => {
            // var paint: user32.PAINTSTRUCT = undefined;
            // const device_ctx = user32.BeginPaint(hWnd, &paint);
            // const x = paint.rcPaint.left;
            // const y = paint.rcPaint.top;
            // const width = paint.rcPaint.right - paint.rcPaint.left;
            // const height = paint.rcPaint.bottom - paint.rcPaint.top;
            // _ = user32.PatBlt(device_ctx, x, y, width, height, 0);
            // _ = user32.EndPaint(hWnd, &paint);
        },
        else => {
            result = user32.DefWindowProcA(hWnd, uMsg, wParam, lParam);
        },
    }

    return result;
}

pub fn wWinMain(
    hInst: win32.HINSTANCE,
    hInstPrev: ?win32.HINSTANCE,
    cmdline: win32.LPWSTR,
    cmdshow: win32.INT,
) win32.INT {
    _ = hInstPrev;
    _ = cmdline;
    _ = cmdshow;

    var win_class = user32.WNDCLASSA.initEmpty();
    win_class.style = user32.CS_OWNDC | user32.CS_HREDRAW | user32.CS_VREDRAW;
    win_class.lpfnWndProc = winMainCallback;
    win_class.hInstance = hInst;
    win_class.lpszClassName = "HandmadeHeroWindowClass";

    if (user32.RegisterClassA(&win_class) > 0) {
        if (user32.CreateWindowExA(
            0,
            win_class.lpszClassName,
            "Handmade Hero",
            user32.WS_OVERLAPPEDWINDOW | user32.WS_VISIBLE,
            user32.CW_USEDEFAULT,
            user32.CW_USEDEFAULT,
            user32.CW_USEDEFAULT,
            user32.CW_USEDEFAULT,
            null,
            null,
            hInst,
            null,
        )) |win_handle| {
            _ = win_handle;
            while (true) {
                var msg: user32.MSG = undefined;
                const rc = user32.GetMessageA(&msg, null, 0, 0);
                if (rc > 0) {
                    _ = user32.TranslateMessage(&msg);
                    _ = user32.DispatchMessageA(&msg);
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
        errorExit();
    }

    return 0;
}

fn errorExit() void {
    // Retrieve the system error message for the last-error code

    var lpMsgBuf: win32.LPSTR = undefined;
    const dw = user32.GetLastError();
    std.debug.print("GetLastError {}\n", .{dw});

    if (user32.FormatMessageA(
        win32.FORMAT_MESSAGE_ALLOCATE_BUFFER |
            win32.FORMAT_MESSAGE_FROM_SYSTEM |
            win32.FORMAT_MESSAGE_IGNORE_INSERTS,
        null,
        dw,
        0,
        &lpMsgBuf,
        0,
        null,
    ) == 0) {
        std.debug.print("FormatMessageA failed\n", .{});
    }

    _ = user32.MessageBoxA(null, lpMsgBuf, "Error", 0);
    //
    // LocalFree(lpMsgBuf);
    // ExitProcess(dw);
}
