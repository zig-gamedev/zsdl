# [zsdl](https://github.com/zig-gamedev/zsdl)

Zigified bindings for SDL libs. Work in progress.

## Getting started (SDL2)

Example `build.zig`:

```zig
pub fn build(b: *std.Build) !void {

    const exe = b.addExecutable(.{ ... });
    exe.linkLibC();

    const zsdl = b.dependency("zsdl", .{});

    exe.root_module.addImport("zsdl2", zsdl.module("zsdl2"));
    exe.root_module.addImport("zsdl2_ttf", zsdl.module("zsdl2_ttf"));
    exe.root_module.addImport("zsdl2_image", zsdl.module("zsdl2_image"));

    // Link against SDL libs
    linkSdlLibs(exe);
}
```

Link against SDL:

```zig
pub fn linkSdlLibs(compile_step: *std.Build.Step.Compile) void {
    // Adjust as needed for the libraries you are using.
    switch (compile_step.rootModuleTarget().os.tag) {
        .windows => {
            compile_step.linkSystemLibrary("SDL2");
            compile_step.linkSystemLibrary("SDL2main"); // Only needed for SDL2, not ttf or image

            compile_step.linkSystemLibrary("SDL2_ttf");
            compile_step.linkSystemLibrary("SDL2_image");
        },
        .linux => {
            compile_step.linkSystemLibrary("SDL2");
            compile_step.linkSystemLibrary("SDL2_ttf");
            compile_step.linkSystemLibrary("SDL2_image");
        },
        .macos => {
            compile_step.linkFramework("SDL2");
            compile_step.linkFramework("SDL2_ttf");
            compile_step.linkFramework("SDL2_image");
        },
        else => {},
    }
}
```

### Using prebuilt libraries
NOTE: If you want to use our prebuilt libraries also add the following run the following commands from your projects root directory to add the entres to your build.zig.zon and download the packages.
```sh
zig fetch --save git+https://github.com/zig-gamedev/sdl2-prebuilt-x86_64-windows-gnu.git#master
zig fetch --save git+https://github.com/zig-gamedev/sdl2-prebuilt-x86_64-linux-gnu.git#master
zig fetch --save git+https://github.com/zig-gamedev/sdl2-prebuilt-macos.git#master
```

And add the following to your `build.zig`:

```zig
fn build(b: *std.Build) !void {

    // ... other build steps ...

    // Optionally use prebuilt libs instead of relying on system installed SDL...
    @import("zsdl").prebuilt_sdl2.addLibraryPathsTo(exe);
    if (@import("zsdl").prebuilt_sdl2.install(b, target.result, .bin), .{
        .ttf = true,
        .image = true,
    }) |install_sdl2_step| {
        b.getInstallStep().dependOn(install_sdl2_step);
    }

    // Prebuilt libraries are installed to the executable directory. Set the RPath so the
    // executable knows where to look at runtime.
    switch (exe.rootModuleTarget().os.tag) {
        .windows => {}, // rpath is not used on Windows
        .linux => exe.root_module.addRPathSpecial("$ORIGIN"),
        .macos => exe.root_module.addRPathSpecial("@executable_path"),
        else => {},
    }
}
```

### Using zsdl2 in your code
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
