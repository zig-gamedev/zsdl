const builtin = @import("builtin");
const std = @import("std");
const assert = std.debug.assert;

const sdl3 = @This();

test {
    _ = std.testing.refAllDeclsRecursive(sdl3);
}

//--------------------------------------------------------------------------------------------------
//
// Initialzation and Shutdown
//
//--------------------------------------------------------------------------------------------------
pub const InitFlags = packed struct(u32) {
    timer: bool = false,
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
    __unused16: u16 = 0,

    pub const everything: InitFlags = .{
        .timer = true,
        .audio = true,
        .video = true,
        .events = true,
        .joystick = true,
        .haptic = true,
        .gamepad = true,
        .sensor = true,
    };
};

pub fn init(flags: InitFlags) Error!void {
    if (SDL_Init(flags) == False) return makeError();
}
extern fn SDL_Init(flags: InitFlags) i32;

pub const quit = SDL_Quit;
extern fn SDL_Quit() void;

//--------------------------------------------------------------------------------------------------
//
// Configuration Variables
//
//--------------------------------------------------------------------------------------------------
pub const hint_windows_dpi_awareness = "SDL_WINDOWS_DPI_AWARENESS";

pub fn setHint(name: [:0]const u8, value: [:0]const u8) bool {
    return SDL_SetHint(name, value) == True;
}
extern fn SDL_SetHint(name: [*:0]const u8, value: [*:0]const u8) Bool;

//--------------------------------------------------------------------------------------------------
//
// Error Handling
//
//--------------------------------------------------------------------------------------------------
pub fn getError() ?[:0]const u8 {
    if (SDL_GetError()) |ptr| {
        return std.mem.sliceTo(ptr, 0);
    }
    return null;
}
extern fn SDL_GetError() ?[*:0]const u8;

pub const Error = error{SdlError};

pub fn makeError() error{SdlError} {
    if (getError()) |str| {
        std.log.debug("SDL3: {s}", .{str});
    }
    return error.SdlError;
}

//--------------------------------------------------------------------------------------------------
//
// Log Handling
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Assertions
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Querying SDL Version
//
//--------------------------------------------------------------------------------------------------
pub const Version = extern struct {
    major: u8,
    minor: u8,
    patch: u8,
};

/// Compiled SDL version
pub const VERSION = Version{
    .major = 3,
    .minor = 0,
    .patch = 0,
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
// Display and Window management
//
//--------------------------------------------------------------------------------------------------
pub const DisplayId = u32;

pub const WindowId = u32;

pub const DisplayMode = extern struct {
    displayId: DisplayId,
    format: PixelFormatEnum,
    w: i32,
    h: i32,
    pixel_density: f32,
    refresh_rate: f32,
    driverdata: ?*anyopaque = null,
};

pub const Window = opaque {
    pub const Flags = packed struct(u32) {
        fullscreen: bool = false,
        opengl: bool = false,
        __unused2: u1 = 0,
        hidden: bool = false,
        borderless: bool = false, // 0x10
        resizable: bool = false,
        minimized: bool = false,
        maximized: bool = false,
        mouse_grabbed: bool = false, // 0x100
        input_focus: bool = false,
        mouse_focus: bool = false,
        foreign: bool = false,
        __unused12: u1 = 0, // 0x1000
        allow_high_pixel_density: bool = false,
        mouse_capture: bool = false,
        always_on_top: bool = false,
        __unused16: u1 = 0, // 0x10000
        utility: bool = false,
        tooltip: bool = false,
        popup_menu: bool = false,
        keyboard_grabbed: bool = false,
        __unused21: u7 = 0,
        vulkan: bool = false, // 0x10000000
        metal: bool = false,
        __unused30: u2 = 0,
    };

    pub const pos_undefined = posUndefinedDisplay(0);
    pub const pos_centered = posCenteredDisplay(0);

    pub fn posUndefinedDisplay(x: i32) i32 {
        return pos_undefined_mask | x;
    }
    pub fn posCenteredDisplay(x: i32) i32 {
        return pos_centered_mask | x;
    }

    const pos_undefined_mask: i32 = 0x1fff_0000;
    const pos_centered_mask: i32 = 0x2fff_0000;

    pub fn create(title: ?[*:0]const u8, w: i32, h: i32, flags: Flags) Error!*Window {
        return SDL_CreateWindow(title, w, h, flags) orelse return makeError();
    }
    extern fn SDL_CreateWindow(title: ?[*:0]const u8, w: i32, h: i32, flags: Flags) ?*Window;

    pub const destroy = SDL_DestroyWindow;
    extern fn SDL_DestroyWindow(window: *Window) void;

    pub fn getFullscreenMode(window: *Window) Error!DisplayMode {
        var mode: DisplayMode = undefined;
        if (SDL_GetWindowFullscreenMode(window, &mode) == False) return makeError();
        return mode;
    }
    extern fn SDL_GetWindowFullscreenMode(window: *Window, mode: *DisplayMode) i32;

    pub fn getPosition(window: *Window, w: ?*i32, h: ?*i32) Error!void {
        if (SDL_GetWindowPosition(window, w, h) == False) return makeError();
    }
    extern fn SDL_GetWindowPosition(window: *Window, x: ?*i32, y: ?*i32) i32;

    pub fn getSize(window: *Window, w: ?*i32, h: ?*i32) Error!void {
        if (SDL_GetWindowSize(window, w, h) == False) return makeError();
    }
    extern fn SDL_GetWindowSize(window: *Window, w: ?*i32, h: ?*i32) i32;

    pub fn setTitle(window: *Window, title: [:0]const u8) void {
        SDL_SetWindowTitle(window, title);
    }
    extern fn SDL_SetWindowTitle(window: *Window, title: ?[*:0]const u8) void;
};

pub fn getNumVideoDrivers() Error!u16 {
    const res = SDL_GetNumVideoDrivers();
    if (res < 1) return makeError();
    return @intCast(res);
}
extern fn SDL_GetNumVideoDrivers() c_int;

pub fn getVideoDriver(index: u16) ?[:0]const u8 {
    if (SDL_GetVideoDriver(@intCast(index))) |ptr| {
        return std.mem.sliceTo(ptr, 0);
    }
    return null;
}
extern fn SDL_GetVideoDriver(index: c_int) ?[*:0]const u8;

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
        if (SDL_GL_SetAttribute(attr, value) == False) return makeError();
    }
    extern fn SDL_GL_SetAttribute(attr: Attr, value: c_int) c_int;

    pub fn getAttribute(attr: Attr) Error!i32 {
        var value: i32 = undefined;
        if (SDL_GL_GetAttribute(attr, &value) == False) return makeError();
        return value;
    }
    extern fn SDL_GL_GetAttribute(attr: Attr, value: *c_int) c_int;

    pub fn setSwapInterval(interval: i32) Error!void {
        if (SDL_GL_SetSwapInterval(interval) == False) return makeError();
    }
    extern fn SDL_GL_SetSwapInterval(interval: c_int) c_int;

    pub fn getSwapInterval() Error!i32 {
        var interval: c_int = undefined;
        if (SDL_GL_GetSwapInterval(&interval) == False) return makeError();
        return @intCast(interval);
    }
    extern fn SDL_GL_GetSwapInterval(interval: *c_int) c_int;

    pub fn swapWindow(window: *Window) Error!void {
        if (SDL_GL_SwapWindow(window) == False) return makeError();
    }
    extern fn SDL_GL_SwapWindow(window: *Window) c_int;

    pub fn getProcAddress(proc: [*:0]const u8) FunctionPointer {
        return SDL_GL_GetProcAddress(proc);
    }
    extern fn SDL_GL_GetProcAddress(proc: ?[*:0]const u8) FunctionPointer;

    pub fn isExtensionSupported(extension: [:0]const u8) bool {
        return SDL_GL_ExtensionSupported(extension) == True;
    }
    extern fn SDL_GL_ExtensionSupported(extension: ?[*:0]const u8) Bool;

    pub fn createContext(window: *Window) Error!Context {
        return SDL_GL_CreateContext(window) orelse return makeError();
    }
    extern fn SDL_GL_CreateContext(window: *Window) ?Context;

    pub fn makeCurrent(window: *Window, context: Context) Error!void {
        if (SDL_GL_MakeCurrent(window, context) == False) return makeError();
    }
    extern fn SDL_GL_MakeCurrent(window: *Window, context: Context) c_int;

    pub const deleteContext = SDL_GL_DeleteContext;
    extern fn SDL_GL_DeleteContext(context: Context) void;
};

//--------------------------------------------------------------------------------------------------
//
// 2D Accelerated Rendering
//
//--------------------------------------------------------------------------------------------------
pub const TextureAccess = enum(c_int) {
    static,
    streaming,
    target,
};

pub const Texture = opaque {
    pub fn destroy(tex: *Texture) void {
        SDL_DestroyTexture(tex);
    }
    extern fn SDL_DestroyTexture(texture: ?*Texture) void;

    pub fn lock(texture: *Texture, rect: ?*Rect) !struct {
        pixels: [*]u8,
        pitch: i32,
    } {
        var pixels: *anyopaque = undefined;
        var pitch: i32 = undefined;
        if (SDL_LockTexture(texture, rect, &pixels, &pitch) == False) {
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
    ) c_int;

    pub fn unlock(texture: *Texture) void {
        SDL_UnlockTexture(texture);
    }
    extern fn SDL_UnlockTexture(texture: *Texture) void;
};

pub const Vertex = extern struct {
    position: FPoint,
    color: Color,
    tex_coord: FPoint,
};

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

pub const RendererFlip = enum(c_int) {
    none = 0x0000,
    horizontal = 0x0001,
    vertical = 0x0002,
    both = 0x0003,
};

pub const RendererLogicalPresentationMode = enum(c_int) {
    disabled,
    stretch,
    letterbox,
    overscan,
    integer_scale,
};

pub const Renderer = opaque {
    pub const Flags = packed struct(u32) {
        software: bool = false,
        accelerated: bool = false,
        present_vsync: bool = false,
        __unused5: u29 = 0,
    };

    pub fn create(window: *Window, name: ?[*:0]const u8, flags: Flags) Error!*Renderer {
        return SDL_CreateRenderer(window, @ptrCast(name), flags) orelse makeError();
    }
    extern fn SDL_CreateRenderer(window: *Window, name: ?[*:0]const u8, flags: Flags) ?*Renderer;

    pub const destroy = SDL_DestroyRenderer;
    extern fn SDL_DestroyRenderer(r: *Renderer) void;

    pub fn clear(r: *Renderer) !void {
        if (SDL_RenderClear(r) == False) return makeError();
    }
    extern fn SDL_RenderClear(r: *Renderer) i32;

    pub const present = SDL_RenderPresent;
    extern fn SDL_RenderPresent(r: *Renderer) void;

    pub fn texture(
        r: *Renderer,
        tex: *Texture,
        src: ?*const Rect,
        dst: ?*const Rect,
    ) Error!void {
        if (SDL_RenderTexture(r, tex, src, dst) == False) return makeError();
    }
    extern fn SDL_RenderTexture(
        r: *Renderer,
        t: *Texture,
        srcrect: ?*const Rect,
        dstrect: ?*const Rect,
    ) c_int;

    pub fn textureRotated(
        r: *Renderer,
        tex: *Texture,
        src: ?*const Rect,
        dst: ?*const Rect,
        angle: f64,
        center: ?*const Point,
        flip: RendererFlip,
    ) Error!void {
        if (SDL_RenderTextureRotated(r, tex, src, dst, angle, center, flip) == False) return makeError();
    }
    extern fn SDL_RenderTextureRotated(
        r: *Renderer,
        t: *Texture,
        srcrect: ?*const Rect,
        dstrect: ?*const Rect,
        angle: f64,
        center: ?*const Point,
        flip: RendererFlip,
    ) c_int;

    pub fn setScale(renderer: *Renderer, x: f32, y: f32) Error!void {
        if (SDL_SetRenderScale(renderer, x, y) == False) return makeError();
    }
    extern fn SDL_SetRenderScale(renderer: *Renderer, scaleX: f32, scaleY: f32) c_int;

    pub fn line(renderer: *Renderer, x0: f32, y0: f32, x1: f32, y1: f32) Error!void {
        if (SDL_RenderLine(renderer, x0, y0, x1, y1) == False) return makeError();
    }
    extern fn SDL_RenderLine(renderer: *Renderer, x1: f32, y1: f32, x2: f32, y2: f32) c_int;

    pub fn point(renderer: *Renderer, x: f32, y: f32) Error!void {
        if (SDL_RenderPoint(renderer, x, y) == False) return makeError();
    }
    extern fn SDL_RenderPoint(renderer: *Renderer, x: f32, y: f32) c_int;

    pub fn fillRect(renderer: *Renderer, _rect: Rect) Error!void {
        if (SDL_RenderFillRect(renderer, &_rect) == False) return makeError();
    }
    extern fn SDL_RenderFillRect(renderer: ?*Renderer, rect: *const Rect) c_int;

    pub fn rect(renderer: *Renderer, _rect: Rect) Error!void {
        if (SDL_RenderRect(renderer, &_rect) == False) return makeError();
    }
    extern fn SDL_RenderRect(renderer: *Renderer, rect: *const Rect) c_int;

    pub fn drawGeometry(
        r: *Renderer,
        tex: ?*const Texture,
        vertices: []const Vertex,
        indices: ?[]const u32,
    ) Error!void {
        if (SDL_RenderGeometry(
            r,
            tex,
            vertices.ptr,
            @as(i32, @intCast(vertices.len)),
            if (indices) |idx| @as([*]const i32, @ptrCast(idx.ptr)) else null,
            if (indices) |idx| @as(i32, @intCast(idx.len)) else 0,
        ) == False)
            return makeError();
    }
    extern fn SDL_RenderGeometry(
        renderer: *Renderer,
        texture: ?*const Texture,
        vertices: [*c]const Vertex,
        num_vertices: i32,
        indices: [*c]const i32,
        num_indices: i32,
    ) c_int;

    pub fn setDrawColor(renderer: *Renderer, color: Color) Error!void {
        if (SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a) == False) {
            return makeError();
        }
    }
    extern fn SDL_SetRenderDrawColor(renderer: *Renderer, r: u8, g: u8, b: u8, a: u8) c_int;

    pub fn getDrawColor(renderer: *const Renderer) Error!Color {
        var color: Color = undefined;
        if (SDL_GetRenderDrawColor(renderer, &color.r, &color.g, &color.b, &color.a) == False) {
            return makeError();
        }
        return color;
    }
    extern fn SDL_GetRenderDrawColor(renderer: *const Renderer, r: *u8, g: *u8, b: *u8, a: *u8) c_int;

    pub fn getDrawBlendMode(r: *const Renderer) Error!BlendMode {
        var blend_mode: BlendMode = undefined;
        if (SDL_GetRenderDrawBlendMode(r, &blend_mode) == False) return makeError();
        return blend_mode;
    }
    extern fn SDL_GetRenderDrawBlendMode(renderer: *const Renderer, blendMode: *BlendMode) c_int;

    pub fn setDrawBlendMode(r: *Renderer, blend_mode: BlendMode) Error!void {
        if (SDL_SetRenderDrawBlendMode(r, blend_mode) == False) return makeError();
    }
    extern fn SDL_SetRenderDrawBlendMode(renderer: *Renderer, blendMode: BlendMode) c_int;

    pub fn getCurrentOutputSize(r: *const Renderer) Error!struct { w: i32, h: i32 } {
        var w: i32 = undefined;
        var h: i32 = undefined;
        if (SDL_GetCurrentRenderOutputSize(r, &w, &h) == False) return makeError();
        return .{ .w = w, .h = h };
    }
    extern fn SDL_GetCurrentRenderOutputSize(renderer: *const Renderer, w: *i32, h: *i32) c_int;

    pub fn createTexture(
        renderer: *Renderer,
        format: PixelFormatEnum,
        access: TextureAccess,
        width: i32,
        height: i32,
    ) Error!*Texture {
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

    pub fn clipEnabled(renderer: *const Renderer) bool {
        return SDL_RenderClipEnabled(renderer) == True;
    }
    pub extern fn SDL_RenderClipEnabled(renderer: *const Renderer) Bool;

    pub fn setClipRect(r: *Renderer, clip_rect: ?*const Rect) Error!void {
        if (SDL_SetRenderClipRect(r, clip_rect) == False) return makeError();
    }
    extern fn SDL_SetRenderClipRect(renderer: *Renderer, rect: ?*const Rect) c_int;

    pub fn getClipRect(r: *Renderer) Error!Rect {
        var clip_rect: Rect = undefined;
        if (SDL_GetRenderClipRect(r, &clip_rect) == False) return makeError();
        return clip_rect;
    }
    extern fn SDL_GetRenderClipRect(renderer: *Renderer, rect: ?*Rect) c_int;

    pub fn getLogicalPresentation(
        renderer: *const Renderer,
        w: *i32,
        h: *i32,
        mode: *RendererLogicalPresentationMode,
        scale_mode: *ScaleMode,
    ) Error!void {
        if (SDL_GetRenderLogicalPresentation(renderer, w, h, mode, scale_mode) == False) {
            return makeError();
        }
    }
    extern fn SDL_GetRenderLogicalPresentation(
        renderer: *const Renderer,
        w: *i32,
        h: *i32,
        mode: *RendererLogicalPresentationMode,
        scale_mode: *ScaleMode,
    ) c_int;

    pub fn setLogicalPresentation(
        renderer: *Renderer,
        w: i32,
        h: i32,
        mode: RendererLogicalPresentationMode,
        scale_mode: ScaleMode,
    ) Error!void {
        if (SDL_SetRenderLogicalPresentation(renderer, w, h, mode, scale_mode) == False) {
            return makeError();
        }
    }
    extern fn SDL_SetRenderLogicalPresentation(
        renderer: *Renderer,
        w: i32,
        h: i32,
        mode: RendererLogicalPresentationMode,
        scale_mode: ScaleMode,
    ) c_int;

    pub fn getViewport(renderer: *const Renderer) Error!Rect {
        var viewport: Rect = undefined;
        if (SDL_GetRenderViewport(renderer, &viewport) == False) return makeError();
        return viewport;
    }
    extern fn SDL_GetRenderViewport(renderer: *const Renderer, rect: *Rect) c_int;

    pub fn setViewport(renderer: *Renderer, maybe_rect: ?*const Rect) Error!void {
        if (SDL_SetRenderViewport(renderer, maybe_rect) == False) {
            return makeError();
        }
    }
    extern fn SDL_SetRenderViewport(renderer: *Renderer, rect: ?*const Rect) c_int;

    pub fn setTarget(r: *Renderer, tex: ?*const Texture) Error!void {
        if (SDL_SetRenderTarget(r, tex) == False) return makeError();
    }
    extern fn SDL_SetRenderTarget(renderer: *Renderer, texture: ?*const Texture) c_int;

    pub fn readPixels(
        renderer: *const Renderer,
        _rect: ?*const Rect,
        format: PixelFormatEnum,
        pixels: [*]u8,
        pitch: i32,
    ) Error!void {
        if (SDL_RenderReadPixels(renderer, _rect, format, pixels, pitch) == False) {
            return makeError();
        }
    }
    extern fn SDL_RenderReadPixels(
        renderer: *const Renderer,
        rect: ?*const Rect,
        format: PixelFormatEnum,
        pixels: ?*anyopaque,
        pitch: c_int,
    ) c_int;
};

pub fn createWindowAndRenderer(
    window_title: ?[*:0]const u8,
    width: u32,
    height: u32,
    window_flags: Window.Flags,
    window: **Window,
    renderer: **Renderer,
) Error!void {
    if (SDL_CreateWindowAndRenderer(
        window_title,
        @bitCast(width),
        @bitCast(height),
        window_flags,
        @ptrCast(window),
        @ptrCast(renderer),
    ) == False) return makeError();
}
extern fn SDL_CreateWindowAndRenderer(
    title: ?[*:0]const u8,
    width: c_int,
    height: c_int,
    window_flags: Window.Flags,
    window: ?*?*Window,
    renderer: ?*?*Renderer,
) c_int;

//--------------------------------------------------------------------------------------------------
//
// Pixel Formats and Conversion Routines
//
//--------------------------------------------------------------------------------------------------
pub const PixelType = enum(c_int) {
    none = 0,
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
};
pub const BitmapOrder = enum(c_int) {
    none = 0,
    @"4321",
    @"1234",
};
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
pub const ArrayOrder = enum(c_int) {
    none = 0,
    rgb,
    rgba,
    argb,
    bgr,
    bgra,
    abgr,
};
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
        .index1, .index4, .index8 => {
            assert(@TypeOf(order) == BitmapOrder);
        },
        .packed8, .packed16, .packed32 => {
            assert(@TypeOf(order) == PackedOrder);
        },
        .arrayu8, .arrayu16, .arrayu32, .arrayf16, .arrayf32 => {
            assert(@TypeOf(order) == ArrayOrder);
        },
        .none => unreachable,
    }
    return ((1 << 28) | ((@intFromEnum(_type)) << 24) | ((@intFromEnum(order)) << 20) |
        ((layout) << 16) | ((bits) << 8) | ((bytes) << 0));
}
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

//--------------------------------------------------------------------------------------------------
//
// Rectangle Functions
//
//--------------------------------------------------------------------------------------------------
pub const Rect = extern struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,

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

pub fn hasRectIntersection(a: *const Rect, b: *const Rect) bool {
    return SDL_HasRectIntersection(a, b) == True;
}
extern fn SDL_HasRectIntersection(a: *const Rect, b: *const Rect) Bool;

pub fn getRectIntersection(a: *const Rect, b: *const Rect, result: *Rect) bool {
    return SDL_GetRectIntersection(a, b, result) == True;
}
extern fn SDL_GetRectIntersection(a: *const Rect, b: *const Rect, result: *Rect) Bool;

pub fn getRectAndLineIntersection(
    r: *const Rect,
    x1: *i32,
    y1: *i32,
    x2: *i32,
    y2: *i32,
) bool {
    return SDL_GetRectAndLineIntersection(r, x1, y1, x2, y2) == True;
}
extern fn SDL_GetRectAndLineIntersection(
    r: *const Rect,
    x1: *i32,
    y1: *i32,
    x2: *i32,
    y2: *i32,
) Bool;

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

pub fn hasRectIntersectionFloat(a: *const FRect, b: *const FRect) bool {
    return SDL_HasRectIntersectionFloat(a, b) == True;
}
extern fn SDL_HasRectIntersectionFloat(a: *const FRect, b: *const FRect) Bool;

pub fn getRectIntersectionFloat(a: *const FRect, b: *const FRect, result: *FRect) bool {
    return SDL_GetRectIntersectionFloat(a, b, result) == True;
}
extern fn SDL_GetRectIntersectionFloat(a: *const FRect, b: *const FRect, result: *FRect) Bool;

pub fn getRectAndLineIntersectionFloat(
    r: *const FRect,
    x1: *f32,
    y1: *f32,
    x2: *f32,
    y2: *f32,
) bool {
    return SDL_GetRectAndLineIntersectionFloat(r, x1, y1, x2, y2);
}
extern fn SDL_GetRectAndLineIntersectionFloat(
    r: *const FRect,
    x1: *f32,
    y1: *f32,
    x2: *f32,
    y2: *f32,
) bool;

pub const Point = extern struct {
    x: i32,
    y: i32,
};

pub const FPoint = extern struct {
    x: f32,
    y: f32,
};

//--------------------------------------------------------------------------------------------------
//
// Surface Creation and Simple Drawing
//
//--------------------------------------------------------------------------------------------------
pub const Surface = opaque {
    pub fn destroy(surface: *Surface) void {
        SDL_DestroySurface(surface);
    }
    extern fn SDL_DestroySurface(surface: *Surface) void;
};

//--------------------------------------------------------------------------------------------------
//
// Clipboard Handling
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Vulkan Support
//
//--------------------------------------------------------------------------------------------------
pub const vk = struct {
    pub const FunctionPointer = ?*const anyopaque;
    pub const Instance = enum(usize) { null_handle = 0, _ };

    pub fn loadLibrary(path: ?[*:0]const u8) Error!void {
        if (SDL_Vulkan_LoadLibrary(path) == False) return makeError();
    }
    extern fn SDL_Vulkan_LoadLibrary(path: ?[*]const u8) i32;

    pub fn getVkGetInstanceProcAddr() FunctionPointer {
        return SDL_Vulkan_GetVkGetInstanceProcAddr();
    }
    extern fn SDL_Vulkan_GetVkGetInstanceProcAddr() FunctionPointer;

    pub fn unloadLibrary() void {
        SDL_Vulkan_UnloadLibrary();
    }
    extern fn SDL_Vulkan_UnloadLibrary() void;

    pub fn getInstanceExtensions(count: *i32, maybe_names: ?[*][*:0]u8) bool {
        return SDL_Vulkan_GetInstanceExtensions(count, maybe_names);
    }
    extern fn SDL_Vulkan_GetInstanceExtensions(count: *i32, names: ?[*][*:0]u8) bool;

    pub fn createSurface(window: *Window, instance: Instance, surface: *anyopaque) bool {
        return SDL_Vulkan_CreateSurface(window, instance, surface);
    }
    extern fn SDL_Vulkan_CreateSurface(window: *Window, instance: Instance, surface: *anyopaque) bool;
};

//--------------------------------------------------------------------------------------------------
//
// Metal Support
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Event Handling
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
    enter_foreground,
    locale_changed,
    system_theme_changed,

    _reserved_sdl2compat_displayevent = 0x150,
    display_orientation,
    display_connected,
    display_disconnected,
    display_moved,
    display_content_scale_changed,

    _reserved_sdl2compat_windowevent = 0x200,
    syswm,
    window_shown,
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

    key_down = 0x300,
    key_up,
    text_editing,
    text_input,
    keymap_changed,
    text_editing_ext,

    mouse_motion = 0x400,
    mouse_button_down,
    mouse_button_up,
    mouse_wheel,

    joystick_axis_motion = 0x600,
    _reserved_sdl2compat_joyballmotion,
    joystick_hat_motion,
    joystick_button_down,
    joystick_button_up,
    joystick_added,
    joystick_removed,
    joystick_battery_updated,
    joystick_update_complete,

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

    finger_down = 0x700,
    finger_up,
    finger_motion,

    _reserved_sdl2compat_dollargesture = 0x800,
    _reserved_sdl2compat_dollarrecord,
    _reserved_sdl2compat_multigesture,

    clipboard_update = 0x900,

    drop_file = 0x1000,
    drop_text,
    drop_begin,
    drop_complete,

    audio_device_added = 0x1100,
    audio_device_removed,

    sensor_update = 0x1200,

    render_targets_reset = 0x2000,
    render_device_reset,

    poll_sentinel = 0x7f00,

    user = 0x8000,

    lastevent = 0xffff,

    _,
};

pub const ReleasedOrPressed = enum(u8) {
    released,
    pressed,
};

pub const CommonEvent = extern struct {
    type: EventType,
    timestamp: u64,
};

pub const DisplayEvent = extern struct {
    type: EventType,
    timestamp: u64,
    display_id: DisplayId,
    data1: i32,
};

pub const WindowEvent = extern struct {
    type: EventType,
    timestamp: u64,
    window_id: WindowId,
    data1: i32,
    data2: i32,
};

pub const KeyboardEvent = extern struct {
    type: EventType,
    reserved: u32,
    timestamp: u64,
    window_id: WindowId,
    which: KeyboardID,
    state: ReleasedOrPressed,
    repeat: u8,
    padding2: u8,
    padding3: u8,
    keysym: Keysym,
};

pub const TextEditingEvent = extern struct {
    type: EventType,
    timestamp: u64,
    window_id: WindowId,
    text: [text_size]u8,
    start: i32,
    length: i32,

    const text_size = 32;
};

pub const TextEditingExtEvent = extern struct {
    type: EventType,
    timestamp: u64,
    window_id: WindowId,
    text: [*:0]u8,
    start: i32,
    length: i32,
};

pub const TextInputEvent = extern struct {
    type: EventType,
    timestamp: u64,
    window_id: WindowId,
    text: [text_size]u8,

    const text_size = 32;
};

pub const MouseMotionEvent = extern struct {
    type: EventType,
    timestamp: u64,
    window_id: WindowId,
    which: MouseId,
    state: u32,
    x: f32,
    y: f32,
    xrel: f32,
    yrel: f32,
};

pub const MouseButtonEvent = extern struct {
    type: EventType,
    timestamp: u64,
    window_id: WindowId,
    which: MouseId,
    button: u8,
    state: ReleasedOrPressed,
    clicks: u8,
    padding: u8,
    x: f32,
    y: f32,
};

pub const MouseWheelEvent = extern struct {
    type: EventType,
    timestamp: u64,
    window_id: WindowId,
    which: MouseId,
    x: f32,
    y: f32,
    direction: MouseWheelDirection,
    preciseX: f32,
    preciseY: f32,
};

pub const QuitEvent = extern struct {
    type: EventType,
    timestamp: u64,
};

pub const DropEvent = extern struct {
    type: EventType,
    timestamp: u64,
    file: ?[*:0]u8,
    window_id: WindowId,
    x: f32,
    y: f32,
};

pub const GamepadDeviceEvent = extern struct {
    type: EventType,
    timestamp: u64,
    which: JoystickId,
};

pub const Event = extern union {
    type: EventType,
    common: CommonEvent,
    display: DisplayEvent,
    window: WindowEvent,
    key: KeyboardEvent,
    edit: TextEditingEvent,
    editExt: TextEditingExtEvent,
    text: TextInputEvent,
    motion: MouseMotionEvent,
    button: MouseButtonEvent,
    wheel: MouseWheelEvent,
    controllerdevice: GamepadDeviceEvent,
    quit: QuitEvent,
    drop: DropEvent,

    padding: [size]u8,

    const size = 128;

    comptime {
        assert(@sizeOf(Event) == size);
    }
};

pub fn pollEvent(event: ?*Event) bool {
    return SDL_PollEvent(event) != 0;
}
extern fn SDL_PollEvent(event: ?*Event) i32;

/// You should set the common.timestamp field before passing an event to `pushEvent`.
/// If the timestamp is 0 it will be filled in with `getTicksNS()`.
/// Returns true if event was added
///         false if event was filtered out
pub fn pushEvent(event: *Event) Error!bool {
    const status = SDL_PushEvent(event);
    if (status == False) return makeError();
    return status == 1;
}
extern fn SDL_PushEvent(event: *Event) c_int;

//--------------------------------------------------------------------------------------------------
//
// Keyboard Support
//
//--------------------------------------------------------------------------------------------------
pub const Scancode = @import("keyboard.zig").Scancode;

pub const Keycode = @import("keyboard.zig").Keycode;

pub const KeyboardID = u32;

pub const Keysym = extern struct {
    scancode: Scancode,
    sym: Keycode,
    mod: u16,
    unused: u32,
};

pub fn getKeyboardState() []const u8 {
    var numkeys: i32 = 0;
    const ptr = SDL_GetKeyboardState(&numkeys).?;
    return ptr[0..@as(usize, @intCast(numkeys))];
}
extern fn SDL_GetKeyboardState(numkeys: ?*i32) ?[*]const u8;

//--------------------------------------------------------------------------------------------------
//
// Mouse Support
//
//--------------------------------------------------------------------------------------------------
pub const MouseId = u32;

pub const MouseWheelDirection = enum(u32) {
    normal,
    flipped,
};

pub const getMouseFocus = SDL_GetMouseFocus;
extern fn SDL_GetMouseFocus() ?*Window;

pub const getMouseState = SDL_GetMouseState;
extern fn SDL_GetMouseState(x: ?*f32, y: ?*f32) u32;

pub fn showCursor() Error!void {
    if (SDL_ShowCursor() == False) return makeError();
}
extern fn SDL_ShowCursor() c_int;

pub fn hideCursor() Error!void {
    if (SDL_HideCursor() == False) return makeError();
}
extern fn SDL_HideCursor() c_int;

//--------------------------------------------------------------------------------------------------
//
// Joystick Support
//
//--------------------------------------------------------------------------------------------------
pub const JoystickId = u32;

pub const JOYSTICK_AXIS_MAX = 32767;
pub const JOYSTICK_AXIS_MIN = -32768;

//--------------------------------------------------------------------------------------------------
//
// Gamepad Support
//
//--------------------------------------------------------------------------------------------------
pub const Gamepad = opaque {
    pub const Axis = enum(c_int) {
        leftx,
        lefty,
        rightx,
        righty,
        left_trigger,
        right_trigger,
    };
    pub const Button = enum(c_int) {
        a,
        b,
        x,
        y,
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
        paddle1,
        paddle2,
        paddle3,
        paddle4,
        touchpad,
    };

    pub fn open(joystick_index: i32) ?*Gamepad {
        return SDL_OpenGamepad(joystick_index);
    }
    extern fn SDL_OpenGamepad(joystick_index: i32) ?*Gamepad;

    pub fn close(controller: *Gamepad) void {
        SDL_CloseGamepad(controller);
    }
    extern fn SDL_CloseGamepad(joystick: *Gamepad) void;

    pub fn getAxis(controller: *Gamepad, axis: Axis) i16 {
        return SDL_GetGamepadAxis(controller, @intFromEnum(axis));
    }
    extern fn SDL_GetGamepadAxis(*Gamepad, axis: c_int) i16;

    pub fn getButton(controller: *Gamepad, button: Button) bool {
        return (SDL_GetGamepadButton(controller, @intFromEnum(button)) == False);
    }
    extern fn SDL_GetGamepadButton(controller: *Gamepad, button: c_int) u8;
};

//--------------------------------------------------------------------------------------------------
//
// Sensors
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Force Feedback Support
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Audio Device Management, Playing and Recording
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

pub const AudioDeviceID = u32;

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
pub fn getAudioPlaybackDevices() Error![]AudioDeviceID {
    var count: c_int = undefined;
    const maybe_list = SDL_GetAudioPlaybackDevices(&count);
    return if (maybe_list) |list| list[0..@intCast(count)] else makeError();
}
extern fn SDL_GetAudioPlaybackDevices(out_count: ?*c_int) ?[*]AudioDeviceID;

/// Get a list of currently-connected audio recording devices.
///
/// This only returns a list of physical devices; it will not have any device
/// IDs returned by SDL_OpenAudioDevice().
///
/// If this function returns NULL, to signify an error, `*count` will be set to  zero.
///
/// Returns a 0 terminated array of device instance IDs or NULL on error;
/// call SDL_free() when it is no longer needed.
pub fn getAudioRecordingDevices() Error![]AudioDeviceID {
    var count: c_int = undefined;
    const maybe_list = SDL_GetAudioRecordingDevices(&count);
    return if (maybe_list) |list| list[0..@intCast(count)] else makeError();
}
extern fn SDL_GetAudioRecordingDevices(out_count: ?*c_int) ?[*]AudioDeviceID;

/// Get the human-readable name of a specific audio device.
pub const getAudioDeviceName = SDL_GetAudioDeviceName;
extern fn SDL_GetAudioDeviceName(AudioDeviceID) [*:0]const u8;

/// Get the current audio format of a specific audio device.
pub fn getAudioDeviceFormat(devid: AudioDeviceID) Error!struct { spec: AudioSpec, sample_frames: c_int } {
    var spec: AudioSpec = undefined;
    var sample_frames: c_int = undefined;
    if (SDL_GetAudioDeviceFormat(devid, &spec, &sample_frames) == False) {
        return makeError();
    }
    return .{ .spec = spec, .sample_frames = sample_frames };
}
extern fn SDL_GetAudioDeviceFormat(AudioDeviceID, out_spec: *AudioSpec, out_sample_frames: *c_int) Bool;

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
pub fn getAudioDeviceChannelMap(devid: AudioDeviceID) ?[]c_int {
    var count: c_int = undefined;
    return if (SDL_GetAudioDeviceChannelMap(devid, &count)) |list_ptr| list_ptr[0..@intCast(count)] else null;
}
extern fn SDL_GetAudioDeviceChannelMap(AudioDeviceID, out_count: *c_int) [*c]c_int;

/// Open a specific audio device.
pub fn openAudioDevice(device: AudioDeviceID, spec: ?*const AudioSpec) Error!void {
    if (SDL_OpenAudioDevice(device, spec) == 0) {
        return makeError();
    }
}
extern fn SDL_OpenAudioDevice(AudioDeviceID, ?*const AudioSpec) AudioDeviceID;

pub fn isAudioDevicePhysical(devid: AudioDeviceID) bool {
    return SDL_IsAudioDevicePhysical(devid) == True;
}
extern fn SDL_IsAudioDevicePhysical(AudioDeviceID) Bool;

pub fn isAudioDevicePlayback(devid: AudioDeviceID) bool {
    return SDL_IsAudioDevicePlayback(devid) == True;
}
extern fn SDL_IsAudioDevicePlayback(AudioDeviceID) Bool;

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
pub fn pauseAudioDevice(device: AudioDeviceID) bool {
    return SDL_PauseAudioDevice(device) == True;
}
extern fn SDL_PauseAudioDevice(AudioDeviceID) Bool;

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
pub fn resumeAudioDevice(device: AudioDeviceID) bool {
    return SDL_ResumeAudioDevice(device) == True;
}
extern fn SDL_ResumeAudioDevice(AudioDeviceID) Bool;

/// Use this function to query if an audio device is paused.
///
/// Unlike in SDL2, audio devices start in an _unpaused_ state, since an app
/// has to bind a stream before any audio will flow. Pausing a paused device is
/// a legal no-op.
///
/// Physical devices can not be paused or unpaused, only logical devices
/// created through SDL_OpenAudioDevice() can be.
pub fn audioDevicePaused(device: AudioDeviceID) bool {
    return SDL_AudioDevicePaused(device) == True;
}
extern fn SDL_AudioDevicePaused(AudioDeviceID) Bool;

/// Get the gain of an audio device.
///
/// Physical devices may not have their gain changed, only logical devices, and
/// this function will always return -1.0f when used on physical devices.
pub fn getAudioDeviceGain(device: AudioDeviceID) Error!f32 {
    const gain = SDL_GetAudioDeviceGain(device);
    return if (gain == -1.0) makeError() else gain;
}
extern fn SDL_GetAudioDeviceGain(AudioDeviceID) f32;

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
pub fn setAudioDeviceGain(device: AudioDeviceID, gain: f32) Error!void {
    if (SDL_SetAudioDeviceGain(device, gain) == False) {
        return makeError();
    }
}
extern fn SDL_SetAudioDeviceGain(AudioDeviceID, f32) Bool;

/// Close a previously-opened audio device.
///
/// The application should close open audio devices once they are no longer  needed.
///
/// This function may block briefly while pending audio data is played by the
/// hardware, so that applications don't drop the last buffer of data they
/// supplied if terminating immediately afterwards.
pub const closeAudioDevice = SDL_CloseAudioDevice;
extern fn SDL_CloseAudioDevice(AudioDeviceID) void;

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
extern fn SDL_GetAudioStreamDevice(*AudioStream) AudioDeviceID;

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
    if (SDL_PutAudioStreamData(stream, data.ptr, @intCast(@sizeOf(SampleType) * data.len)) == False) {
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
pub const getAudioStreamQueued = SDL_GetAudioStreamQueued;
extern fn SDL_GetAudioStreamQueued(*AudioStream) c_int;

/// Tell the stream that you're done sending data, and anything being buffered
/// should be converted/resampled and made available immediately.
///
/// It is legal to add more data to a stream after flushing, but there may be
/// audio gaps in the output. Generally this is intended to signal the end of
/// input, so the complete output becomes available.
pub fn flushAudioStream(stream: *AudioStream) Error!void {
    if (SDL_FlushAudioStream(stream) == False) {
        return makeError();
    }
}
extern fn SDL_FlushAudioStream(*AudioStream) Bool;

/// Clear any pending data in the stream.
///
/// This drops any queued data, so there will be nothing to read from the
/// stream until more is added.
pub fn clearAudioStream(stream: *AudioStream) Error!void {
    if (SDL_ClearAudioStream(stream) == False) {
        return makeError();
    }
}
extern fn SDL_ClearAudioStream(*AudioStream) Bool;

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
) callconv(.C) void;

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
pub fn openAudioDeviceStream(device: AudioDeviceID, spec: *const AudioSpec, callback: ?AudioStreamCallback, userdata: *anyopaque) Error!*AudioStream {
    const maybe_stream = SDL_OpenAudioDeviceStream(device, spec, callback, userdata);
    return if (maybe_stream) |stream| stream else makeError();
}
extern fn SDL_OpenAudioDeviceStream(AudioDeviceID, *const AudioSpec, ?AudioStreamCallback, *anyopaque) ?*AudioStream;

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
// Thread Management
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Thread Synchronization Primitives
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Atomic Operations
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Timer Support
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
// Filesystem Paths
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
// File I/O Abstraction
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Shared Object Loading and Function Lookup
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Platform Detection
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// CPU Feature Detection
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Byte Order and Byte Swapping
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Bit Manipulation
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Power Management Status
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// Message boxes
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
    title: [:0]const u8,
    message: [:0]const u8,
    window: ?*Window,
) Error!void {
    if (SDL_ShowSimpleMessageBox(flags, title, message, window) == False) return makeError();
}
extern fn SDL_ShowSimpleMessageBox(
    flags: MessageBoxFlags,
    title: ?[*:0]const u8,
    message: ?[*:0]const u8,
    window: ?*Window,
) i32;

//--------------------------------------------------------------------------------------------------
//
// Platform-specific Functionality
//
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
//
// "Standard Library" Functionality
//
//--------------------------------------------------------------------------------------------------
pub const Bool = c_int;
pub const False = @as(Bool, 0);
pub const True = @as(Bool, 1);

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
