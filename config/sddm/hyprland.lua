-- Load Omarchy's greeter settings, including its keyboard layout.
dofile("/usr/share/sddm/hyprland.lua")

hl.monitor({ output = "DSI-1", mode = "preferred", position = "auto", scale = 1, transform = 3 })
hl.config({ input = { touchdevice = { output = "DSI-1", transform = 3 } } })
hl.device({ name = "goodix-capacitive-touchscreen-1", output = "DSI-1", transform = 3 })
