"""
Persistent information regarding a surface to render to.

Information subject to changes, like the extent of a window, will
not be collected here.
"""
struct Surface
  handle::Vk.SurfaceKHR
  color_format::Vk.Format
  color_space::Vk.ColorSpaceKHR
  usage::Vk.ImageUsageFlag
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, surface::Surface) = surface.handle

function Surface(window::XCBWindow, device)
  # Hardcode usage for now. There is no reason to make that dynamic at the moment.
  usage = Vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT
  surface = unwrap(Vk.create_xcb_surface_khr(Vk.instance(device), window.conn, window.id))
  surface_formats = unwrap(Vk.get_physical_device_surface_formats_khr(Lava.physical_device(device), surface))
  format = first(surface_formats)
  Surface(surface, format.format, format.color_space, usage)
end

struct Swapchain
  handle::Vk.SwapchainKHR
  info::Vk.SwapchainCreateInfoKHR
end

function Swapchain(surface::Surface, device)
    capabilities = unwrap(Vk.get_physical_device_surface_capabilities_khr(Lava.physical_device(device), surface))
    @assert Vk.COMPOSITE_ALPHA_OPAQUE_BIT_KHR in capabilities.supported_composite_alpha
    @assert surface.usage in capabilities.supported_usage_flags
    info = Vk.SwapchainCreateInfoKHR(
        surface.handle,
        3,
        surface.color_format,
        surface.color_space,
        capabilities.current_extent,
        1,
        surface.usage,
        Vk.SHARING_MODE_EXCLUSIVE,
        [],
        capabilities.current_transform,
        Vk.COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        Vk.PRESENT_MODE_IMMEDIATE_KHR,
        false,
    )
    handle = Vk.SwapchainKHR(device, info)
    Swapchain(handle, info)
end

struct Target
  window::XCBWindow
  surface::Surface
  swapchain::Swapchain
  pending_objects::Vector{Any}
end

function Target(target::XCBWindow, device, objects = [])
  Target(target, Surface(target, device), objects)
end
