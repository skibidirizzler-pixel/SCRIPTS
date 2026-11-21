local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TARGET_NAME = "rake"
local PART_NAME = "HumanoidRootPart"
local HOTKEY = Enum.KeyCode.I
local BOX_COLOR = Color3.fromRGB(255, 0, 0)

local enabled = false
local targetPart = nil
local lastSearch = 0

---------------------------------------------------------------- Panel GUI
local panelGui = Instance.new("ScreenGui")
panelGui.Name = "AdminPanel"
panelGui.ResetOnSpawn = false
panelGui.Parent = lp:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(190, 90)
frame.Position = UDim2.new(0, 20, 0.5, -45)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = panelGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundTransparency = 1
title.Text = "Admin Panel"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 30)
button.Position = UDim2.fromOffset(10, 28)
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamMedium
button.TextSize = 13
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = frame
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 18)
status.Position = UDim2.fromOffset(10, 64)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(180, 180, 180)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Target: -"
status.Parent = frame

local function refreshButton()
    button.Text = "Rake ESP [I]: " .. (enabled and "ON" or "OFF")
    button.BackgroundColor3 = enabled and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(150, 45, 45)
end

---------------------------------------------------------------- ESP box (in PlayerGui)
local espGui = Instance.new("ScreenGui")
espGui.Name = "RakeESPGui"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 10
espGui.Parent = lp:WaitForChild("PlayerGui")

local box = Instance.new("Frame")
box.Name = "RakeBox"
box.BackgroundTransparency = 1
box.BorderSizePixel = 0
box.Visible = false
box.Parent = espGui

local stroke = Instance.new("UIStroke")
stroke.Color = BOX_COLOR
stroke.Thickness = 2
stroke.Parent = box

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 16)
label.Position = UDim2.new(0, 0, 0, -18)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0
label.Font = Enum.Font.GothamBold
label.TextSize = 13
label.Parent = box

---------------------------------------------------------------- Helpers
local function findTarget()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower() == TARGET_NAME then
            local part = obj:FindFirstChild(PART_NAME)
            if part and part:IsA("BasePart") then
                return part
            end
        end
    end
    return nil
end

-- Projects the part's 8 corners to a 2D screen rectangle
local function getScreenRect(part)
    local cf, half = part.CFrame, part.Size / 2
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local worldPos = (cf * CFrame.new(half.X * x, half.Y * y, half.Z * z)).Position
                local screenPos = camera:WorldToViewportPoint(worldPos)
                if screenPos.Z <= 0 then
                    return nil -- behind the camera
                end
                minX = math.min(minX, screenPos.X)
                minY = math.min(minY, screenPos.Y)
                maxX = math.max(maxX, screenPos.X)
                maxY = math.max(maxY, screenPos.Y)
            end
        end
    end

    return minX, minY, maxX, maxY
end

local function setEnabled(state)
    enabled = state
    targetPart = nil
    box.Visible = false
    if enabled then
        targetPart = findTarget()
    end
    status.Text = enabled and ("Target: " .. (targetPart and "found" or "NOT found")) or "Target: -"
    refreshButton()
end

---------------------------------------------------------------- Hooks
button.MouseButton1Click:Connect(function()
    setEnabled(not enabled)
end)

UserInputService.InputBegan:Connect(function(input)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == HOTKEY then
        setEnabled(not enabled)
    end
end)

RunService.RenderStepped:Connect(function()
    if not enabled then return end
    camera = workspace.CurrentCamera

    -- Re-search (throttled) if we have no valid target
    if not (targetPart and targetPart:IsDescendantOf(workspace)) then
        targetPart = nil
        if os.clock() - lastSearch > 0.5 then
            lastSearch = os.clock()
            targetPart = findTarget()
        end
        status.Text = "Target: " .. (targetPart and "found" or "NOT found")
    end

    if not targetPart then
        box.Visible = false
        return
    end

    local minX, minY, maxX, maxY = getScreenRect(targetPart)
    if not minX then
        box.Visible = false
        return
    end

    box.Position = UDim2.fromOffset(minX, minY)
    box.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
    box.Visible = true

    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        local dist = (targetPart.Position - myRoot.Position).Magnitude
        label.Text = string.format("Rake | %d studs", dist)
    end
end)

refreshButton()
