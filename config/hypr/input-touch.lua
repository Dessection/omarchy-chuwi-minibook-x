-- ====================================================================
-- Chuwi MiniBook X (Intel N100) Touchscreen Configuration
-- Maps goodix-capacitive-touchscreen-1 to DSI-1 with transform = 3
-- ====================================================================

-- Touchscreen device mapping
hl.device({
  name = "goodix-capacitive-touchscreen-1",
  output = "DSI-1",
  transform = 3,
})

-- Global touchdevice fallback
hl.config({
  input = {
    touchdevice = {
      output = "DSI-1",
      transform = 3,
    },
  },
})
