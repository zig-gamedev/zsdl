//! SDL3 bindings for Zig
//! Ordered by category as per https://wiki.libsdl.org/SDL3/APIByCategory

const builtin = @import("builtin");

const std = @import("std");
const assert = std.debug.assert;
const log = std.log.scoped(.zsdl3);

const sdl3 = @This();

test {
    _ = std.testing.refAllDeclsRecursive(sdl3);
}

//--------------------------------------------------------------------------------------------------
//
// Application entry points (SDL_main.h)
//
//--------------------------------------------------------------------------------------------------

pub const AppResult = enum(c_int) {
    @"continue" = 0,
    success = 1,
    failure = 2,
};

pub const appInit = SDL_AppInit;
extern fn SDL_AppInit(appstate: ?*?*anyopaque, argc: c_int, argv: [*c][*c]const u8) AppResult;

pub const appIterate = SDL_AppIterate;
extern fn SDL_AppIterate(appstate: ?*anyopaque) AppResult;

pub const appEvent = SDL_AppEvent;
extern fn SDL_AppEvent(appstate: ?*anyopaque, event: *Event) AppResult;

pub const appQuit = SDL_AppQuit;
extern fn SDL_AppQuit(appstate: ?*anyopaque, result: AppResult) void;

pub const AppInit_func = fn (?*?*anyopaque, c_int, [*c][*c]const u8) callconv(.c) AppResult;
pub const AppIterate_func = fn (?*anyopaque) callconv(.c) AppResult;
pub const AppEvent_func = fn (?*anyopaque, *Event) callconv(.c) AppResult;
pub const AppQuit_func = fn (?*anyopaque, AppResult) callconv(.c) void;

pub const enterAppMainCallbacks = SDL_EnterAppMainCallbacks;
extern fn SDL_EnterAppMainCallbacks(
    argc: c_int,
    argv: [*c][*c]u8,
    appinit: ?*const AppInit_func,
    appiter: ?*const AppIterate_func,
    appevent: ?*const AppEvent_func,
    appquit: ?*const AppQuit_func,
) c_int;

pub const setMainReady = SDL_SetMainReady;
extern fn SDL_SetMainReady() void;

//--------------------------------------------------------------------------------------------------
//
// Initialization and Shutdown (SDL_init.h)
//
//--------------------------------------------------------------------------------------------------
pub const InitFlags = packed struct(u32) {
    __unused0: bool = false,
    __unused1: bool = false,
    __unused2: bool = false,
    __unused3: bool = false,
    audio: bool = false,
    video: bool = false,
    __unused6: bool = false,
    __unused7: bool = false,
    __unused8: bool = false,
    joystick: bool = false,
    __unused10: bool = false,
    __unused11: bool = false,
    haptic: bool = false,
    gamepad: bool = false,
    events: bool = false,
    sensor: bool = false,
    camera: bool = false,
    __unused17: u15 = 0,

    pub const everything: InitFlags = .{
        .audio = true,
        .video = true,
        .events = true,
        .joystick = true,
        .haptic = true,
        .gamepad = true,
        .sensor = true,
        .camera = true,
    };
};

pub fn init(flags: InitFlags) Error!void {
    if (!SDL_Init(flags)) return makeError();
}
extern fn SDL_Init(flags: InitFlags) bool;

pub const quit = SDL_Quit;
extern fn SDL_Quit() void;

//--------------------------------------------------------------------------------------------------
//
// Configuration Variables (SDL_hints.h)
//
//--------------------------------------------------------------------------------------------------
pub const hint_windows_dpi_awareness = "SDL_WINDOWS_DPI_AWARENESS";

pub fn setHint(name: [:0]const u8, value: [:0]const u8) bool {
    return SDL_SetHint(@ptrCast(name.ptr), @ptrCast(value.ptr));
}
extern fn SDL_SetHint(name: [*c]const u8, value: [*c]const u8) bool;

pub fn setAppMetadata(name: [:0]const u8, version: [:0]const u8, identifier: [:0]const u8) Error!void {
    if (!SDL_SetAppMetadata(@ptrCast(name.ptr), @ptrCast(version.ptr), @ptrCast(identifier.ptr))) {
        return makeError();
    }
}
extern fn SDL_SetAppMetadata(appname: [*c]const u8, appversion: [*c]const u8, appidentifier: [*c]const u8) bool;

//--------------------------------------------------------------------------------------------------
//
// Object Properties (SDL_properties.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Error Handling (SDL_error.h)
//
//--------------------------------------------------------------------------------------------------
pub fn getError() ?[:0]const u8 {
    if (SDL_GetError()) |err_str| {
        return std.mem.span(err_str);
    }
    return null;
}
extern fn SDL_GetError() [*c]const u8;

pub const Error = error{SdlError};

pub fn makeError() error{SdlError} {
    if (getError()) |str| {
        log.debug("{s}", .{str});
    }
    return error.SdlError;
}

//--------------------------------------------------------------------------------------------------
//
// Log Handling (SDL_log.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Assertions (SDL_assert.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Querying SDL Version (SDL_version.h)
//
//--------------------------------------------------------------------------------------------------
pub const Version = extern struct {
    major: u8,
    minor: u8,
    patch: u8,
};

/// Returns the linked SDL version
pub fn getVersion() Version {
    var version: Version = undefined;
    SDL_GetVersion(&version);

    return version;
}
extern fn SDL_GetVersion(version: *Version) void;

//--------------------------------------------------------------------------------------------------
//
// Display and Window Management (SDL_video.h)
//
//--------------------------------------------------------------------------------------------------
pub const DisplayId = u32;

pub const WindowId = u32;

pub const DisplayMode = extern struct {
    displayId: DisplayId,
    format: PixelFormatEnum,
    w: c_int,
    h: c_int,
    pixel_density: f32,
    refresh_rate: f32,
    refresh_rate_numerator: c_int,
    refresh_rate_denominator: c_int,
    internal: ?*anyopaque,
};

pub const Window = opaque {
    pub const Flags = packed struct(u64) {
        fullscreen: bool = false,
        opengl: bool = false,
        occluded: bool = false,
        hidden: bool = false,
        borderless: bool = false, // 0x10
        resizable: bool = false,
        minimized: bool = false,
        maximized: bool = false,
        mouse_grabbed: bool = false, // 0x100
        input_focus: bool = false,
        mouse_focus: bool = false,
        external: bool = false,
        modal: bool = false, // 0x1000
        high_pixel_density: bool = false,
        mouse_capture: bool = false,
        mouse_relative_mode: bool = false,
        always_on_top: bool = false, // 0x10000
        utility: bool = false,
        tooltip: bool = false,
        popup_menu: bool = false,
        keyboard_grabbed: bool = false,
        __unused21: u7 = 0,
        vulkan: bool = false, // 0x10000000
        metal: bool = false,
        transparent: bool = false,
        not_focusable: bool = false,
        __unused32: u32 = 0,
    };

    pub const pos_undefined = posUndefinedDisplay(0);
    pub const pos_centered = posCenteredDisplay(0);

    pub const create = createWindow;
    pub const destroy = destroyWindow;
    pub const getFullscreenMode = getWindowFullscreenMode;
    pub const getPosition = getWindowPosition;
    pub const getSize = getWindowSize;
    pub const setTitle = setWindowTitle;
};

pub fn posUndefinedDisplay(x: i32) i32 {
    return pos_undefined_mask | x;
}
pub fn posCenteredDisplay(x: i32) i32 {
    return pos_centered_mask | x;
}

const pos_undefined_mask: i32 = 0x1fff_0000;
const pos_centered_mask: i32 = 0x2fff_0000;

pub fn createWindow(title: ?[*:0]const u8, w: c_int, h: c_int, flags: Window.Flags) Error!*Window {
    assert(w > 0);
    assert(h > 0);
    return SDL_CreateWindow(title, w, h, flags) orelse return makeError();
}
extern fn SDL_CreateWindow(title: ?[*:0]const u8, w: c_int, h: c_int, flags: Window.Flags) ?*Window;

pub const destroyWindow = SDL_DestroyWindow;
extern fn SDL_DestroyWindow(window: *Window) void;

pub const getWindowFullscreenMode = SDL_GetWindowFullscreenMode;
extern fn SDL_GetWindowFullscreenMode(window: *Window) ?*const DisplayMode;

pub fn getWindowPosition(window: *Window, w: ?*c_int, h: ?*c_int) Error!void {
    if (!SDL_GetWindowPosition(window, w, h)) return makeError();
}
extern fn SDL_GetWindowPosition(window: *Window, x: ?*c_int, y: ?*c_int) bool;

pub fn getWindowSize(window: *Window, w: ?*c_int, h: ?*c_int) Error!void {
    if (!SDL_GetWindowSize(window, w, h)) return makeError();
}
extern fn SDL_GetWindowSize(window: *Window, w: ?*c_int, h: ?*c_int) bool;

pub fn setWindowTitle(window: *Window, title: [:0]const u8) void {
    SDL_SetWindowTitle(window, @ptrCast(title.ptr));
}
extern fn SDL_SetWindowTitle(window: *Window, title: [*c]const u8) void;

pub const getNumVideoDrivers = SDL_GetNumVideoDrivers;
extern fn SDL_GetNumVideoDrivers() c_int;

pub fn getVideoDriver(index: u16) ?[:0]const u8 {
    if (SDL_GetVideoDriver(@intCast(index))) |ptr| {
        return std.mem.span(ptr);
    }
    return null;
}
extern fn SDL_GetVideoDriver(index: c_int) [*c]const u8;

pub const gl = struct {
    pub const Context = *anyopaque;

    pub const FunctionPointer = ?*const anyopaque;

    pub const Attr = enum(i32) {
        red_size,
        green_size,
        blue_size,
        alpha_size,
        buffer_size,
        doublebuffer,
        depth_size,
        stencil_size,
        accum_red_size,
        accum_green_size,
        accum_blue_size,
        accum_alpha_size,
        stereo,
        multisamplebuffers,
        multisamplesamples,
        accelerated_visual,
        retained_backing,
        context_major_version,
        context_minor_version,
        context_flags,
        context_profile_mask,
        share_with_current_context,
        framebuffer_srgb_capable,
        context_release_behavior,
        context_reset_notification,
        context_no_error,
        floatbuffers,
    };

    pub const Profile = enum(c_int) {
        core = 0x0001,
        compatibility = 0x0002,
        es = 0x0004,
    };

    pub const ContextFlags = packed struct(i32) {
        debug: bool = false,
        forward_compatible: bool = false,
        robust_access: bool = false,
        reset_isolation: bool = false,
        __unused: i28 = 0,
    };

    pub const ContextReleaseFlags = packed struct(i32) {
        flush: bool = false,
        __unused: i31 = 0,
    };

    pub const ContextResetNotification = enum(c_int) {
        no_notification = 0x0000,
        lose_context = 0x0001,
    };

    pub fn setAttribute(attr: Attr, value: i32) Error!void {
        if (!SDL_GL_SetAttribute(attr, value)) return makeError();
    }
    extern fn SDL_GL_SetAttribute(attr: Attr, value: c_int) bool;

    pub fn getAttribute(attr: Attr) Error!i32 {
        var value: i32 = undefined;
        if (!SDL_GL_GetAttribute(attr, &value)) return makeError();
        return value;
    }
    extern fn SDL_GL_GetAttribute(attr: Attr, value: *c_int) bool;

    pub fn setSwapInterval(interval: i32) Error!void {
        if (!SDL_GL_SetSwapInterval(interval)) return makeError();
    }
    extern fn SDL_GL_SetSwapInterval(interval: c_int) bool;

    pub fn getSwapInterval() Error!i32 {
        var interval: c_int = undefined;
        if (!SDL_GL_GetSwapInterval(&interval)) return makeError();
        return @intCast(interval);
    }
    extern fn SDL_GL_GetSwapInterval(interval: *c_int) bool;

    pub fn swapWindow(window: *Window) Error!void {
        if (!SDL_GL_SwapWindow(window)) return makeError();
    }
    extern fn SDL_GL_SwapWindow(window: *Window) bool;

    pub fn getProcAddress(proc: [*:0]const u8) callconv(.c) FunctionPointer {
        return SDL_GL_GetProcAddress(proc);
    }
    extern fn SDL_GL_GetProcAddress(proc: [*c]const u8) callconv(.c) FunctionPointer;

    pub fn isExtensionSupported(extension: [:0]const u8) bool {
        return SDL_GL_ExtensionSupported(@ptrCast(extension.ptr));
    }
    extern fn SDL_GL_ExtensionSupported(extension: [*c]const u8) bool;

    pub fn createContext(window: *Window) Error!Context {
        return SDL_GL_CreateContext(window) orelse return makeError();
    }
    extern fn SDL_GL_CreateContext(window: *Window) ?Context;

    pub fn makeCurrent(window: *Window, context: Context) Error!void {
        if (!SDL_GL_MakeCurrent(window, context)) return makeError();
    }
    extern fn SDL_GL_MakeCurrent(window: *Window, context: Context) bool;

    pub const destroyContext = SDL_GL_DestroyContext;
    extern fn SDL_GL_DestroyContext(context: Context) void;
};

//--------------------------------------------------------------------------------------------------
//
// 2D Accelerated Rendering (SDL_render.h)
//
//--------------------------------------------------------------------------------------------------

pub const Vertex = extern struct {
    position: FPoint,
    color: FColor,
    tex_coord: FPoint,
};

pub const TextureAccess = enum(c_int) {
    static,
    streaming,
    target,
};

pub const RendererLogicalPresentationMode = enum(c_int) {
    disabled,
    stretch,
    letterbox,
    overscan,
    integer_scale,
};

pub const Texture = opaque {
    pub const destroy = destroyTexture;
    pub const lock = lockTexture;
    pub const unlock = unlockTexture;
};

pub const destroyTexture = SDL_DestroyTexture;
extern fn SDL_DestroyTexture(texture: ?*Texture) void;

pub fn lockTexture(texture: *Texture, rect: ?*Rect) !struct {
    pixels: [*]u8,
    pitch: c_int,
} {
    var pixels: *anyopaque = undefined;
    var pitch: c_int = undefined;
    if (!SDL_LockTexture(texture, rect, &pixels, &pitch)) {
        return makeError();
    }
    return .{
        .pixels = @ptrCast(pixels),
        .pitch = pitch,
    };
}
extern fn SDL_LockTexture(
    texture: *Texture,
    rect: ?*Rect,
    pixels: **anyopaque,
    pitch: *c_int,
) bool;

pub const unlockTexture = SDL_UnlockTexture;
extern fn SDL_UnlockTexture(texture: *Texture) void;

pub const Renderer = opaque {
    pub const Flags = packed struct(u32) {
        software: bool = false,
        accelerated: bool = false,
        present_vsync: bool = false,
        _: u29 = 0,
    };

    pub const create = createRenderer;
    pub const destroy = destroyRenderer;
    pub const present = renderPresent;
    pub const debugText = renderDebugText;
};

/// Get the number of 2D rendering drivers available for the current display.
///
/// A render driver is a set of code that handles rendering and texture
/// management on a particular display. Normally there is only one, but some
/// drivers may have several available with different capabilities.
///
/// There may be none if SDL was compiled without render support.
pub const getNumRenderDrivers = SDL_GetNumRenderDrivers;
extern fn SDL_GetNumRenderDrivers() c_int;

/// Use this function to get the name of a built in 2D rendering driver.
///
/// The list of rendering drivers is given in the order that they are normally
/// initialized by default; the drivers that seem more reasonable to choose
/// first (as far as the SDL developers believe) are earlier in the list.
///
/// The names of drivers are all simple, low-ASCII identifiers, like "opengl",
/// "direct3d12" or "metal". These never have Unicode characters, and are not
/// meant to be proper names.
pub const getRenderDriver = SDL_GetRenderDriver;
extern fn SDL_GetRenderDriver(index: c_int) ?[*:0]const u8;

/// Create a window and default renderer.
pub fn createWindowAndRenderer(
    window_title: ?[*:0]const u8,
    width: c_int,
    height: c_int,
    window_flags: Window.Flags,
    window: **Window,
    renderer: **Renderer,
) Error!void {
    assert(width > 0);
    assert(height > 0);
    if (!SDL_CreateWindowAndRenderer(
        window_title,
        width,
        height,
        window_flags,
        @ptrCast(window),
        @ptrCast(renderer),
    )) {
        return makeError();
    }
}
extern fn SDL_CreateWindowAndRenderer(
    title: ?[*:0]const u8,
    width: c_int,
    height: c_int,
    window_flags: Window.Flags,
    window: ?*?*Window,
    renderer: ?*?*Renderer,
) bool;

/// Create a 2D rendering context for a window.
///
/// If you want a specific renderer, you can specify its name here. A list of
/// available renderers can be obtained by calling SDL_GetRenderDriver()
/// multiple times, with indices from 0 to SDL_GetNumRenderDrivers()-1. If you
/// don't need a specific renderer, specify NULL and SDL will attempt to choose
/// the best option for you, based on what is available on the user's system.
///
/// If `name` is a comma-separated list, SDL will try each name, in the order
/// listed, until one succeeds or all of them fail.
///
/// By default the rendering size matches the window size in pixels, but you
/// can call SDL_SetRenderLogicalPresentation() to change the content size and
/// scaling options.
pub fn createRenderer(window: *Window, maybe_name: ?[:0]const u8) Error!*Renderer {
    return SDL_CreateRenderer(
        window,
        if (maybe_name) |name| @as([*c]const u8, @ptrCast(name.ptr)) else null,
    ) orelse makeError();
}
extern fn SDL_CreateRenderer(window: *Window, name: [*c]const u8) ?*Renderer;

// TODO

pub const destroyRenderer = SDL_DestroyRenderer;
extern fn SDL_DestroyRenderer(r: *Renderer) void;

//--------------------------------------------------------------------------------------------------
//
// Blend modes (SDL_blendmode.h)
//
//--------------------------------------------------------------------------------------------------

pub const BlendMode = enum(c_int) {
    none = 0x00000000,
    blend = 0x00000001,
    add = 0x00000002,
    mod = 0x00000004,
    multiply = 0x00000008,
    invalid = 0x7fffffff,
};

pub const ScaleMode = enum(c_int) {
    nearest = 0x0000,
    linear = 0x0001,
    best = 0x0002,
};

pub fn renderClear(r: *Renderer) !void {
    if (!SDL_RenderClear(r)) return makeError();
}
extern fn SDL_RenderClear(r: *Renderer) bool;

pub const renderPresent = SDL_RenderPresent;
extern fn SDL_RenderPresent(r: *Renderer) void;

pub fn renderTexture(
    r: *Renderer,
    tex: *Texture,
    src: ?*const FRect,
    dst: ?*const FRect,
) Error!void {
    if (!SDL_RenderTexture(r, tex, src, dst)) {
        return makeError();
    }
}
extern fn SDL_RenderTexture(
    r: *Renderer,
    t: *Texture,
    srcrect: ?*const FRect,
    dstrect: ?*const FRect,
) bool;

pub fn renderTextureRotated(
    r: *Renderer,
    tex: *Texture,
    src: ?*const FRect,
    dst: ?*const FRect,
    angle: f64,
    center: ?*const FPoint,
    flip: Surface.FlipMode,
) Error!void {
    if (!SDL_RenderTextureRotated(r, tex, src, dst, angle, center, flip)) {
        return makeError();
    }
}
extern fn SDL_RenderTextureRotated(
    r: *Renderer,
    t: *Texture,
    srcrect: ?*const FRect,
    dstrect: ?*const FRect,
    angle: f64,
    center: ?*const FPoint,
    flip: Surface.FlipMode,
) bool;

pub fn setRenderScale(renderer: *Renderer, x: f32, y: f32) Error!void {
    if (!SDL_SetRenderScale(renderer, x, y)) return makeError();
}
extern fn SDL_SetRenderScale(renderer: *Renderer, scaleX: f32, scaleY: f32) bool;

pub fn renderLine(renderer: *Renderer, x0: f32, y0: f32, x1: f32, y1: f32) Error!void {
    if (!SDL_RenderLine(renderer, x0, y0, x1, y1)) return makeError();
}
extern fn SDL_RenderLine(renderer: *Renderer, x1: f32, y1: f32, x2: f32, y2: f32) bool;

pub fn renderPoint(renderer: *Renderer, x: f32, y: f32) Error!void {
    if (!SDL_RenderPoint(renderer, x, y)) return makeError();
}
extern fn SDL_RenderPoint(renderer: *Renderer, x: f32, y: f32) bool;

pub fn renderFillRect(renderer: *Renderer, _rect: FRect) Error!void {
    if (!SDL_RenderFillRect(renderer, &_rect)) return makeError();
}
extern fn SDL_RenderFillRect(renderer: ?*Renderer, rect: *const FRect) bool;

pub fn renderRect(renderer: *Renderer, _rect: FRect) Error!void {
    if (!SDL_RenderRect(renderer, &_rect)) return makeError();
}
extern fn SDL_RenderRect(renderer: *Renderer, rect: *const FRect) bool;

pub fn renderGeometry(
    r: *Renderer,
    tex: ?*const Texture,
    vertices: []const Vertex,
    maybe_indices: ?[]const c_int,
) Error!void {
    if (!SDL_RenderGeometry(
        r,
        tex,
        vertices.ptr,
        @intCast(vertices.len),
        if (maybe_indices) |indices| indices.ptr else null,
        if (maybe_indices) |indices| @intCast(indices.len) else 0,
    )) {
        return makeError();
    }
}
extern fn SDL_RenderGeometry(
    renderer: *Renderer,
    texture: ?*const Texture,
    vertices: [*c]const Vertex,
    num_vertices: c_int,
    indices: [*c]const c_int,
    num_indices: c_int,
) bool;

pub fn setRenderDrawColor(renderer: *Renderer, color: Color) Error!void {
    if (!SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a)) {
        return makeError();
    }
}
extern fn SDL_SetRenderDrawColor(renderer: *Renderer, r: u8, g: u8, b: u8, a: u8) bool;

pub fn getRenderDrawColor(renderer: *const Renderer) Error!Color {
    var color: Color = undefined;
    if (!SDL_GetRenderDrawColor(renderer, &color.r, &color.g, &color.b, &color.a)) {
        return makeError();
    }
    return color;
}
extern fn SDL_GetRenderDrawColor(renderer: *const Renderer, r: *u8, g: *u8, b: *u8, a: *u8) bool;

pub fn getRenderDrawBlendMode(r: *const Renderer) Error!BlendMode {
    var blend_mode: BlendMode = undefined;
    if (!SDL_GetRenderDrawBlendMode(r, &blend_mode)) return makeError();
    return blend_mode;
}
extern fn SDL_GetRenderDrawBlendMode(renderer: *const Renderer, blendMode: *BlendMode) bool;

pub fn setRenderDrawBlendMode(r: *Renderer, blend_mode: BlendMode) Error!void {
    if (!SDL_SetRenderDrawBlendMode(r, blend_mode)) return makeError();
}
extern fn SDL_SetRenderDrawBlendMode(renderer: *Renderer, blendMode: BlendMode) bool;

pub fn getCurrentRenderOutputSize(r: *const Renderer, w: ?*c_int, h: ?*c_int) Error!void {
    if (!SDL_GetCurrentRenderOutputSize(r, w, h)) return makeError();
}
extern fn SDL_GetCurrentRenderOutputSize(renderer: *const Renderer, w: ?*c_int, h: ?*c_int) bool;

pub fn createTexture(
    renderer: *Renderer,
    format: PixelFormatEnum,
    access: TextureAccess,
    width: c_int,
    height: c_int,
) Error!*Texture {
    assert(width > 0);
    assert(height > 0);
    return SDL_CreateTexture(renderer, format, access, width, height) orelse makeError();
}
extern fn SDL_CreateTexture(
    renderer: *Renderer,
    format: PixelFormatEnum,
    access: TextureAccess,
    w: c_int,
    h: c_int,
) ?*Texture;

pub fn createTextureFromSurface(renderer: *Renderer, surface: *Surface) Error!*Texture {
    return SDL_CreateTextureFromSurface(renderer, surface) orelse makeError();
}
extern fn SDL_CreateTextureFromSurface(renderer: *Renderer, surface: *Surface) ?*Texture;

pub const renderClipEnabled = SDL_RenderClipEnabled;
pub extern fn SDL_RenderClipEnabled(renderer: *const Renderer) bool;

pub fn setRenderClipRect(r: *Renderer, clip_rect: ?*const Rect) Error!void {
    if (!SDL_SetRenderClipRect(r, clip_rect)) return makeError();
}
extern fn SDL_SetRenderClipRect(renderer: *Renderer, rect: ?*const Rect) bool;

pub fn getRenderClipRect(r: *Renderer) Error!Rect {
    var clip_rect: Rect = undefined;
    if (!SDL_GetRenderClipRect(r, &clip_rect)) return makeError();
    return clip_rect;
}
extern fn SDL_GetRenderClipRect(renderer: *Renderer, rect: ?*Rect) bool;

pub fn getRenderLogicalPresentation(
    renderer: *const Renderer,
    w: *c_int,
    h: *c_int,
    mode: *RendererLogicalPresentationMode,
    scale_mode: *ScaleMode,
) Error!void {
    if (!SDL_GetRenderLogicalPresentation(renderer, w, h, mode, scale_mode)) {
        return makeError();
    }
}
extern fn SDL_GetRenderLogicalPresentation(
    renderer: *const Renderer,
    w: *c_int,
    h: *c_int,
    mode: *RendererLogicalPresentationMode,
    scale_mode: *ScaleMode,
) bool;

pub fn setRenderLogicalPresentation(
    renderer: *Renderer,
    w: c_int,
    h: c_int,
    mode: RendererLogicalPresentationMode,
    scale_mode: ScaleMode,
) Error!void {
    if (!SDL_SetRenderLogicalPresentation(renderer, w, h, mode, scale_mode)) {
        return makeError();
    }
}
extern fn SDL_SetRenderLogicalPresentation(
    renderer: *Renderer,
    w: c_int,
    h: c_int,
    mode: RendererLogicalPresentationMode,
    scale_mode: ScaleMode,
) bool;

pub fn getRenderViewport(renderer: *const Renderer) Error!Rect {
    var viewport: Rect = undefined;
    if (SDL_GetRenderViewport(renderer, &viewport)) {
        return viewport;
    } else {
        return makeError();
    }
}
extern fn SDL_GetRenderViewport(renderer: *const Renderer, rect: *Rect) bool;

pub fn setRenderViewport(renderer: *Renderer, maybe_rect: ?*const Rect) Error!void {
    if (!SDL_SetRenderViewport(renderer, maybe_rect)) {
        return makeError();
    }
}
extern fn SDL_SetRenderViewport(renderer: *Renderer, rect: ?*const Rect) bool;

pub fn setRenderTarget(r: *Renderer, tex: ?*const Texture) Error!void {
    if (!SDL_SetRenderTarget(r, tex)) return makeError();
}
extern fn SDL_SetRenderTarget(renderer: *Renderer, texture: ?*const Texture) bool;

pub fn renderReadPixels(
    renderer: *const Renderer,
    _rect: ?*const Rect,
    format: PixelFormatEnum,
    pixels: [*]u8,
    pitch: c_int,
) Error!void {
    if (!SDL_RenderReadPixels(renderer, _rect, format, pixels, pitch)) {
        return makeError();
    }
}
extern fn SDL_RenderReadPixels(
    renderer: *const Renderer,
    rect: ?*const Rect,
    format: PixelFormatEnum,
    pixels: ?*anyopaque,
    pitch: c_int,
) bool;

pub fn renderDebugText(renderer: *Renderer, x: f32, y: f32, str: [*:0]const u8) Error!void {
    if (!SDL_RenderDebugText(renderer, x, y, str)) return makeError();
}
extern fn SDL_RenderDebugText(renderer: *Renderer, x: f32, y: f32, str: [*:0]const u8) bool;

//--------------------------------------------------------------------------------------------------
//
// Pixel Formats and Conversion Routines (SDL_pixels.h)
//
//--------------------------------------------------------------------------------------------------
pub const ALPHA_OPAQUE: u8 = 255;
pub const ALPHA_OPAQUE_FLOAT: f32 = 1.0;
pub const ALPHA_TRANSPARENT: u8 = 0;
pub const ALPHA_TRANSPARENT_FLOAT: f32 = 0.0;

pub const PixelType = enum(c_int) {
    unknown = 0,
    index1,
    index4,
    index8,
    packed8,
    packed16,
    packed32,
    arrayu8,
    arrayu16,
    arrayu32,
    arrayf16,
    arrayf32,
    // appended at end for compatibility with sdl2-compat
    index2,
};

/// Bitmap pixel order, high bit -> low bit.
pub const BitmapOrder = enum(c_int) {
    none = 0,
    @"4321",
    @"1234",
};

/// Packed component order, high bit -> low bit.
pub const PackedOrder = enum(c_int) {
    none = 0,
    xrgb,
    rgbx,
    argb,
    rgba,
    xbgr,
    bgrx,
    abgr,
    bgra,
};

/// Array component order, low byte -> high byte.
pub const ArrayOrder = enum(c_int) {
    none = 0,
    rgb,
    rgba,
    argb,
    bgr,
    bgra,
    abgr,
};

/// Packed component layout.
pub const PackedLayout = enum(c_int) {
    none = 0,
    @"332",
    @"4444",
    @"1555",
    @"5551",
    @"565",
    @"8888",
    @"2101010",
    @"1010102",
};

fn definePixelFormatEnum(
    _type: PixelType,
    order: anytype,
    layout: u32,
    bits: u32,
    bytes: u32,
) u32 {
    switch (_type) {
        .index1, .index2, .index4, .index8 => {
            assert(@TypeOf(order) == BitmapOrder);
        },
        .packed8, .packed16, .packed32 => {
            assert(@TypeOf(order) == PackedOrder);
        },
        .arrayu8, .arrayu16, .arrayu32, .arrayf16, .arrayf32 => {
            assert(@TypeOf(order) == ArrayOrder);
        },
        .unknown => unreachable,
    }
    return ((1 << 28) | ((@intFromEnum(_type)) << 24) | ((@intFromEnum(order)) << 20) |
        ((layout) << 16) | ((bits) << 8) | ((bytes) << 0));
}

/// SDL's pixel formats have the following naming convention:
///
/// - Names with a list of components and a single bit count, such as RGB24 and
///   ABGR32, define a platform-independent encoding into bytes in the order
///   specified. For example, in RGB24 data, each pixel is encoded in 3 bytes
///   (red, green, blue) in that order, and in ABGR32 data, each pixel is
///   encoded in 4 bytes alpha, blue, green, red) in that order. Use these
///   names if the property of a format that is important to you is the order
///   of the bytes in memory or on disk.
/// - Names with a bit count per component, such as ARGB8888 and XRGB1555, are
///   "packed" into an appropriately-sized integer in the platform's native
///   endianness. For example, ARGB8888 is a sequence of 32-bit integers; in
///   each integer, the most significant bits are alpha, and the least
///   significant bits are blue. On a little-endian CPU such as x86, the least
///   significant bits of each integer are arranged first in memory, but on a
///   big-endian CPU such as s390x, the most significant bits are arranged
///   first. Use these names if the property of a format that is important to
///   you is the meaning of each bit position within a native-endianness
///   integer.
/// - In indexed formats such as INDEX4LSB, each pixel is represented by
///   encoding an index into the palette into the indicated number of bits,
///   with multiple pixels packed into each byte if appropriate. In LSB
///   formats, the first (leftmost) pixel is stored in the least-significant
///   bits of the byte; in MSB formats, it's stored in the most-significant
///   bits. INDEX8 does not need LSB/MSB variants, because each pixel exactly
///   fills one byte.
///
/// The 32-bit byte-array encodings such as RGBA32 are aliases for the
/// appropriate 8888 encoding for the current platform. For example, RGBA32 is
/// an alias for ABGR8888 on little-endian CPUs like x86, or an alias for
/// RGBA8888 on big-endian CPUs.
pub const PixelFormatEnum = enum(u32) {
    index1lsb = definePixelFormatEnum(.index1, BitmapOrder.@"4321", 0, 1, 0),
    index1msb = definePixelFormatEnum(.index1, BitmapOrder.@"1234", 0, 1, 0),
    index4lsb = definePixelFormatEnum(.index4, BitmapOrder.@"4321", 0, 4, 0),
    index4msb = definePixelFormatEnum(.index4, BitmapOrder.@"1234", 0, 4, 0),
    index8 = definePixelFormatEnum(.index8, BitmapOrder.none, 0, 8, 1),
    rgb332 = definePixelFormatEnum(.packed8, PackedOrder.xrgb, @intFromEnum(PackedLayout.@"332"), 8, 1),
    xrgb4444 = definePixelFormatEnum(.packed16, PackedOrder.xrgb, @intFromEnum(PackedLayout.@"4444"), 12, 2),
    xbgr4444 = definePixelFormatEnum(.packed16, PackedOrder.xbgr, @intFromEnum(PackedLayout.@"4444"), 12, 2),
    xrgb1555 = definePixelFormatEnum(.packed16, PackedOrder.xrgb, @intFromEnum(PackedLayout.@"1555"), 15, 2),
    xbgr1555 = definePixelFormatEnum(.packed16, PackedOrder.xbgr, @intFromEnum(PackedLayout.@"1555"), 15, 2),
    argb4444 = definePixelFormatEnum(.packed16, PackedOrder.argb, @intFromEnum(PackedLayout.@"4444"), 16, 2),
    rgba4444 = definePixelFormatEnum(.packed16, PackedOrder.rgba, @intFromEnum(PackedLayout.@"4444"), 16, 2),
    abgr4444 = definePixelFormatEnum(.packed16, PackedOrder.abgr, @intFromEnum(PackedLayout.@"4444"), 16, 2),
    bgra4444 = definePixelFormatEnum(.packed16, PackedOrder.bgra, @intFromEnum(PackedLayout.@"4444"), 16, 2),
    argb1555 = definePixelFormatEnum(.packed16, PackedOrder.argb, @intFromEnum(PackedLayout.@"1555"), 16, 2),
    rgba5551 = definePixelFormatEnum(.packed16, PackedOrder.rgba, @intFromEnum(PackedLayout.@"5551"), 16, 2),
    abgr1555 = definePixelFormatEnum(.packed16, PackedOrder.abgr, @intFromEnum(PackedLayout.@"1555"), 16, 2),
    bgra5551 = definePixelFormatEnum(.packed16, PackedOrder.bgra, @intFromEnum(PackedLayout.@"5551"), 16, 2),
    rgb565 = definePixelFormatEnum(.packed16, PackedOrder.xrgb, @intFromEnum(PackedLayout.@"565"), 16, 2),
    bgr565 = definePixelFormatEnum(.packed16, PackedOrder.xbgr, @intFromEnum(PackedLayout.@"565"), 16, 2),
    rgb24 = definePixelFormatEnum(.arrayu8, ArrayOrder.rgb, 0, 24, 3),
    bgr24 = definePixelFormatEnum(.arrayu8, ArrayOrder.bgr, 0, 24, 3),
    xrgb8888 = definePixelFormatEnum(.packed32, PackedOrder.xrgb, @intFromEnum(PackedLayout.@"8888"), 24, 4),
    rgbx8888 = definePixelFormatEnum(.packed32, PackedOrder.rgbx, @intFromEnum(PackedLayout.@"8888"), 24, 4),
    xbgr8888 = definePixelFormatEnum(.packed32, PackedOrder.xbgr, @intFromEnum(PackedLayout.@"8888"), 24, 4),
    bgrx8888 = definePixelFormatEnum(.packed32, PackedOrder.bgrx, @intFromEnum(PackedLayout.@"8888"), 24, 4),
    argb8888 = definePixelFormatEnum(.packed32, PackedOrder.argb, @intFromEnum(PackedLayout.@"8888"), 32, 4),
    rgba8888 = definePixelFormatEnum(.packed32, PackedOrder.rgba, @intFromEnum(PackedLayout.@"8888"), 32, 4),
    abgr8888 = definePixelFormatEnum(.packed32, PackedOrder.abgr, @intFromEnum(PackedLayout.@"8888"), 32, 4),
    bgra8888 = definePixelFormatEnum(.packed32, PackedOrder.bgra, @intFromEnum(PackedLayout.@"8888"), 32, 4),
    argb2101010 = definePixelFormatEnum(.packed32, PackedOrder.argb, @intFromEnum(PackedLayout.@"2101010"), 32, 4),
};

pub const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const FColor = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

//--------------------------------------------------------------------------------------------------
//
// Rectangle Functions (SDL_rect.h)
//
//--------------------------------------------------------------------------------------------------
pub const Rect = extern struct {
    x: c_int,
    y: c_int,
    w: c_int,
    h: c_int,

    pub fn hasIntersection(a: *const Rect, b: *const Rect) bool {
        return hasRectIntersection(a, b);
    }

    pub fn getIntersection(a: *const Rect, b: *const Rect, result: *Rect) bool {
        return getRectIntersection(a, b, result);
    }

    pub fn getLineIntersection(rect: *const Rect, x1: *i32, y1: *i32, x2: *i32, y2: *i32) bool {
        return getRectAndLineIntersection(rect, x1, y1, x2, y2);
    }
};

pub const hasRectIntersection = SDL_HasRectIntersection;
extern fn SDL_HasRectIntersection(a: *const Rect, b: *const Rect) bool;

pub const getRectIntersection = SDL_GetRectIntersection;
extern fn SDL_GetRectIntersection(a: *const Rect, b: *const Rect, result: *Rect) bool;

pub const getRectAndLineIntersection = SDL_GetRectAndLineIntersection;
extern fn SDL_GetRectAndLineIntersection(
    r: *const Rect,
    x1: *c_int,
    y1: *c_int,
    x2: *c_int,
    y2: *c_int,
) bool;

pub const FRect = extern struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,

    pub fn hasIntersection(a: *const FRect, b: *const FRect) bool {
        return hasRectIntersectionFloat(a, b);
    }

    pub fn getRectIntersecton(a: *const FRect, b: *const FRect, result: *FRect) bool {
        return getRectIntersectionFloat(a, b, result);
    }

    pub fn getLineIntersection(rect: *const FRect, x1: *f32, y1: *f32, x2: *f32, y2: *f32) bool {
        return getRectAndLineIntersectionFloat(rect, x1, y1, x2, y2);
    }
};

pub const hasRectIntersectionFloat = SDL_HasRectIntersectionFloat;
extern fn SDL_HasRectIntersectionFloat(a: *const FRect, b: *const FRect) bool;

pub const getRectIntersectionFloat = SDL_GetRectIntersectionFloat;
extern fn SDL_GetRectIntersectionFloat(a: *const FRect, b: *const FRect, result: *FRect) bool;

pub const getRectAndLineIntersectionFloat = SDL_GetRectAndLineIntersectionFloat;
extern fn SDL_GetRectAndLineIntersectionFloat(
    r: *const FRect,
    x1: *f32,
    y1: *f32,
    x2: *f32,
    y2: *f32,
) bool;

pub const Point = extern struct {
    x: c_int,
    y: c_int,
};

pub const FPoint = extern struct {
    x: f32,
    y: f32,
};

//--------------------------------------------------------------------------------------------------
//
// Surface Creation and Simple Drawing (SDL_surface.h)
//
//--------------------------------------------------------------------------------------------------
pub const Surface = opaque {
    pub const Flags = packed struct(u32) {
        /// Surface uses preallocatred pixel memory
        preallocated: bool = false,
        /// Surface needs to be locked to access pixels
        lock_needed: bool = false,
        /// Surface is currently locked
        locked: bool = false,
        /// Surface used pixel memory allocated wth SDL_aliged_alloc()
        simd_aligned: bool = false,
        _: u28 = 0,
    };

    pub const ScaleMode = enum(c_int) {
        nearest,
        linear,
    };

    pub const FlipMode = enum(c_int) {
        none,
        horizontal,
        vertical,
    };

    pub const destroy = destroySurface;
};

// TODO:
// - SDL_CreateSurface
// - SDL_CreateSurfaceFrom

pub fn destroySurface(surface: *Surface) void {
    SDL_DestroySurface(surface);
}
extern fn SDL_DestroySurface(surface: *Surface) void;

// TODO:
// - SDL_GetSurfaceProperties
// - SDL_SetSurfaceColorspace
// - SDL_GetSurfaceColorspace
// - SDL_CreateSurfacePalette
// - SDL_SetSurfacePalette
// - SDL_GetSurfacePalette
// - SDL_AddSurfaceAlternateImage
// - SDL_SurfaceHasAlternateImages
// - SDL_GetSurfaceImages
// - SDL_RemoveSurfaceAlternateImages
// - SDL_LockSurface
// - SDL_UnlockSurface
// - SDL_LoadBMP_IO
// - SDL_LoadBMP
// - SDL_SaveBMP_IO
// - SDL_SaveBMP
// - SDL_SetSurfaceRLE
// - SDL_SurfaceHasRLE
// - SDL_SetSurfaceColorKey
// - SDL_SurfaceHasColorKey
// - SDL_GetSurfaceColorKey
// - SDL_SetSurfaceColorMod
// - SDL_GetSurfaceColorMod
// - SDL_SetSurfaceAlphaMod
// - SDL_GetSurfaceAlphaMod
// - SDL_SetSurfaceBlendMode
// - SDL_GetSurfaceBlendMode
// - SDL_SetSurfaceClipRect
// - SDL_GetSurfaceClipRect
// - SDL_FlipSurface
// - SDL_DuplicateSurface
// - SDL_ScaleSurface
// - SDL_ConvertSurface
// - SDL_ConvertSurfaceAndColorspace
// - SDL_ConvertPixels
// - SDL_ConvertPixelsAndColorspace
// - SDL_PremultiplyAlpha
// - SDL_PremultiplySurfaceAlpha
// - SDL_ClearSurface
// - SDL_FillSurfaceRect
// - SDL_FillSurfaceRects
// - SDL_BlitSurface
// - SDL_BlitSurfaceUnchecked
// - SDL_BlitSurfaceScaled
// - SDL_BlitSurfaceUncheckedScaled
// - SDL_StretchSurface
// - SDL_BlitSurfaceTiled
// - SDL_BlitSurfaceTiledWithScale
// - SDL_BlitSurface9Grid
// - SDL_MapSurfaceRGB
// - SDL_MapSurfaceRGBA
// - SDL_ReadSurfacePixel
// - SDL_ReadSurfacePixelFloat
// - SDL_WriteSurfacePixel
// - SDL_WriteSurfacePixelFloat

//--------------------------------------------------------------------------------------------------
//
// Clipboard Handling (SDL_clipboard.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Vulkan Support (SDL_vulkan.h)
//
//--------------------------------------------------------------------------------------------------
pub const vk = struct {
    pub const FunctionPointer = ?*const anyopaque;
    pub const Instance = enum(usize) { null_handle = 0, _ };

    pub fn loadLibrary(path: ?[*:0]const u8) Error!void {
        if (!SDL_Vulkan_LoadLibrary(@ptrCast(path))) return makeError();
    }
    extern fn SDL_Vulkan_LoadLibrary(path: [*c]const u8) bool;

    pub const getVkGetInstanceProcAddr = SDL_Vulkan_GetVkGetInstanceProcAddr;
    extern fn SDL_Vulkan_GetVkGetInstanceProcAddr() FunctionPointer;

    pub const unloadLibrary = SDL_Vulkan_UnloadLibrary;
    extern fn SDL_Vulkan_UnloadLibrary() void;

    pub const getInstanceExtensions = SDL_Vulkan_GetInstanceExtensions;
    extern fn SDL_Vulkan_GetInstanceExtensions(count: *u32) [*c]const [*c]const u8;

    pub fn createSurface(
        window: *Window,
        instance: Instance,
        allocator_callbacks: *anyopaque,
        surface: *anyopaque,
    ) bool {
        return SDL_Vulkan_CreateSurface(window, instance, allocator_callbacks, surface);
    }

    extern fn SDL_Vulkan_CreateSurface(
        window: *Window,
        instance: Instance,
        allocator_callbacks: *anyopaque,
        surface: *anyopaque,
    ) bool;
};

//--------------------------------------------------------------------------------------------------
//
// Metal Support (SDL_metal.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Camera (SDL_camera.h)
//
//--------------------------------------------------------------------------------------------------
pub const CameraId = u32;

pub const Camera = opaque {};

// TODO: Camera API

//--------------------------------------------------------------------------------------------------
//
// Event Handling (SDL_events.h)
//
//--------------------------------------------------------------------------------------------------
pub const EventType = enum(u32) {
    first = 0,

    quit = 0x100,
    terminating,
    low_memory,
    will_enter_background,
    did_enter_background,
    will_enter_foreground,
    did_enter_foreground,
    locale_changed,
    system_theme_changed,

    // Display events
    // _reserved_sdl2compat_displayevent = 0x150,
    display_orientation = 0x151,
    display_connected,
    display_disconnected,
    display_moved,
    display_content_scale_changed,

    // Window events
    // _reserved_sdl2compat_windowevent = 0x200,
    // _reserved_sdl2compat_syswm = 0x201
    window_shown = 0x202,
    window_hidden,
    window_exposed,
    window_moved,
    window_resized,
    window_pixel_size_changed,
    window_minimized,
    window_maximized,
    window_restored,
    window_mouse_enter,
    window_mouse_leave,
    window_focus_gained,
    window_focus_lost,
    window_close_requested,
    window_take_focus,
    window_hit_test,
    window_iccprof_changed,
    window_display_changed,
    window_display_scale_changed,
    window_destroyed,
    window_hdr_state_changed,

    // Keyboard events
    key_down = 0x300,
    key_up,
    text_editing,
    text_input,
    keymap_changed,
    keyboard_added,
    keyboard_removed,
    text_editing_candidates,

    // Mouse events
    mouse_motion = 0x400,
    mouse_button_down,
    mouse_button_up,
    mouse_wheel,
    mouse_added,
    mouse_removed,

    // Joystick events
    joystick_axis_motion = 0x600,
    joystick_ball_motion,
    joystick_hat_motion,
    joystick_button_down,
    joystick_button_up,
    joystick_added,
    joystick_removed,
    joystick_battery_updated,
    joystick_update_complete,

    // Gamepad events
    gamepad_axis_motion = 0x650,
    gamepad_button_down,
    gamepad_button_up,
    gamepad_added,
    gamepad_removed,
    gamepad_remapped,
    gamepad_touchpad_down,
    gamepad_touchpad_motion,
    gamepad_touchpad_up,
    gamepad_sensor_update,
    gamepad_update_complete,
    gamepad_steam_handle_updated,

    // Touch events
    finger_down = 0x700,
    finger_up,
    finger_motion,
    finger_cancelled,

    // 0x800, 0x801, 0x802 were gesture events from SDL2, reserved for sdl compat
    // _reserved_sdl2compat_dollargesture = 0x800,
    // _reserved_sdl2compat_dollarrecord,
    // _reserved_sdl2compat_multigesture,

    // CLipboard events
    clipboard_update = 0x900,

    // Drag and drop events
    drop_file = 0x1000,
    drop_text,
    drop_begin,
    drop_complete,
    drop_position,

    // Audio hotplug events
    audio_device_added = 0x1100,
    audio_device_removed,
    audio_device_format_changed,

    // Sensor events
    sensor_update = 0x1200,

    // Pressure-sensitive pen events
    pen_proximity_in = 0x1300,
    pen_proximity_out,
    pen_down,
    pen_up,
    pen_button_down,
    pen_button_up,
    pen_motion,
    pen_axis,

    // Camera hotplug events
    camera_device_added = 0x1400,
    camera_device_removed,
    camera_device_approved,
    camera_device_denied,

    // Render events
    render_targets_reset = 0x2000,
    render_device_reset,
    render_device_lost,

    // Reserved events for private platforms
    private0 = 0x4000,
    private1,
    private2,
    private3,

    // Internal events
    poll_sentinel = 0x7f00,

    // 0x8000 to 0xffff are for your own use, and should be allocated with SDL_RegisterEvents
    // user = 0x8000,
    _,
};

pub const CommonEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
};

pub const DisplayEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    display_id: DisplayId,
    data1: i32,
    data2: i32,
};

pub const WindowEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    data1: i32,
    data2: i32,
};

pub const KeyboardDeviceEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: KeyboardId,
};

pub const KeyboardEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: KeyboardId,
    scancode: Scancode,
    key: Keycode,
    mod: Keymod,
    raw: u16,
    down: bool,
    repeat: bool,
};

pub const TextEditingEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    text: ?[*:0]const u8,
    start: i32,
    length: i32,
};

pub const TextEditingCandidatesEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    candidates: *const [*:0]const u8,
    num_candidates: i32,
    selected_candidate: i32,
    horizontal: bool,
    // padding
    _: u8,
    __: u8,
    ___: u8,
};

pub const TextInputEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    text: ?[*:0]const u8,
};

pub const MouseDeviceEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: MouseId,
};

pub const MouseMotionEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: MouseId,
    state: MouseButtonFlags,
    x: f32,
    y: f32,
    xrel: f32,
    yrel: f32,
};

pub const MouseButtonEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: MouseId,
    button: u8,
    down: bool,
    clicks: u8,
    _: u8, // padding
    x: f32,
    y: f32,
};

pub const MouseWheelEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: MouseId,
    x: f32,
    y: f32,
    direction: MouseWheelDirection,
    mouse_x: f32,
    mouse_y: f32,
};

pub const JoyAxisEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
    axis: u8,
    // padding
    _: u8,
    __: u8,
    ___: u8,
    value: i16,
    ____: u16, // padding
};

pub const JoyBallEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
    ball: u8,
    // padding
    _: u8,
    __: u8,
    ___: u8,
    xrel: i16,
    yrel: i16,
};

pub const JoyHatEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
    hat: u8,
    value: u8,
    _: u16, // padding
};

pub const JoyButtonEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
    button: u8,
    down: bool,
    _: u16, // padding
};

pub const JoyDeviceEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
};

pub const JoyBatteryEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
    state: PowerState,
    percent: c_int,
};

pub const GamepadAxisEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
    axis: u8,
    // padding
    _: u8,
    __: u8,
    ___: u8,
    value: i16,
    ____: u16, // padding
};

pub const GamepadButtonEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
    button: u8,
    down: bool,
    _: u16, // padding
};

pub const GamepadDeviceEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
};

pub const GamepadTouchpadEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u32,
    which: Joystick.Id,
    touchpad: i32,
    finger: i32,
    x: f32,
    y: f32,
    pressure: f32,
};

pub const GamepadSensorEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: Joystick.Id,
    senor: i32,
    data: [3]f32,
    sensor_timestamp: u64,
};

pub const AudioDeviceEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: AudioDeviceId,
    recording: bool,
    // padding
    _: u8,
    __: u8,
    ___: u8,
};

pub const CameraDeviceEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: CameraId,
};

pub const RenderEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
};

pub const TouchFingerEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    touch_id: TouchId,
    finger_id: FingerId,
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
    pressure: f32,
    window_id: WindowId,
};

pub const PenProximityEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: PenId,
};

pub const PenMotionEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: PenId,
    pen_state: PenInputFlags,
    x: f32,
    y: f32,
};

pub const PenTouchEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: PenId,
    pen_state: PenInputFlags,
    x: f32,
    y: f32,
    eraser: bool,
    down: bool,
};

pub const PenButtonEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: PenId,
    pen_state: PenInputFlags,
    x: f32,
    y: f32,
    button: u8,
    down: bool,
};

pub const PenAxisEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: PenId,
    pen_state: PenInputFlags,
    x: f32,
    y: f32,
    axis: PenAxis,
    value: f32,
};

pub const DropEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    x: f32,
    y: f32,
    source: ?[*:0]const u8,
    data: ?[*:0]const u8,
};

pub const ClipboardEvent = extern struct { type: EventType, reserved: u32, timestamp: u64, owner: bool, num_mime_types: i32, mime_types: ?*[*:0]const u8 };

pub const SensorEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    which: SensorId,
    data: [6]f32,
    sensor_timestamp: u64,
};

pub const QuitEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
};

pub const UserEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    code: i32,
    data1: ?*anyopaque,
    data2: ?*anyopaque,
};

pub const Event = extern union {
    type: EventType,
    common: CommonEvent,
    display: DisplayEvent,
    window: WindowEvent,
    kdevice: KeyboardDeviceEvent,
    key: KeyboardEvent,
    edit: TextEditingEvent,
    edit_candidates: TextEditingCandidatesEvent,
    text: TextInputEvent,
    mdevice: MouseDeviceEvent,
    motion: MouseMotionEvent,
    button: MouseButtonEvent,
    wheel: MouseWheelEvent,
    jdevice: JoyDeviceEvent,
    jaxis: JoyAxisEvent,
    jball: JoyBallEvent,
    jhat: JoyHatEvent,
    jbutton: JoyButtonEvent,
    jbattery: JoyBatteryEvent,
    gdevice: GamepadDeviceEvent,
    gaxis: GamepadAxisEvent,
    gbutton: GamepadButtonEvent,
    gtouchpad: GamepadTouchpadEvent,
    gsensor: GamepadSensorEvent,
    adevice: AudioDeviceEvent,
    cdevice: CameraDeviceEvent,
    sensor: SensorEvent,
    quit: QuitEvent,
    user: UserEvent,
    tfinger: TouchFingerEvent,
    pproximity: PenProximityEvent,
    ptouch: PenTouchEvent,
    pmotion: PenMotionEvent,
    pbutton: PenButtonEvent,
    paxis: PenAxisEvent,
    render: RenderEvent,
    drop: DropEvent,
    clipboard: ClipboardEvent,
    _: [128]u8, // padding
};

/// Pump the event loop, gathering events from the input devices.
pub const pumpEvents = SDL_PumpEvents;
extern fn SDL_PumpEvents() void;

/// The type of action to request from SDL_PeepEvents().
pub const EventAction = enum(c_int) {
    /// Add events to the back of the queue.
    addevent,
    /// Check but don't remove events from the queue front.
    peekevent,
    /// Retrieve/remove events from the front of the queue.
    getevent,
};

// TODO
// - SDL_PeepEvents
// - SDL_HasEvent
// - SDL_HasEvents
// - SDL_FlushEvent
// - SDL_FlushEvents

pub const pollEvent = SDL_PollEvent;
extern fn SDL_PollEvent(event: ?*Event) bool;

// TODO
// - SDL_WaitEvent
// - SDL_WaitEventTimeout

/// You should set the common.timestamp field before passing an event to `pushEvent`.
/// If the timestamp is 0 it will be filled in with `getTicksNS()`.
/// Returns true if event was added, false if event was filtered out or on failure;
/// call SDL_GetError() for more information.
pub const pushEvent = SDL_PushEvent;
extern fn SDL_PushEvent(event: *Event) bool;

/// A function pointer used for callbacks that watch the event queue.
pub const EventFilter = fn (userdata: ?*anyopaque, event: *Event) bool;

/// TODO
// - SDL_SetEventFilter
// - SDL_GetEventFilter
// - SDL_AddEventWatch
// - SDL_RemoveEventWatch
// - SDL_FilterEvents
// - SDL_SetEventEnabled
// - SDL_EventEnabled
// - SDL_RegisterEvents
// - SDL_GetWindowFromEvent

//--------------------------------------------------------------------------------------------------
//
// Keyboard Support (SDL_keyboard.h)
//
//--------------------------------------------------------------------------------------------------

pub const KeyboardId = u32;

// TODO
// - SDL_HasKeyboard
// - SDL_GetKeyboards
// - SDL_GetKeyboardNameForID
// - SDL_GetKeyboardFocus
// - SDL_GetKeyboardState
// - SDL_ResetKeyboard
// - SDL_GetModState
// - SDL_SetModState
// - SDL_GetKeyFromScancode
// - SDL_GetScancodeFromKey
// - SDL_SetScancodeName
// - SDL_GetScancodeName
// - SDL_GetScancodeFromName
// - SDL_GetKeyName
// - SDL_GetKeyFromName
// - SDL_StartTextInput
// - SDL_StartTextInputWithProperties
// - SDL_TextInputActive
// - SDL_StopTextInput
// - SDL_ClearComposition
// - SDL_SetTextInputArea
// - SDL_GetTextInputArea
// - SDL_HasScreenKeyboardSupport
// - SDL_ScreenKeyboardShown

//--------------------------------------------------------------------------------------------------
//
// Keyboard Scancodes (SDL_scancode.h)
//
//--------------------------------------------------------------------------------------------------
/// The SDL keyboard scancode representation.
///
/// An SDL scancode is the physical representation of a key on the keyboard,
/// independent of language and keyboard mapping.
///
/// Values of this type are used to represent keyboard keys, among other places
/// in the `scancode` field of the SDL_KeyboardEvent structure.
///
/// The values in this enumeration are based on the USB usage page standard:
/// https://usb.org/sites/default/files/hut1_5.pdf
pub const Scancode = enum(u32) {
    unknown = 0,
    a = 4,
    b = 5,
    c = 6,
    d = 7,
    e = 8,
    f = 9,
    g = 10,
    h = 11,
    i = 12,
    j = 13,
    k = 14,
    l = 15,
    m = 16,
    n = 17,
    o = 18,
    p = 19,
    q = 20,
    r = 21,
    s = 22,
    t = 23,
    u = 24,
    v = 25,
    w = 26,
    x = 27,
    y = 28,
    z = 29,
    @"1" = 30,
    @"2" = 31,
    @"3" = 32,
    @"4" = 33,
    @"5" = 34,
    @"6" = 35,
    @"7" = 36,
    @"8" = 37,
    @"9" = 38,
    @"0" = 39,
    @"return" = 40,
    escape = 41,
    backspace = 42,
    tab = 43,
    space = 44,
    minus = 45,
    equals = 46,
    leftbracket = 47,
    rightbracket = 48,
    backslash = 49,
    nonushash = 50,
    semicolon = 51,
    apostrophe = 52,
    grave = 53,
    comma = 54,
    period = 55,
    slash = 56,
    capslock = 57,
    f1 = 58,
    f2 = 59,
    f3 = 60,
    f4 = 61,
    f5 = 62,
    f6 = 63,
    f7 = 64,
    f8 = 65,
    f9 = 66,
    f10 = 67,
    f11 = 68,
    f12 = 69,
    printscreen = 70,
    scrolllock = 71,
    pause = 72,
    insert = 73,
    home = 74,
    pageup = 75,
    delete = 76,
    end = 77,
    pagedown = 78,
    right = 79,
    left = 80,
    down = 81,
    up = 82,
    numlockclear = 83,
    kp_divide = 84,
    kp_multiply = 85,
    kp_minus = 86,
    kp_plus = 87,
    kp_enter = 88,
    kp_1 = 89,
    kp_2 = 90,
    kp_3 = 91,
    kp_4 = 92,
    kp_5 = 93,
    kp_6 = 94,
    kp_7 = 95,
    kp_8 = 96,
    kp_9 = 97,
    kp_0 = 98,
    kp_period = 99,
    nonusbackslash = 100,
    application = 101,
    power = 102,
    kp_equals = 103,
    f13 = 104,
    f14 = 105,
    f15 = 106,
    f16 = 107,
    f17 = 108,
    f18 = 109,
    f19 = 110,
    f20 = 111,
    f21 = 112,
    f22 = 113,
    f23 = 114,
    f24 = 115,
    execute = 116,
    help = 117,
    menu = 118,
    select = 119,
    stop = 120,
    again = 121,
    undo = 122,
    cut = 123,
    copy = 124,
    paste = 125,
    find = 126,
    mute = 127,
    volumeup = 128,
    volumedown = 129,
    // lockingcapslock, lockingnumlock, lockingscrolllock disabled in SDL_scancode.h
    kp_comma = 133,
    kp_equalsas400 = 134,
    international1 = 135,
    international2 = 136,
    international3 = 137,
    international4 = 138,
    international5 = 139,
    international6 = 140,
    international7 = 141,
    international8 = 142,
    international9 = 143,
    lang1 = 144,
    lang2 = 145,
    lang3 = 146,
    lang4 = 147,
    lang5 = 148,
    lang6 = 149,
    lang7 = 150,
    lang8 = 151,
    lang9 = 152,
    alterase = 153,
    sysreq = 154,
    cancel = 155,
    clear = 156,
    prior = 157,
    return2 = 158,
    separator = 159,
    out = 160,
    oper = 161,
    clearagain = 162,
    crsel = 163,
    exsel = 164,
    kp_00 = 176,
    kp_000 = 177,
    thousandsseparator = 178,
    decimalseparator = 179,
    currencyunit = 180,
    currencysubunit = 181,
    kp_leftparen = 182,
    kp_rightparen = 183,
    kp_leftbrace = 184,
    kp_rightbrace = 185,
    kp_tab = 186,
    kp_backspace = 187,
    kp_a = 188,
    kp_b = 189,
    kp_c = 190,
    kp_d = 191,
    kp_e = 192,
    kp_f = 193,
    kp_xor = 194,
    kp_power = 195,
    kp_percent = 196,
    kp_less = 197,
    kp_greater = 198,
    kp_ampersand = 199,
    kp_dblampersand = 200,
    kp_verticalbar = 201,
    kp_dblverticalbar = 202,
    kp_colon = 203,
    kp_hash = 204,
    kp_space = 205,
    kp_at = 206,
    kp_exclam = 207,
    kp_memstore = 208,
    kp_memrecall = 209,
    kp_memclear = 210,
    kp_memadd = 211,
    kp_memsubtract = 212,
    kp_memmultiply = 213,
    kp_memdivide = 214,
    kp_plusminus = 215,
    kp_clear = 216,
    kp_clearentry = 217,
    kp_binary = 218,
    kp_octal = 219,
    kp_decimal = 220,
    kp_hexadecimal = 221,
    lctrl = 224,
    lshift = 225,
    lalt = 226,
    lgui = 227,
    rctrl = 228,
    rshift = 229,
    ralt = 230,
    rgui = 231,
    mode = 257,
    sleep = 258,
    wake = 259,
    channel_increment = 260,
    channel_decrement = 261,
    media_play = 262,
    media_pause = 263,
    media_record = 264,
    media_fast_forward = 265,
    media_rewind = 266,
    media_next_track = 267,
    media_previous_track = 268,
    media_stop = 269,
    media_eject = 270,
    media_play_pause = 271,
    media_select = 272,
    ac_new = 273,
    ac_open = 274,
    ac_close = 275,
    ac_exit = 276,
    ac_save = 277,
    ac_print = 278,
    ac_properties = 279,
    ac_search = 280,
    ac_home = 281,
    ac_back = 282,
    ac_forward = 283,
    ac_stop = 284,
    ac_refresh = 285,
    ac_bookmarks = 286,
    softleft = 287,
    softright = 288,
    call = 289,
    endcall = 290,
    _,
    // 400 - 500 reserved for dynamic keyboard
};

pub inline fn SCANCODE_TO_KEYCODE(scancode: u32) u32 {
    return scancode | (1 << 30);
}

//--------------------------------------------------------------------------------------------------
//
// Keyboard Keycodes (SDL_keycode.h)
//
//--------------------------------------------------------------------------------------------------
/// The SDL virtual key representation.
///
/// Values of this type are used to represent keyboard keys using the current
/// layout of the keyboard. These values include Unicode values representing
/// the unmodified character that would be generated by pressing the key, or an
/// `SDLK_*` constant for those keys that do not generate characters.
///
/// A special exception is the number keys at the top of the keyboard which map
/// to SDLK_0...SDLK_9 on AZERTY layouts.
///
/// Keys with the `SDLK_EXTENDED_MASK` bit set do not map to a scancode or
/// unicode code point.
pub const Keycode = enum(u32) {
    pub const EXTENDED_MASK: u32 = 1 << 29;
    pub const SCANCODE_MASK: u32 = 1 << 30;

    pub inline fn fromScancode(scancode: Scancode) Keycode {
        return @enumFromInt(SCANCODE_TO_KEYCODE(@intFromEnum(scancode)));
    }

    unknown = 0,
    @"return" = '\r',
    escape = '\x1b',
    backspace = '\x08',
    tab = '\t',
    space = ' ',
    exclaim = '!',
    dblapostrophe = '"',
    hash = '#',
    percent = '%',
    dollar = '$',
    ampersand = '&',
    apostrophe = '\'',
    leftparen = '(',
    rightparen = ')',
    asterisk = '*',
    plus = '+',
    comma = ',',
    minus = '-',
    period = '.',
    slash = '/',
    @"0" = '0',
    @"1" = '1',
    @"2" = '2',
    @"3" = '3',
    @"4" = '4',
    @"5" = '5',
    @"6" = '6',
    @"7" = '7',
    @"8" = '8',
    @"9" = '9',
    colon = ':',
    semicolon = ';',
    less = '<',
    equals = '=',
    greater = '>',
    question = '?',
    at = '@',
    leftbracket = '[',
    backslash = '\\',
    rightbracket = ']',
    caret = '^',
    underscore = '_',
    grave = '`',
    a = 'a',
    b = 'b',
    c = 'c',
    d = 'd',
    e = 'e',
    f = 'f',
    g = 'g',
    h = 'h',
    i = 'i',
    j = 'j',
    k = 'k',
    l = 'l',
    m = 'm',
    n = 'n',
    o = 'o',
    p = 'p',
    q = 'q',
    r = 'r',
    s = 's',
    t = 't',
    u = 'u',
    v = 'v',
    w = 'w',
    x = 'x',
    y = 'y',
    z = 'z',
    leftbrace = '{',
    pipe = '|',
    rightbrace = '}',
    tilde = '~',
    delete = '\x7f',
    plusminus = '\x81',
    capslock = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.capslock)),
    f1 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f1)),
    f2 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f2)),
    f3 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f3)),
    f4 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f4)),
    f5 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f5)),
    f6 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f6)),
    f7 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f7)),
    f8 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f8)),
    f9 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f9)),
    f10 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f10)),
    f11 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f11)),
    f12 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f12)),
    printscreen = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.printscreen)),
    scrolllock = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.scrolllock)),
    pause = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.pause)),
    insert = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.insert)),
    home = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.home)),
    pageup = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.pageup)),
    end = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.end)),
    pagedown = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.pagedown)),
    right = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.right)),
    left = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.left)),
    down = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.down)),
    up = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.up)),
    numlockclear = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.numlockclear)),
    kp_divide = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_divide)),
    kp_multiply = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_multiply)),
    kp_minus = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_minus)),
    kp_plus = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_plus)),
    kp_enter = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_enter)),
    kp_1 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_1)),
    kp_2 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_2)),
    kp_3 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_3)),
    kp_4 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_4)),
    kp_5 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_5)),
    kp_6 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_6)),
    kp_7 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_7)),
    kp_8 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_8)),
    kp_9 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_9)),
    kp_0 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_0)),
    kp_period = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_period)),
    application = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.application)),
    power = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.power)),
    kp_equals = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_equals)),
    f13 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f13)),
    f14 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f14)),
    f15 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f15)),
    f16 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f16)),
    f17 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f17)),
    f18 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f18)),
    f19 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f19)),
    f20 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f20)),
    f21 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f21)),
    f22 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f22)),
    f23 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f23)),
    f24 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.f24)),
    execute = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.execute)),
    help = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.help)),
    menu = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.menu)),
    select = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.select)),
    stop = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.stop)),
    again = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.again)),
    undo = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.undo)),
    cut = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.cut)),
    copy = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.copy)),
    paste = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.paste)),
    find = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.find)),
    mute = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.mute)),
    volumeup = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.volumeup)),
    volumedown = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.volumedown)),
    kp_comma = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_comma)),
    kp_equalsas400 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_equalsas400)),
    alterase = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.alterase)),
    sysreq = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.sysreq)),
    cancel = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.cancel)),
    clear = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.clear)),
    prior = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.prior)),
    return2 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.return2)),
    separator = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.separator)),
    out = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.out)),
    oper = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.oper)),
    clearagain = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.clearagain)),
    crsel = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.crsel)),
    exsel = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.exsel)),
    kp_00 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_00)),
    kp_000 = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_000)),
    thousandsseparator = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.thousandsseparator)),
    decimalseparator = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.decimalseparator)),
    currencyunit = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.currencyunit)),
    currencysubunit = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.currencysubunit)),
    kp_leftparen = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_leftparen)),
    kp_rightparen = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_rightparen)),
    kp_leftbrace = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_leftbrace)),
    kp_rightbrace = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_rightbrace)),
    kp_tab = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_tab)),
    kp_backspace = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_backspace)),
    kp_a = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_a)),
    kp_b = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_b)),
    kp_c = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_c)),
    kp_d = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_d)),
    kp_e = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_e)),
    kp_f = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_f)),
    kp_xor = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_xor)),
    kp_power = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_power)),
    kp_percent = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_percent)),
    kp_less = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_less)),
    kp_greater = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_greater)),
    kp_ampersand = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_ampersand)),
    kp_dblampersand = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_dblampersand)),
    kp_verticalbar = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_verticalbar)),
    kp_dblverticalbar = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_dblverticalbar)),
    kp_colon = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_colon)),
    kp_hash = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_hash)),
    kp_space = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_space)),
    kp_at = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_at)),
    kp_exclam = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_exclam)),
    kp_memstore = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_memstore)),
    kp_memrecall = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_memrecall)),
    kp_memclear = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_memclear)),
    kp_memadd = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_memadd)),
    kp_memsubtract = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_memsubtract)),
    kp_memmultiply = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_memmultiply)),
    kp_memdivide = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_memdivide)),
    kp_plusminus = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_plusminus)),
    kp_clear = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_clear)),
    kp_clearentry = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_clearentry)),
    kp_binary = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_binary)),
    kp_octal = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_octal)),
    kp_decimal = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_decimal)),
    kp_hexadecimal = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.kp_hexadecimal)),
    lctrl = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.lctrl)),
    lshift = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.lshift)),
    lalt = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.lalt)),
    lgui = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.lgui)),
    rctrl = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.rctrl)),
    rshift = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.rshift)),
    ralt = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ralt)),
    rgui = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.rgui)),
    mode = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.mode)),
    sleep = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.sleep)),
    wake = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.wake)),
    channel_increment = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.channel_increment)),
    channel_decrement = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.channel_decrement)),
    media_play = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_play)),
    media_pause = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_pause)),
    media_record = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_record)),
    media_fast_forward = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_fast_forward)),
    media_rewind = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_rewind)),
    media_next_track = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_next_track)),
    media_previous_track = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_previous_track)),
    media_stop = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_stop)),
    media_eject = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_eject)),
    media_play_pause = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_play_pause)),
    media_select = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.media_select)),
    ac_new = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_new)),
    ac_open = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_open)),
    ac_close = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_close)),
    ac_exit = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_exit)),
    ac_save = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_save)),
    ac_print = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_print)),
    ac_properties = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_properties)),
    ac_search = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_search)),
    ac_home = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_home)),
    ac_back = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_back)),
    ac_forward = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_forward)),
    ac_stop = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_stop)),
    ac_refresh = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_refresh)),
    ac_bookmarks = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.ac_bookmarks)),
    softleft = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.softleft)),
    softright = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.softright)),
    call = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.call)),
    endcall = SCANCODE_TO_KEYCODE(@intFromEnum(Scancode.endcall)),
    left_tab = 0x20000001,
    level5_shift = 0x20000002,
    multi_key_compose = 0x20000003,
    lmeta = 0x20000004,
    rmeta = 0x20000005,
    lhyper = 0x20000006,
    rhyper = 0x20000007,
    _,
};

/// Valid key modifiers (possibly OR'd together).
pub const Keymod = enum(u16) {
    pub const none: u16 = 0x0000;
    pub const lshift: u16 = 0x0001;
    pub const rshift: u16 = 0x0002;
    pub const level5: u16 = 0x0004;
    pub const lctrl: u16 = 0x0040;
    pub const rctrl: u16 = 0x0080;
    pub const lalt: u16 = 0x0100;
    pub const ralt: u16 = 0x0200;
    pub const lgui: u16 = 0x0400;
    pub const rgui: u16 = 0x0800;
    pub const num: u16 = 0x1000;
    pub const caps: u16 = 0x2000;
    pub const mode: u16 = 0x4000;
    pub const scroll: u16 = 0x8000;
    pub const ctrl: u16 = lctrl | rctrl;
    pub const shift: u16 = lshift | rshift;
    pub const alt: u16 = lalt | ralt;
    pub const gui: u16 = lgui | rgui;
};

pub fn getKeyboardState() []const bool {
    var numkeys: i32 = 0;
    if (SDL_GetKeyboardState(&numkeys)) |ptr| {
        return ptr[0..@as(usize, @intCast(numkeys))];
    } else {
        return &[_]bool{};
    }
}
extern fn SDL_GetKeyboardState(numkeys: ?*c_int) [*c]const bool;

// TODO
// - SDL_ResetKeyboard
// - SDL_GetModState
// - SDL_SetModState
// - SDL_GetKeyFromScancode
// - SDL_GetScancodeFromKey
// - SDL_SetScancodeName
// - SDL_GetScancodeName
// - SDL_GetScancodeFromName
// - SDL_GetKeyName
// - SDL_GetKeyFromName
// - SDL_StartTextInput

pub const TextInputType = enum(c_int) {
    text,
    text_name,
    text_email,
    text_username,
    text_password_hidden,
    text_password_visible,
    number,
    number_password_hidden,
    number_password_visible,
};

pub const Capitalization = enum(c_int) {
    none,
    sentences,
    words,
    letters,
};

// TODO
// - SDL_StartTextInputWithProperties
// - SDL_PROP_TEXTINPUT_ constants
// - SDL_TextInputActive
// - SDL_StopTextInput
// - SDL_ClearComposition
// - SDL_SetTextInputArea
// - SDL_GetTextInputArea
// - SDL_HasScreenKeyboardSupport
// - SDL_ScreenKeyboardShown

//--------------------------------------------------------------------------------------------------
//
// Mouse Support (SDL_mouse.h)
//
//--------------------------------------------------------------------------------------------------
pub const MouseId = u32;

pub const Cursor = opaque {};

pub const SystemCursor = enum {
    default,
    text,
    wait,
    crosshair,
    progress,
    nwse_resize,
    nesw_resize,
    ew_resize,
    ns_resize,
    move,
    not_allowed,
    pointer,
    nw_resize,
    n_resize,
    ne_resize,
    e_resize,
    se_resize,
    s_resize,
    sw_resize,
    w_resize,
};

pub const MouseWheelDirection = enum(u32) {
    normal,
    flipped,
};

pub const MouseButtonFlags = packed struct(u32) {
    left: u1 = 0,
    middle: u1 = 0,
    right: u1 = 0,
    x1: u1 = 0,
    x2: u1 = 0,
    _: u27 = undefined,
};

// TODO
// - SDL_HasMouse
// - SDL_GetMice
// - SDL_GetMouseNameForID

/// Get the window which currently has mouse focus.
pub const getMouseFocus = SDL_GetMouseFocus;
extern fn SDL_GetMouseFocus() ?*Window;

/// Query SDL's cache for the synchronous mouse button state and the
/// window-relative SDL-cursor position.
pub const getMouseState = SDL_GetMouseState;
extern fn SDL_GetMouseState(x: ?*f32, y: ?*f32) u32;

// TODO
// - SDL_GetGlobalMouseState
// - SDL_GetRelativeMouseState
// - SDL_WarpMouseInWindow
// - SDL_WarpMouseGlobal
// - SDL_SetWindowRelativeMouseMode
// - SDL_GetWindowRelativeMouseMode
// - SDL_CaptureMouse
// - SDL_CreateCursor
// - SDL_CreateColorCursor
// - SDL_CreateSystemCursor
// - SDL_SetCursor
// - SDL_GetCursor
// - SDL_GetDefaultCursor
// - SDL_DestroyCursor

pub fn showCursor() Error!void {
    if (!SDL_ShowCursor()) return makeError();
}
extern fn SDL_ShowCursor() bool;

pub fn hideCursor() Error!void {
    if (!SDL_HideCursor()) return makeError();
}
extern fn SDL_HideCursor() bool;

pub const cursorVisible = SDL_CursorVisible;
extern fn SDL_CursorVisible() bool;

//--------------------------------------------------------------------------------------------------
//
// Joystick Support (SDL_joystick.h)
//
//--------------------------------------------------------------------------------------------------

pub const Joystick = struct {
    pub const Id = u32;

    pub const Type = enum(c_int) {
        unknown,
        gamepad,
        wheel,
        arcade_stick,
        flight_stick,
        dance_pad,
        guitar,
        drum_kit,
        arcade_pad,
        throttle,
    };

    pub const ConnectionState = enum(c_int) {
        invalid = -1,
        unknown,
        wired,
        wireless,
    };

    pub const JOYSTICK_AXIS_MAX = 32767;
    pub const JOYSTICK_AXIS_MIN = -32768;
};

// TODO: Joystick API (see SDL_joystick.h)

//--------------------------------------------------------------------------------------------------
//
// Gamepad Support (SDL_gamepad.h)
//
//--------------------------------------------------------------------------------------------------
pub const Gamepad = opaque {
    pub const Type = enum(c_int) {
        unknown,
        standard,
        xbox360,
        xboxone,
        ps3,
        ps4,
        ps5,
        nintendo_switch_pro,
        nintendo_switch_joycon_left,
        nintendo_switch_joycon_right,
        nintendo_switch_joycon_pair,
    };

    pub const Button = enum(c_int) {
        invalid = -1,
        south,
        east,
        west,
        north,
        back,
        guide,
        start,
        left_stick,
        right_stick,
        left_shoulder,
        right_shoulder,
        dpad_up,
        dpad_down,
        dpad_left,
        dpad_right,
        misc1,
        right_paddle1,
        left_paddle1,
        right_paddle2,
        left_paddle2,
        touchpad,
        misc2,
        misc3,
        misc4,
        misc5,
        misc6,
    };

    pub const ButtonLabel = enum(c_int) {
        unknown,
        label_a,
        label_b,
        label_x,
        label_y,
        label_cross,
        label_circle,
        label_square,
        label_triangle,
    };

    pub const Axis = enum(c_int) {
        invalid = -1,
        leftx,
        lefty,
        rightx,
        righty,
        left_trigger,
        right_trigger,
    };

    pub const BindingType = enum(c_int) {
        none,
        button,
        axis,
        hat,
    };

    /// A mapping between one joystick input to a gamepad control.
    ///
    /// A gamepad has a collection of several bindings, to say, for example, when
    /// joystick button number 5 is pressed, that should be treated like the
    /// gamepad's "start" button.
    ///
    /// SDL has these bindings built-in for many popular controllers, and can add
    /// more with a simple text string. Those strings are parsed into a collection
    /// of these structs to make it easier to operate on the data.
    pub const Binding = extern struct {
        input_type: BindingType,
        input: extern union {
            button: Button,
            axis: extern struct {
                axis: Axis,
                axis_min: c_int,
                axis_max: c_int,
            },
            hat: extern struct {
                hat: c_int,
                hat_mask: c_int,
            },
        },
        output_type: BindingType,
        output: extern union {
            button: Button,
            axis: extern struct {
                axis: Axis,
                axis_min: c_int,
                axis_max: c_int,
            },
        },
    };

    pub const close = closeGamepad;
    pub const getAxis = getGamepadAxis;
    pub const getButton = getGamepadButton;
};

// TODO
// - SDL_AddGamepadMapping
// - SDL_AddGamepadMappingsFromIO
// - SDL_AddGamepadMappingsFromFile
// - SDL_ReloadGamepadMappings
// - SDL_GetGamepadMappings
// - SDL_GetGamepadMappingForGUID
// - SDL_GetGamepadMapping
// - SDL_SetGamepadMapping
// - SDL_HasGamepad
// - SDL_GetGamepads
// - SDL_IsGamepad
// - SDL_GetGamepadNameForID
// - SDL_GetGamepadPathForID
// - SDL_GetGamepadPlayerIndexForID
// - SDL_GetGamepadGUIDForID
// - SDL_GetGamepadVendorForID
// - SDL_GetGamepadProductForID
// - SDL_GetGamepadProductVersionForID
// - SDL_GetGamepadTypeForID
// - SDL_GetRealGamepadTypeForID
// - SDL_GetGamepadMappingForID

pub const openGamepad = SDL_OpenGamepad;
extern fn SDL_OpenGamepad(joystick_index: Joystick.Id) ?*Gamepad;

// TODO
// - SDL_GetGamepadFromID
// - SDL_GetGamepadFromPlayerIndex
// - SDL_GetGamepadProperties
// - SDL_GetGamepadID
// - SDL_GetGamepadName
// - SDL_GetGamepadPath
// - SDL_GetGamepadType
// - SDL_GetRealGamepadType
// - SDL_GetGamepadPlayerIndex
// - SDL_SetGamepadPlayerIndex
// - SDL_GetGamepadVendor
// - SDL_GetGamepadProduct
// - SDL_GetGamepadProductVersion
// - SDL_GetGamepadSerial
// - SDL_GetGamepadSteamHandle
// - SDL_GetGamepadConnectionState
// - SDL_GetGamepadPowerInfo
// - SDL_GamepadConnected
// - SDL_GetGamepadJoystick
// - SDL_SetGamepadEventsEnabled
// - SDL_GamepadEventsEnabled
// - SDL_GetGamepadBindings
// - SDL_UpdateGamepads
// - SDL_GetGamepadTypeFromString
// - SDL_GetGamepadStringForType
// - SDL_GetGamepadAxisFromString
// - SDL_GetGamepadStringForAxis
// - SDL_GamepadHasAxis

pub const getGamepadAxis = SDL_GetGamepadAxis;
extern fn SDL_GetGamepadAxis(*Gamepad, axis: Gamepad.Axis) i16;

// TODO
// - SDL_GetGamepadButtonFromString
// - SDL_GetGamepadStringForButton
// - SDL_GamepadHasButton
// - SDL_GetGamepadButton

pub const getGamepadButton = SDL_GetGamepadButton;
extern fn SDL_GetGamepadButton(*Gamepad, Gamepad.Button) bool;

// TODO
// - SDL_GetGamepadButtonLabelForType
// - SDL_GetGamepadButtonLabel
// - SDL_GetNumGamepadTouchpads
// - SDL_GetNumGamepadTouchpadFingers
// - SDL_GetGamepadTouchpadFinger
// - SDL_GamepadHasSensor
// - SDL_SetGamepadSensorEnabled
// - SDL_GamepadSensorEnabled
// - SDL_GetGamepadSensorDataRate
// - SDL_GetGamepadSensorData
// - SDL_RumbleGamepad
// - SDL_RumbleGamepadTriggers
// - SDL_SetGamepadLED
// - SDL_SendGamepadEffect

pub const closeGamepad = SDL_CloseGamepad;
extern fn SDL_CloseGamepad(joystick: *Gamepad) void;

//--------------------------------------------------------------------------------------------------
//
// Touch Support (SDL_touch.h)
//
//--------------------------------------------------------------------------------------------------
pub const TouchId = u64;

pub const FingerId = u64;

pub const TouchDeviceType = enum(c_int) {
    invalid = -1,
    direct,
    indirect_absolute,
    indirect_relative,
};

pub const Finger = extern struct {
    id: FingerId,
    x: f32,
    y: f32,
    pressure: f32,
};

pub const TOUCH_MOUSEID: c_int = -1;

pub const MOUSE_TOUCHID: c_int = -1;

// TODO
// - SDL_GetTouchDevices
// - SDL_GetTouchDeviceName
// - SDL_GetTouchDeviceType
// - SDL_GetTouchFingers

//--------------------------------------------------------------------------------------------------
//
// Pen Support (SDL_pen.h)
//
//--------------------------------------------------------------------------------------------------
pub const PenId = u32;

pub const PEN_MOUSEID: c_int = -2;

pub const PEN_TOUCHID: c_int = -2;

pub const PenInputFlags = packed struct(u32) {
    down: u1,
    button_1: u1,
    button_2: u1,
    button_3: u1,
    button_4: u1,
    button_5: u1,
    _: u25,
    eraser_tip: u1,
};

pub const PEN_INPUT_DOWN: u32 = @as(u32, 1) << 0;
pub const PEN_INPUT_BUTTON_1: u32 = @as(u32, 1) << 1;
pub const PEN_INPUT_BUTTON_2: u32 = @as(u32, 1) << 2;
pub const PEN_INPUT_BUTTON_3: u32 = @as(u32, 1) << 3;
pub const PEN_INPUT_BUTTON_4: u32 = @as(u32, 1) << 4;
pub const PEN_INPUT_BUTTON_5: u32 = @as(u32, 1) << 5;
pub const PEN_INPUT_ERASER_TIP: u32 = @as(u32, 1) << 30;

pub const PenAxis = enum(c_int) {
    pressure,
    xtilt,
    ytilt,
    distance,
    rotation,
    slider,
    tangential_pressure,
};

//--------------------------------------------------------------------------------------------------
//
// Sensors (SDL_sensor.h)
//
//--------------------------------------------------------------------------------------------------
pub const Sensor = opaque {};

pub const SensorId = u32;

// TODO: Sensor API

//--------------------------------------------------------------------------------------------------
//
// HIDAPI (SDL_hidapi.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Force Feedback Support (SDL_haptic.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Audio Device Management, Playing and Recording (SDL_audio.h)
//
//--------------------------------------------------------------------------------------------------
pub const AUDIO_MASK_BITSIZE = @as(c_uint, 0xff);
pub const AUDIO_MASK_FLOAT = @as(c_uint, 1) << 8;
pub const AUDIO_MASK_BIG_ENDIAN = @as(c_uint, 1) << 12;
pub const AUDIO_MASK_SIGNED = @as(c_uint, 1) << 15;

pub const AudioFormat = enum(c_uint) {
    UNKNOWN = 0x0,
    U8 = 0x0008,
    S8 = 0x8008,
    S16LE = 0x8010,
    S16BE = 0x9010,
    S32LE = 0x8020,
    S32BE = 0x9020,
    F32LE = 0x8120,
    F32BE = 0x9120,

    pub const S16 = if (builtin.target.cpu.arch.endian() == .little) AudioFormat.S16LE else AudioFormat.S16BE;
    pub const S32 = if (builtin.target.cpu.arch.endian() == .little) AudioFormat.S32LE else AudioFormat.S32BE;
    pub const F32 = if (builtin.target.cpu.arch.endian() == .little) AudioFormat.F32LE else AudioFormat.F32BE;
};

pub inline fn AUDIO_BITSIZE(format: AudioFormat) c_uint {
    return @intFromEnum(format) & AUDIO_MASK_BITSIZE;
}

pub inline fn AUDIO_BYTESIZE(format: AudioFormat) c_uint {
    return AUDIO_BITSIZE(@intFromEnum(format)) / 8;
}

pub inline fn AUDIO_ISFLOAT(format: AudioFormat) bool {
    return (@intFromEnum(format) & AUDIO_MASK_FLOAT) != 0;
}

pub inline fn AUDIO_ISBIGENDIAN(format: AudioFormat) bool {
    return (@intFromEnum(format) & AUDIO_MASK_BIG_ENDIAN) != 0;
}

pub inline fn AUDIO_ISSIGNED(format: AudioFormat) bool {
    return (@intFromEnum(format) & AUDIO_MASK_SIGNED) != 0;
}

pub inline fn AUDIO_ISINT(format: AudioFormat) bool {
    return !AUDIO_ISFLOAT(format);
}

pub inline fn AUDIO_ISLITTLEENDIAN(format: AudioFormat) bool {
    return !AUDIO_ISBIGENDIAN(format);
}

pub inline fn AUDIO_ISUNSIGNED(format: AudioFormat) bool {
    return !AUDIO_ISSIGNED(format);
}

pub const AudioDeviceId = u32;

pub const AUDIO_DEVICE_DEFAULT_PLAYBACK = 0xFFFFFFFF;
pub const AUDIO_DEVICE_DEFAULT_RECORDING = 0xFFFFFFFE;

pub const AudioSpec = extern struct {
    channels: u8,
    format: AudioFormat,
    freq: c_int,
};

pub inline fn AUDIO_FRAMESIZE(spec: AudioSpec) c_uint {
    return AUDIO_BYTESIZE(spec.format) * spec.channels;
}

pub const AudioStream = opaque {};

/// Use this function to get the number of built-in audio drivers.
///
/// This function returns a hardcoded number. This never returns a negative
/// value; if there are no drivers compiled into this build of SDL, this
/// function returns zero. The presence of a driver in this list does not mean
/// it will function, it just means SDL is capable of interacting with that
/// interface. For example, a build of SDL might have esound support, but if
/// there's no esound server available, SDL's esound driver would fail if used.
pub const getNumAudioDrivers = SDL_GetNumAudioDrivers;
extern fn SDL_GetNumAudioDrivers() c_int;

/// Use this function to get the name of a built in audio driver.
pub const getAudioDriver = SDL_GetAudioDriver;
extern fn SDL_GetAudioDriver(index: c_int) [*:0]const u8;

/// Get the name of the current audio driver.
pub const getCurrentAudioDriver = SDL_GetCurrentAudioDriver;
extern fn SDL_GetCurrentAudioDriver() [*:0]const u8;

/// Get a list of currently-connected audio playback devices.
///
/// This only returns a list of physical devices; it will not have any device
/// IDs returned by SDL_OpenAudioDevice().
///
/// If this function returns NULL, to signify an error, `*count` will be set to  zero.
///
/// Returns a 0 terminated array of device instance IDs or NULL on error;
/// call SDL_free() when it is no longer needed.
pub fn getAudioPlaybackDevices() Error![]AudioDeviceId {
    var count: c_int = undefined;
    const maybe_list = SDL_GetAudioPlaybackDevices(&count);
    return if (maybe_list) |list| list[0..@intCast(count)] else makeError();
}
extern fn SDL_GetAudioPlaybackDevices(out_count: ?*c_int) ?[*]AudioDeviceId;

/// Get a list of currently-connected audio recording devices.
///
/// This only returns a list of physical devices; it will not have any device
/// IDs returned by SDL_OpenAudioDevice().
///
/// If this function returns NULL, to signify an error, `*count` will be set to  zero.
///
/// Returns a 0 terminated array of device instance IDs or NULL on error;
/// call SDL_free() when it is no longer needed.
pub fn getAudioRecordingDevices() Error![]AudioDeviceId {
    var count: c_int = undefined;
    const maybe_list = SDL_GetAudioRecordingDevices(&count);
    return if (maybe_list) |list| list[0..@intCast(count)] else makeError();
}
extern fn SDL_GetAudioRecordingDevices(out_count: ?*c_int) ?[*]AudioDeviceId;

/// Get the human-readable name of a specific audio device.
pub fn getAudioDeviceName(devid: AudioDeviceId) Error![:0]const u8 {
    if (SDL_GetAudioDeviceName(devid)) |name| {
        return std.mem.span(name);
    } else {
        return makeError();
    }
}
extern fn SDL_GetAudioDeviceName(AudioDeviceId) [*c]const u8;

/// Get the current audio format of a specific audio device.
pub fn getAudioDeviceFormat(devid: AudioDeviceId) Error!struct { spec: AudioSpec, sample_frames: c_int } {
    var spec: AudioSpec = undefined;
    var sample_frames: c_int = undefined;
    if (!SDL_GetAudioDeviceFormat(devid, &spec, &sample_frames)) {
        return makeError();
    }
    return .{ .spec = spec, .sample_frames = sample_frames };
}
extern fn SDL_GetAudioDeviceFormat(AudioDeviceId, out_spec: *AudioSpec, out_sample_frames: *c_int) bool;

/// Get the current audio format of a specific audio device.
/// Channel maps are optional; most things do not need them, instead passing
/// data in the [order that SDL expects](CategoryAudio#channel-layouts).
///
/// Audio devices usually have no remapping applied. This is represented by
/// returning NULL, and does not signify an error.
///
/// Returns an array of the current channel mapping, with as many elements as
/// the current output spec's channels, or NULL if default. This
/// should be freed with SDL_free() when it is no longer needed.
pub fn getAudioDeviceChannelMap(devid: AudioDeviceId) ?[]c_int {
    var count: c_int = undefined;
    return if (SDL_GetAudioDeviceChannelMap(devid, &count)) |list_ptr| list_ptr[0..@intCast(count)] else null;
}
extern fn SDL_GetAudioDeviceChannelMap(AudioDeviceId, out_count: *c_int) [*c]c_int;

/// Open a specific audio device.
pub fn openAudioDevice(device: AudioDeviceId, spec: ?*const AudioSpec) Error!void {
    if (SDL_OpenAudioDevice(device, spec) == 0) {
        return makeError();
    }
}
extern fn SDL_OpenAudioDevice(AudioDeviceId, ?*const AudioSpec) AudioDeviceId;

pub const isAudioDevicePhysical = SDL_IsAudioDevicePhysical;
extern fn SDL_IsAudioDevicePhysical(AudioDeviceId) bool;

pub const isAudioDevicePlayback = SDL_IsAudioDevicePlayback;
extern fn SDL_IsAudioDevicePlayback(AudioDeviceId) bool;

/// Use this function to pause audio playback on a specified device.
///
/// This function pauses audio processing for a given device. Any bound audio
/// streams will not progress, and no audio will be generated. Pausing one
/// device does not prevent other unpaused devices from running.
///
/// Unlike in SDL2, audio devices start in an _unpaused_ state, since an app
/// has to bind a stream before any audio will flow. Pausing a paused device is
/// a legal no-op.
///
/// Pausing a device can be useful to halt all audio without unbinding all the
/// audio streams. This might be useful while a game is paused, or a level is
/// loading, etc.
///
/// Physical devices can not be paused or unpaused, only logical devices
/// created through SDL_OpenAudioDevice() can be.
pub const pauseAudioDevice = SDL_PauseAudioDevice;
extern fn SDL_PauseAudioDevice(AudioDeviceId) bool;

/// Use this function to unpause audio playback on a specified device.
///
/// This function unpauses audio processing for a given device that has
/// previously been paused with SDL_PauseAudioDevice(). Once unpaused, any
/// bound audio streams will begin to progress again, and audio can be
/// generated.
///
/// Unlike in SDL2, audio devices start in an _unpaused_ state, since an app
/// has to bind a stream before any audio will flow. Pausing a paused device is
/// a legal no-op.
///
/// Physical devices can not be paused or unpaused, only logical devices
/// created through SDL_OpenAudioDevice() can be.
pub const resumeAudioDevice = SDL_ResumeAudioDevice;
extern fn SDL_ResumeAudioDevice(AudioDeviceId) bool;

/// Use this function to query if an audio device is paused.
///
/// Unlike in SDL2, audio devices start in an _unpaused_ state, since an app
/// has to bind a stream before any audio will flow. Pausing a paused device is
/// a legal no-op.
///
/// Physical devices can not be paused or unpaused, only logical devices
/// created through SDL_OpenAudioDevice() can be.
pub const audioDevicePaused = SDL_AudioDevicePaused;
extern fn SDL_AudioDevicePaused(AudioDeviceId) bool;

/// Get the gain of an audio device.
///
/// Physical devices may not have their gain changed, only logical devices, and
/// this function will always return -1.0f when used on physical devices.
pub fn getAudioDeviceGain(device: AudioDeviceId) Error!f32 {
    const gain = SDL_GetAudioDeviceGain(device);
    return if (gain == -1.0) makeError() else gain;
}
extern fn SDL_GetAudioDeviceGain(AudioDeviceId) f32;

/// Change the gain of an audio device.
///
/// Physical devices may not have their gain changed, only logical devices, and
/// this function will always return false when used on physical devices. While
/// it might seem attractive to adjust several logical devices at once in this
/// way, it would allow an app or library to interfere with another portion of
/// the program's otherwise-isolated devices.
///
/// This is applied, along with any per-audiostream gain, during playback to
/// the hardware, and can be continuously changed to create various effects. On
/// recording devices, this will adjust the gain before passing the data into
/// an audiostream; that recording audiostream can then adjust its gain further
/// when outputting the data elsewhere, if it likes, but that second gain is
/// not applied until the data leaves the audiostream again.
pub fn setAudioDeviceGain(device: AudioDeviceId, gain: f32) Error!void {
    if (!SDL_SetAudioDeviceGain(device, gain)) {
        return makeError();
    }
}
extern fn SDL_SetAudioDeviceGain(AudioDeviceId, f32) bool;

/// Close a previously-opened audio device.
///
/// The application should close open audio devices once they are no longer  needed.
///
/// This function may block briefly while pending audio data is played by the
/// hardware, so that applications don't drop the last buffer of data they
/// supplied if terminating immediately afterwards.
pub const closeAudioDevice = SDL_CloseAudioDevice;
extern fn SDL_CloseAudioDevice(AudioDeviceId) void;

// TODO
// - SDL_BindAudioStreams
// - SDL_BindAudioStream
// - SDL_UnbindAudioStreams
// - SDL_UnbindAudioStream

/// Query an audio stream for its currently-bound device.
///
/// This reports the audio device that an audio stream is currently bound to.
///
/// If not bound, or invalid, this returns zero, which is not a valid device ID.
pub const getAudioStreamDevice = SDL_GetAudioStreamDevice;
extern fn SDL_GetAudioStreamDevice(*AudioStream) AudioDeviceId;

// TODO
// - SDL_CreateAudioStream
// - SDL_GetAudioStreamProperties
// - SDL_GetAudioStreamFormat
// - SDL_SetAudioStreamFormat
// - SDL_GetAudioStreamFrequencyRatio
// - SDL_SetAudioStreamFrequencyRatio
// - SDL_GetAudioStreamGain
// - SDL_SetAudioStreamGain
// - SDL_GetAudioStreamInputChannelMap
// - SDL_GetAudioStreamOutputChannelMap
// - SDL_SetAudioStreamInputChannelMap
// - SDL_SetAudioStreamOutputChannelMap

/// Add data to the stream.
///
/// This data must match the format/channels/samplerate specified in the latest
/// call to SDL_SetAudioStreamFormat, or the format specified when creating the
/// stream if it hasn't been changed.
///
/// Note that this call simply copies the unconverted data for later. This is
/// different than SDL2, where data was converted during the Put call and the
/// Get call would just dequeue the previously-converted data.
pub fn putAudioStreamData(comptime SampleType: type, stream: *AudioStream, data: []const SampleType) Error!void {
    if (!SDL_PutAudioStreamData(stream, @ptrCast(data.ptr), @intCast(@sizeOf(SampleType) * data.len))) {
        return makeError();
    }
}
extern fn SDL_PutAudioStreamData(*AudioStream, data: *const anyopaque, len: c_int) bool;

// TODO
// - SDL_GetAudioStreamData
// - SDL_GetAudioStreamAvailable

/// Get the number of bytes currently queued.
///
// This is the number of bytes put into a stream as input, not the number that
// can be retrieved as output. Because of several details, it's not possible
// to calculate one number directly from the other. If you need to know how
// much usable data can be retrieved right now, you should use
// SDL_GetAudioStreamAvailable() and not this function.
//
// Note that audio streams can change their input format at any time, even if
// there is still data queued in a different format, so the returned byte
// count will not necessarily match the number of _sample frames_ available.
// Users of this API should be aware of format changes they make when feeding
// a stream and plan accordingly.
//
// Queued data is not converted until it is consumed by
// SDL_GetAudioStreamData, so this value should be representative of the exact
// data that was put into the stream.
//
// If the stream has so much data that it would overflow an int, the return
// value is clamped to a maximum value, but no queued data is lost; if there
// are gigabytes of data queued, the app might need to read some of it with
// SDL_GetAudioStreamData before this function's return value is no longer
// clamped.
pub fn getAudioStreamQueued(stream: *AudioStream) Error!usize {
    const queued = SDL_GetAudioStreamQueued(stream);
    if (queued < 0) {
        return makeError();
    }
    return @intCast(queued);
}
extern fn SDL_GetAudioStreamQueued(*AudioStream) c_int;

/// Tell the stream that you're done sending data, and anything being buffered
/// should be converted/resampled and made available immediately.
///
/// It is legal to add more data to a stream after flushing, but there may be
/// audio gaps in the output. Generally this is intended to signal the end of
/// input, so the complete output becomes available.
pub fn flushAudioStream(stream: *AudioStream) Error!void {
    if (!SDL_FlushAudioStream(stream)) {
        return makeError();
    }
}
extern fn SDL_FlushAudioStream(*AudioStream) bool;

/// Clear any pending data in the stream.
///
/// This drops any queued data, so there will be nothing to read from the
/// stream until more is added.
pub fn clearAudioStream(stream: *AudioStream) Error!void {
    if (!SDL_ClearAudioStream(stream)) {
        return makeError();
    }
}
extern fn SDL_ClearAudioStream(*AudioStream) bool;

// TODO
// - SDL_PauseAudioStreamDevice
// - SDL_ResumeAudioStreamDevice
// - SDL_AudioStreamDevicePaused
// - SDL_LockAudioStream
// - SDL_UnlockAudioStream

pub const AudioStreamCallback = *const fn (
    userdata: ?*anyopaque,
    stream: ?*AudioStream,
    additional_amount: c_int,
    total_amount: c_int,
) callconv(.c) void;

// TODO
// - SDL_SetAudioStreamGetCallback
// - SDL_SetAudioStreamPutCallback
// - SDL_DestroyAudioStream

/// Convenience function for straightforward audio init for the common case.
///
/// If all your app intends to do is provide a single source of PCM audio, this
/// function allows you to do all your audio setup in a single call.
///
/// This is also intended to be a clean means to migrate apps from SDL2.
///
/// This function will open an audio device, create a stream and bind it.
/// Unlike other methods of setup, the audio device will be closed when this
/// stream is destroyed, so the app can treat the returned SDL_AudioStream as
/// the only object needed to manage audio playback.
///
/// Also unlike other functions, the audio device begins paused. This is to map
/// more closely to SDL2-style behavior, since there is no extra step here to
/// bind a stream to begin audio flowing. The audio device should be resumed
/// with `SDL_ResumeAudioStreamDevice(stream);`
///
/// This function works with both playback and recording devices.
///
/// The `spec` parameter represents the app's side of the audio stream. That
/// is, for recording audio, this will be the output format, and for playing
/// audio, this will be the input format. If spec is NULL, the system will
/// choose the format, and the app can use SDL_GetAudioStreamFormat() to obtain
/// this information later.
///
/// If you don't care about opening a specific audio device, you can (and
/// probably _should_), use SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK for playback and
/// SDL_AUDIO_DEVICE_DEFAULT_RECORDING for recording.
///
/// One can optionally provide a callback function; if NULL, the app is
/// expected to queue audio data for playback (or unqueue audio data if
/// capturing). Otherwise, the callback will begin to fire once the device is
/// unpaused.
///
/// Destroying the returned stream with SDL_DestroyAudioStream will also close
/// the audio device associated with this stream.
pub fn openAudioDeviceStream(device: AudioDeviceId, spec: *const AudioSpec, callback: ?AudioStreamCallback, userdata: *anyopaque) Error!*AudioStream {
    const maybe_stream = SDL_OpenAudioDeviceStream(device, spec, callback, userdata);
    return if (maybe_stream) |stream| stream else makeError();
}
extern fn SDL_OpenAudioDeviceStream(AudioDeviceId, *const AudioSpec, ?AudioStreamCallback, *anyopaque) ?*AudioStream;

// TODO
// - SDL_AudioPostmixCallback
// - SDL_SetAudioPostmixCallback
// - SDL_LoadWAV_IO
// - SDL_LoadWAV
// - SDL_MixAudio
// - SDL_ConvertAudioSamples
// - SDL_GetAudioFormatName
// - SDL_GetSilenceValueForFormat

//--------------------------------------------------------------------------------------------------
//
// 3D Rendering and GPU Compute (SDL_gpu.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Thread Management (SDL_thread.h)
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Thread Synchronization Primitives (SDL_mutex.h)
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Atomic Operations (SDL_atomic.h)
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Timer Support (SDL_timer.h)
//
//--------------------------------------------------------------------------------------------------
/// Get the number of nanoseconds since SDL library initialization.
pub const getTicksNS = SDL_GetTicksNS;
extern fn SDL_GetTicksNS() u64;

pub const getPerformanceCounter = SDL_GetPerformanceCounter;
extern fn SDL_GetPerformanceCounter() u64;

pub const getPerformanceFrequency = SDL_GetPerformanceFrequency;
extern fn SDL_GetPerformanceFrequency() u64;

pub const delay = SDL_Delay;
extern fn SDL_Delay(ms: u32) void;

pub const getTicks = SDL_GetTicks;
extern fn SDL_GetTicks() u64;

//--------------------------------------------------------------------------------------------------
//
// Date and Time (SDL_time.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Filesystem Access (SDL_filesystem.h)
//
//--------------------------------------------------------------------------------------------------
pub fn getBasePath() ?[]const u8 {
    return if (SDL_GetBasePath()) |path| std.mem.span(path) else null;
}
extern fn SDL_GetBasePath() [*c]const u8;

pub fn getPrefPath(org: [:0]const u8, app: [:0]const u8) ?[]const u8 {
    return if (SDL_GetPrefPath(org.ptr, app.ptr)) |path| std.mem.span(path) else null;
}
extern fn SDL_GetPrefPath(org: [*c]const u8, app: [*c]const u8) [*c]const u8;

//--------------------------------------------------------------------------------------------------
//
// Storage Abstraction (SDL_storage.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// I/O Streams (SDL_iostream.h)
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Async I/O (SDL_asyncio.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Shared Object/DLL Management (SDL_loadso.h)
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Platform Detection (SDL_platform.h)
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// CPU Feature Detection (SDL_cpuinfo.h)
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Compiler Intrinsics Detection (SDL_intrin.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Byte Order and Byte Swapping (SDL_endian.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Bit Manipulation (SDL_bits.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Power Management Status (SDL_power.h)
//
//--------------------------------------------------------------------------------------------------
pub const PowerState = enum(c_int) {
    @"error" = -1,
    unknown,
    on_battery,
    no_battery,
    charging,
    charged,
};

// TODO: SDL_GetPowerInfo

//--------------------------------------------------------------------------------------------------
//
// Process Control (SDL_process.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Message Boxes (SDL_messagebox.h)
//
//--------------------------------------------------------------------------------------------------
pub const MessageBoxFlags = packed struct(u32) {
    err: bool = false,
    warning: bool = false,
    information: bool = false,
    buttons_left_to_right: bool = false,
    buttons_right_to_left: bool = false,
    __unused: u27 = 0,
};

pub fn showSimpleMessageBox(
    flags: MessageBoxFlags,
    title: ?[:0]const u8,
    message: ?[:0]const u8,
    window: ?*Window,
) Error!void {
    if (!SDL_ShowSimpleMessageBox(flags, @ptrCast(title), @ptrCast(message), window)) {
        return makeError();
    }
}
extern fn SDL_ShowSimpleMessageBox(
    flags: MessageBoxFlags,
    title: [*c]const u8,
    message: [*c]const u8,
    window: ?*Window,
) bool;

//--------------------------------------------------------------------------------------------------
//
// File Dialogs (SDL_dialog.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// System Tray (SDL_tray.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Locale Info (SDL_locale.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Platform-specific Functionality (SDL_system.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Standard Library Functionality (SDL_stdinc.h)
//
//--------------------------------------------------------------------------------------------------

/// Allocate uinitialized memory.
///
/// The allocated memory returned by this function must be freed with SDL_free().
///
/// If `size` is 0, it will be set to 1.
///
/// If you want to allocate memory aligned to a specific alignment, consider using SDL_aligned_alloc().
///
/// Returns a pointer to the allocated memory, or NULL if allocation failed.
pub const malloc = SDL_malloc;
extern fn SDL_malloc(isize) *anyopaque;

/// Free allocated memory.
/// The pointer is no longer valid after this call and cannot be dereferenced  anymore.
pub const free = SDL_free;
extern fn SDL_free(*anyopaque) void;

// TODO
// - Declare SDL_malloc_func, SDL_calloc_func, SDL_realloc_func and SDL_free_func
// - Zig Allocator interface

//--------------------------------------------------------------------------------------------------
//
// GUIDs (SDL_guid.h)
//
//--------------------------------------------------------------------------------------------------
// TODO

//--------------------------------------------------------------------------------------------------
//
// Miscellaneous (SDL_misc.h)
//
//--------------------------------------------------------------------------------------------------
// TODO
