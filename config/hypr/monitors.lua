-- ====================================================================
-- Chuwi MiniBook X (Intel N100) Display Configuration
-- Native internal display: DSI-1 (1200x1920 portrait panel)
-- Transform 3 (270°) rotates the display into standard landscape format
-- ====================================================================

hl.monitor({
  output = "DSI-1",
  mode = "preferred",
  position = "0x0",
  scale = 1,
  transform = 3,
})

-- Fallback for any connected external displays
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})
