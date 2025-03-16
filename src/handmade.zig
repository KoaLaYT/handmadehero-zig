pub const OffscreenBuffer = struct {
    memory: ?*anyopaque,
    width: i32,
    height: i32,
    bytes_per_pixel: i32,
};

pub fn updateAndRender(buffer: *const OffscreenBuffer, x_offset: usize, y_offset: usize) void {
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
