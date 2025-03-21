const std = @import("std");
const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").system.system_services;
    usingnamespace @import("zigwin32").system.memory;
    usingnamespace @import("zigwin32").system.library_loader;
    usingnamespace @import("zigwin32").system.com;
    usingnamespace @import("zigwin32").system.performance;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").ui.input.xbox_controller;
    usingnamespace @import("zigwin32").ui.input.keyboard_and_mouse;
    usingnamespace @import("zigwin32").graphics.gdi;
    usingnamespace @import("zigwin32").media.audio.direct_sound;
    usingnamespace @import("zigwin32").media.audio;
};
const util = @import("util.zig");
const game = @import("handmade.zig");

const DyXInputGetState = fn (
    dwUserIndex: u32,
    pState: ?*win32.XINPUT_STATE,
) callconv(@import("std").os.windows.WINAPI) u32;
fn XInputGetStateStub(
    dwUserIndex: u32,
    pState: ?*win32.XINPUT_STATE,
) callconv(@import("std").os.windows.WINAPI) u32 {
    _ = dwUserIndex;
    _ = pState;
    return @intFromEnum(win32.ERROR_DEVICE_NOT_CONNECTED);
}
var g_XInputGetState: *const DyXInputGetState = XInputGetStateStub;

const DyXInputSetState = fn (
    dwUserIndex: u32,
    pVibration: ?*win32.XINPUT_VIBRATION,
) callconv(@import("std").os.windows.WINAPI) u32;
fn XInputSetStateStub(
    dwUserIndex: u32,
    pVibration: ?*win32.XINPUT_VIBRATION,
) callconv(@import("std").os.windows.WINAPI) u32 {
    _ = dwUserIndex;
    _ = pVibration;
    return @intFromEnum(win32.ERROR_DEVICE_NOT_CONNECTED);
}
var g_XInputSetState: *const DyXInputSetState = XInputSetStateStub;

const DyDirectSoundCreate = fn (
    pcGuidDevice: ?*const win32.Guid,
    ppDS: ?*?*win32.IDirectSound,
    pUnkOuter: ?*win32.IUnknown,
) callconv(@import("std").os.windows.WINAPI) win32.HRESULT;

fn loadXInput() void {
    const lib_name = "xinput1_4.dll";
    if (win32.LoadLibraryA(lib_name)) |module| {
        g_XInputGetState = @ptrCast(win32.GetProcAddress(module, "XInputGetState"));
        g_XInputSetState = @ptrCast(win32.GetProcAddress(module, "XInputSetState"));
    } else {
        std.debug.print("Cannot load {s}\n", .{lib_name});
    }
}

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
var g_secondary_buffer: ?*win32.IDirectSoundBuffer = undefined;

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
        win32.WM_SYSKEYDOWN,
        win32.WM_SYSKEYUP,
        win32.WM_KEYDOWN,
        win32.WM_KEYUP,
        => {
            const vk_code: win32.VIRTUAL_KEY = @enumFromInt(wParam);
            const was_down = (lParam & (1 << 30)) != 0;
            const is_down = (lParam & (1 << 31)) == 0;
            if (was_down != is_down) {
                switch (vk_code) {
                    win32.VK_W => {},
                    win32.VK_A => {},
                    win32.VK_S => {},
                    win32.VK_D => {},
                    win32.VK_Q => {},
                    win32.VK_E => {},
                    win32.VK_UP => {},
                    win32.VK_DOWN => {},
                    win32.VK_LEFT => {},
                    win32.VK_RIGHT => {},
                    win32.VK_ESCAPE => {},
                    win32.VK_SPACE => {
                        std.debug.print("SPACE: ", .{});
                        if (is_down) {
                            std.debug.print("is down ", .{});
                        }
                        if (was_down) {
                            std.debug.print("was down ", .{});
                        }
                        std.debug.print("\n", .{});
                    },
                    else => {},
                }
            }
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

const SoundOutput = struct {
    samples_per_sec: u32,
    running_sample_index: u32,
    bytes_per_sample: u32,
    secondary_buffer_size: u32,
    latency_sample_count: u32,

    const Self = @This();

    fn init(hWnd: ?win32.HWND) Self {
        const samples_per_sec = 48000;
        const bytes_per_sample = @sizeOf(i16) * 2;
        const buffer_size = samples_per_sec * bytes_per_sample;

        if (win32.LoadLibraryA("dsound.dll")) |module| {
            if (@as(?*const DyDirectSoundCreate, @ptrCast(win32.GetProcAddress(module, "DirectSoundCreate")))) |DirectSoundCreate| {
                var direct_sound_opt: ?*win32.IDirectSound = undefined;
                if (!win32.SUCCEEDED(DirectSoundCreate(null, &direct_sound_opt, null))) {
                    // TODO: diagnostic
                    @panic("DirectSoundCreate failed");
                }
                if (direct_sound_opt) |direct_sound| {
                    if (!win32.SUCCEEDED(direct_sound.SetCooperativeLevel(hWnd, win32.DSSCL_PRIORITY))) {
                        // TODO: diagnostic
                        @panic("DirectSound::SetCooperativeLevel failed");
                    }
                    var primary_desc = std.mem.zeroes(win32.DSBUFFERDESC);
                    primary_desc.dwSize = @sizeOf(win32.DSBUFFERDESC);
                    primary_desc.dwFlags = win32.DSBCAPS_PRIMARYBUFFER;
                    var primary_buffer_opt: ?*win32.IDirectSoundBuffer = undefined;
                    if (!win32.SUCCEEDED(direct_sound.CreateSoundBuffer(&primary_desc, &primary_buffer_opt, null))) {
                        // TODO: diagnostic
                        @panic("DirectSound::CreateSoundBuffer failed");
                    }
                    if (primary_buffer_opt) |primary_buffer| {
                        var wave_format = std.mem.zeroes(win32.WAVEFORMATEX);
                        wave_format.wFormatTag = win32.WAVE_FORMAT_PCM;
                        wave_format.nChannels = 2;
                        wave_format.nSamplesPerSec = samples_per_sec;
                        wave_format.nAvgBytesPerSec = samples_per_sec * 4;
                        wave_format.nBlockAlign = 4;
                        wave_format.wBitsPerSample = 16;
                        wave_format.cbSize = 0;
                        if (!win32.SUCCEEDED(primary_buffer.SetFormat(&wave_format))) {
                            // TODO: diagnostic
                            @panic("IDirectSoundBuffer::SetFormat failed");
                        }
                        var secondary_desc = std.mem.zeroes(win32.DSBUFFERDESC);
                        secondary_desc.dwSize = @sizeOf(win32.DSBUFFERDESC);
                        // secondary_desc.dwFlags = 0;
                        secondary_desc.dwBufferBytes = buffer_size;
                        secondary_desc.lpwfxFormat = &wave_format;
                        if (!win32.SUCCEEDED(direct_sound.CreateSoundBuffer(&secondary_desc, &g_secondary_buffer, null))) {
                            // TODO: diagnostic
                            @panic("DirectSound::CreateSoundBuffer failed");
                        }
                    }
                }
            }
        }

        return .{
            .samples_per_sec = samples_per_sec,
            .running_sample_index = 0,
            .bytes_per_sample = bytes_per_sample,
            .secondary_buffer_size = buffer_size,
            .latency_sample_count = samples_per_sec / 15,
        };
    }

    fn bytesToLock(self: *const Self) u32 {
        return (self.running_sample_index * self.bytes_per_sample) % self.secondary_buffer_size;
    }

    fn clear(self: *Self) void {
        var region1: ?*anyopaque = undefined;
        var region1_size: u32 = undefined;
        var region2: ?*anyopaque = undefined;
        var region2_size: u32 = undefined;

        if (win32.SUCCEEDED(g_secondary_buffer.?.Lock(
            0,
            self.secondary_buffer_size,
            &region1,
            &region1_size,
            &region2,
            &region2_size,
            0,
        ))) {
            var sample_out: [*]u8 = undefined;

            if (region1_size > 0) {
                sample_out = @alignCast(@ptrCast(region1));
                for (0..@intCast(region1_size)) |_| {
                    sample_out[0] = 0;
                    sample_out += 1;
                }
            }

            if (region2_size > 0) {
                sample_out = @alignCast(@ptrCast(region2));
                for (0..@intCast(region2_size)) |_| {
                    sample_out[0] = 0;
                    sample_out += 1;
                }
            }

            _ = g_secondary_buffer.?.Unlock(
                region1,
                region1_size,
                region2,
                region2_size,
            );
        }
    }

    fn fillBuffer(self: *Self, bytes_to_lock: u32, bytes_to_write: u32, src_buffer: *const game.SoundOutputBuffer) void {
        var region1: ?*anyopaque = undefined;
        var region1_size: u32 = undefined;
        var region2: ?*anyopaque = undefined;
        var region2_size: u32 = undefined;

        if (win32.SUCCEEDED(g_secondary_buffer.?.Lock(
            bytes_to_lock,
            bytes_to_write,
            &region1,
            &region1_size,
            &region2,
            &region2_size,
            0,
        ))) {
            var idx: usize = 0;
            var sample_out: [*]i16 = undefined;

            std.debug.assert((region1_size + region2_size) / self.bytes_per_sample <= src_buffer.samples.len);
            if (region1_size > 0) {
                sample_out = @alignCast(@ptrCast(region1));
                for (0..@intCast(region1_size / self.bytes_per_sample)) |_| {
                    sample_out[0] = src_buffer.samples[idx];
                    sample_out[1] = src_buffer.samples[idx + 1];
                    sample_out += 2;
                    idx += 2;
                    self.running_sample_index += 1;
                }
            }

            if (region2_size > 0) {
                sample_out = @alignCast(@ptrCast(region2));
                for (0..@intCast(region2_size / self.bytes_per_sample)) |_| {
                    sample_out[0] = src_buffer.samples[idx];
                    sample_out[1] = src_buffer.samples[idx + 1];
                    sample_out += 2;
                    idx += 2;
                    self.running_sample_index += 1;
                }
            }

            _ = g_secondary_buffer.?.Unlock(
                region1,
                region1_size,
                region2,
                region2_size,
            );
        }
    }
};

fn processXInputDigitalButton(
    button_state: u16,
    button_bit: u32,
    old_state: *game.ButtonState,
    new_state: *game.ButtonState,
) void {
    new_state.ended_down = (button_state & button_bit) == button_bit;
    new_state.half_transition_count = if (old_state.ended_down != new_state.ended_down) 1 else 0;
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

    loadXInput();

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
            var sound_output = SoundOutput.init(win_handle);
            sound_output.clear();
            if (!win32.SUCCEEDED(g_secondary_buffer.?.Play(0, 0, win32.DSBPLAY_LOOPING))) {
                @panic("g_secondary_buffer Play failed");
            }

            var perf_counter_frequency_result: win32.LARGE_INTEGER = undefined;
            _ = win32.QueryPerformanceFrequency(&perf_counter_frequency_result);
            const perf_counter_frequency: f32 = @floatFromInt(perf_counter_frequency_result.QuadPart);
            var last_counter: win32.LARGE_INTEGER = undefined;
            _ = win32.QueryPerformanceCounter(&last_counter);
            var last_cycle_counter = util.clockCycles();

            var inputs = std.mem.zeroes([2]game.Input);
            var old_input = &inputs[0];
            var new_input = &inputs[1];

            var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer _ = arena.deinit();
            const allocator = arena.allocator();

            g_running = true;
            while (g_running) {
                _ = arena.reset(.{ .retain_with_limit = 5 * 1024 * 1024 });

                var msg: win32.MSG = undefined;
                while (win32.PeekMessageA(&msg, null, 0, 0, win32.PM_REMOVE) > 0) {
                    if (msg.message == win32.WM_QUIT) {
                        g_running = false;
                        break;
                    }
                    _ = win32.TranslateMessage(&msg);
                    _ = win32.DispatchMessageA(&msg);
                }

                for (0..@min(new_input.controllers.len, win32.XUSER_MAX_COUNT)) |i| {
                    var controller_state: win32.XINPUT_STATE = undefined;

                    const rc = g_XInputGetState(@intCast(i), &controller_state);
                    if (@as(win32.WIN32_ERROR, @enumFromInt(rc)) == win32.ERROR_SUCCESS) {
                        // The controller is plugged in
                        const stick_x = if (controller_state.Gamepad.sThumbLX < 0)
                            @as(f32, @floatFromInt(controller_state.Gamepad.sThumbLX)) / 32768.0
                        else
                            @as(f32, @floatFromInt(controller_state.Gamepad.sThumbLX)) / 32767.0;
                        const stick_y = if (controller_state.Gamepad.sThumbLY < 0)
                            @as(f32, @floatFromInt(controller_state.Gamepad.sThumbLY)) / 32768.0
                        else
                            @as(f32, @floatFromInt(controller_state.Gamepad.sThumbLY)) / 32767.0;

                        var old_controller = &old_input.controllers[i];
                        var new_controller = &new_input.controllers[i];

                        const button_state = controller_state.Gamepad.wButtons;
                        processXInputDigitalButton(button_state, win32.XINPUT_GAMEPAD_A, &old_controller.down, &new_controller.down);
                        processXInputDigitalButton(button_state, win32.XINPUT_GAMEPAD_B, &old_controller.right, &new_controller.right);
                        processXInputDigitalButton(button_state, win32.XINPUT_GAMEPAD_X, &old_controller.left, &new_controller.left);
                        processXInputDigitalButton(button_state, win32.XINPUT_GAMEPAD_Y, &old_controller.up, &new_controller.up);
                        processXInputDigitalButton(button_state, win32.XINPUT_GAMEPAD_LEFT_SHOULDER, &old_controller.left_shoulder, &new_controller.left_shoulder);
                        processXInputDigitalButton(button_state, win32.XINPUT_GAMEPAD_RIGHT_SHOULDER, &old_controller.right_shoulder, &new_controller.right_shoulder);

                        new_controller.is_analog = true;
                        new_controller.start_x = old_controller.end_x;
                        new_controller.start_y = old_controller.end_y;

                        new_controller.min_x = stick_x;
                        new_controller.max_x = stick_x;
                        new_controller.end_x = stick_x;

                        new_controller.min_y = stick_y;
                        new_controller.max_y = stick_y;
                        new_controller.end_y = stick_y;

                        // const up = controller_state.Gamepad.wButtons & win32.XINPUT_GAMEPAD_DPAD_UP;
                        // const down = controller_state.Gamepad.wButtons & win32.XINPUT_GAMEPAD_DPAD_DOWN;
                        // const left = controller_state.Gamepad.wButtons & win32.XINPUT_GAMEPAD_DPAD_LEFT;
                        // const right = controller_state.Gamepad.wButtons & win32.XINPUT_GAMEPAD_DPAD_RIGHT;
                        // const start = controller_state.Gamepad.wButtons & win32.XINPUT_GAMEPAD_START;
                        // const back = controller_state.Gamepad.wButtons & win32.XINPUT_GAMEPAD_BACK;
                    } else {
                        // The controller is not available
                    }
                }

                var bytes_to_lock: u32 = 0;
                var bytes_to_write: u32 = 0;
                var play_cursor: u32 = undefined;
                var write_cursor: u32 = undefined;
                var sound_is_valid = false;
                if (win32.SUCCEEDED(g_secondary_buffer.?.GetCurrentPosition(&play_cursor, &write_cursor))) {
                    bytes_to_lock = sound_output.bytesToLock();
                    const target_cursor = (play_cursor + (sound_output.latency_sample_count * sound_output.bytes_per_sample)) % sound_output.secondary_buffer_size;

                    if (bytes_to_lock > target_cursor) {
                        bytes_to_write = sound_output.secondary_buffer_size - bytes_to_lock;
                        bytes_to_write += target_cursor;
                    } else {
                        bytes_to_write = target_cursor - bytes_to_lock;
                    }
                    sound_is_valid = true;
                }

                const samples = allocator.alloc(i16, 2 * bytes_to_write / sound_output.bytes_per_sample) catch unreachable;
                var sound_buffer = game.SoundOutputBuffer{
                    .samples = samples,
                    .samples_per_sec = sound_output.samples_per_sec,
                };
                const buffer = game.OffscreenBuffer{
                    .memory = g_backbuffer.memory,
                    .width = g_backbuffer.width,
                    .height = g_backbuffer.height,
                    .bytes_per_pixel = g_backbuffer.bytes_per_pixel,
                };
                game.updateAndRender(new_input, &buffer, &sound_buffer);

                if (sound_is_valid) {
                    sound_output.fillBuffer(bytes_to_lock, bytes_to_write, &sound_buffer);
                }

                const device_ctx = win32.GetDC(win_handle);
                const dimension = WindowDimension.from(win_handle);
                updateWindow(device_ctx, &g_backbuffer, dimension.width, dimension.height);
                _ = win32.ReleaseDC(win_handle, device_ctx);

                const end_cycle_counter = util.clockCycles();
                var end_counter: win32.LARGE_INTEGER = undefined;
                _ = win32.QueryPerformanceCounter(&end_counter);

                const counter_elapsed: f32 = @floatFromInt(end_counter.QuadPart - last_counter.QuadPart);
                const ms_elapsed = 1000 * counter_elapsed / perf_counter_frequency;
                const fps = perf_counter_frequency / counter_elapsed;
                const mcpf = @as(f32, @floatFromInt(end_cycle_counter - last_cycle_counter)) / 1e6;

                std.debug.print("{d:.3}ms/f - {d:.0}f/s - {d:.2}mc/f\n", .{ ms_elapsed, fps, mcpf });

                last_counter = end_counter;
                last_cycle_counter = end_cycle_counter;

                std.mem.swap(game.Input, old_input, new_input);
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
