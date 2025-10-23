add_rules("mode.release", "mode.debug")
add_rules("platform.linux.bpf")
set_license("GPL-2.0")

if xmake.version():satisfies(">=2.5.7 <=2.5.9") then
    on_load(function (target)
        raise("xmake(%s) has a bug preventing BPF source code compilation. Please run `xmake update -f 2.5.6` to revert to v2.5.6 version or upgrade to xmake v2.6.1 that fixed the issue.", xmake.version())

    end)
end

option("system-libbpf",      {showmenu = true, default = false, description = "Use system-installed libbpf"})
option("require-bpftool",    {showmenu = true, default = false, description = "Require bpftool package"})

add_requires("elfutils", "zlib", "zstd")
if is_plat("android") then
    add_requires("ndk >=22.x <26", "argp-standalone")
    set_toolchains("@ndk", {sdkver = "23"})
else
    add_requires("llvm >=10.x" )
    set_toolchains("@llvm")
    add_files("linux-headers")

end

target("hello")
    set_kind("binary")
    add_files("src/*.cpp")


-- perf or Ftrace APIs
target("tracepoint")
    set_kind("binary")
    add_files("tracepoint.c", "tracepoint.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end
    if is_plat("android") then
        -- fix vmlinux.h to support android
        set_default(false)
    end

-- User Statically-Defined Tracing (USDT) probes
target("usdt")
    set_kind("binary")
    add_files("usdt.c", "usdt.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

target("uprobe")
    set_kind("binary")
    add_files("uprobe.c", "uprobe.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

target("kprobe")
    set_kind("binary")
    add_files("kprobe.c", "kprobe.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end
    if is_plat("android") then
        -- fix vmlinux.h to support android
        set_default(false)
    end

target("cgroup_device")
    set_kind("binary")
    add_files("cgroup_device.c", "cgroup_device.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

target("cgroup_skb")
    set_kind("binary")
    add_files("cgroup_skb.c", "cgroup_skb.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

target("cgroup_sysctl")
    set_kind("binary")
    add_files("cgroup_sysctl.c", "cgroup_sysctl.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

-- modify_return, fentry, fexit, iter, raw_tp
target("tracing")
    set_kind("binary")
    add_files("tracing.c", "tracing.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

target("xdp")
    set_kind("binary")
    add_files("xdp.c", "xdp.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

target("syscall")
    set_kind("binary")
    add_files("syscall.c", "syscall.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

target("struct_ops")
    set_kind("binary")
    add_files("struct.c", "struct.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

-- attached to cgroups; change settings per
-- connection or record existence of a socket
target("sock_ops")
    set_kind("binary")
    add_files("sock.c", "sock.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

-- socket_filter monitors the host network traffic
target("socket_filter")
    set_kind("binary")
    add_files("socket_filter.c", "socket_filter.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

-- socket buffer (SKB) programs are called on L4 data streams to parse L7 messages
-- and/or to determine if the L4/L7 messages should be allowed, blocked or redirected
target("sk_skb")
    set_kind("binary")
    add_files("sk_skb.c", "sk_skb.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end

target("lsm")
    set_kind("binary")
    add_files("lsm.c", "lsm.bpf.c")
    add_packages("linux-headers")
    if not has_config("system-libbpf") then
        add_deps("libbpf")
    end


--
-- If you want to known more usage about xmake, please see https://xmake.io
--
-- ## FAQ
--
-- You can enter the project directory firstly before building project.
--
--   $ cd projectdir
--
-- 1. How to build project?
--
--   $ xmake
--
-- 2. How to configure project?
--
--   $ xmake f -p [macosx|linux|iphoneos ..] -a [x86_64|i386|arm64 ..] -m [debug|release]
--
-- 3. Where is the build output directory?
--
--   The default output directory is `./build` and you can configure the output directory.
--
--   $ xmake f -o outputdir
--   $ xmake
--
-- 4. How to run and debug target after building project?
--
--   $ xmake run [targetname]
--   $ xmake run -d [targetname]
--
-- 5. How to install target to the system directory or other output directory?
--
--   $ xmake install
--   $ xmake install -o installdir
--
-- 6. Add some frequently-used compilation flags in xmake.lua
--
-- @code
--    -- add debug and release modes
--    add_rules("mode.debug", "mode.release")
--
--    -- add macro definition
--    add_defines("NDEBUG", "_GNU_SOURCE=1")
--
--    -- set warning all as error
--    set_warnings("all", "error")
--
--    -- set language: c99, c++11
--    set_languages("c99", "c++11")
--
--    -- set optimization: none, faster, fastest, smallest
--    set_optimize("fastest")
--
--    -- add include search directories
--    add_includedirs("/usr/include", "/usr/local/include")
--
--    -- add link libraries and search directories
--    add_links("tbox")
--    add_linkdirs("/usr/local/lib", "/usr/lib")
--
--    -- add system link libraries
--    add_syslinks("z", "pthread")
--
--    -- add compilation and link flags
--    add_cxflags("-stdnolib", "-fno-strict-aliasing")
--    add_ldflags("-L/usr/local/lib", "-lpthread", {force = true})
--
-- @endcode
--

