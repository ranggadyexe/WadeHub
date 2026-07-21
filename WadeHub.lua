local WadeHub = {}
WadeHub.Version = "1.0.0"

-- Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Security bypass to hide GUI from anti-cheat
local function ProtectGui(gui)
    local success, err = pcall(function()
        if gethui then
            gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        else
            gui.Parent = CoreGui
        end
    end)
    if not success then
        gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Dragging Logic
local function MakeDraggable(topbarObject, object)
    local dragging = false
    local dragInput, mousePos, framePos

    topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            object.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Main Window Creation
function WadeHub:CreateWindow(config)
    -- === ANTI DUPLICATE & CLEANUP ===
    if getgenv and getgenv().WadeHub_Destroy then
        pcall(getgenv().WadeHub_Destroy)
    end

    config = config or {}
    local windowName = config.Name or "Wade Hub"
    local LocalPlayer = game:GetService("Players").LocalPlayer

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WadeHub_UI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ProtectGui(ScreenGui)

    -- Main Floating Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22) -- Dark elegant color
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.Size = UDim2.new(0, 0, 0, 0) -- Start from 0 for pop-in effect (Tween)
    MainFrame.ClipsDescendants = true

    -- Elegant rounded corners
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame
    
    -- Subtle drop shadow for floating effect
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(70, 70, 75)
    UIStroke.Thickness = 1
    UIStroke.Parent = MainFrame

    -- Topbar (Drag Handle)
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Parent = MainFrame
    Topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    Topbar.BackgroundTransparency = 1
    Topbar.BorderSizePixel = 0
    Topbar.Size = UDim2.new(1, 0, 0, 40)

    local Title = Instance.new("TextLabel")
    Title.Parent = Topbar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = windowName
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.TextXAlignment = Enum.TextXAlignment.Center

    -- === WINDOW CONTROL BUTTONS ===
    local normalSize = UDim2.new(0, 600, 0, 400)
    local normalPos = UDim2.new(0.5, -300, 0.5, -200)
    local isFullscreen = false
    local isMinimized = false
    local allConnections = {} -- Cleanup on close

    -- Register global destroy function
    if getgenv then
        getgenv().WadeHub_Destroy = function()
            if config.OnClose then pcall(config.OnClose) end
            for _, conn in ipairs(allConnections) do
                pcall(function() conn:Disconnect() end)
            end
            if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
            getgenv().WadeHub_Destroy = nil
        end
    end

    -- Helper: small round control button
    local function createControlDot(parent, color, posOffset)
        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.BackgroundColor3 = color
        btn.Size = UDim2.new(0, 12, 0, 12)
        btn.Position = UDim2.new(0, posOffset, 0.5, -6)
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn
        return btn
    end

    -- Top-left corner (Mac OS style)
    local CloseBtn = createControlDot(Topbar, Color3.fromRGB(255, 95, 86), 15)
    local MinimizeBtn = createControlDot(Topbar, Color3.fromRGB(255, 189, 46), 35)
    local FullscreenBtn = createControlDot(Topbar, Color3.fromRGB(39, 201, 63), 55)

    local iconId = config.Icon or "rbxassetid://78533790239403"

    -- === MINIMIZE ICON ===
    local MinimizeIcon
    if iconId then
        MinimizeIcon = Instance.new("ImageButton")
        MinimizeIcon.Image = iconId
        MinimizeIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
        MinimizeIcon.BackgroundTransparency = 0 -- Give background if image is transparent
    else
        MinimizeIcon = Instance.new("TextButton")
        MinimizeIcon.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
        MinimizeIcon.Text = ""

        local MinIconStroke = Instance.new("UIStroke")
        MinIconStroke.Color = Color3.fromRGB(0, 130, 210)
        MinIconStroke.Thickness = 2
        MinIconStroke.Parent = MinimizeIcon

        local MinIconLabel = Instance.new("TextLabel")
        MinIconLabel.Parent = MinimizeIcon
        MinIconLabel.BackgroundTransparency = 1
        MinIconLabel.Size = UDim2.new(1, 0, 1, 0)
        MinIconLabel.Font = Enum.Font.GothamBold
        MinIconLabel.Text = "W"
        MinIconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        MinIconLabel.TextSize = 18
    end

    MinimizeIcon.Name = "WadeHub_MinIcon"
    MinimizeIcon.Parent = ScreenGui
    MinimizeIcon.Size = UDim2.new(0, 40, 0, 40)
    MinimizeIcon.Position = UDim2.new(0, 20, 1, -60)
    MinimizeIcon.AutoButtonColor = false
    MinimizeIcon.BorderSizePixel = 0
    MinimizeIcon.Visible = true

    local MinIconCorner = Instance.new("UICorner")
    MinIconCorner.CornerRadius = UDim.new(1, 0)
    MinIconCorner.Parent = MinimizeIcon

    MakeDraggable(MinimizeIcon, MinimizeIcon)

    -- Minimize / Restore Logic
    local savedMainPos = normalPos
    local savedMainSize = normalSize

    local function doMinimize()
        if isMinimized then return end
        isMinimized = true
        savedMainPos = MainFrame.Position
        savedMainSize = MainFrame.Size
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = MinimizeIcon.Position + UDim2.new(0, 10, 0, 10)
        }):Play()
        task.wait(0.4)
        MainFrame.Visible = false
    end

    local function doRestore()
        if not isMinimized then return end
        isMinimized = false
        MainFrame.Visible = true
        local targetSize = isFullscreen and UDim2.new(1, -20, 1, -20) or savedMainSize
        local targetPos = isFullscreen and UDim2.new(0, 10, 0, 10) or savedMainPos

        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = MinimizeIcon.Position + UDim2.new(0, 10, 0, 10)

        TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = targetSize,
            Position = targetPos
        }):Play()
    end

    MinimizeBtn.MouseButton1Click:Connect(doMinimize)
    MinimizeIcon.MouseButton1Click:Connect(function()
        if isMinimized then doRestore() else doMinimize() end
    end)

    -- Fullscreen Logic
    FullscreenBtn.MouseButton1Click:Connect(function()
        isFullscreen = not isFullscreen
        if isFullscreen then
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, -20, 1, -20),
                Position = UDim2.new(0, 10, 0, 10)
            }):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = normalSize,
                Position = normalPos
            }):Play()
        end
    end)

    -- === ICONS ===
    local _icons = nil
    local _iconsLoaded = false

    local function GetIcons()
        if _iconsLoaded then return _icons end
        _iconsLoaded = true
        pcall(function()
            local source = game:HttpGet(
                "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"
            )
            local loader = loadstring(source)
            local data = loader()
            if type(data) == "table" and data["48px"] then
                _icons = data["48px"]
            end
        end)
        return _icons
    end

    local function CreateIcon(parent, iconKey, size, position)
        local icons = GetIcons()
        if not icons or not icons[iconKey] then return nil end
        local data = icons[iconKey]
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Image = "rbxassetid://" .. data[1]
        img.ImageRectSize = Vector2.new(data[2][1], data[2][2])
        img.ImageRectOffset = Vector2.new(data[3][1], data[3][2])
        img.Size = size or UDim2.new(0, 16, 0, 16)
        if position then img.Position = position end
        img.Parent = parent
        return img
    end

    -- === DIALOG SYSTEM (macOS Style) ===
    local isDialogOpen = false

    local function createDialog(opts)
        if isDialogOpen then return end
        isDialogOpen = true

        local dTitle = opts.Title or "Dialog"
        local dContent = opts.Content or ""
        local dIcon = opts.Icon
        local buttons = opts.Buttons or {}
        if opts.Type == "Info" then
            buttons = {{Name = "OK", Kind = "primary"}}
        elseif opts.Type == "Confirm" or #buttons == 0 then
            buttons = {
                {Name = "Cancel", Kind = "cancel"},
                {Name = "OK", Kind = "primary"},
            }
        end
        if opts.OnCancel == nil then opts.OnCancel = function() end end

        local Overlay = Instance.new("TextButton")
        Overlay.Text = ""
        Overlay.Parent = ScreenGui
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 1
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.ZIndex = 100

        TweenService:Create(Overlay, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()

        local Card = Instance.new("Frame")
        Card.Parent = Overlay
        Card.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
        Card.BackgroundTransparency = 0.1
        Card.BorderSizePixel = 0
        Card.Size = UDim2.new(0, 300, 0, 0)
        Card.Position = UDim2.new(0.5, 0, 0.5, 0)
        Card.AnchorPoint = Vector2.new(0.5, 0.5)
        Card.ZIndex = 101

        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 14)
        CardCorner.Parent = Card

        local CardStroke = Instance.new("UIStroke")
        CardStroke.Color = Color3.fromRGB(80, 80, 85)
        CardStroke.Thickness = 0.5
        CardStroke.Transparency = 0.4
        CardStroke.Parent = Card

        TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, 165)
        }):Play()

        local yOffset = 20
        if dIcon then
            local IconFrame = Instance.new("Frame")
            IconFrame.Parent = Card
            IconFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
            IconFrame.BackgroundTransparency = 0.3
            IconFrame.Position = UDim2.new(0.5, -20, 0, yOffset)
            IconFrame.Size = UDim2.new(0, 40, 0, 40)
            IconFrame.ZIndex = 102
            local IconCorner = Instance.new("UICorner")
            IconCorner.CornerRadius = UDim.new(0, 10)
            IconCorner.Parent = IconFrame
            CreateIcon(IconFrame, dIcon, UDim2.new(0, 22, 0, 22), UDim2.new(0.5, -11, 0.5, -11))
            yOffset = yOffset + 50
        end

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Parent = Card
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Position = UDim2.new(0, 20, 0, yOffset)
        TitleLbl.Size = UDim2.new(1, -40, 0, 22)
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.Text = dTitle
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextSize = 15
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Center
        TitleLbl.ZIndex = 102

        local ContentLbl
        if dContent ~= "" then
            ContentLbl = Instance.new("TextLabel")
            ContentLbl.Parent = Card
            ContentLbl.BackgroundTransparency = 1
            ContentLbl.Position = UDim2.new(0, 20, 0, yOffset + 22)
            ContentLbl.Size = UDim2.new(1, -40, 0, 18)
            ContentLbl.Font = Enum.Font.Gotham
            ContentLbl.Text = dContent
            ContentLbl.TextColor3 = Color3.fromRGB(160, 160, 165)
            ContentLbl.TextSize = 12
            ContentLbl.TextXAlignment = Enum.TextXAlignment.Center
            ContentLbl.ZIndex = 102
        end

        local function dismissDialog()
            isDialogOpen = false
            TweenService:Create(Card, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 300, 0, 0)}):Play()
            TweenService:Create(Overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            task.wait(0.25)
            Overlay:Destroy()
        end

        Overlay.MouseButton1Click:Connect(function()
            dismissDialog()
            opts.OnCancel()
        end)

        -- Build buttons
        local num = #buttons
        local btnW = num <= 2 and 115 or math.floor((300 - (num+1) * 10) / num)
        local totalW = num * btnW + (num - 1) * 10
        local startX = (300 - totalW) / 2

        for i, btn in ipairs(buttons) do
            local bg = Color3.fromRGB(70, 70, 75)
            local txt = Color3.fromRGB(210, 210, 215)
            if btn.Kind == "primary" then
                bg = Color3.fromRGB(10, 132, 255)
                txt = Color3.fromRGB(255, 255, 255)
            end
            local btnX = startX + (i - 1) * (btnW + 10)

            local Btn = Instance.new("TextButton")
            Btn.Parent = Card
            Btn.BackgroundColor3 = bg
            Btn.BorderSizePixel = 0
            Btn.Position = UDim2.new(0, btnX, 1, -45)
            Btn.Size = UDim2.new(0, btnW, 0, 32)
            Btn.Font = Enum.Font.GothamMedium
            Btn.Text = btn.Name or "Button"
            Btn.TextColor3 = txt
            Btn.TextSize = 13
            Btn.AutoButtonColor = false
            Btn.ZIndex = 102
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 8)
            BtnCorner.Parent = Btn

            if btn.Kind ~= "primary" then
                Btn.MouseEnter:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(85, 85, 90)}):Play()
                end)
                Btn.MouseLeave:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = bg}):Play()
                end)
            end

            Btn.MouseButton1Click:Connect(function()
                dismissDialog()
                if btn.Callback then
                    pcall(btn.Callback)
                else
                    opts.OnCancel()
                end
            end)
        end
    end

    local function showCloseDialog()
        createDialog({
            Title = "Quit Wade Hub?",
            Content = "All scripts will be stopped.",
            Icon = "log-out",
            Buttons = {
                {Name = "Cancel", Kind = "cancel"},
                {Name = "Quit", Kind = "primary", Callback = function()
                    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
                    task.wait(0.4)
                    if getgenv and getgenv().WadeHub_Destroy then
                        pcall(getgenv().WadeHub_Destroy)
                    else
                        if config.OnClose then pcall(config.OnClose) end
                        for _, conn in ipairs(allConnections) do
                            pcall(function() conn:Disconnect() end)
                        end
                        ScreenGui:Destroy()
                    end
                end},
            },
        })
    end

    CloseBtn.MouseButton1Click:Connect(function()
        showCloseDialog()
    end)

    MakeDraggable(Topbar, MainFrame)

    -- Window Open Animation
    local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 600, 0, 400)
    })
    openTween:Play()

    -- Sidebar Container
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = MainFrame
    Sidebar.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    Sidebar.BorderSizePixel = 0
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.Size = UDim2.new(0, 150, 1, -40)

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 12)
    SidebarCorner.Parent = Sidebar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Parent = Sidebar
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.Size = UDim2.new(1, 0, 1, -60)
    TabContainer.ScrollBarThickness = 0

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Parent = TabContainer
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Padding = UDim.new(0, 5)

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.Parent = Sidebar
    SidebarPadding.PaddingTop = UDim.new(0, 10)
    SidebarPadding.PaddingLeft = UDim.new(0, 10)
    SidebarPadding.PaddingRight = UDim.new(0, 10)
    SidebarPadding.PaddingBottom = UDim.new(0, 10)

    -- Sidebar Footer (avatar + username)
    local SidebarFooter = Instance.new("Frame")
    SidebarFooter.Parent = Sidebar
    SidebarFooter.BackgroundTransparency = 1
    SidebarFooter.Position = UDim2.new(0, 0, 1, -55)
    SidebarFooter.Size = UDim2.new(1, 0, 0, 45)

    local FooterLine = Instance.new("Frame")
    FooterLine.Parent = SidebarFooter
    FooterLine.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    FooterLine.BorderSizePixel = 0
    FooterLine.Size = UDim2.new(1, -16, 0, 1)
    FooterLine.Position = UDim2.new(0, 8, 0, 0)

    local AvatarFrame = Instance.new("ImageLabel")
    AvatarFrame.Name = "Avatar"
    AvatarFrame.Parent = SidebarFooter
    AvatarFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    AvatarFrame.Position = UDim2.new(0, 8, 0.5, -14)
    AvatarFrame.Size = UDim2.new(0, 28, 0, 28)
    AvatarFrame.ZIndex = 2
    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = AvatarFrame

    local UserNameLabel = Instance.new("TextLabel")
    UserNameLabel.Parent = SidebarFooter
    UserNameLabel.BackgroundTransparency = 1
    UserNameLabel.Position = UDim2.new(0, 44, 0, 0)
    UserNameLabel.Size = UDim2.new(1, -50, 1, 0)
    UserNameLabel.Font = Enum.Font.GothamSemibold
    UserNameLabel.Text = LocalPlayer.Name
    UserNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    UserNameLabel.TextSize = 15
    UserNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserNameLabel.TextYAlignment = Enum.TextYAlignment.Center

    task.spawn(function()
        pcall(function()
            local userId = LocalPlayer.UserId
            local Players = game:GetService("Players")
            local thumbType = Enum.ThumbnailType.HeadShot
            local thumbSize = Enum.ThumbnailSize.Size100x100
            local content, ready = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
            AvatarFrame.Image = content
        end)
    end)

    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Parent = MainFrame
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 160, 0, 40)
    ContentContainer.Size = UDim2.new(1, -170, 1, -50)

    -- === NOTIFICATION CONTAINER ===
    local NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "NotificationContainer"
    NotificationContainer.Parent = ScreenGui
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.Position = UDim2.new(1, -240, 0, 10)
    NotificationContainer.Size = UDim2.new(0, 230, 1, 0)

    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.Parent = NotificationContainer
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    NotifLayout.Padding = UDim.new(0, 6)

    local WindowElements = {}
    local currentActiveTab = nil
    local configRegistry = {}
    local _isLoading = false

    local cfg = config.Configuration or {}
    cfg.Enabled = cfg.Enabled ~= false
    cfg.AutoSave = cfg.AutoSave or false
    cfg.AutoLoad = cfg.AutoLoad or false
    cfg.AutoLoadDelay = cfg.AutoLoadDelay or 0.5
    cfg.FolderName = cfg.FolderName or "WadeHub"
    cfg.OnConfigLoaded = cfg.OnConfigLoaded or nil

    local HttpService = game:GetService("HttpService")
    local currentConfigName = "default"

    local function sanitizeProfileName(name)
        local cleaned = string.gsub(tostring(name or ""), "[^%w_%-]", "")
        if cleaned == "" then return nil end
        return cleaned
    end

    local function initFolder()
        if makefolder and not isfolder(cfg.FolderName) then
            makefolder(cfg.FolderName)
        end
    end

    local function cfgPath(name)
        return cfg.FolderName .. "/" .. (name or currentConfigName) .. ".json"
    end

    local function autoloadPath()
        return cfg.FolderName .. "/_autoload.txt"
    end

    local _saveGeneration = 0

    local function saveConfig(name)
        if not cfg.Enabled or not writefile then return false end
        local n
        if name then
            n = sanitizeProfileName(name)
        else
            local autoName = currentConfigName
            if isfile and isfile(autoloadPath()) then
                local ok, raw = pcall(function() return readfile(autoloadPath()) end)
                if ok and raw and raw ~= "" then
                    local cleaned = sanitizeProfileName(raw)
                    if cleaned then autoName = cleaned end
                end
            end
            n = sanitizeProfileName(autoName)
        end
        if not n then return false end
        local data = {}
        for flag, item in pairs(configRegistry) do
            if item.GetValue and flag ~= "cfg_select" then
                data[flag] = item.GetValue()
            end
        end
        data["cfg_select"] = n
        initFolder()
        local json = HttpService:JSONEncode(data)
        local actualPath = cfgPath(n)
        local tmpPath = cfgPath(n .. "_tmp")
        local ok, err = pcall(function() writefile(tmpPath, json) end)
        if not ok then
            pcall(function() if delfile then delfile(tmpPath) end end)
            return false
        end
        if movefile then
            ok, err = pcall(function() movefile(tmpPath, actualPath) end)
            if not ok then
                pcall(function() if delfile then delfile(tmpPath) end end)
                return false
            end
        else
            ok, err = pcall(function() writefile(actualPath, json) end)
            if not ok then
                return false
            end
            pcall(function() if delfile then delfile(tmpPath) end end)
        end
        pcall(function() writefile(autoloadPath(), n) end)
        return true
    end

    local function RequestSave()
        if _isLoading or not cfg.AutoSave then return end
        _saveGeneration = _saveGeneration + 1
        local gen = _saveGeneration
        task.delay(0.3, function()
            if _saveGeneration ~= gen then return end
            saveConfig()
        end)
    end

    local function loadConfig(name)
        if not cfg.Enabled or not readfile or not isfile then return false end
        local n = sanitizeProfileName(name or currentConfigName)
        if not n then return false end
        local path = cfgPath(n)
        local tmpPath = cfgPath(n .. "_tmp")
        local selectedPath = nil
        local parsed = nil
        if isfile(path) then
            local ok, raw = pcall(function() return readfile(path) end)
            local ok2
            if ok then
                ok2, parsed = pcall(function() return HttpService:JSONDecode(raw) end)
            end
            if ok and ok2 then
                selectedPath = path
            else
                warn("WadeHub: Failed to load config: " .. path)
            end
        end
        if not selectedPath and isfile(tmpPath) then
            local ok, raw = pcall(function() return readfile(tmpPath) end)
            local ok2 = false
            if ok then
                ok2, parsed = pcall(function() return HttpService:JSONDecode(raw) end)
            end
            if ok and ok2 then
                selectedPath = tmpPath
                warn("WadeHub: Recovered config from tmp backup for '" .. n .. "'")
            end
        end
        if not selectedPath then
            if isfile(path) or isfile(tmpPath) then
                warn("WadeHub: Both config and tmp backup are corrupt for '" .. n .. "'")
            end
            return false
        end
        _isLoading = true
        for flag, val in pairs(parsed) do
            local item = configRegistry[flag]
            if item and item.SetValue then
                local valType = type(val)
                local expectedType = item.Type
                if valType == expectedType then
                    item.SetValue(val)
                else
                    warn("WadeHub: Type mismatch for flag '" .. flag .. "' — expected " .. tostring(expectedType) .. ", got " .. valType .. ". Skipping.")
                    if item.Default ~= nil then
                        item.SetValue(item.Default)
                    end
                end
            end
        end
        for flag, item in pairs(configRegistry) do
            if flag ~= "cfg_select" and parsed[flag] == nil and item.Default ~= nil then
                item.SetValue(item.Default)
            end
        end
        if configRegistry["cfg_select"] then
            configRegistry["cfg_select"].SetValue(n)
        end
        _isLoading = false
        currentConfigName = n
        if type(cfg.OnConfigLoaded) == "function" then
            task.defer(function() pcall(cfg.OnConfigLoaded, n) end)
        end
        return true
    end

    local function deleteConfig(name)
        if not cfg.Enabled or not delfile then return false end
        local n = sanitizeProfileName(name or currentConfigName)
        if not n then return false end
        local path = cfgPath(n)
        if isfile and isfile(path) then delfile(path) end
        if currentConfigName == n then
            currentConfigName = "default"
        end
        return true
    end

    local function getConfigList()
        local list = {}
        if not cfg.Enabled or not listfiles or not isfolder then
            table.insert(list, "default")
            return list
        end
        initFolder()
        if isfolder(cfg.FolderName) then
            for _, file in ipairs(listfiles(cfg.FolderName)) do
                local name = file:match("([^/\\]+)%.json$")
                if name and name ~= "_autoload" and not string.find(name, "_tmp$") then
                    table.insert(list, name)
                end
            end
        end
        if #list == 0 then table.insert(list, "default") end
        return list
    end

    local function RegisterFlag(flag, item)
        configRegistry[flag] = item
    end

    function WindowElements:SaveConfig(name)
        local displayName = name or currentConfigName
        local success = saveConfig(name)
        if success then
            self:Notify({Title = "Config", Content = "Saved: " .. displayName, Duration = 2})
        else
            self:Notify({Title = "Config Error", Content = "Failed to save: " .. displayName, Duration = 3})
        end
        return success
    end

    function WindowElements:LoadConfig(name)
        local displayName = name or currentConfigName
        local success = loadConfig(name)
        if success then
            self:Notify({Title = "Config", Content = "Loaded: " .. displayName, Duration = 2})
        else
            self:Notify({Title = "Config Error", Content = "Failed to load: " .. displayName, Duration = 3})
        end
        return success
    end

    function WindowElements:DeleteConfig(name)
        local displayName = name or currentConfigName
        local success = deleteConfig(name)
        if success then
            self:Notify({Title = "Config", Content = "Deleted: " .. displayName, Duration = 2})
        else
            self:Notify({Title = "Config Error", Content = "Failed to delete: " .. displayName, Duration = 3})
        end
        return success
    end

    function WindowElements:GetConfigList()
        return getConfigList()
    end

    function WindowElements:GetCurrentConfig()
        return currentConfigName
    end

    function WindowElements:SetAutoLoad(name)
        local n = sanitizeProfileName(name)
        if not n then
            self:Notify({Title = "Config Error", Content = "Invalid name for auto-load: " .. tostring(name), Duration = 3})
            return false
        end
        initFolder()
        pcall(function() writefile(autoloadPath(), n) end)
        self:Notify({Title = "Auto Load", Content = "Set to: " .. n, Duration = 2})
        return true
    end

    function WindowElements:AutoLoadConfig()
        local name = "default"
        if isfile and isfile(autoloadPath()) then
            pcall(function()
                local n = readfile(autoloadPath())
                if n and n ~= "" then
                    local cleaned = sanitizeProfileName(n)
                    if cleaned then name = cleaned end
                end
            end)
        end
        loadConfig(name)
    end

    function WindowElements:Dialog(options)
        createDialog(options)
    end

    function WindowElements:Notify(config)
        local title = config.Title or "Notification"
        local content = config.Content or "This is a notification."
        local duration = config.Duration or 3

        local NotifWrapper = Instance.new("Frame")
        NotifWrapper.Name = "NotifWrapper"
        NotifWrapper.Parent = NotificationContainer
        NotifWrapper.BackgroundTransparency = 1
        NotifWrapper.Size = UDim2.new(1, 0, 0, 56)
        NotifWrapper.ClipsDescendants = true

        local NotifFrame = Instance.new("Frame")
        NotifFrame.Name = "NotifFrame"
        NotifFrame.Parent = NotifWrapper
        NotifFrame.BackgroundColor3 = Color3.fromRGB(44, 44, 46)
        NotifFrame.BackgroundTransparency = 0.3
        NotifFrame.BorderSizePixel = 0
        NotifFrame.Size = UDim2.new(1, 0, 0, 56)
        NotifFrame.Position = UDim2.new(1, 10, 0, 0)
        NotifFrame.ClipsDescendants = true

        local NotifCorner = Instance.new("UICorner")
        NotifCorner.CornerRadius = UDim.new(0, 12)
        NotifCorner.Parent = NotifFrame

        local NotifStroke = Instance.new("UIStroke")
        NotifStroke.Color = Color3.fromRGB(65, 65, 68)
        NotifStroke.Thickness = 0.5
        NotifStroke.Transparency = 0.3
        NotifStroke.Parent = NotifFrame

        local IconBg = Instance.new("Frame")
        IconBg.Parent = NotifFrame
        IconBg.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
        IconBg.BackgroundTransparency = 1
        IconBg.Position = UDim2.new(0, 10, 0.5, -12)
        IconBg.Size = UDim2.new(0, 24, 0, 24)
        IconBg.ZIndex = 2
        local IconBgCorner = Instance.new("UICorner")
        IconBgCorner.CornerRadius = UDim.new(0, 6)
        IconBgCorner.Parent = IconBg

        CreateIcon(IconBg, "bell", UDim2.new(0, 14, 0, 14), UDim2.new(0.5, -7, 0.5, -7))

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Parent = NotifFrame
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Position = UDim2.new(0, 44, 0.5, -14)
        TitleLbl.Size = UDim2.new(1, -75, 0, 18)
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.Text = title
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextSize = 15
        TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.TextYAlignment = Enum.TextYAlignment.Center
        TitleLbl.ZIndex = 2

        local ContentLbl = Instance.new("TextLabel")
        ContentLbl.Parent = NotifFrame
        ContentLbl.BackgroundTransparency = 1
        ContentLbl.Position = UDim2.new(0, 44, 0.5, 6)
        ContentLbl.Size = UDim2.new(1, -55, 0, 14)
        ContentLbl.Font = Enum.Font.Gotham
        ContentLbl.Text = content
        ContentLbl.TextColor3 = Color3.fromRGB(160, 160, 165)
        ContentLbl.TextSize = 12
        ContentLbl.TextTruncate = Enum.TextTruncate.AtEnd
        ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
        ContentLbl.TextYAlignment = Enum.TextYAlignment.Center
        ContentLbl.ZIndex = 2

        local TimeStamp = Instance.new("TextLabel")
        TimeStamp.Parent = NotifFrame
        TimeStamp.BackgroundTransparency = 1
        TimeStamp.Position = UDim2.new(1, -32, 0.5, -14)
        TimeStamp.Size = UDim2.new(0, 28, 0, 14)
        TimeStamp.Font = Enum.Font.Gotham
        TimeStamp.Text = "now"
        TimeStamp.TextColor3 = Color3.fromRGB(100, 100, 105)
        TimeStamp.TextSize = 9
        TimeStamp.TextXAlignment = Enum.TextXAlignment.Right
        TimeStamp.ZIndex = 2

        TweenService:Create(NotifFrame, TweenInfo.new(0.85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        task.delay(duration, function()
            TweenService:Create(NotifFrame, TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 350, 0, 0)
            }):Play()
            task.wait(0.75)
            NotifWrapper:Destroy()
        end)
    end

    function WindowElements:CreateTab(config)
        local tabName, tabIcon
        if type(config) == "table" then
            tabName = config.Name or "Tab"
            tabIcon = config.Icon
        else
            tabName = config
        end

        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName .. "_Button"
        TabButton.Parent = TabContainer
        TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 0, 35)
        TabButton.Font = Enum.Font.GothamBold
        TabButton.Text = "      " .. tabName
        TabButton.TextColor3 = Color3.fromRGB(180, 180, 185)
        TabButton.TextSize = 14
        TabButton.TextTruncate = Enum.TextTruncate.AtEnd
        TabButton.AutoButtonColor = false

        if tabIcon then
            local tabIconImg = CreateIcon(TabButton, tabIcon, UDim2.new(0, 18, 0, 18), UDim2.new(0, 8, 0.5, -9))
            -- fallback: use circle icon if tab icon unavailable
            if not tabIconImg then
                tabIconImg = CreateIcon(TabButton, "circle", UDim2.new(0, 18, 0, 18), UDim2.new(0, 8, 0.5, -9))
            end
        end

        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 6)
        ButtonCorner.Parent = TabButton

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "_Content"
        TabContent.Parent = ContentContainer
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.ScrollBarThickness = 2
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.ScrollingDirection = Enum.ScrollingDirection.Y
        TabContent.Visible = false

        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Parent = TabContent
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 8)

        local function updateCanvas()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
        end
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.Parent = TabContent
        ContentPadding.PaddingTop = UDim.new(0, 5)
        ContentPadding.PaddingBottom = UDim.new(0, 0)

        -- Tab Switch Logic
        TabButton.MouseButton1Click:Connect(function()
            if currentActiveTab and currentActiveTab.Content == TabContent then return end

            if currentActiveTab then
                TweenService:Create(currentActiveTab.Button, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 48), TextColor3 = Color3.fromRGB(180, 180, 185)}):Play()
                currentActiveTab.Content.Visible = false
            end

            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50, 50, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            
            -- Smooth Slide-in Transition
            TabContent.Visible = true
            TabContent.Position = UDim2.new(0, 0, 0, 15)
            TweenService:Create(TabContent, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
            
            currentActiveTab = {Button = TabButton, Content = TabContent}
        end)

        -- Auto-select first tab
        if not currentActiveTab then
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            TabContent.Visible = true
            currentActiveTab = {Button = TabButton, Content = TabContent}
        end

        local TabElements = {}

                function TabElements:CreateSection(config)
            local sectionName = type(config) == "table" and config.Name or config
            local defaultOpen = true
            if type(config) == "table" and config.Default ~= nil then
                defaultOpen = config.Default
            end

            local SectionBtn = Instance.new("TextButton")
            SectionBtn.Name = "SectionBtn"
            SectionBtn.Parent = TabContent
            SectionBtn.BackgroundTransparency = 1
            SectionBtn.Size = UDim2.new(1, 0, 0, 30)
            SectionBtn.Text = ""

            local Title = Instance.new("TextLabel")
            Title.Parent = SectionBtn
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 20, 0, 0)
            Title.Size = UDim2.new(1, -25, 1, 0)
            Title.Font = Enum.Font.GothamBold
            Title.Text = sectionName
            Title.TextColor3 = Color3.fromRGB(10, 132, 255)
            Title.TextSize = 12
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Arrow = CreateIcon(SectionBtn, "chevron-down", UDim2.new(0, 14, 0, 14), UDim2.new(0, 0, 0.5, -7))

            -- Switch icon on collapse/expand
            local sectionIcon = "chevron-down"
            local isOpen = defaultOpen
            if not isOpen then
                if Arrow then Arrow:Destroy() end
                Arrow = CreateIcon(SectionBtn, "chevron-right", UDim2.new(0, 14, 0, 14), UDim2.new(0, 0, 0.5, -7))
                sectionIcon = "chevron-right"
            end

            local Line = Instance.new("Frame")
            Line.Parent = SectionBtn
            Line.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
            Line.BorderSizePixel = 0
            Line.Position = UDim2.new(0, 5, 1, -5)
            Line.Size = UDim2.new(1, -10, 0, 1)

            local SectionContainer = Instance.new("Frame")
            SectionContainer.Name = "SectionContainer"
            SectionContainer.Parent = TabContent
            SectionContainer.BackgroundTransparency = 1
            SectionContainer.Size = UDim2.new(1, 0, 0, 0)
            SectionContainer.AutomaticSize = Enum.AutomaticSize.Y
            SectionContainer.ClipsDescendants = true
            SectionContainer.Visible = defaultOpen

            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.Parent = SectionContainer
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Padding = UDim.new(0, 8)

            TabElements.CurrentSectionContainer = SectionContainer

            SectionBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                SectionContainer.Visible = isOpen
                if Arrow then Arrow:Destroy() end
                if isOpen then
                    Arrow = CreateIcon(SectionBtn, "chevron-down", UDim2.new(0, 14, 0, 14), UDim2.new(0, 0, 0.5, -7))
                else
                    Arrow = CreateIcon(SectionBtn, "chevron-right", UDim2.new(0, 14, 0, 14), UDim2.new(0, 0, 0.5, -7))
                end
            end)
        end

        -- Base Elements
        function TabElements:CreateButton(config)
            local btnName = config.Name or "Button"
            local callback = config.Callback or function() end

            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Name = "ButtonFrame"
            ButtonFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            ButtonFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            ButtonFrame.BorderSizePixel = 0
            ButtonFrame.Size = UDim2.new(1, 0, 0, 40)

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = ButtonFrame

            local RealButton = Instance.new("TextButton")
            RealButton.Parent = ButtonFrame
            RealButton.BackgroundTransparency = 1
            RealButton.Size = UDim2.new(1, 0, 1, 0)
            RealButton.Font = Enum.Font.GothamSemibold
            RealButton.Text = btnName
            RealButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            RealButton.TextSize = 14
            RealButton.TextTruncate = Enum.TextTruncate.AtEnd

            -- Click effect (animation)
            RealButton.MouseButton1Click:Connect(function()
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
                task.wait(0.1)
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundColor3 = Color3.fromRGB(45, 45, 48)}):Play()
                callback()
            end)
        end

        function TabElements:CreateLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Parent = TabElements.CurrentSectionContainer or TabContent
            Label.BackgroundTransparency = 1
            Label.Size = UDim2.new(1, 0, 0, 30)
            Label.Font = Enum.Font.Gotham
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(210, 210, 215)
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
        end

        function TabElements:CreateParagraph(config)
            local title = config.Title or "Paragraph"
            local content = config.Content or ""

            local ParagraphFrame = Instance.new("Frame")
            ParagraphFrame.Name = "ParagraphFrame"
            ParagraphFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            ParagraphFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            ParagraphFrame.BackgroundTransparency = 0.5
            ParagraphFrame.BorderSizePixel = 0
            ParagraphFrame.Size = UDim2.new(1, 0, 0, 0)
            ParagraphFrame.AutomaticSize = Enum.AutomaticSize.Y

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = ParagraphFrame
            
            local UIPadding = Instance.new("UIPadding")
            UIPadding.Parent = ParagraphFrame
            UIPadding.PaddingTop = UDim.new(0, 10)
            UIPadding.PaddingBottom = UDim.new(0, 10)
            UIPadding.PaddingLeft = UDim.new(0, 15)
            UIPadding.PaddingRight = UDim.new(0, 15)

            local UIListLayout = Instance.new("UIListLayout")
            UIListLayout.Parent = ParagraphFrame
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Padding = UDim.new(0, 5)

            if title ~= "" then
                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Parent = ParagraphFrame
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Size = UDim2.new(1, 0, 0, 16)
                TitleLbl.Font = Enum.Font.GothamBold
                TitleLbl.Text = title
                TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLbl.TextSize = 14
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            end

            local ContentLbl = Instance.new("TextLabel")
            ContentLbl.Parent = ParagraphFrame
            ContentLbl.BackgroundTransparency = 1
            ContentLbl.Size = UDim2.new(1, 0, 0, 0)
            ContentLbl.AutomaticSize = Enum.AutomaticSize.Y
            ContentLbl.Font = Enum.Font.Gotham
            ContentLbl.Text = content
            ContentLbl.TextColor3 = Color3.fromRGB(180, 180, 185)
            ContentLbl.TextSize = 13
            ContentLbl.TextWrapped = true
            ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
            ContentLbl.TextYAlignment = Enum.TextYAlignment.Top
        end

        function TabElements:CreateTextBox(config)
            local tbName = config.Name or "TextBox"
            local placeholder = config.Placeholder or "Type here..."
            local clearOnFocus = config.ClearOnFocus or false
            local callback = config.Callback or function() end

            local TextBoxFrame = Instance.new("Frame")
            TextBoxFrame.Name = "TextBoxFrame"
            TextBoxFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            TextBoxFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            TextBoxFrame.BorderSizePixel = 0
            TextBoxFrame.Size = UDim2.new(1, 0, 0, 40)

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = TextBoxFrame

            local Title = Instance.new("TextLabel")
            Title.Parent = TextBoxFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.Size = UDim2.new(0.5, -15, 1, 0)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = tbName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local InputFrame = Instance.new("Frame")
            InputFrame.Parent = TextBoxFrame
            InputFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
            InputFrame.BorderSizePixel = 0
            InputFrame.Position = UDim2.new(0.5, 10, 0.5, -12)
            InputFrame.Size = UDim2.new(0.5, -25, 0, 24)

            local InputCorner = Instance.new("UICorner")
            InputCorner.CornerRadius = UDim.new(0, 6)
            InputCorner.Parent = InputFrame

            local UIStroke = Instance.new("UIStroke")
            UIStroke.Color = Color3.fromRGB(70, 70, 75)
            UIStroke.Thickness = 1
            UIStroke.Parent = InputFrame

            local InputBox = Instance.new("TextBox")
            InputBox.Parent = InputFrame
            InputBox.BackgroundTransparency = 1
            InputBox.Size = UDim2.new(1, -10, 1, 0)
            InputBox.Position = UDim2.new(0, 5, 0, 0)
            InputBox.Font = Enum.Font.Gotham
            InputBox.PlaceholderText = placeholder
            InputBox.Text = ""
            InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            InputBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 135)
            InputBox.TextSize = 12
            InputBox.TextXAlignment = Enum.TextXAlignment.Left
            InputBox.ClearTextOnFocus = clearOnFocus
            InputBox.TextTruncate = Enum.TextTruncate.AtEnd

            InputBox.Focused:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(10, 132, 255)}):Play()
            end)

            local currentText = ""
            InputBox.FocusLost:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(70, 70, 75)}):Play()
                currentText = InputBox.Text
                callback(currentText)
                RequestSave()
            end)

            if config.Flag then
                RegisterFlag(config.Flag, {
                    Type = "string",
                    Default = "",
                    GetValue = function() return currentText end,
                    SetValue = function(val)
                        currentText = tostring(val or "")
                        InputBox.Text = currentText
                    end,
                })
            end
        end

        function TabElements:CreateKeybind(config)
            local kbName = config.Name or "Keybind"
            local currentKey = config.CurrentKey or Enum.KeyCode.E
            local callback = config.Callback or function() end

            local KeybindFrame = Instance.new("Frame")
            KeybindFrame.Name = "KeybindFrame"
            KeybindFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            KeybindFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            KeybindFrame.BorderSizePixel = 0
            KeybindFrame.Size = UDim2.new(1, 0, 0, 40)

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = KeybindFrame

            local Title = Instance.new("TextLabel")
            Title.Parent = KeybindFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.Size = UDim2.new(0.5, -15, 1, 0)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = kbName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local BindButton = Instance.new("TextButton")
            BindButton.Parent = KeybindFrame
            BindButton.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
            BindButton.BorderSizePixel = 0
            BindButton.Position = UDim2.new(1, -115, 0.5, -12)
            BindButton.Size = UDim2.new(0, 100, 0, 24)
            BindButton.Font = Enum.Font.GothamBold
            BindButton.Text = currentKey.Name
            BindButton.TextColor3 = Color3.fromRGB(10, 132, 255)
            BindButton.TextSize = 12
            BindButton.AutoButtonColor = false

            local BindCorner = Instance.new("UICorner")
            BindCorner.CornerRadius = UDim.new(0, 6)
            BindCorner.Parent = BindButton

            local UIStroke = Instance.new("UIStroke")
            UIStroke.Color = Color3.fromRGB(70, 70, 75)
            UIStroke.Thickness = 1
            UIStroke.Parent = BindButton

            local isBinding = false

            BindButton.MouseButton1Click:Connect(function()
                isBinding = true
                BindButton.Text = "..."
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 190, 50)}):Play()
            end)

            local inputConn
            inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if isBinding then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        BindButton.Text = currentKey.Name
                        isBinding = false
                        TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(70, 70, 75)}):Play()
                        RequestSave()
                    end
                elseif not gameProcessed then
                    if input.KeyCode == currentKey then
                        TweenService:Create(BindButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(55, 55, 58)}):Play()
                        task.wait(0.1)
                        TweenService:Create(BindButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28, 28, 30)}):Play()
                        callback(currentKey.Name)
                    end
                end
            end)
            table.insert(allConnections, inputConn)

            if config.Flag then
                RegisterFlag(config.Flag, {
                    Type = "string",
                    Default = currentKey.Name,
                    GetValue = function() return currentKey.Name end,
                    SetValue = function(val)
                        local kc = Enum.KeyCode[val]
                        if kc then
                            currentKey = kc
                            BindButton.Text = kc.Name
                        end
                    end,
                })
            end
        end

                function TabElements:CreateToggle(config)
            local toggleName = config.Name or "Toggle"
            local default = config.CurrentValue or false
            local callback = config.Callback or function() end

            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = "ToggleFrame"
            ToggleFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Size = UDim2.new(1, 0, 0, 40)

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = ToggleFrame

            local Title = Instance.new("TextLabel")
            Title.Parent = ToggleFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.Size = UDim2.new(1, -50, 1, 0)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = toggleName
            Title.TextColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 155)
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local GlowRing = Instance.new("Frame")
            GlowRing.Parent = ToggleFrame
            GlowRing.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
            GlowRing.BackgroundTransparency = default and 0.6 or 1
            GlowRing.Position = UDim2.new(1, -30, 0.5, -8)
            GlowRing.Size = UDim2.new(0, 16, 0, 16)

            local GlowCorner = Instance.new("UICorner")
            GlowCorner.CornerRadius = UDim.new(1, 0)
            GlowCorner.Parent = GlowRing

            local Dot = Instance.new("Frame")
            Dot.Parent = ToggleFrame
            Dot.BackgroundColor3 = default and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(70, 70, 75)
            Dot.Position = UDim2.new(1, -27, 0.5, -5)
            Dot.Size = UDim2.new(0, 10, 0, 10)

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = Dot

            local ClickButton = Instance.new("TextButton")
            ClickButton.Parent = ToggleFrame
            ClickButton.BackgroundTransparency = 1
            ClickButton.Size = UDim2.new(1, 0, 1, 0)
            ClickButton.Text = ""

            local state = default
            local pulseLoop = nil

            local function startPulse()
                pulseLoop = task.spawn(function()
                    while state do
                        TweenService:Create(GlowRing, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.85}):Play()
                        task.wait(1)
                        if not state then break end
                        TweenService:Create(GlowRing, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.5}):Play()
                        task.wait(1)
                    end
                end)
            end

            local function SetState(newState)
                if state == newState then return end
                state = newState
                if state then
                    TweenService:Create(Dot, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(10, 132, 255), Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -28, 0.5, -6)}):Play()
                    TweenService:Create(GlowRing, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6, Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -31, 0.5, -9)}):Play()
                    TweenService:Create(Title, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    startPulse()
                else
                    TweenService:Create(Dot, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(70, 70, 75), Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -27, 0.5, -5)}):Play()
                    TweenService:Create(GlowRing, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -30, 0.5, -8)}):Play()
                    TweenService:Create(Title, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(150, 150, 155)}):Play()
                end
                if not _isLoading then
                    callback(state)
                end
            end

            if default then startPulse() end

            ClickButton.MouseButton1Click:Connect(function()
                SetState(not state)
                RequestSave()
            end)

            if config.Flag then
                RegisterFlag(config.Flag, {
                    Type = "boolean",
                    Default = default,
                    GetValue = function() return state end,
                    SetValue = function(val) SetState(val) end
                })
            end
        end
        function TabElements:CreateSlider(config)
            local sliderName = config.Name or "Slider"
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or min
            local step = config.Step or 1
            local callback = config.Callback or function() end

            local function snap(val)
                return math.clamp(math.floor(val / step + 0.5) * step, min, max)
            end

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = "SliderFrame"
            SliderFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            SliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = SliderFrame

            local Title = Instance.new("TextLabel")
            Title.Parent = SliderFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 15, 0, 4)
            Title.Size = UDim2.new(1, -80, 0, 18)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = sliderName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local ValueText = Instance.new("TextLabel")
            ValueText.Parent = SliderFrame
            ValueText.BackgroundTransparency = 1
            ValueText.Position = UDim2.new(1, -62, 0, 4)
            ValueText.Size = UDim2.new(0, 38, 0, 18)
            ValueText.Font = Enum.Font.GothamBold
            ValueText.Text = tostring(snap(default))
            ValueText.TextColor3 = Color3.fromRGB(10, 132, 255)
            ValueText.TextSize = 13
            ValueText.TextXAlignment = Enum.TextXAlignment.Right

            local ValueClickBtn = Instance.new("TextButton")
            ValueClickBtn.Parent = SliderFrame
            ValueClickBtn.BackgroundTransparency = 1
            ValueClickBtn.Position = UDim2.new(1, -66, 0, 2)
            ValueClickBtn.Size = UDim2.new(0, 52, 0, 22)
            ValueClickBtn.Text = ""

            local PencilIcon = CreateIcon(SliderFrame, "pencil-line", UDim2.new(0, 12, 0, 12), UDim2.new(1, -20, 0, 7))

            local ValueInput = Instance.new("TextBox")
            ValueInput.Parent = SliderFrame
            ValueInput.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
            ValueInput.BorderSizePixel = 0
            ValueInput.Position = UDim2.new(1, -66, 0, 2)
            ValueInput.Size = UDim2.new(0, 50, 0, 22)
            ValueInput.Font = Enum.Font.GothamBold
            ValueInput.Text = ""
            ValueInput.TextColor3 = Color3.fromRGB(10, 132, 255)
            ValueInput.TextSize = 13
            ValueInput.Visible = false
            ValueInput.ZIndex = 5

            local InputCorner = Instance.new("UICorner")
            InputCorner.CornerRadius = UDim.new(0, 4)
            InputCorner.Parent = ValueInput

            local InputStroke = Instance.new("UIStroke")
            InputStroke.Color = Color3.fromRGB(10, 132, 255)
            InputStroke.Thickness = 1
            InputStroke.Parent = ValueInput

            local SliderBack = Instance.new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
            SliderBack.BorderSizePixel = 0
            SliderBack.Position = UDim2.new(0, 14, 0, 27)
            SliderBack.Size = UDim2.new(1, -28, 0, 6)

            local BackCorner = Instance.new("UICorner")
            BackCorner.CornerRadius = UDim.new(1, 0)
            BackCorner.Parent = SliderBack

            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBack
            SliderFill.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
            SliderFill.BorderSizePixel = 0
            local percent = math.clamp((snap(default) - min) / (max - min), 0, 1)
            SliderFill.Size = UDim2.new(percent, 0, 1, 0)

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = SliderFill

            local KnobShadow = Instance.new("Frame")
            KnobShadow.Parent = SliderFrame
            KnobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            KnobShadow.BackgroundTransparency = 0.75
            KnobShadow.Size = UDim2.new(0, 12, 0, 12)
            KnobShadow.AnchorPoint = Vector2.new(0.5, 0.5)
            KnobShadow.ZIndex = 2

            local ShadowCorner = Instance.new("UICorner")
            ShadowCorner.CornerRadius = UDim.new(1, 0)
            ShadowCorner.Parent = KnobShadow

            local Knob = Instance.new("Frame")
            Knob.Parent = SliderFrame
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.Size = UDim2.new(0, 10, 0, 10)
            Knob.AnchorPoint = Vector2.new(0.5, 0.5)
            Knob.ZIndex = 3

            local KnobCorner = Instance.new("UICorner")
            KnobCorner.CornerRadius = UDim.new(1, 0)
            KnobCorner.Parent = Knob

            local KnobStroke = Instance.new("UIStroke")
            KnobStroke.Color = Color3.fromRGB(10, 132, 255)
            KnobStroke.Thickness = 2
            KnobStroke.Parent = Knob

            local SliderButton = Instance.new("TextButton")
            SliderButton.Parent = SliderFrame
            SliderButton.BackgroundTransparency = 1
            SliderButton.Position = UDim2.new(0, 8, 0, 20)
            SliderButton.Size = UDim2.new(1, -16, 0, 18)
            SliderButton.Text = ""
            SliderButton.ZIndex = 4

            local MinLabel = Instance.new("TextLabel")
            MinLabel.Parent = SliderFrame
            MinLabel.BackgroundTransparency = 1
            MinLabel.Position = UDim2.new(0, 14, 0, 35)
            MinLabel.Size = UDim2.new(0, 30, 0, 12)
            MinLabel.Font = Enum.Font.Gotham
            MinLabel.Text = tostring(min)
            MinLabel.TextColor3 = Color3.fromRGB(120, 120, 125)
            MinLabel.TextSize = 10
            MinLabel.TextXAlignment = Enum.TextXAlignment.Left

            local MaxLabel = Instance.new("TextLabel")
            MaxLabel.Parent = SliderFrame
            MaxLabel.BackgroundTransparency = 1
            MaxLabel.Position = UDim2.new(1, -42, 0, 35)
            MaxLabel.Size = UDim2.new(0, 30, 0, 12)
            MaxLabel.Font = Enum.Font.Gotham
            MaxLabel.Text = tostring(max)
            MaxLabel.TextColor3 = Color3.fromRGB(120, 120, 125)
            MaxLabel.TextSize = 10
            MaxLabel.TextXAlignment = Enum.TextXAlignment.Right

            local dragging = false
            local currentValue = snap(default)

            local function updateKnobPosition(p)
                local trackAbsX = SliderBack.AbsolutePosition.X
                local trackAbsW = SliderBack.AbsoluteSize.X
                local trackAbsY = SliderBack.AbsolutePosition.Y + SliderBack.AbsoluteSize.Y / 2
                local parentAbsX = SliderFrame.AbsolutePosition.X
                local parentAbsY = SliderFrame.AbsolutePosition.Y

                local cx = trackAbsX + p * trackAbsW
                local cy = trackAbsY

                Knob.Position = UDim2.new(0, cx - parentAbsX, 0, cy - parentAbsY)
                KnobShadow.Position = UDim2.new(0, cx - parentAbsX, 0, cy - parentAbsY + 1)
            end

            local function SetValue(val)
                currentValue = snap(tonumber(val) or min)
                local p = (currentValue - min) / (max - min)
                ValueText.Text = tostring(currentValue)
                TweenService:Create(SliderFill, TweenInfo.new(0.2), {Size = UDim2.new(p, 0, 1, 0)}):Play()
                updateKnobPosition(p)
                if not _isLoading then
                    callback(currentValue)
                end
            end

            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                local value = snap(min + ((max - min) * pos))
                currentValue = value
                ValueText.Text = tostring(value)
                local p = (value - min) / (max - min)
                TweenService:Create(SliderFill, TweenInfo.new(0.1), {Size = UDim2.new(p, 0, 1, 0)}):Play()
                updateKnobPosition(p)
                callback(value)
                RequestSave()
            end

            updateKnobPosition(percent)

            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)

            local endConn = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            table.insert(allConnections, endConn)

            local changeConn = UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
            table.insert(allConnections, changeConn)

            ValueClickBtn.MouseButton1Click:Connect(function()
                ValueText.Visible = false
                ValueClickBtn.Visible = false
                if PencilIcon then PencilIcon.Visible = false end
                ValueInput.Text = ""
                ValueInput.Visible = true
                ValueInput:CaptureFocus()
            end)

            ValueInput.FocusLost:Connect(function()
                local typed = tonumber(ValueInput.Text)
                if typed then
                    SetValue(typed)
                    RequestSave()
                end
                ValueInput.Text = ""
                ValueInput.Visible = false
                ValueText.Visible = true
                ValueClickBtn.Visible = true
                if PencilIcon then PencilIcon.Visible = true end
            end)

            if config.Flag then
                RegisterFlag(config.Flag, {
                    Type = "number",
                    Default = snap(default),
                    GetValue = function() return currentValue end,
                    SetValue = function(val) SetValue(val) end
                })
            end
        end
        function TabElements:CreateDropdown(config)
            local dropName = config.Name or "Dropdown"
            local options = config.Options or {}
            local default = config.Default
            local callback = config.Callback or function() end

            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = "DropdownFrame"
            DropdownFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.ClipsDescendants = true

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = DropdownFrame

            local TopButton = Instance.new("TextButton")
            TopButton.Parent = DropdownFrame
            TopButton.BackgroundTransparency = 1
            TopButton.Size = UDim2.new(1, 0, 0, 40)
            TopButton.Text = ""

            local Title = Instance.new("TextLabel")
            Title.Parent = TopButton
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Size = UDim2.new(0.45, -12, 1, 0)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = dropName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Parent = TopButton
            SelectedText.BackgroundTransparency = 1
            SelectedText.Position = UDim2.new(0.45, 0, 0, 0)
            SelectedText.Size = UDim2.new(0.55, -28, 1, 0)
            SelectedText.Font = Enum.Font.Gotham
            SelectedText.Text = default or "None"
            SelectedText.TextColor3 = default and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(150, 150, 155)
            SelectedText.TextSize = 12
            SelectedText.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedText.TextXAlignment = Enum.TextXAlignment.Right

            local Arrow = CreateIcon(TopButton, "chevron-down", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))

            local SearchFrame = Instance.new("Frame")
            SearchFrame.Parent = DropdownFrame
            SearchFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
            SearchFrame.BorderSizePixel = 0
            SearchFrame.Position = UDim2.new(0, 8, 0, 42)
            SearchFrame.Size = UDim2.new(1, -16, 0, 26)

            local SearchCorner = Instance.new("UICorner")
            SearchCorner.CornerRadius = UDim.new(0, 6)
            SearchCorner.Parent = SearchFrame

            local SearchBox = Instance.new("TextBox")
            SearchBox.Parent = SearchFrame
            SearchBox.BackgroundTransparency = 1
            SearchBox.Size = UDim2.new(1, -27, 1, 0)
            SearchBox.Position = UDim2.new(0, 19, 0, 0)
            SearchBox.Font = Enum.Font.Gotham
            SearchBox.PlaceholderText = "Search..."
            SearchBox.Text = ""
            SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            SearchBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 75)
            SearchBox.TextSize = 12
            SearchBox.TextXAlignment = Enum.TextXAlignment.Left
            SearchBox.ClearTextOnFocus = false

            CreateIcon(SearchFrame, "search", UDim2.new(0, 12, 0, 12), UDim2.new(0, 3, 0.5, -6))

            local OptionContainer = Instance.new("ScrollingFrame")
            OptionContainer.Parent = DropdownFrame
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.BorderSizePixel = 0
            OptionContainer.Position = UDim2.new(0, 0, 0, 72)
            OptionContainer.Size = UDim2.new(1, 0, 1, -72)
            OptionContainer.ScrollBarThickness = 2
            OptionContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
            OptionContainer.ScrollingDirection = Enum.ScrollingDirection.Y

            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.Parent = OptionContainer
            OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionLayout.Padding = UDim.new(0, 2)

            local UIPadding = Instance.new("UIPadding")
            UIPadding.Parent = OptionContainer
            UIPadding.PaddingLeft = UDim.new(0, 6)
            UIPadding.PaddingRight = UDim.new(0, 6)
            UIPadding.PaddingTop = UDim.new(0, 2)

            local optionButtons = {}
            local isOpen = false
            local currentSelected = default
            local maxVisibleItems = 5

            local function BuildOptions()
                for _, item in ipairs(optionButtons) do
                    item.btn:Destroy()
                end
                table.clear(optionButtons)

                for _, opt in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Parent = OptionContainer
                    OptBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 58)
                    OptBtn.BorderSizePixel = 0
                    OptBtn.Size = UDim2.new(1, 0, 0, 28)
                    OptBtn.Font = Enum.Font.Gotham
                    OptBtn.Text = "  " .. opt
                    OptBtn.TextColor3 = Color3.fromRGB(210, 210, 215)
                    OptBtn.TextSize = 13
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.TextTruncate = Enum.TextTruncate.AtEnd

                    local BtnCorner = Instance.new("UICorner")
                    BtnCorner.CornerRadius = UDim.new(0, 5)
                    BtnCorner.Parent = OptBtn

                    OptBtn.MouseEnter:Connect(function()
                        TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 70, 75)}):Play()
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 55, 58)}):Play()
                    end)

                    OptBtn.MouseButton1Click:Connect(function()
                        currentSelected = opt
                        SelectedText.Text = opt
                        SelectedText.TextColor3 = Color3.fromRGB(10, 132, 255)
                        callback(opt)
                        RequestSave()
                        isOpen = false
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                        if Arrow then Arrow:Destroy() end
                        Arrow = CreateIcon(TopButton, "chevron-down", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))
                        SearchBox.Text = ""
                    end)

                    table.insert(optionButtons, {btn = OptBtn, name = opt})
                end

                OptionContainer.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
            end

            BuildOptions()

            local function doFilter()
                local query = string.lower(SearchBox.Text)
                local visibleCount = 0
                for _, item in ipairs(optionButtons) do
                    local match = query == "" or string.find(string.lower(item.name), query, 1, true)
                    item.btn.Visible = match ~= nil
                    if match then visibleCount = visibleCount + 1 end
                end
                OptionContainer.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 30)

                if isOpen then
                    local clampedVisible = math.min(visibleCount, maxVisibleItems)
                    local totalHeight = 72 + (clampedVisible * 30)
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, totalHeight)}):Play()
                end
            end

            SearchBox:GetPropertyChangedSignal("Text"):Connect(doFilter)

            TopButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local query = string.lower(SearchBox.Text)
                    local visibleCount = 0
                    for _, item in ipairs(optionButtons) do
                        local match = query == "" or string.find(string.lower(item.name), query, 1, true)
                        if match then visibleCount = visibleCount + 1 end
                    end
                    local clampedVisible = math.min(visibleCount, maxVisibleItems)
                    local totalHeight = 72 + (clampedVisible * 30)
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, totalHeight)}):Play()
                    if Arrow then Arrow:Destroy() end
                    Arrow = CreateIcon(TopButton, "chevron-up", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))
                else
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                    if Arrow then Arrow:Destroy() end
                    Arrow = CreateIcon(TopButton, "chevron-down", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))
                end
            end)

            local function RefreshOptions(newOptions)
                options = newOptions
                BuildOptions()
                doFilter()
            end

            if config.Flag then
                RegisterFlag(config.Flag, {
                    Type = "string",
                    Default = default,
                    GetValue = function() return currentSelected end,
                    SetValue = function(val)
                        currentSelected = val
                        SelectedText.Text = val or "None"
                        SelectedText.TextColor3 = val and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(150, 150, 155)
                    end,
                    Refresh = RefreshOptions
                })
            end

            return { Refresh = RefreshOptions }
        end

        function TabElements:CreateMultiDropdown(config)
            local dropName = config.Name or "Multi Dropdown"
            local options = config.Options or {}
            local currentSelected = config.CurrentSelected or {}
            local callback = config.Callback or function() end

            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = "MultiDropdownFrame"
            DropdownFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.ClipsDescendants = true

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = DropdownFrame

            local TopButton = Instance.new("TextButton")
            TopButton.Parent = DropdownFrame
            TopButton.BackgroundTransparency = 1
            TopButton.Size = UDim2.new(1, 0, 0, 40)
            TopButton.Text = ""

            local Title = Instance.new("TextLabel")
            Title.Parent = TopButton
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Size = UDim2.new(0.45, -12, 1, 0)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = dropName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Parent = TopButton
            SelectedText.BackgroundTransparency = 1
            SelectedText.Position = UDim2.new(0.45, 0, 0, 0)
            SelectedText.Size = UDim2.new(0.55, -28, 1, 0)
            SelectedText.Font = Enum.Font.Gotham
            SelectedText.Text = #currentSelected > 0 and (#currentSelected .. " Selected") or "None"
            SelectedText.TextColor3 = #currentSelected > 0 and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(150, 150, 155)
            SelectedText.TextSize = 12
            SelectedText.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedText.TextXAlignment = Enum.TextXAlignment.Right

            local Arrow = CreateIcon(TopButton, "chevron-down", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))

            local SearchFrame = Instance.new("Frame")
            SearchFrame.Parent = DropdownFrame
            SearchFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
            SearchFrame.BorderSizePixel = 0
            SearchFrame.Position = UDim2.new(0, 8, 0, 42)
            SearchFrame.Size = UDim2.new(1, -16, 0, 26)

            local SearchCorner = Instance.new("UICorner")
            SearchCorner.CornerRadius = UDim.new(0, 6)
            SearchCorner.Parent = SearchFrame

            local SearchBox = Instance.new("TextBox")
            SearchBox.Parent = SearchFrame
            SearchBox.BackgroundTransparency = 1
            SearchBox.Size = UDim2.new(1, -27, 1, 0)
            SearchBox.Position = UDim2.new(0, 19, 0, 0)
            SearchBox.Font = Enum.Font.Gotham
            SearchBox.PlaceholderText = "Search..."
            SearchBox.Text = ""
            SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            SearchBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 75)
            SearchBox.TextSize = 12
            SearchBox.TextXAlignment = Enum.TextXAlignment.Left
            SearchBox.ClearTextOnFocus = false

            CreateIcon(SearchFrame, "search", UDim2.new(0, 12, 0, 12), UDim2.new(0, 3, 0.5, -6))

            local OptionContainer = Instance.new("ScrollingFrame")
            OptionContainer.Parent = DropdownFrame
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.BorderSizePixel = 0
            OptionContainer.Position = UDim2.new(0, 0, 0, 72)
            OptionContainer.Size = UDim2.new(1, 0, 1, -72)
            OptionContainer.ScrollBarThickness = 2
            OptionContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
            OptionContainer.ScrollingDirection = Enum.ScrollingDirection.Y

            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.Parent = OptionContainer
            OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionLayout.Padding = UDim.new(0, 2)

            local UIPadding = Instance.new("UIPadding")
            UIPadding.Parent = OptionContainer
            UIPadding.PaddingLeft = UDim.new(0, 6)
            UIPadding.PaddingRight = UDim.new(0, 6)
            UIPadding.PaddingTop = UDim.new(0, 2)

            local optionButtons = {}
            local isOpen = false
            local maxVisibleItems = 5

            local function UpdateSelectedText()
                if #currentSelected > 0 then
                    SelectedText.Text = #currentSelected .. " Selected"
                    SelectedText.TextColor3 = Color3.fromRGB(10, 132, 255)
                else
                    SelectedText.Text = "None"
                    SelectedText.TextColor3 = Color3.fromRGB(150, 150, 155)
                end
            end

            local function BuildOptions()
                for _, item in ipairs(optionButtons) do
                    item.btn:Destroy()
                end
                table.clear(optionButtons)

                for _, opt in ipairs(options) do
                    local isSelected = table.find(currentSelected, opt) ~= nil

                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Parent = OptionContainer
                    OptBtn.BackgroundColor3 = isSelected and Color3.fromRGB(70, 70, 75) or Color3.fromRGB(55, 55, 58)
                    OptBtn.BorderSizePixel = 0
                    OptBtn.Size = UDim2.new(1, 0, 0, 28)
                    OptBtn.Font = Enum.Font.Gotham
                    OptBtn.Text = "  " .. opt
                    OptBtn.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(210, 210, 215)
                    OptBtn.TextSize = 13
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.TextTruncate = Enum.TextTruncate.AtEnd

                    local BtnCorner = Instance.new("UICorner")
                    BtnCorner.CornerRadius = UDim.new(0, 5)
                    BtnCorner.Parent = OptBtn

                    local Checkmark
                    if isSelected then
                        Checkmark = CreateIcon(OptBtn, "check", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))
                    end

                    OptBtn.MouseEnter:Connect(function()
                        if not table.find(currentSelected, opt) then
                            TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 70, 75)}):Play()
                        end
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        if not table.find(currentSelected, opt) then
                            TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 55, 58)}):Play()
                        end
                    end)

                    OptBtn.MouseButton1Click:Connect(function()
                        if table.find(currentSelected, opt) then
                            table.remove(currentSelected, table.find(currentSelected, opt))
                            TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 58), TextColor3 = Color3.fromRGB(210, 210, 215)}):Play()
                            if Checkmark then Checkmark:Destroy() Checkmark = nil end
                        else
                            table.insert(currentSelected, opt)
                            TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 75), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                            Checkmark = CreateIcon(OptBtn, "check", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))
                        end
                        UpdateSelectedText()
                        callback(currentSelected)
                        RequestSave()
                    end)

                    table.insert(optionButtons, {btn = OptBtn, name = opt})
                end

                OptionContainer.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
            end

            BuildOptions()

            local function doFilter()
                local query = string.lower(SearchBox.Text)
                local visibleCount = 0
                for _, item in ipairs(optionButtons) do
                    local match = query == "" or string.find(string.lower(item.name), query, 1, true)
                    item.btn.Visible = match ~= nil
                    if match then visibleCount = visibleCount + 1 end
                end
                OptionContainer.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 30)

                if isOpen then
                    local clampedVisible = math.min(visibleCount, maxVisibleItems)
                    local totalHeight = 72 + (clampedVisible * 30)
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, totalHeight)}):Play()
                end
            end

            SearchBox:GetPropertyChangedSignal("Text"):Connect(doFilter)

            TopButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local query = string.lower(SearchBox.Text)
                    local visibleCount = 0
                    for _, item in ipairs(optionButtons) do
                        local match = query == "" or string.find(string.lower(item.name), query, 1, true)
                        if match then visibleCount = visibleCount + 1 end
                    end
                    local clampedVisible = math.min(visibleCount, maxVisibleItems)
                    local totalHeight = 72 + (clampedVisible * 30)
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, totalHeight)}):Play()
                    if Arrow then Arrow:Destroy() end
                    Arrow = CreateIcon(TopButton, "chevron-up", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))
                else
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                    if Arrow then Arrow:Destroy() end
                    Arrow = CreateIcon(TopButton, "chevron-down", UDim2.new(0, 16, 0, 16), UDim2.new(1, -22, 0.5, -8))
                end
            end)

            local function RefreshOptions(newOptions)
                options = newOptions
                BuildOptions()
                UpdateSelectedText()
                doFilter()
            end

            if config.Flag then
                RegisterFlag(config.Flag, {
                    Type = "table",
                    Default = config.CurrentSelected or {},
                    GetValue = function() return currentSelected end,
                    SetValue = function(val)
                        currentSelected = val or {}
                        UpdateSelectedText()
                    end,
                    Refresh = RefreshOptions
                })
            end

            return {
                Refresh = RefreshOptions,
                GetSelected = function() return currentSelected end
            }
        end

        function TabElements:CreateColorPicker(config)
            local cpName = config.Name or "Color Picker"
            local default = config.Color or Color3.fromRGB(255, 255, 255)
            local callback = config.Callback or function() end

            -- Set initial color
            local h, s, v = default:ToHSV()

            local CPFrame = Instance.new("Frame")
            CPFrame.Name = "ColorPickerFrame"
            CPFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            CPFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
            CPFrame.BorderSizePixel = 0
            CPFrame.Size = UDim2.new(1, 0, 0, 40)
            CPFrame.ClipsDescendants = true

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = CPFrame

            local Title = Instance.new("TextLabel")
            Title.Parent = CPFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 32, 0, 0)
            Title.Size = UDim2.new(1, -85, 0, 40)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = cpName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left

            CreateIcon(CPFrame, "palette", UDim2.new(0, 14, 0, 14), UDim2.new(0, 13, 0.5, -7))

            local ColorDisplay = Instance.new("Frame")
            ColorDisplay.Parent = CPFrame
            ColorDisplay.BackgroundColor3 = default
            ColorDisplay.Position = UDim2.new(1, -45, 0, 10)
            ColorDisplay.Size = UDim2.new(0, 30, 0, 20)
            
            local DisplayCorner = Instance.new("UICorner")
            DisplayCorner.CornerRadius = UDim.new(0, 4)
            DisplayCorner.Parent = ColorDisplay

            local ClickButton = Instance.new("TextButton")
            ClickButton.Parent = CPFrame
            ClickButton.BackgroundTransparency = 1
            ClickButton.Size = UDim2.new(1, 0, 0, 40)
            ClickButton.Text = ""

            -- Container Ekstensi (SV Map & Hue Slider)
            local Extension = Instance.new("Frame")
            Extension.Parent = CPFrame
            Extension.BackgroundTransparency = 1
            Extension.Position = UDim2.new(0, 0, 0, 40)
            Extension.Size = UDim2.new(1, 0, 1, -40)

            -- SV Map (Saturation & Value Map)
            local SVMap = Instance.new("ImageLabel")
            SVMap.Parent = Extension
            SVMap.Position = UDim2.new(0, 15, 0, 5)
            SVMap.Size = UDim2.new(1, -30, 0, 100)
            SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            SVMap.Image = "rbxassetid://4155801252"
            SVMap.BorderSizePixel = 0

            local SVCorner = Instance.new("UICorner")
            SVCorner.CornerRadius = UDim.new(0, 6)
            SVCorner.Parent = SVMap

            local SVMarker = Instance.new("Frame")
            SVMarker.Parent = SVMap
            SVMarker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SVMarker.Size = UDim2.new(0, 8, 0, 8)
            SVMarker.AnchorPoint = Vector2.new(0.5, 0.5)
            SVMarker.Position = UDim2.new(s, 0, 1 - v, 0)
            local SVMarkerCorner = Instance.new("UICorner")
            SVMarkerCorner.CornerRadius = UDim.new(1, 0)
            SVMarkerCorner.Parent = SVMarker
            local SVMarkerStroke = Instance.new("UIStroke")
            SVMarkerStroke.Color = Color3.fromRGB(0, 0, 0)
            SVMarkerStroke.Parent = SVMarker

            local SVButton = Instance.new("TextButton")
            SVButton.Parent = SVMap
            SVButton.BackgroundTransparency = 1
            SVButton.Size = UDim2.new(1, 0, 1, 0)
            SVButton.Text = ""

            -- Hue Slider (Rainbow)
            local HueSlider = Instance.new("Frame")
            HueSlider.Parent = Extension
            HueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            HueSlider.Position = UDim2.new(0, 15, 0, 115)
            HueSlider.Size = UDim2.new(1, -30, 0, 15)
            HueSlider.BorderSizePixel = 0

            local HueCorner = Instance.new("UICorner")
            HueCorner.CornerRadius = UDim.new(1, 0)
            HueCorner.Parent = HueSlider

            local HueGradient = Instance.new("UIGradient")
            HueGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }
            HueGradient.Parent = HueSlider

            local HueMarker = Instance.new("Frame")
            HueMarker.Parent = HueSlider
            HueMarker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            HueMarker.Size = UDim2.new(0, 4, 1, 4)
            HueMarker.Position = UDim2.new(1 - h, 0, 0, -2)
            local HueMarkerCorner = Instance.new("UICorner")
            HueMarkerCorner.CornerRadius = UDim.new(1, 0)
            HueMarkerCorner.Parent = HueMarker
            local HueMarkerStroke = Instance.new("UIStroke")
            HueMarkerStroke.Color = Color3.fromRGB(0, 0, 0)
            HueMarkerStroke.Parent = HueMarker

            local HueButton = Instance.new("TextButton")
            HueButton.Parent = HueSlider
            HueButton.BackgroundTransparency = 1
            HueButton.Size = UDim2.new(1, 0, 1, 0)
            HueButton.Text = ""

            -- Logic Dragging
            local svDragging = false
            local hueDragging = false

            local function updateFinalColor()
                local finalColor = Color3.fromHSV(h, s, v)
                ColorDisplay.BackgroundColor3 = finalColor
                SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                callback(finalColor)
            end

            -- Hue Drag
            local function updateHue(input)
                local pos = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                h = 1 - pos
                TweenService:Create(HueMarker, TweenInfo.new(0.1), {Position = UDim2.new(pos, -2, 0, -2)}):Play()
                updateFinalColor()
            end

            HueButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    hueDragging = true
                    updateHue(input)
                end
            end)

            -- SV Drag
            local function updateSV(input)
                local posX = math.clamp((input.Position.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
                local posY = math.clamp((input.Position.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
                s = posX
                v = 1 - posY
                TweenService:Create(SVMarker, TweenInfo.new(0.1), {Position = UDim2.new(posX, 0, posY, 0)}):Play()
                updateFinalColor()
            end

            SVButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = true
                    updateSV(input)
                end
            end)

            -- Global Drag Ending
            local cpEndConn = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = false
                    hueDragging = false
                end
            end)
            table.insert(allConnections, cpEndConn)

            local cpChangeConn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if svDragging then
                        updateSV(input)
                    end
                    if hueDragging then
                        updateHue(input)
                    end
                end
            end)
            table.insert(allConnections, cpChangeConn)

            -- Animasi Open/Close
            local isOpen = false
            ClickButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetSize = isOpen and UDim2.new(1, 0, 0, 180) or UDim2.new(1, 0, 0, 40)
                TweenService:Create(CPFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
            end)
        end

        function TabElements:CreateGroup(columns)
            columns = math.clamp(columns or 2, 2, 4)
            local gap = 8

            local GroupFrame = Instance.new("Frame")
            GroupFrame.Parent = TabElements.CurrentSectionContainer or TabContent
            GroupFrame.BackgroundTransparency = 1
            GroupFrame.Size = UDim2.new(1, 0, 0, 0)
            GroupFrame.AutomaticSize = Enum.AutomaticSize.Y

            local GroupLayout = Instance.new("UIListLayout")
            GroupLayout.Parent = GroupFrame
            GroupLayout.FillDirection = Enum.FillDirection.Horizontal
            GroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
            GroupLayout.Padding = UDim.new(0, gap)
            GroupLayout.VerticalAlignment = Enum.VerticalAlignment.Top

            local cols = {}

            for i = 1, columns do
                local scale = 1 / columns
                local offset = -(gap * (columns - 1)) / columns

                local ColFrame = Instance.new("Frame")
                ColFrame.Parent = GroupFrame
                ColFrame.BackgroundTransparency = 1
                ColFrame.Size = UDim2.new(scale, offset, 0, 0)
                ColFrame.AutomaticSize = Enum.AutomaticSize.Y

                local ColLayout = Instance.new("UIListLayout")
                ColLayout.Parent = ColFrame
                ColLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ColLayout.Padding = UDim.new(0, 8)

                local ColElements = {}

                for k, v in pairs(TabElements) do
                    if type(v) == "function" and k ~= "CreateGroup" then
                        ColElements[k] = function(_, ...)
                            local prev = TabElements.CurrentSectionContainer
                            TabElements.CurrentSectionContainer = ColFrame
                            local result = v(TabElements, ...)
                            TabElements.CurrentSectionContainer = prev
                            return result
                        end
                    end
                end

                table.insert(cols, ColElements)
            end

            return unpack(cols)
        end

        return TabElements
    end

    if cfg.AutoLoad then
        task.spawn(function()
            game:GetService("RunService").Heartbeat:Wait()
            if cfg.AutoLoadDelay and cfg.AutoLoadDelay > 0 then
                task.wait(cfg.AutoLoadDelay)
            end
            local name = "default"
            if isfile and isfile(autoloadPath()) then
                pcall(function()
                    local n = readfile(autoloadPath())
                    if n and n ~= "" then
                        local cleaned = sanitizeProfileName(n)
                        if cleaned then name = cleaned end
                    end
                end)
            end
            loadConfig(name)
        end)
    end

    return WindowElements
end

return WadeHub
