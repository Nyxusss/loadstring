local NXLib = {}

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local isTouch          = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local currentHotkey    = Enum.KeyCode.RightControl
local defaultNotifPos  = "TopRight"
local compactNotifs    = false

local THEME = {
    Background  = Color3.fromRGB(10, 10, 10),
    TopBar      = Color3.fromRGB(20, 20, 20),
    SectionBG   = Color3.fromRGB(18, 18, 18),
    ControlBG   = Color3.fromRGB(30, 30, 30),
    TextMain    = Color3.fromRGB(255, 255, 255),
    TextSub     = Color3.fromRGB(200, 200, 200),
    Accent      = Color3.fromRGB(0, 120, 215),
    Shadow      = Color3.fromRGB(0, 0, 0),
    NotifyBG    = Color3.fromRGB(25, 25, 25),
    Success     = Color3.fromRGB(46, 204, 113),
    Error       = Color3.fromRGB(231, 76, 60),
    Warning     = Color3.fromRGB(241, 196, 15),
}

---------------------------------------------------------------------
-- ROOT GUI
---------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NXLib_Root"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game:GetService("CoreGui")

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------
local function new(inst, props)
    local o = Instance.new(inst)
    for k, v in pairs(props) do
        o[k] = v
    end
    return o
end

local function roundify(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 4)
    c.Parent = obj
    return c
end

local function addStroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 60, 60)
    s.Thickness = thickness or 1
    s.Transparency = 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function shadow(parent)
    local s = new("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageTransparency = 0.4,
        ImageColor3 = THEME.Shadow,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10,10,118,118),
        Size = UDim2.fromScale(1,1),
        Position = UDim2.fromScale(0,0),
        ZIndex = parent.ZIndex - 1,
        Parent = parent
    })
    return s
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

---------------------------------------------------------------------
-- NOTIFICATIONS
---------------------------------------------------------------------
local notifyContainers = {}

local function typeToColor(ntype)
    if ntype == "Success" then return THEME.Success end
    if ntype == "Error"   then return THEME.Error   end
    if ntype == "Warning" then return THEME.Warning end
    return THEME.NotifyBG
end

local function getNotifyHolder(pos)
    if notifyContainers[pos] then return notifyContainers[pos] end

    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(0, 320, 0, 240)
    holder.ZIndex = 100

    local layout = Instance.new("UIListLayout")
    layout.Parent = holder
    layout.Padding = UDim.new(0, 8)

    if pos == "TopLeft" then
        holder.AnchorPoint = Vector2.new(0,0)
        holder.Position = UDim2.new(0, 20, 0, 20)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.VerticalAlignment   = Enum.VerticalAlignment.Top
    elseif pos == "TopRight" then
        holder.AnchorPoint = Vector2.new(1,0)
        holder.Position = UDim2.new(1, -20, 0, 20)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment   = Enum.VerticalAlignment.Top
    elseif pos == "BottomLeft" then
        holder.AnchorPoint = Vector2.new(0,1)
        holder.Position = UDim2.new(0, 20, 1, -20)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    elseif pos == "BottomRight" then
        holder.AnchorPoint = Vector2.new(1,1)
        holder.Position = UDim2.new(1, -20, 1, -20)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    else
        holder.AnchorPoint = Vector2.new(0.5,0.5)
        holder.Position = UDim2.new(0.5,0,0.5,0)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    end

    holder.Parent = screenGui
    notifyContainers[pos] = holder
    return holder
end

function NXLib:Notify(opts)
    -- opts = {Title, Text, Duration, Position, Color, Type, Click}
    local title    = opts.Title or "Notification"
    local text     = opts.Text or ""
    local duration = opts.Duration or 4
    local pos      = opts.Position or defaultNotifPos
    local color    = opts.Color or typeToColor(opts.Type)
    local onClick  = opts.Click

    local holder   = getNotifyHolder(pos)
    local height   = compactNotifs and 44 or 60

    local toast = Instance.new("TextButton")
    toast.AutoButtonColor = false
    toast.BackgroundColor3 = color
    toast.BackgroundTransparency = 0.15
    toast.BorderSizePixel = 0
    toast.Size = UDim2.new(1, 0, 0, height)
    toast.Text = ""
    toast.ZIndex = 101
    toast.Parent = holder
    roundify(toast, 4)
    addStroke(toast, Color3.fromRGB(255,255,255), 1)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.Size = UDim2.new(1, -20, 0, 18)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = THEME.TextMain
    titleLabel.ZIndex = 102
    titleLabel.Parent = toast

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.new(0, 10, 0, compactNotifs and 22 or 24)
    textLabel.Size = UDim2.new(1, -20, 0, compactNotifs and 18 or 30)
    textLabel.Font = Enum.Font.Gotham
    textLabel.Text = text
    textLabel.TextWrapped = true
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextColor3 = THEME.TextSub
    textLabel.ZIndex = 102
    textLabel.Parent = toast

    toast.BackgroundTransparency = 1
    titleLabel.TextTransparency   = 1
    textLabel.TextTransparency    = 1

    TweenService:Create(toast,      TweenInfo.new(0.2), {BackgroundTransparency = 0.15}):Play()
    TweenService:Create(titleLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    TweenService:Create(textLabel,  TweenInfo.new(0.2), {TextTransparency = 0}):Play()

    if onClick then
        toast.MouseButton1Click:Connect(onClick)
    end

    task.delay(duration, function()
        pcall(function()
            TweenService:Create(toast,      TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(titleLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            TweenService:Create(textLabel,  TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            task.wait(0.25)
            toast:Destroy()
        end)
    end)
end

function NXLib:NotifySuccess(title, text)
    NXLib:Notify({Title = title, Text = text, Type = "Success"})
end

function NXLib:NotifyError(title, text)
    NXLib:Notify({Title = title, Text = text, Type = "Error", Position = "Center"})
end

function NXLib:NotifyWarn(title, text)
    NXLib:Notify({Title = title, Text = text, Type = "Warning"})
end

---------------------------------------------------------------------
-- MAIN WINDOW + TABS + CONTROLS
---------------------------------------------------------------------
function NXLib:CreateWindow(titleText)
    titleText = titleText or "NXLib Window"

    local baseWidth  = isTouch and 520 or 650
    local baseHeight = isTouch and 300 or 360

    local window = {}

    local mainFrame = new("Frame", {
        Name = "NXLib_Main",
        Parent = screenGui,
        BackgroundColor3 = THEME.Background,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Size = UDim2.new(0, baseWidth, 0, baseHeight),
        Position = UDim2.new(0.5, -baseWidth/2, 0.5, -baseHeight/2),
        ZIndex = 5,
        Visible = true
    })
    roundify(mainFrame, 2)
    addStroke(mainFrame, Color3.fromRGB(70,70,70), 1)
    shadow(mainFrame)

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = isTouch and 1.1 or 1
    uiScale.Parent = mainFrame
    local currentScale = uiScale.Scale

    local function setScale(val)
        currentScale = math.clamp(val, 0.6, 1.6)
        uiScale.Scale = currentScale
    end

    -- anim entrada
    mainFrame.Size = UDim2.new(0, baseWidth * 0.95, 0, baseHeight * 0.95)
    TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, baseWidth, 0, baseHeight)}):Play()

    -- top bar
    local topBar = new("Frame", {
        Parent = mainFrame,
        BackgroundColor3 = THEME.TopBar,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 6
    })

    local title = new("TextLabel", {
        Parent = topBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Font = Enum.Font.GothamBlack,
        Text = titleText,
        TextSize = isTouch and 24 or 26,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = THEME.TextMain,
        ZIndex = 7
    })

    local minimizeButton = new("TextButton", {
        Parent = topBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -70, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "_",
        TextSize = 20,
        TextColor3 = THEME.TextSub,
        ZIndex = 7
    })

    local closeButton = new("TextButton", {
        Parent = topBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -35, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "X",
        TextSize = 20,
        TextColor3 = Color3.fromRGB(220, 80, 80),
        ZIndex = 7
    })

    makeDraggable(mainFrame, topBar)

    local minimized = false
    local originalPos = mainFrame.Position
    local originalSize = mainFrame.Size

    local minimizedFrame = new("TextButton", {
        Parent = screenGui,
        BackgroundColor3 = THEME.TopBar,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 140, 0, 32),
        Position = UDim2.new(0, 20, 1, -52),
        Text = titleText,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = THEME.TextMain,
        Visible = false,
        ZIndex = 4
    })
    roundify(minimizedFrame, 4)
    addStroke(minimizedFrame, Color3.fromRGB(60,60,60), 1)

    local function minimize()
        if minimized then return end
        minimized = true
        originalPos  = mainFrame.Position
        originalSize = mainFrame.Size

        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0, 20, 1, -80), Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
            :Play()
        task.delay(0.21, function()
            mainFrame.Visible = false
            minimizedFrame.Visible = true
        end)
    end

    local function restore()
        if not minimized then return end
        minimized = false
        minimizedFrame.Visible = false
        mainFrame.Visible = true
        mainFrame.BackgroundTransparency = 1
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.Position = UDim2.new(0, 20, 1, -80)

        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = originalPos, Size = originalSize, BackgroundTransparency = 0.25})
            :Play()
    end

    minimizeButton.MouseButton1Click:Connect(minimize)
    minimizedFrame.MouseButton1Click:Connect(restore)
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)

    -- tab bar
    local tabBarHeight = isTouch and 36 or 32
    local tabBar = new("Frame", {
        Parent = mainFrame,
        BackgroundColor3 = THEME.SectionBG,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, tabBarHeight),
        Position = UDim2.new(0, 0, 0, 40),
        ZIndex = 6
    })

    local tabLayout = new("UIListLayout", {
        Parent = tabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4)
    })

    local contentHolder = new("Frame", {
        Parent = mainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -(40 + tabBarHeight)),
        Position = UDim2.new(0, 0, 0, 40 + tabBarHeight),
        ZIndex = 5
    })

    local tabs = {}
    local currentTab

    local function switchTab(name)
        for n, data in pairs(tabs) do
            local active = (n == name)
            data.Button.BackgroundColor3 = active and Color3.fromRGB(35,35,35) or Color3.fromRGB(18,18,18)
            data.Button.TextColor3       = active and THEME.TextMain or THEME.TextSub
            data.Page.Visible            = active
        end
        currentTab = name
    end

    local function createTab(name)
        local btn = new("TextButton", {
            Parent = tabBar,
            BackgroundColor3 = Color3.fromRGB(18,18,18),
            BorderSizePixel = 0,
            Size = UDim2.new(0, isTouch and 110 or 90, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = name,
            TextSize = 14,
            TextColor3 = THEME.TextSub,
            ZIndex = 7
        })

        local page = new("Frame", {
            Parent = contentHolder,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Visible = false
        })

        local layout = new("UIListLayout", {
            Parent = page,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, 6)
        })

        tabs[name] = {Button = btn, Page = page, Layout = layout}

        btn.MouseButton1Click:Connect(function()
            switchTab(name)
        end)

        if not currentTab then
            switchTab(name)
        end

        return page
    end

    -- HOTKEY GLOBAL
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == currentHotkey then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)

    -----------------------------------------------------------------
    -- CONTROL BUILDERS
    -----------------------------------------------------------------

    local function createBaseControl(tabPage, height)
        local frame = new("Frame", {
            Parent = tabPage,
            BackgroundColor3 = THEME.SectionBG,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -20, 0, height),
            ZIndex = 6
        })
        roundify(frame, 4)
        addStroke(frame, Color3.fromRGB(40,40,40), 1)
        frame.Position = UDim2.new(0, 10, 0, 0)
        return frame
    end

    function window:Button(tabPage, text, callback)
        local frame = createBaseControl(tabPage, 36)

        local btn = new("TextButton", {
            Parent = frame,
            BackgroundColor3 = THEME.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 140, 0, 28),
            Position = UDim2.new(0, 10, 0.5, -14),
            Font = Enum.Font.GothamBold,
            Text = text or "Button",
            TextSize = 14,
            TextColor3 = THEME.TextMain,
            ZIndex = 7
        })
        roundify(btn, 3)

        btn.MouseButton1Click:Connect(function()
            if callback then
                task.spawn(callback)
            end
        end)

        return btn
    end

    function window:Toggle(tabPage, text, default, callback)
        local frame = createBaseControl(tabPage, 36)

        local label = new("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            Font = Enum.Font.Gotham,
            Text = text or "Toggle",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = THEME.TextMain,
            ZIndex = 7
        })

        local btn = new("TextButton", {
            Parent = frame,
            BackgroundColor3 = THEME.ControlBG,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 40, 0, 20),
            Position = UDim2.new(1, -50, 0.5, -10),
            Font = Enum.Font.SourceSans,
            Text = "",
            ZIndex = 7
        })
        roundify(btn, 10)

        local fill = new("Frame", {
            Parent = btn,
            BackgroundColor3 = THEME.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0.4, 0, 1, 0),
            ZIndex = 8
        })
        roundify(fill, 10)

        local state = default and true or false
        local function apply()
            if state then
                TweenService:Create(fill, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            else
                TweenService:Create(fill, TweenInfo.new(0.15), {Size = UDim2.new(0.4, 0, 1, 0)}):Play()
            end
        end
        apply()

        btn.MouseButton1Click:Connect(function()
            state = not state
            apply()
            if callback then task.spawn(callback, state) end
        end)

        return {
            Set = function(_, v)
                state = v and true or false
                apply()
                if callback then task.spawn(callback, state) end
            end,
            Get = function() return state end
        }
    end

    function window:Slider(tabPage, text, min, max, default, callback)
        min = min or 0
        max = max or 100
        default = default or min

        local frame = createBaseControl(tabPage, 42)

        local label = new("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -60, 0, 20),
            Font = Enum.Font.Gotham,
            Text = text or "Slider",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = THEME.TextMain,
            ZIndex = 7
        })

        local valueLabel = new("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -50, 0, 0),
            Size = UDim2.new(0, 40, 0, 20),
            Font = Enum.Font.Gotham,
            Text = tostring(default),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = THEME.TextSub,
            ZIndex = 7
        })

        local bar = new("Frame", {
            Parent = frame,
            BackgroundColor3 = THEME.ControlBG,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -20, 0, 6),
            Position = UDim2.new(0, 10, 0, 28),
            ZIndex = 7
        })
        roundify(bar, 3)

        local fill = new("Frame", {
            Parent = bar,
            BackgroundColor3 = THEME.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 8
        })
        roundify(fill, 3)

        local dragging = false
        local current = default

        local function setValueFromX(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel + 0.5)
            current = val
            valueLabel.Text = tostring(val)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            if callback then task.spawn(callback, current) end
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setValueFromX(input.Position.X)
            end
        end)

        bar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                setValueFromX(input.Position.X)
            end
        end)

        -- set default visual
        setValueFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((default - min)/(max-min)))

        return {
            Set = function(_, v)
                v = math.clamp(v, min, max)
                local rel = (v - min)/(max-min)
                current = v
                valueLabel.Text = tostring(v)
                fill.Size = UDim2.new(rel,0,1,0)
                if callback then task.spawn(callback, current) end
            end,
            Get = function() return current end
        }
    end

    function window:Dropdown(tabPage, text, items, default, callback)
        items = items or {}
        local frame = createBaseControl(tabPage, 36)

        local label = new("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0.5, -10, 1, 0),
            Font = Enum.Font.Gotham,
            Text = text or "Dropdown",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = THEME.TextMain,
            ZIndex = 7
        })

        local valueButton = new("TextButton", {
            Parent = frame,
            BackgroundColor3 = THEME.ControlBG,
            BorderSizePixel = 0,
            Size = UDim2.new(0.45, -10, 0, 24),
            Position = UDim2.new(0.55, 0, 0.5, -12),
            Font = Enum.Font.Gotham,
            Text = default or (items[1] or "Select"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = THEME.TextSub,
            ZIndex = 7
        })
        roundify(valueButton, 3)

        local arrow = new("TextLabel", {
            Parent = valueButton,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 16, 1, 0),
            Position = UDim2.new(1, -18, 0, 0),
            Font = Enum.Font.GothamBold,
            Text = "▼",
            TextSize = 12,
            TextColor3 = THEME.TextSub,
            ZIndex = 8
        })

        local listFrame = new("Frame", {
            Parent = frame,
            BackgroundColor3 = THEME.SectionBG,
            BorderSizePixel = 0,
            Size = UDim2.new(0.45, -10, 0, 0),
            Position = UDim2.new(0.55, 0, 1, 2),
            Visible = false,
            ZIndex = 100
        })
        roundify(listFrame, 3)
        addStroke(listFrame, Color3.fromRGB(40,40,40), 1)

        local listLayout = new("UIListLayout", {
            Parent = listFrame,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, 2)
        })

        local function rebuild()
            for _,c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _,name in ipairs(items) do
                local opt = new("TextButton", {
                    Parent = listFrame,
                    BackgroundColor3 = THEME.ControlBG,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -4, 0, 22),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextSize = 13,
                    TextColor3 = THEME.TextMain,
                    ZIndex = 101
                })
                roundify(opt, 2)
                opt.MouseButton1Click:Connect(function()
                    valueButton.Text = name
                    listFrame.Visible = false
                    listFrame.Size = UDim2.new(0.45, -10, 0, 0)
                    if callback then task.spawn(callback, name) end
                end)
            end
            listFrame.Size = UDim2.new(0.45, -10, 0, #items * 24 + 4)
        end

        rebuild()

        valueButton.MouseButton1Click:Connect(function()
            listFrame.Visible = not listFrame.Visible
        end)

        return {
            Set = function(_, v)
                valueButton.Text = v
                if callback then task.spawn(callback, v) end
            end,
            Get = function() return valueButton.Text end,
            Refresh = function(_, newItems)
                items = newItems or {}
                rebuild()
            end
        }
    end

    -----------------------------------------------------------------
    -- API PÚBLICA DEL WINDOW
    -----------------------------------------------------------------
    function window:CreateTab(name)
        return createTab(name)
    end

    function window:SetHotkey(keyCode)
        if typeof(keyCode) == "EnumItem" then currentHotkey = keyCode end
    end

    function window:SetScale(scale)
        setScale(scale)
    end

    function window:SetDefaultNotifPosition(pos)
        defaultNotifPos = pos
    end

    function window:SetCompactNotifications(state)
        compactNotifs = state and true or false
    end

    function window:GetMainFrame()
        return mainFrame
    end

    function window:IsTouchDevice()
        return isTouch
    end

    return window
end

return NXLib
