--== Tool Attributes Modder FINAL (tolerante con texto/0/vacío) ==--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-----------------------------------------------------------
-- GUI
-----------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ToolAttrMod"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0.20, 0, 0.7, 0)
main.Position = UDim2.new(0.4, 0, 0.15, 0)
main.BackgroundColor3 = Color3.fromRGB(25,25,35)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

local top = Instance.new("Frame")
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(15,15,25)
top.BorderSizePixel = 0
top.Parent = main
Instance.new("UICorner", top).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.65,0,1,0)
title.Position = UDim2.new(0,8,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Text = "Tool Attributes"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Parent = top

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0,26,0,26)
minBtn.Position = UDim2.new(1,-54,0,2)
minBtn.BackgroundColor3 = Color3.fromRGB(255,150,80)
minBtn.Text = "-"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextScaled = true
minBtn.TextColor3 = Color3.fromRGB(255,255,255)
minBtn.Parent = top
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0,6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,26,0,26)
closeBtn.Position = UDim2.new(1,-26,0,2)
closeBtn.BackgroundColor3 = Color3.fromRGB(255,80,80)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Parent = top
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-10,1,-40)
content.Position = UDim2.new(0,5,0,35)
content.BackgroundTransparency = 1
content.Parent = main

local toolLabel = Instance.new("TextLabel")
toolLabel.Size = UDim2.new(1,0,0.12,0)
toolLabel.BackgroundColor3 = Color3.fromRGB(40,40,55)
toolLabel.Font = Enum.Font.GothamSemibold
toolLabel.TextScaled = true
toolLabel.Text = "Equip a tool"
toolLabel.TextColor3 = Color3.fromRGB(255,150,150)
toolLabel.Parent = content
Instance.new("UICorner", toolLabel).CornerRadius = UDim.new(0,6)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1,0,0.70,0)
list.Position = UDim2.new(0,0,0.14,0)
list.BackgroundColor3 = Color3.fromRGB(32,32,44)
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.Parent = content
Instance.new("UICorner", list).CornerRadius = UDim.new(0,6)

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,2)
layout.Parent = list

local apply = Instance.new("TextButton")
apply.Size = UDim2.new(1,0,0.12,0)
apply.Position = UDim2.new(0,0,0.86,0)
apply.BackgroundColor3 = Color3.fromRGB(0,170,0)
apply.Font = Enum.Font.GothamBold
apply.TextScaled = true
apply.Text = "APPLY CHANGES"
apply.TextColor3 = Color3.fromRGB(255,255,255)
apply.Parent = content
Instance.new("UICorner", apply).CornerRadius = UDim.new(0,6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,0,0.08,0)
status.Position = UDim2.new(0,0,0.98,0)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextScaled = true
status.Text = "Ready"
status.TextColor3 = Color3.fromRGB(150,255,150)
status.Parent = content

-----------------------------------------------------------
-- Drag
-----------------------------------------------------------
local dragging, dragStart, startPos

top.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

top.InputChanged:Connect(function(i)
    if (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
        and dragging and dragStart then
        local delta = i.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-----------------------------------------------------------
-- Atributos
-----------------------------------------------------------
local currentTool = nil
local attrs = {}   -- {name,value,type}
local pending = {} -- cambios: siempre guardamos el TEXTO para no bool

local function clearList()
    for _,c in ipairs(list:GetChildren()) do
        if c:IsA("Frame") then
            c:Destroy()
        end
    end
end

local function getEquippedTool()
    local char = player.Character
    if not char then return nil end
    for _,child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end
    return nil
end

local function buildUI()
    clearList()
    attrs = {}
    pending = {}

    local tool = getEquippedTool()
    currentTool = tool

    if not tool then
        toolLabel.Text = "Equip a tool"
        toolLabel.TextColor3 = Color3.fromRGB(255,150,150)
        status.Text = "No tool equipped"
        status.TextColor3 = Color3.fromRGB(255,180,150)
        list.CanvasSize = UDim2.new(0,0,0,0)
        return
    end

    toolLabel.Text = "Tool: "..tool.Name
    toolLabel.TextColor3 = Color3.fromRGB(150,255,150)

    local raw = tool:GetAttributes()
    for name,val in pairs(raw) do
        table.insert(attrs,{name=name,value=val,type=typeof(val)})
    end

    table.sort(attrs,function(a,b) return a.name:lower() < b.name:lower() end)

    if #attrs == 0 then
        status.Text = "This tool has no attributes"
        status.TextColor3 = Color3.fromRGB(255,200,150)
        list.CanvasSize = UDim2.new(0,0,0,0)
        return
    end

    status.Text = "Loaded "..#attrs.." attributes"
    status.TextColor3 = Color3.fromRGB(150,255,150)

    for _,info in ipairs(attrs) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-6,0,26)
        row.BackgroundColor3 = Color3.fromRGB(50,50,60)
        row.Parent = list
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,5)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.55,0,1,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextScaled = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = info.name..":"
        nameLabel.TextColor3 = Color3.fromRGB(230,230,255)
        nameLabel.Parent = row

        if info.type == "boolean" then
            -- BOOL: toggle
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.4,0,1,0)
            btn.Position = UDim2.new(0.58,0,0,0)
            btn.BackgroundColor3 = info.value and Color3.fromRGB(0,160,0) or Color3.fromRGB(200,50,50)
            btn.Font = Enum.Font.GothamBold
            btn.TextScaled = true
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.Text = tostring(info.value)
            btn.Parent = row
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

            btn.MouseButton1Click:Connect(function()
                local cur = pending[info.name]
                if cur == nil then cur = info.value end
                cur = not cur
                pending[info.name] = cur
                btn.Text = tostring(cur)
                btn.BackgroundColor3 = cur and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,50,50)
                status.Text = "Edited "..info.name.." (press APPLY)"
                status.TextColor3 = Color3.fromRGB(255,210,120)
            end)
        else
            -- NO BOOL: TextBox; guardamos SIEMPRE el texto
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.4,0,1,0)
            box.Position = UDim2.new(0.58,0,0,0)
            box.BackgroundColor3 = Color3.fromRGB(0,60,120)
            box.Font = Enum.Font.GothamBold
            box.TextScaled = true
            box.TextColor3 = Color3.fromRGB(255,255,255)
            box.Text = tostring(info.value)
            box.ClearTextOnFocus = false
            box.Parent = row
            Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)

            box.FocusLost:Connect(function(enterPressed)
                if not enterPressed then return end
                local txt = box.Text  -- puede ser "0", "", "123", etc.
                pending[info.name] = txt
                status.Text = "Edited "..info.name.." (press APPLY)"
                status.TextColor3 = Color3.fromRGB(255,210,120)
            end)
        end
    end

    list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+4)
end

-----------------------------------------------------------
-- APPLY: conversión final aquí
-----------------------------------------------------------
apply.MouseButton1Click:Connect(function()
    if not currentTool or next(pending) == nil then
        status.Text = "No changes to apply"
        status.TextColor3 = Color3.fromRGB(255,180,150)
        return
    end

    for _,info in ipairs(attrs) do
        local key = info.name
        local new = pending[key]

        if new ~= nil then
            local finalValue

            if info.type == "boolean" then
                finalValue = new  -- ya es bool
            elseif info.type == "number" then
                -- new es texto; "" => 0; "123" => 123; basura => 0
                local txt = tostring(new)
                if txt == "" then
                    finalValue = 0
                else
                    finalValue = tonumber(txt) or 0
                end
            else
                -- string / otros: mantener texto tal cual (incluido vacío)
                finalValue = tostring(new)
            end

            currentTool:SetAttribute(key, finalValue)
        end
    end

    -- re‑equip para que el juego pille cambios
    local t = currentTool
    t.Parent = player.Backpack
    task.wait(0.1)
    t.Parent = player.Character

    status.Text = "Changes applied!"
    status.TextColor3 = Color3.fromRGB(150,255,150)
    pending = {}
end)

-----------------------------------------------------------
-- Minimize / Close
-----------------------------------------------------------
local minimized = false

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(main,TweenInfo.new(0.2),{Size=UDim2.new(0.20,0,0,30)}):Play()
        content.Visible = false
        minBtn.Text = "+"
    else
        TweenService:Create(main,TweenInfo.new(0.2),{Size=UDim2.new(0.20,0,0.7,0)}):Play()
        content.Visible = true
        minBtn.Text = "-"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-----------------------------------------------------------
-- Eventos equip / respawn
-----------------------------------------------------------
local function hookCharacter(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            buildUI()
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            buildUI()
        end
    end)
    buildUI()
end

if player.Character then
    hookCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    hookCharacter(char)
end)

print("Tool Attributes Modder FINAL loaded")
