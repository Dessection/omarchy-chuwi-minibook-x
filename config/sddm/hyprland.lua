-- Hyprland configuration for SDDM Wayland greeter on Chuwi MiniBook X
hl.config({
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
  },
  animations = {
    enabled = false,
  },
  input = {
    touchdevice = {
      transform = 3,
      output = "DSI-1",
    },
  },
})

-- Chuwi MiniBook X internal display rotation (transform = 3)
hl.monitor({ output = "DSI-1", mode = "preferred", position = "0x0", scale = 1, transform = 3 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Touchscreen mapping
hl.device({
  name = "goodix-capacitive-touchscreen-1",
  output = "DSI-1",
  transform = 3,
})
