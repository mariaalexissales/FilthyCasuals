local MainMenu = require("SoulForgeMenu/SoulForgedMainMenu")

-- Correct hook for right-click menus
Events.OnFillInventoryObjectContextMenu.Add(MainMenu.addContextMenu)

print("[SoulForge] Initialized")
