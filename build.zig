const builtin = @import("builtin");
const std = @import("std");
const assert = std.debug.assert;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const zsdl2_module = b.addModule("zsdl2", .{
        .root_source_file = b.path("src/sdl2.zig"),
    });
    zsdl2_module.addIncludePath(b.path("libs/sdl2/include/"));

    _ = b.addModule("zsdl2_ttf", .{
        .root_source_file = b.path("src/sdl2_ttf.zig"),
        .imports = &.{
            .{ .name = "zsdl2", .module = zsdl2_module },
        },
    });

    _ = b.addModule("zsdl2_image", .{
        .root_source_file = b.path("src/sdl2_image.zig"),
        .imports = &.{
            .{ .name = "zsdl2", .module = zsdl2_module },
        },
    });

    _ = b.addModule("zsdl3", .{
        .root_source_file = b.path("src/sdl3.zig"),
    });

    {
        const test_step = b.step("test", "Run bindings tests");
        { // Test SDL2 bindings
            const zsdl2_tests = addTests(test_step, target, optimize, "zsdl2-tests", "src/sdl2.zig");
            link_SDL2_libs_testing(zsdl2_tests);
            prebuilt_sdl2.addLibraryPathsTo(zsdl2_tests);
        }
        { // Test SDL2_ttf bindings
            const zsdl2_ttf_tests = addTestsAux(
                test_step,
                target,
                optimize,
                "zsdl2_ttf-tests",
                "src/sdl2_ttf.zig",
                "zsdl2",
                zsdl2_module,
            );
            link_SDL2_libs_testing(zsdl2_ttf_tests);
            prebuilt_sdl2.addLibraryPathsTo(zsdl2_ttf_tests);
        }
        { // Test SDL2_image bindings
            const zsdl2_image_tests = addTestsAux(
                test_step,
                target,
                optimize,
                "zsdl2_ttf-image",
                "src/sdl2_image.zig",
                "zsdl2",
                zsdl2_module,
            );
            link_SDL2_libs_testing(zsdl2_image_tests);
            prebuilt_sdl2.addLibraryPathsTo(zsdl2_image_tests);
        }
        { // Test SDL3 bindings
            const zsdl3_tests = addTests(test_step, target, optimize, "zsdl3-tests", "src/sdl3.zig");
            link_SDL3_libs_testing(zsdl3_tests);
            prebuilt_sdl3.addLibraryPathsTo(zsdl3_tests);
        }

        if (prebuilt_sdl2.install(b, target.result, .bin, .{ .ttf = true, .image = true })) |install_sdl2_step| {
            b.getInstallStep().dependOn(install_sdl2_step);
        }

        if (prebuilt_sdl3.install(b, target.result, .bin, .{})) |install_sdl3_step| {
            b.getInstallStep().dependOn(install_sdl3_step);
        }
    }
}

fn link_SDL2_libs_testing(compile_step: *std.Build.Step.Compile) void {
    switch (compile_step.rootModuleTarget().os.tag) {
        .windows => {
            compile_step.linkSystemLibrary("SDL2");
            compile_step.linkSystemLibrary("SDL2main");
            compile_step.linkSystemLibrary("SDL2_ttf");
            compile_step.linkSystemLibrary("SDL2_image");
        },
        .linux => {
            compile_step.linkSystemLibrary("SDL2");
            compile_step.linkSystemLibrary("SDL2_ttf");
            compile_step.linkSystemLibrary("SDL2_image");
            compile_step.root_module.addRPathSpecial("$ORIGIN");
        },
        .macos => {
            compile_step.linkFramework("SDL2");
            compile_step.linkFramework("SDL2_ttf");
            compile_step.linkFramework("SDL2_image");
            compile_step.root_module.addRPathSpecial("@executable_path");
        },
        else => {},
    }
}

fn link_SDL3_libs_testing(compile_step: *std.Build.Step.Compile) void {
    switch (compile_step.rootModuleTarget().os.tag) {
        .windows => {
            compile_step.linkSystemLibrary("SDL3");
        },
        .linux => {
            compile_step.linkSystemLibrary("SDL3");
            compile_step.root_module.addRPathSpecial("$ORIGIN");
        },
        .macos => {
            compile_step.linkFramework("SDL3");
            compile_step.root_module.addRPathSpecial("@executable_path");
        },
        else => {},
    }
}

pub fn link_SDL2(compile_step: *std.Build.Step.Compile) void {
    _ = compile_step;
    @compileError("link_SDL2 no longer supported. Refer to README for linking instructions.");

    // link_SDL2 is no longer supported for linking, as it assumes too much
    // about the build environment. You should instead copy the relevant link
    // calls from the README into your build.zig file and adjust as necessary.
}

pub fn link_SDL2_ttf(compile_step: *std.Build.Step.Compile) void {
    _ = compile_step;
    @compileError("link_SDL2_ttf no longer supported. Refer to README for linking instructions.");
}

pub fn link_SDL2_image(compile_step: *std.Build.Step.Compile) void {
    _ = compile_step;
    @compileError("link_SDL2_image no longer supported. Refer to README for linking instructions.");
}

pub fn link_SDL3(compile_step: *std.Build.Step.Compile) void {
    _ = compile_step;
    @compileError("link_SDL3 no longer supported. Refer to README for linking instructions.");

    // link_SDL3 is no longer supported for linking, as it assumes too much
    // about the build environment. You should instead copy the relevant link
    // calls from the README into your build.zig file and adjust as necessary.
}

pub fn testVersionCheckSDL2(b: *std.Build, target: std.Build.ResolvedTarget) *std.Build.Step {
    const test_sdl2_version_check = b.addTest(.{
        .name = "sdl2-version-check",
        .root_module = b.createModule(.{
            .root_source_file = b.dependency("zsdl", .{}).path("src/sdl2_version_check.zig"),
            .target = target,
            .optimize = .ReleaseSafe,
        }),
    });

    link_SDL2_libs_testing(test_sdl2_version_check);

    prebuilt_sdl2.addLibraryPathsTo(test_sdl2_version_check);

    const version_check_run = b.addRunArtifact(test_sdl2_version_check);

    if (target.result.os.tag == .windows) {
        version_check_run.setCwd(.{
            .cwd_relative = b.getInstallPath(.bin, ""),
        });
    }

    version_check_run.step.dependOn(&test_sdl2_version_check.step);

    if (prebuilt_sdl2.install(b, target.result, .bin, .{})) |install_sdl2_step| {
        version_check_run.step.dependOn(install_sdl2_step);
    }

    return &version_check_run.step;
}

pub const prebuilt_sdl2 = struct {
    pub fn addLibraryPathsTo(compile_step: *std.Build.Step.Compile) void {
        const b = compile_step.step.owner;
        const target = compile_step.rootModuleTarget();
        switch (target.os.tag) {
            .windows => {
                if (target.cpu.arch.isX86()) {
                    if (b.lazyDependency("sdl2_prebuilt_x86_64_windows_gnu", .{})) |sdl2_prebuilt| {
                        compile_step.addLibraryPath(sdl2_prebuilt.path("lib"));
                    }
                }
            },
            .linux => {
                if (target.cpu.arch.isX86()) {
                    if (b.lazyDependency("sdl2_prebuilt_x86_64_linux_gnu", .{})) |sdl2_prebuilt| {
                        compile_step.addLibraryPath(sdl2_prebuilt.path("lib"));
                    }
                }
            },
            .macos => {
                if (b.lazyDependency("sdl2_prebuilt_macos", .{})) |sdl2_prebuilt| {
                    compile_step.addFrameworkPath(sdl2_prebuilt.path("Frameworks"));
                }
            },
            else => {},
        }
    }

    pub fn install(
        b: *std.Build,
        target: std.Target,
        install_dir: std.Build.InstallDir,
        aux_libs: packed struct {
            ttf: bool = false,
            image: bool = false,
        },
    ) ?*std.Build.Step {
        var install_step = b.step("Install SDL2", "Installs SDL2 and auxillary runtime libraries.");

        switch (target.os.tag) {
            .windows => {
                if (target.cpu.arch.isX86()) {
                    if (b.lazyDependency("sdl2_prebuilt_x86_64_windows_gnu", .{})) |sdl2_prebuilt| {
                        install_step.dependOn(&b.addInstallFileWithDir(
                            sdl2_prebuilt.path("bin/SDL2.dll"),
                            install_dir,
                            "SDL2.dll",
                        ).step);
                        if (aux_libs.ttf) {
                            install_step.dependOn(&b.addInstallFileWithDir(
                                sdl2_prebuilt.path("bin/SDL2_ttf.dll"),
                                install_dir,
                                "SDL2_ttf.dll",
                            ).step);
                        }
                        if (aux_libs.image) {
                            install_step.dependOn(&b.addInstallFileWithDir(
                                sdl2_prebuilt.path("bin/SDL2_image.dll"),
                                install_dir,
                                "SDL2_image.dll",
                            ).step);
                        }
                    }
                }
            },
            .linux => {
                if (target.cpu.arch.isX86()) {
                    if (b.lazyDependency("sdl2_prebuilt_x86_64_linux_gnu", .{})) |sdl2_prebuilt| {
                        install_step.dependOn(&b.addInstallFileWithDir(
                            sdl2_prebuilt.path("lib/libSDL2.so"),
                            install_dir,
                            "libSDL2.so",
                        ).step);
                        if (aux_libs.ttf) {
                            install_step.dependOn(&b.addInstallFileWithDir(
                                sdl2_prebuilt.path("lib/libSDL2_ttf.so"),
                                install_dir,
                                "libSDL2_ttf.so",
                            ).step);
                        }
                        if (aux_libs.image) {
                            install_step.dependOn(&b.addInstallFileWithDir(
                                sdl2_prebuilt.path("lib/libSDL2_image.so"),
                                install_dir,
                                "libSDL2_image.so",
                            ).step);
                        }
                    }
                }
            },
            .macos => {
                if (b.lazyDependency("sdl2_prebuilt_macos", .{})) |sdl2_prebuilt| {
                    install_step.dependOn(&b.addInstallDirectory(.{
                        .source_dir = sdl2_prebuilt.path("Frameworks/SDL2.framework"),
                        .install_dir = install_dir,
                        .install_subdir = "SDL2.framework",
                    }).step);
                    if (aux_libs.ttf) {
                        install_step.dependOn(&b.addInstallDirectory(.{
                            .source_dir = sdl2_prebuilt.path("Frameworks/SDL2_ttf.framework"),
                            .install_dir = install_dir,
                            .install_subdir = "SDL2_ttf.framework",
                        }).step);
                    }
                    if (aux_libs.image) {
                        install_step.dependOn(&b.addInstallDirectory(.{
                            .source_dir = sdl2_prebuilt.path("Frameworks/SDL2_image.framework"),
                            .install_dir = install_dir,
                            .install_subdir = "SDL2_image.framework",
                        }).step);
                    }
                }
            },
            else => {},
        }

        return install_step;
    }
};

pub const prebuilt_sdl3 = struct {
    pub fn addLibraryPathsTo(compile_step: *std.Build.Step.Compile) void {
        const b = compile_step.step.owner;
        const target = compile_step.rootModuleTarget();
        switch (target.os.tag) {
            .windows => {
                if (target.cpu.arch.isX86()) {
                    if (b.lazyDependency("sdl3_prebuilt_x86_64_windows_gnu", .{})) |sdl3_prebuilt| {
                        compile_step.addLibraryPath(sdl3_prebuilt.path("bin"));
                    }
                }
            },
            .linux => {
                if (target.cpu.arch.isX86()) {
                    if (b.lazyDependency("sdl3_prebuilt_x86_64_linux_gnu", .{})) |sdl3_prebuilt| {
                        compile_step.addLibraryPath(sdl3_prebuilt.path("lib"));
                    }
                }
            },
            .macos => {
                if (b.lazyDependency("sdl3_prebuilt_macos", .{})) |sdl3_prebuilt| {
                    compile_step.addFrameworkPath(sdl3_prebuilt.path("Frameworks"));
                }
            },
            else => {},
        }
    }

    pub fn install(
        b: *std.Build,
        target: std.Target,
        install_dir: std.Build.InstallDir,
        aux_libs: packed struct {
            // TODO
        },
    ) ?*std.Build.Step {
        _ = aux_libs;
        switch (target.os.tag) {
            .windows => {
                if (target.cpu.arch.isX86()) {
                    if (b.lazyDependency("sdl3_prebuilt_x86_64_windows_gnu", .{})) |sdl3_prebuilt| {
                        return &b.addInstallFileWithDir(
                            sdl3_prebuilt.path("bin/SDL3.dll"),
                            install_dir,
                            "SDL3.dll",
                        ).step;
                    }
                }
            },
            .linux => {
                if (target.cpu.arch.isX86()) {
                    if (b.lazyDependency("sdl3_prebuilt_x86_64_linux_gnu", .{})) |sdl3_prebuilt| {
                        return &b.addInstallFileWithDir(
                            sdl3_prebuilt.path("lib/libSDL3.so"),
                            install_dir,
                            "libSDL3.so",
                        ).step;
                    }
                }
            },
            .macos => {
                if (b.lazyDependency("sdl3_prebuilt_macos", .{})) |sdl3_prebuilt| {
                    return &b.addInstallDirectory(.{
                        .source_dir = sdl3_prebuilt.path("Frameworks/SDL3.framework"),
                        .install_dir = install_dir,
                        .install_subdir = "SDL3.framework",
                    }).step;
                }
            },
            else => {},
        }
        return null;
    }
};

fn addTests(
    test_step: *std.Build.Step,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
    root_src_path: []const u8,
) *std.Build.Step.Compile {
    const b = test_step.owner;
    const tests = b.addTest(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(root_src_path),
            .target = target,
            .optimize = optimize,
        }),
    });
    const install = b.addInstallArtifact(tests, .{});

    const run = b.addRunArtifact(tests);
    if (target.result.os.tag == .windows) {
        run.setCwd(.{
            .cwd_relative = b.getInstallPath(.bin, ""),
        });
    }

    run.step.dependOn(&install.step);
    test_step.dependOn(&run.step);
    return tests;
}

fn addTestsAux(
    test_step: *std.Build.Step,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
    root_src_path: []const u8,
    parent_module_name: []const u8,
    parent_module: *std.Build.Module,
) *std.Build.Step.Compile {
    const tests = addTests(test_step, target, optimize, name, root_src_path);
    tests.root_module.addImport(parent_module_name, parent_module);
    return tests;
}
