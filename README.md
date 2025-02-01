# [zsdl](https://github.com/zig-gamedev/zsdl)

Zig bindings for SDL libs. Work in progress.

## Getting started (SDL2)

Example `build.zig`:

```zig
pub fn build(b: *std.Build) !void {

    const exe = b.addExecutable(.{ ... });
    exe.linkLibC();

    const zsdl = b.dependency("zsdl", .{});
    
    exe.root_module.addImport("zsdl2", zsdl.module("zsdl2"));
    @import("zsdl").link_SDL2(exe);

    exe.root_module.addImport("zsdl2_ttf", zsdl.module("zsdl2_ttf"));
    @import("zsdl").link_SDL2_ttf(exe);
    
    exe.root_module.addImport("zsdl2_image", zsdl.module("zsdl2_image"));
    @import("zsdl").link_SDL2_image(exe);

    // Optionally use prebuilt libs instead of relying on system installed SDL...
    @import("zsdl").prebuilt.addLibraryPathsTo(exe);
    if (@import("zsdl").prebuilt.install_SDL2(b, target.result, .bin)) |install_sdl2_step| {
        b.getInstallStep().dependOn(install_sdl2_step);
    }
    if (@import("zsdl").prebuilt.install_SDL2_ttf(b, target.result, .bin)) |install_sdl2_ttf_step| {
        b.getInstallStep().dependOn(install_sdl2_ttf_step);
    }
    if (@import("zsdl").prebuilt.install_SDL2_image(b, target.result, .bin)) |install_sdl2_image_step| {
        b.getInstallStep().dependOn(install_sdl2_image_step);
    }
}
```

NOTE: If you want to use our prebuilt libraries also add the following to your `build.zig.zon`:
```zig
        .@"sdl2-prebuilt-macos" = .{
            .url = "https://github.com/zig-gamedev/sdl2-prebuilt-macos/archive/f14773fa3de719b3a399b854c31eb4139d63842f.tar.gz",
            .hash = "12205cb2da6fb4a7fcf28b9cd27b60aaf12f4d4a55be0260b1ae36eaf93ca5a99f03",
            .lazy = true,
        },
        .@"sdl2-prebuilt-x86_64-windows-gnu" = .{
            .url = "https://github.com/zig-gamedev/sdl2-prebuilt-x86_64-windows-gnu/archive/8143e2a5c28dbace399cbff14c3e8749a1afd418.tar.gz",
            .hash = "1220ade6b84d06d73bf83cef22c73ec4abc21a6d50b9f48875f348b7942c80dde11b",
            .lazy = true,
        },
        .@"sdl2-prebuilt-x86_64-linux-gnu" = .{
            .url = "https://github.com/zig-gamedev/sdl2-prebuilt-x86_64-linux-gnu/archive/2eccc574ad909b0d00b694b10c217a95145c47af.tar.gz",
            .hash = "12200ecb91c0596d0356ff39d573af83abcd44fecb27943589f11c2cd172763fea39",
            .lazy = true,
        },
```

Now in your code you may import and use `zsdl2`:

```zig
const std = @import("std");
const sdl = @import("zsdl2");

pub fn main() !void {
    ...
    try sdl.init(.{ .audio = true, .video = true });
    defer sdl.quit();

    const window = try sdl.Window.create(
        "zig-gamedev-window",
        sdl.Window.pos_undefined,
        sdl.Window.pos_undefined,
        600,
        600,
        .{ .opengl = true, .allow_highdpi = true },
    );
    defer window.destroy();
    ...
}
```

## Getting started (SDL3)
TODO
