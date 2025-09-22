const std = @import("std");
const bpf = @import("bpf");

const Xdp = bpf.Xdp;
const BPF = std.os.linux.BPF;
const helpers = BPF.kern.helpers;

var ipv4 = bpf.Map.HashMap("ipv4", u32, u32, 1, 0).init();
var ipv6 = bpf.Map.HashMap("ipv6", u32, u32, 1, 0).init();

// Ethernet headers
const EthHdr = extern struct {
    dest: [6]u8,
    src: [6]u8,
    proto: u16,
};

// ICMP headers
const IcmpHdr = extern struct {
    typ: u8,
    code: u8,
    checksum: u16,
    id: u16,
    seq: u16,
};

// ipv6 headers
const IPv6Hdr = extern struct {
    flow: u32,
    plen: u16,
    nxt: u8,
    hlim: u8,
    id: u16,
    seq: u16,
};

const IPv4Hdr = extern struct {
    ver_ihl: u8,
    // late tos
    dscp: u16,
    ecn: u8,
    tot_len: u16,
    id: u16,
    frag_off: u16,
    ttl: u8,
    proto: u8,
    check: u16,
    src: u32,
    dst: u32,
};

// pub
export fn xdp_dummy_prog() linksection(".sec") c_long {
    bpf.printErr(@src(), @as(c_long, 1));
    return 0;
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
