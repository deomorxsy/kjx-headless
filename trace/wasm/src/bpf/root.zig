const std = @import("std");
const trace_printk = std.os.linux.BPF.kern.helpers.trace_printk;
const builtin = std.builtin;
const SourceLocation = builtin.SourceLocation;
const StackTrace = builtin.StackTrace;


pub const Tracepoint = @import("tracepoint.zig");
pub const Xdp = @import("xdp.zig");


pub inline fn printErr(comptime src: SourceLocation, ret: c_long) void {
    const fmt = "error occur at %s:%d return %d";
    const file = @as(*const [src.file.len:0]u8, @ptrCast(src.file)).*;
    const line = src.line;

    _ = trace_printk(fmt, fmt.len + 1, @intFromPtr(&file), line, @bitCast))
}
// ?* optional pointer
pub inline fn panic(msg: []const u8, error_return_trace: ?*StackTrace, ret_addr: ?usize) {

}
