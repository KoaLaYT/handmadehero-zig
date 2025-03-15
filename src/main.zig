const std = @import("std");
const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").system.system_services;
    usingnamespace @import("zigwin32").system.memory;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").graphics.gdi;
};

const WindowDimension = struct {
    width: i32,
    height: i32,

    const Self = @This();

    fn from(hWnd: ?win32.HWND) Self {
        var client_rect: win32.RECT = undefined;
        _ = win32.GetClientRect(hWnd, &client_rect);
        const width = client_rect.right - client_rect.left;
        const height = client_rect.bottom - client_rect.top;
        return .{ .width = width, .height = height };
    }
};

const OffscreenBuffer = struct {
    info: win32.BITMAPINFO,
    memory: ?*anyopaque,
    width: i32,
    height: i32,
    bytes_per_pixel: i32,

    const Self = @This();

    fn init(width: i32, height: i32) Self {
        var buffer: OffscreenBuffer = undefined;

        // if (self.memory != null) {
        //     _ = win32.VirtualFree(self.memory, 0, win32.MEM_RELEASE);
        // }

        buffer.width = width;
        buffer.height = height;
        buffer.bytes_per_pixel = 4;
        buffer.info = .{
            .bmiHeader = .{
                .biSize = @sizeOf(win32.BITMAPINFOHEADER),
                .biWidth = buffer.width,
                .biHeight = -buffer.height,
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

        const bitmap_memory_size: usize = @intCast(buffer.width * buffer.height * buffer.bytes_per_pixel);
        buffer.memory = win32.VirtualAlloc(
            null,
            bitmap_memory_size,
            win32.MEM_COMMIT,
            win32.PAGE_READWRITE,
        );

        return buffer;
    }
};

var g_running = false;
var g_backbuffer: OffscreenBuffer = undefined;

fn renderWeirdGradient(buffer: *const OffscreenBuffer, x_offset: usize, y_offset: usize) void {
    var mem: [*]u8 = @ptrCast(buffer.memory);
    const pitch: usize = @intCast(buffer.width * buffer.bytes_per_pixel);
    for (0..@intCast(buffer.height)) |y| {
        var pixel: [*]u32 = @alignCast(@ptrCast(mem));
        for (0..@intCast(buffer.width)) |x| {
            const blue: u8 = @truncate(x + x_offset); // BB
            const green: u8 = @truncate(y + y_offset); // GG
            const red: u8 = 0; // RR
            pixel[0] = @bitCast([4]u8{ blue, green, red, 0 });
            pixel += 1;
        }
        mem += pitch;
    }
}

fn updateWindow(
    device_ctx: ?win32.HDC,
    buffer: *const OffscreenBuffer,
    width: i32,
    height: i32,
) void {
    _ = win32.StretchDIBits(
        device_ctx,
        0,
        0,
        width,
        height,
        0,
        0,
        buffer.width,
        buffer.height,
        buffer.memory,
        &buffer.info,
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
        win32.WM_SIZE => {},
        win32.WM_DESTROY => {
            g_running = false;
        },
        win32.WM_CLOSE => {
            g_running = false;
        },
        win32.WM_PAINT => {
            var paint: win32.PAINTSTRUCT = undefined;
            const device_ctx = win32.BeginPaint(hWnd, &paint);
            const window_dimension = WindowDimension.from(hWnd);
            updateWindow(device_ctx, &g_backbuffer, window_dimension.width, window_dimension.height);
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
        .style = .{ .HREDRAW = 1, .VREDRAW = 1 },
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

    g_backbuffer = OffscreenBuffer.init(1280, 720);

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
                renderWeirdGradient(&g_backbuffer, x_offset, y_offset);
                const device_ctx = win32.GetDC(win_handle);
                const dimension = WindowDimension.from(win_handle);
                updateWindow(device_ctx, &g_backbuffer, dimension.width, dimension.height);
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
