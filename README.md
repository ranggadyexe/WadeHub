# Wade Hub v2.0 — UI Library

Mac OS styled Roblox UI library with smooth animations, Lucide icons via Rayfield, auto-save config system, sidebar avatar footer, and a simple API.

## Getting Started

```lua
local WadeHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/ranggadyexe/WadeHub/main/WadeHub.lua"))()

local Window = WadeHub:CreateWindow({
    Name = "My Script Hub",
    OnClose = function()
        print("UI closed!")
    end
})
```

## Window

### Tab + Icon
```lua
local MainTab = Window:CreateTab({Name = "Main", Icon = "home"})
local ConfigTab = Window:CreateTab({Name = "Config", Icon = "settings"})
```

### Section
```lua
MainTab:CreateSection("Basic Settings")
MainTab:CreateSection({Name = "Advanced", Default = false})  -- collapsed by default
```

## Elements

### Button
```lua
MainTab:CreateButton({
    Name = "Click Me",
    Callback = function()
        print("Button clicked!")
    end
})
```

### Toggle
```lua
MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(state)
        print("State:", state)
    end
})
```

### Slider
```lua
MainTab:CreateSlider({
    Name = "Speed",
    Min = 16,
    Max = 100,
    Default = 50,
    Step = 5,          -- optional, snaps to multiples
    Callback = function(value)
        print("Value:", value)
    end
})
```

### Dropdown (Single + Search)
```lua
local dd = MainTab:CreateDropdown({
    Name = "Select Weapon",
    Options = {"Sword", "Bow", "Staff"},
    Default = "Sword",
    Callback = function(val) print(val) end
})

-- Refresh options
dd.Refresh({"New", "List"})
```

### Multi Dropdown (Multi-select + Search)
```lua
local md = MainTab:CreateMultiDropdown({
    Name = "Select Skills",
    Options = {"Fireball", "Heal", "Shield"},
    CurrentSelected = {"Heal"},
    Callback = function(arr)
        print(table.concat(arr, ", "))
    end
})
```

### TextBox
```lua
MainTab:CreateTextBox({
    Name = "Username",
    Placeholder = "Type here...",
    Callback = function(text) print(text) end
})
```

### Keybind
```lua
MainTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKey = Enum.KeyCode.RightControl,
    Callback = function(key) print(key) end
})
```

### ColorPicker
```lua
MainTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 100),
    Callback = function(color) print(color) end
})
```

### Label
```lua
MainTab:CreateLabel("Status: Active")
```

### Paragraph
```lua
MainTab:CreateParagraph({
    Title = "Info",
    Content = "WadeHub v2.0 is running smoothly."
})
```

### Group (2-4 Columns)
```lua
local left, right = MainTab:CreateGroup(2)

left:CreateButton({Name = "Save"})
left:CreateToggle({Name = "Option A"})

right:CreateButton({Name = "Load"})
right:CreateToggle({Name = "Option B"})
```

## Configuration

### Setup
```lua
local Window = WadeHub:CreateWindow({
    Name = "My Hub",
    Configuration = {
        AutoLoad = true,          -- auto-load last-used config on startup
        AutoSave = true,          -- auto-save on any flagged element change (debounced 0.3s)
        AutoLoadDelay = 0.5,      -- optional, seconds before auto-load (default 0.5)
        FolderName = "MyGame",    -- folder name for config files (default "WadeHub")
        OnConfigLoaded = function(name)  -- optional, called after config restore
            print("Config loaded: " .. name)
        end,
    },
})
```

### Flag System
Only elements with `Flag = "unique_name"` are saved/loaded. Every flagged element must have a unique name — duplicates will overwrite each other.

```lua
Tab:CreateToggle({         Name = "Aimbot",   Flag = "aimbot",   CurrentValue = false })
Tab:CreateSlider({         Name = "Speed",    Flag = "speed",    Min = 16, Max = 100, Default = 50 })
Tab:CreateDropdown({       Name = "Weapon",   Flag = "weapon",   Options = {"Sword", "Bow"}, Default = "Sword"})
Tab:CreateMultiDropdown({  Name = "Skills",   Flag = "skills",   Options = {"A","B","C"}, CurrentSelected = {"A"}})
Tab:CreateTextBox({        Name = "Username", Flag = "username", Placeholder = "..." })
Tab:CreateKeybind({        Name = "UI Key",   Flag = "ui_key",   CurrentKey = Enum.KeyCode.RightShift })
```

> **Important**: Callbacks do NOT fire when config is loaded — only UI state changes. Your game logic won't trigger automatically on restart.

| Element | Flag Support | Saved As | Example |
|---|---|---|---|
| `CreateToggle` | ✅ | Boolean | `"aimbot"` → `true` |
| `CreateSlider` | ✅ | Number | `"speed"` → `50` |
| `CreateDropdown` | ✅ | String | `"weapon"` → `"Sword"` |
| `CreateMultiDropdown` | ✅ | Array | `"skills"` → `{"A","B"}` |
| `CreateTextBox` | ✅ | String | `"username"` → `"Player123"` |
| `CreateKeybind` | ✅ | String (KeyCode name) | `"ui_key"` → `"RightShift"` |
| `CreateColorPicker` | ❌ | — | Not supported |
| `CreateButton` | ❌ | — | No value to save |
| `CreateLabel` | ❌ | — | No value to save |

### Multi-Profile API
All config functions return `true`/`false` and show a notification on result.

```lua
-- Save current flagged values to a profile (also updates auto-load target)
Window:SaveConfig("Profile1")     -- MyGame/Profile1.json

-- Load flagged values from a profile (UI updates, callbacks NOT fired)
Window:LoadConfig("Profile2")     -- MyGame/Profile2.json

-- Delete a profile file
Window:DeleteConfig("Old")

-- Set which config loads on next script restart (without saving)
Window:SetAutoLoad("Warrior")     -- writes only _autoload.txt

-- Manually trigger auto-load (reads _autoload.txt, loads that config)
Window:AutoLoadConfig()

-- Get current active config name
local name = Window:GetCurrentConfig()  -- "Profile1"

-- Get list of all saved profiles (excludes _tmp and _autoload)
local profiles = Window:GetConfigList() -- {"default", "Profile1", "Profile2"}
```

### How AutoLoad + AutoSave Work (Default Behavior)

When `AutoLoad = true` and `AutoSave = true`:

```
FIRST RUN (no files exist):
  User changes any flagged element
    → RequestSave() debounced 0.3s
    → saveConfig() → creates default.json + _autoload.txt = "default"
  
RESTART:
  Heartbeat:Wait() — ensures all flags are registered
  → task.wait(AutoLoadDelay)
  → getAutoLoadTarget() reads _autoload.txt → "default"
  → loadConfig("default") → restores default.json → OnConfigLoaded("default")

SAVE EXPLICITLY:
  Window:SaveConfig("Warrior") → creates Warrior.json + _autoload.txt = "Warrior"
  Next restart loads Warrior.json automatically

SET AUTO-LOAD WITHOUT SAVING:
  Window:SetAutoLoad("Mage") → writes _autoload.txt = "Mage"
  Next restart tries to load Mage.json (silent fail if it doesn't exist)
```

### Safety Features
- **No side effects on load**: All `SetValue()` calls skip user callbacks via `_isLoading` guard
- **Type validation**: Wrong types in JSON → fall back to element default + `warn()`
- **Missing flag fallback**: New flags not in file → restored to their default values
- **Atomic writes**: Uses `movefile` if available, or writes to `_tmp` first then copies
- **Tmp recovery**: If main file is corrupt, `loadConfig()` tries `_tmp` backup
- **Name sanitization**: Only `[a-zA-Z0-9_-]` allowed in profile names
- **Generation debounce**: Rapid slider drags only save once (last value wins)

## Dialog
```lua
-- Confirm
Window:Dialog({
    Title = "Reset Settings",
    Content = "Are you sure you want to reset all settings?",
    Icon = "alert-triangle",      -- optional
    Buttons = {
        {Name = "Cancel", Kind = "cancel"},
        {Name = "Reset", Kind = "primary", Callback = function()
            Window:Notify({Title = "Reset", Content = "Settings reset!"})
        end},
    },
})

-- Info only
Window:Dialog({
    Title = "Update",
    Content = "You're on the latest version!",
    Type = "Info",
})
```

## Notification
```lua
Window:Notify({
    Title = "Weapon",
    Content = "Selected: Sword",
    Duration = 3
})
```

## Icons
Lucide icons via Rayfield — auto-loaded, no setup required.

```lua
local Tab = Window:CreateTab({Name = "Main", Icon = "home"})
-- Available: home, settings, user, shield, swords, circle, bell, zap, star...
```

## Security
| Feature | Description |
|---|---|
| ProtectGui | Auto-detect executor (`gethui`, `syn.protect_gui`, fallback to PlayerGui) |
| Anti-duplicate | Destroy old instance before creating a new one |
| Cleanup | Disconnect all events on close |

## License
MIT License.
