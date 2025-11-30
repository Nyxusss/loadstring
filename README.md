# AttributeModderSource - Tool Attribute Modder Open Sourced
# NXLibSource – Prison Life Styled UI Library Open Sourced

NXLib is a lightweight Roblox UI library inspired by classic Prison Life aesthetics, designed for script hubs and executors.  
It provides a semi–transparent, draggable window with tabs, notifications, and common controls (buttons, toggles, sliders, dropdowns), plus built‑in scaling and a configurable hotkey.

> PC + mobile friendly. Automatically tweaks layout when running on touch devices.

---

## Features

- Prison Life–style main window (semi‑transparent, draggable).
- Minimize bar + close button with tween animations.
- Tab system for organizing pages (Main, Scripts, Config, etc.).
- Notification system:
  - `Notify` (normal – dark).
  - `NotifySuccess` (green).
  - `NotifyError` (red, centered).
  - `NotifyWarn` (yellow).
- Controls with callbacks:
  - `Button`
  - `Toggle`
  - `Slider`
  - `Dropdown`
- Config API:
  - Global hotkey to show/hide the window.
  - Global UI scale (UIScale).
  - Default notification position.
  - Compact notifications toggle.
- Touch‑aware layout for mobile executors.

---

## Getting Started

### 1. Load NXLib

Put `NXLib.lua` in your executor with the loadstring, then execute it:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Nyxusss/loadstring/refs/heads/main/NXLibSource.lua",true))()
```

### 2. Create a window

local Window = NXLib:CreateWindow("Example")

- The window is draggable, semi‑transparent, and has minimize + close buttons.
- By default, the global toggle hotkey is `RightControl`.

### 3. Create tabs

```lua
local MainTab = Window:CreateTab("Main")
local ScriptsTab = Window:CreateTab("Scripts")
local ConfigTab = Window:CreateTab("Config")
```

Each tab is a container frame; all controls created with NXLib are automatically parented inside the tab you pass.

---

## Controls

All control constructors live on the window object returned by `CreateWindow`.

### Button

```lua
Window:Button(MainTab, "Name", function()
-- your function here
end)
```

Signature:

```lua
Window:Button(tabFrame, text, callback)
```

- `tabFrame`: the tab created by `Window:CreateTab`.
- `text`: button label.
- `callback()`: called when the button is clicked.

---

### Toggle

```lua
local noobToggle = Window:Toggle(MainTab, "print noob is bad", false, function(state)
print("noob is:", state)
end)
```

```lua
noobToggle:Set(true) -- programmatically enable
print(noobToggle:Get()) -- current state (true/false)
```

Signature:

local toggle = Window:Toggle(tabFrame, text, defaultValue, callback)

- `defaultValue`: boolean.
- `callback(state)`: receives the new boolean.

Returned object:

```lua
toggle:Set(boolean)
local current = toggle:Get()
```

---

### Slider

```lua
local wsSlider = Window:Slider(MainTab, "WalkSpeed", 16, 100, 16, function(value)
print("WalkSpeed:", value)
end)
```

```lua
wsSlider:Set(50)
print(wsSlider:Get())
```

- `min`, `max`: numeric range.
- `default`: starting value.
- `callback(value)`: called whenever the slider changes.

Returned object:

```lua
slider:Set(number)
local value = slider:Get()
```

---

### Dropdown (Exanple with Prison Life Teams)

```lua
local teamDrop = Window:Dropdown(MainTab, "Team",
{"Guards", "Inmates", "Criminals"},
"Guards",
function(value)
print("Selected team:", value)
end
)

teamDrop:Set("Inmates")
print(teamDrop:Get())

teamDrop:Refresh({"Guards","Inmates","Criminals","Neutral"})
```

Signature:

```lua
local dropdown = Window:Dropdown(tabFrame, text, items, default, callback)
```

- `items`: array of strings.
- `default`: initial selected value (optional).
- `callback(value)`: receives the selected string.

Returned object:

```lua
dropdown:Set(value)
local v = dropdown:Get()
dropdown:Refresh(newItemsTable)
```

---

## Notifications

NXLib exposes four helpers for quick notifications, plus a generic `Notify` for full control.

### Generic

```lua
NXLib:Notify({
Title = "Info",
Text = "This is a normal notification.",
Type = "Info", -- "Info" / "Success" / "Error" / "Warning" / nil
Position = "TopRight", -- "TopRight","TopLeft","BottomRight","BottomLeft","Center"
Duration = 4, -- seconds
Click = function() end -- optional callback when clicked
})
```

### Shortcuts

```lua
NXLib:NotifySuccess("OK", "Everything worked!") -- green
NXLib:NotifyError("Error", "Something went wrong.") -- red, centered
NXLib:NotifyWarn("Warning", "Check your settings.") -- yellow
```

Color mapping:

- Success → green  
- Error → red  
- Warning → yellow  
- Default/Info → dark semi‑transparent (Prison Life style)

---

## Global Configuration

```lua
-- Change global hotkey to toggle the main window
Window:SetHotkey(Enum.KeyCode.RightControl)

-- Change UI scale (0.6 – 1.6)
Window:SetScale(1.0)

-- Default notification position
Window:SetDefaultNotifPosition("TopRight")

-- Use compact notifications (shorter height)
Window:SetCompactNotifications(true)

-- Check if running on touch device
local isTouch = Window:IsTouchDevice()
```

---

## Basic Example

```lua
local NXLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nyxusss/loadstring/refs/heads/main/NXLibSource.lua",true))()

local Window = NXLib:CreateWindow("NX Hub")
local MainTab = Window:CreateTab("Main")
local Config = Window:CreateTab("Config")

Window:Button(MainTab, "Test Button", function()
NXLib:NotifySuccess("Button", "Clicked!")
end)

Window:Toggle(MainTab, "Godmode", false, function(state)
print("Godmode:", state)
end)

Window:Slider(MainTab, "WalkSpeed", 16, 100, 16, function(value)
print("WalkSpeed:", value)
end)

Window:Dropdown(MainTab, "Team", {"Guards","Inmates"}, "Guards", function(value)
print("Team:", value)
end)

Window:Button(Config, "Change Hotkey", function()
NXLib:NotifyWarn("Hotkey", "Press a key for the toggle.")
local uis = game:GetService("UserInputService")
local conn
conn = uis.InputBegan:Connect(function(input, gp)
if gp then return end
if input.UserInputType == Enum.UserInputType.Keyboard then
Window:SetHotkey(input.KeyCode)
NXLib:NotifySuccess("Hotkey", "Now: "..input.KeyCode.Name)
if conn then conn:Disconnect() end
end
end)
end)

Window:Slider(Config, "UI Scale", 60, 160, 100, function(val)
Window:SetScale(val/100)
end)
```
