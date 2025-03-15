const std = @import("std");
const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").system.system_services;
    usingnamespace @import("zigwin32").system.memory;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").graphics.gdi;
};

var g_running = false;
var g_bitmap_info: win32.BITMAPINFO = undefined;
var g_bitmap_memory: ?*anyopaque = null;
var g_bitmap_width: i32 = undefined;
var g_bitmap_height: i32 = undefined;

fn renderWeirdGradient(x_offset: usize, y_offset: usize) void {
    var mem: [*]u8 = @ptrCast(g_bitmap_memory);
    const pitch: usize = @intCast(g_bitmap_width * 4);
    for (0..@intCast(g_bitmap_height)) |y| {
        var pixel: [*]u32 = @alignCast(@ptrCast(mem));
        for (0..@intCast(g_bitmap_width)) |x| {
            const blue: u8 = @truncate(x + x_offset); // BB
            const green: u8 = @truncate(y + y_offset); // GG
            const red: u8 = 0; // RR
            pixel[0] = @bitCast([4]u8{ blue, green, red, 0 });
            pixel += 1;
        }
        mem += pitch;
    }
}

fn resizeDIBSection(width: i32, height: i32) void {
    if (g_bitmap_memory != null) {
        _ = win32.VirtualFree(g_bitmap_memory, 0, win32.MEM_RELEASE);
    }

    g_bitmap_width = width;
    g_bitmap_height = height;

    g_bitmap_info = .{
        .bmiHeader = .{
            .biSize = @sizeOf(win32.BITMAPINFOHEADER),
            .biWidth = g_bitmap_width,
            .biHeight = -g_bitmap_height,
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

    const bitmap_memory_size: usize = @intCast(g_bitmap_width * g_bitmap_height * 4);
    g_bitmap_memory = win32.VirtualAlloc(
        null,
        bitmap_memory_size,
        win32.MEM_COMMIT,
        win32.PAGE_READWRITE,
    );
}

fn updateWindow(device_ctx: ?win32.HDC, window_rect: *const win32.RECT) void {
    const window_width = window_rect.right - window_rect.left;
    const window_height = window_rect.bottom - window_rect.top;
    _ = win32.StretchDIBits(
        device_ctx,
        0,
        0,
        g_bitmap_width,
        g_bitmap_height,
        0,
        0,
        window_width,
        window_height,
        g_bitmap_memory,
        &g_bitmap_info,
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
            _ = win32.BeginPaint(hWnd, &paint);
            // var client_rect: win32.RECT = undefined;
            // _ = win32.GetClientRect(hWnd, &client_rect);
            // updateWindow(device_ctx, &client_rect);
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
            g_running = true;
            var x_offset: usize = 0;
            var y_offset: usize = 0;
            while (g_running) {
                var msg: win32.MSG = undefined;
                while (win32.PeekMessageA(&msg, null, 0, 0, win32.PM_REMOVE) > 0) {
                    if (msg.message == win32.WM_QUIT) {
                        g_running = false;
                        break;
                    }
                    _ = win32.TranslateMessage(&msg);
                    _ = win32.DispatchMessageA(&msg);
                }
                renderWeirdGradient(x_offset, y_offset);
                const device_ctx = win32.GetDC(win_handle);
                var client_rect: win32.RECT = undefined;
                _ = win32.GetClientRect(win_handle, &client_rect);
                updateWindow(device_ctx, &client_rect);
                _ = win32.ReleaseDC(win_handle, device_ctx);
                x_offset +%= 1;
                y_offset +%= 1;
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
