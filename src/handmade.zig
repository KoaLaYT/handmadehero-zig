const std = @import("std");

pub const ButtonState = struct {
    half_transition_count: u32,
    ended_down: bool,
};

pub const ControllerInput = struct {
    is_analog: bool,

    start_x: f32,
    start_y: f32,

    min_x: f32,
    min_y: f32,

    max_x: f32,
    max_y: f32,

    end_x: f32,
    end_y: f32,

    up: ButtonState,
    down: ButtonState,
    left: ButtonState,
    right: ButtonState,
    left_shoulder: ButtonState,
    right_shoulder: ButtonState,
};

pub const Input = struct {
    controllers: [4]ControllerInput,
};

pub const OffscreenBuffer = struct {
    memory: ?*anyopaque,
    width: i32,
    height: i32,
    bytes_per_pixel: i32,
};

pub const SoundOutputBuffer = struct {
    samples: []i16,
    samples_per_sec: u32,
};

pub fn updateAndRender(
    input: *const Input,
    buffer: *const OffscreenBuffer,
    sound_buffer: *SoundOutputBuffer,
) void {
    _ = input;

    const S = struct {
        var x_offset: usize = 0;
        var y_offset: usize = 0;
    };
    S.x_offset +%= 1;
    S.y_offset +%= 2;

    outputSound(sound_buffer);
    renderWeirdGradient(buffer, S.x_offset, S.y_offset);
}

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

fn outputSound(buffer: *SoundOutputBuffer) void {
    const S = struct {
        var t_sine: f32 = 0;
    };
    const tone_volume: f32 = 3000;
    const tone_hz = 256;
    const wave_period: f32 = @floatFromInt(buffer.samples_per_sec / tone_hz);

    std.debug.assert(buffer.samples.len % 2 == 0);
    for (0..buffer.samples.len / 2) |i| {
        const sine_value = @sin(S.t_sine);
        const sample_value: i16 = @intFromFloat(sine_value * tone_volume);
        buffer.samples[2 * i] = sample_value;
        buffer.samples[2 * i + 1] = sample_value;
        S.t_sine += 2 * std.math.pi / wave_period;
    }
}
