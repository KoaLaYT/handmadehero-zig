const std = @import("std");

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
    buffer: *const OffscreenBuffer,
    x_offset: usize,
    y_offset: usize,
    sound_buffer: *SoundOutputBuffer,
) void {
    outputSound(sound_buffer);
    renderWeirdGradient(buffer, x_offset, y_offset);
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
