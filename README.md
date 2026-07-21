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
        AutoLoad = true,        -- auto-load last-used config on startup
        FolderName = "MyGame",  -- folder name for config files
    },
})
```

### Flag System
Only elements with `Flag` are saved to config files. Add `Flag = "unique_name"` to any element you want to persist:

```lua
Tab:CreateToggle({  Name = "Aimbot",   Flag = "aimbot",   CurrentValue = false })
Tab:CreateSlider({  Name = "Speed",    Flag = "speed",    Min = 16, Max = 100, Default = 50 })
Tab:CreateDropdown({Name = "Weapon",   Flag = "weapon",   Options = {"Sword", "Bow"}, Default = "Sword"})
Tab:CreateMultiDropdown({Name = "Skills", Flag = "skills", Options = {"A","B","C"}, CurrentSelected = {"A"}})
Tab:CreateTextBox({ Name = "Username", Flag = "username", Placeholder = "..." })
Tab:CreateKeybind({ Name = "UI Key",   Flag = "ui_key",   CurrentKey = Enum.KeyCode.RightShift })
```

| Element | Flag | Value Type | Example |
|---|---|---|---|
| `CreateToggle` | ✅ | Boolean | `"aimbot"` → `true/false` |
| `CreateSlider` | ✅ | Number | `"speed"` → `50` |
| `CreateDropdown` | ✅ | String | `"weapon"` → `"Sword"` |
| `CreateMultiDropdown` | ✅ | Array | `"skills"` → `{"A","B"}` |
| `CreateTextBox` | ✅ | String | `"username"` → `"Player123"` |
| `CreateKeybind` | ✅ | String (KeyCode name) | `"ui_key"` → `"RightShift"` |
| `CreateColorPicker` | ❌ | — | Not supported |
| `CreateButton` | ❌ | — | No value to save |
| `CreateLabel` | ❌ | — | No value to save |

### Multi-Profile
```lua
-- Save current flags to a profile
Window:SaveConfig("Profile1")   -- MyGame/Profile1.json

-- Load flags from a profile
Window:LoadConfig("Profile2")   -- MyGame/Profile2.json

-- Delete a profile
Window:DeleteConfig("Old")

-- Get list of all saved profiles
local profiles = Window:GetConfigList()  -- {"default", "Profile1", "Profile2"}
```

### Auto-Load
Set which config loads on startup:
```lua
-- Write to _autoload.txt manually (or use the "Set Auto Load" button in your UI)
writefile("MyGame/_autoload.txt", "Profile1")
```

On next script execution, `Profile1` loads automatically (0.5s delay after UI init).

### How It Works
1. **Flag** registers the element in `configRegistry`
2. **SaveConfig** collects all `GetValue()` from registered flags → JSONEncode → writefile
3. **LoadConfig** reads file → JSONDecode → calls `SetValue()` on each flag → restores UI state
4. **_autoload.txt** stores the name of the last-used config for auto-load on startup

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
