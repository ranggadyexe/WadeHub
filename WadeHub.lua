local WadeHub = {}
WadeHub.Version = "1.0.0"

-- Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Security Bypass untuk menyembunyikan GUI dari game anti-cheat
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

-- Dragging Logic (Dibuat oleh Agen Interaction Engineer)
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

-- Fungsi Pembuatan Jendela Utama (Didesain oleh UI/UX Artist)
function WadeHub:CreateWindow(config)
    -- === ANTI DUPLICATE & CLEANUP LAMA ===
    if getgenv and getgenv().WadeHub_Destroy then
        pcall(getgenv().WadeHub_Destroy)
    end

    config = config or {}
    local windowName = config.Name or "Wade Hub"

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WadeHub_UI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ProtectGui(ScreenGui)

    -- Main Floating Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22) -- Warna sangat gelap elegan
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.Size = UDim2.new(0, 0, 0, 0) -- Dimulai dari 0 untuk efek muncul (Tween)
    MainFrame.ClipsDescendants = true

    -- Membuat sudut membulat elegan
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame
    
    -- DropShadow tipis untuk kesan "Floating"
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(70, 70, 75)
    UIStroke.Thickness = 1
    UIStroke.Parent = MainFrame

    -- Topbar (Untuk Dragging)
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
    local allConnections = {} -- Untuk cleanup saat Close

    -- Daftarkan fungsi destroy global untuk instance baru ini
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

    -- Helper: buat tombol kontrol bulat kecil
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

    -- Posisi di kiri atas (Gaya Mac OS)
    local CloseBtn = createControlDot(Topbar, Color3.fromRGB(255, 95, 86), 15)
    local MinimizeBtn = createControlDot(Topbar, Color3.fromRGB(255, 189, 46), 35)
    local FullscreenBtn = createControlDot(Topbar, Color3.fromRGB(39, 201, 63), 55)

    local iconId = config.Icon or "rbxassetid://78533790239403"

    -- === MINIMIZE ICON (Lingkaran kecil di pojok kiri bawah) ===
    local MinimizeIcon
    if iconId then
        MinimizeIcon = Instance.new("ImageButton")
        MinimizeIcon.Image = iconId
        MinimizeIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
        MinimizeIcon.BackgroundTransparency = 0 -- Beri background jika gambar transparan
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
    MinimizeIcon.Size = UDim2.new(0, 0, 0, 0)
    MinimizeIcon.Position = UDim2.new(0, 20, 1, -60)
    MinimizeIcon.AutoButtonColor = false
    MinimizeIcon.BorderSizePixel = 0
    MinimizeIcon.Visible = false

    local MinIconCorner = Instance.new("UICorner")
    MinIconCorner.CornerRadius = UDim.new(1, 0)
    MinIconCorner.Parent = MinimizeIcon

    -- Minimize Logic
    MinimizeBtn.MouseButton1Click:Connect(function()
        if isMinimized then return end
        isMinimized = true
        -- Shrink MainFrame
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, 40, 1, -60)
        }):Play()
        task.wait(0.4)
        MainFrame.Visible = false
        -- Tampilkan icon
        MinimizeIcon.Visible = true
        TweenService:Create(MinimizeIcon, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 40, 0, 40)
        }):Play()
    end)

    -- Restore dari Minimize
    MinimizeIcon.MouseButton1Click:Connect(function()
        if not isMinimized then return end
        -- Sembunyikan icon
        TweenService:Create(MinimizeIcon, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.wait(0.2)
        MinimizeIcon.Visible = false
        -- Restore MainFrame
        MainFrame.Visible = true
        local targetSize = isFullscreen and UDim2.new(1, -20, 1, -20) or normalSize
        local targetPos = isFullscreen and UDim2.new(0, 10, 0, 10) or normalPos
        
        -- Set posisi awal ke icon
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0, 40, 1, -60)
        
        TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = targetSize,
            Position = targetPos
        }):Play()
        isMinimized = false
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

    -- === CLOSE CONFIRMATION DIALOG ===
    local function showCloseDialog()
        local Overlay = Instance.new("Frame")
        Overlay.Parent = ScreenGui
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 1
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.ZIndex = 100

        TweenService:Create(Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()

        local Dialog = Instance.new("Frame")
        Dialog.Parent = Overlay
        Dialog.BackgroundColor3 = Color3.fromRGB(36, 36, 38)
        Dialog.Size = UDim2.new(0, 0, 0, 0)
        Dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
        Dialog.AnchorPoint = Vector2.new(0.5, 0.5)
        Dialog.ZIndex = 101

        local DialogCorner = Instance.new("UICorner")
        DialogCorner.CornerRadius = UDim.new(0, 10)
        DialogCorner.Parent = Dialog

        TweenService:Create(Dialog, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 280, 0, 130)
        }):Play()

        local DialogTitle = Instance.new("TextLabel")
        DialogTitle.Parent = Dialog
        DialogTitle.BackgroundTransparency = 1
        DialogTitle.Position = UDim2.new(0, 0, 0, 15)
        DialogTitle.Size = UDim2.new(1, 0, 0, 25)
        DialogTitle.Font = Enum.Font.GothamBold
        DialogTitle.Text = "Keluar dari Wade Hub?"
        DialogTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        DialogTitle.TextSize = 16
        DialogTitle.ZIndex = 102

        local DialogDesc = Instance.new("TextLabel")
        DialogDesc.Parent = Dialog
        DialogDesc.BackgroundTransparency = 1
        DialogDesc.Position = UDim2.new(0, 0, 0, 40)
        DialogDesc.Size = UDim2.new(1, 0, 0, 20)
        DialogDesc.Font = Enum.Font.Gotham
        DialogDesc.Text = "Semua script akan dihentikan."
        DialogDesc.TextColor3 = Color3.fromRGB(150, 150, 155)
        DialogDesc.TextSize = 13
        DialogDesc.ZIndex = 102

        -- Tombol Ya (Keluar)
        local YesBtn = Instance.new("TextButton")
        YesBtn.Parent = Dialog
        YesBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
        YesBtn.Position = UDim2.new(0.5, 10, 1, -50)
        YesBtn.Size = UDim2.new(0, 110, 0, 35)
        YesBtn.Font = Enum.Font.GothamBold
        YesBtn.Text = "Ya, Keluar"
        YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        YesBtn.TextSize = 14
        YesBtn.AutoButtonColor = false
        YesBtn.ZIndex = 102
        local YesCorner = Instance.new("UICorner")
        YesCorner.CornerRadius = UDim.new(0, 8)
        YesCorner.Parent = YesBtn

        -- Tombol Batal
        local NoBtn = Instance.new("TextButton")
        NoBtn.Parent = Dialog
        NoBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
        NoBtn.Position = UDim2.new(0.5, -120, 1, -50)
        NoBtn.Size = UDim2.new(0, 110, 0, 35)
        NoBtn.Font = Enum.Font.GothamBold
        NoBtn.Text = "Batal"
        NoBtn.TextColor3 = Color3.fromRGB(210, 210, 215)
        NoBtn.TextSize = 14
        NoBtn.AutoButtonColor = false
        NoBtn.ZIndex = 102
        local NoCorner = Instance.new("UICorner")
        NoCorner.CornerRadius = UDim.new(0, 8)
        NoCorner.Parent = NoBtn

        -- Batal: tutup dialog
        NoBtn.MouseButton1Click:Connect(function()
            TweenService:Create(Dialog, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            TweenService:Create(Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            Overlay:Destroy()
        end)

        -- Ya: cleanup dan destroy segalanya
        YesBtn.MouseButton1Click:Connect(function()
            -- Animasi keluar
            TweenService:Create(Dialog, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            TweenService:Create(Overlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            task.wait(0.5)
            
            if getgenv and getgenv().WadeHub_Destroy then
                pcall(getgenv().WadeHub_Destroy)
            else
                if config.OnClose then pcall(config.OnClose) end
                for _, conn in ipairs(allConnections) do
                    pcall(function() conn:Disconnect() end)
                end
                ScreenGui:Destroy()
            end
        end)
    end

    CloseBtn.MouseButton1Click:Connect(function()
        showCloseDialog()
    end)

    MakeDraggable(Topbar, MainFrame)

    -- Animasi Membuka Jendela (TweenService)
    local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 600, 0, 400)
    })
    openTween:Play()

    -- Sidebar Container untuk navigasi
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
    TabContainer.Size = UDim2.new(1, 0, 1, -45)
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

    -- Content Container (Tempat isi tab berada)
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Parent = MainFrame
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 160, 0, 40)
    ContentContainer.Size = UDim2.new(1, -170, 1, -50)

    -- === NOTIFICATION CONTAINER (Mac OS Style - Pojok Kanan Atas) ===
    local NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "NotificationContainer"
    NotificationContainer.Parent = ScreenGui
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.Position = UDim2.new(1, -330, 0, 10)
    NotificationContainer.Size = UDim2.new(0, 320, 1, 0)

    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.Parent = NotificationContainer
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    NotifLayout.Padding = UDim.new(0, 8)

    local WindowElements = {}
    local currentActiveTab = nil
    local configRegistry = {} -- {name = {type, getValue, setValue}}

    function WindowElements:Notify(config)
        local title = config.Title or "Notification"
        local content = config.Content or "This is a notification."
        local duration = config.Duration or 3

        -- Wrapper frame to bypass UIListLayout position locking
        local NotifWrapper = Instance.new("Frame")
        NotifWrapper.Name = "NotifWrapper"
        NotifWrapper.Parent = NotificationContainer
        NotifWrapper.BackgroundTransparency = 1
        NotifWrapper.Size = UDim2.new(1, 0, 0, 56)
        NotifWrapper.ClipsDescendants = true

        -- Mac OS Notification Banner (Compact)
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Name = "NotifFrame"
        NotifFrame.Parent = NotifWrapper
        NotifFrame.BackgroundColor3 = Color3.fromRGB(44, 44, 46)
        NotifFrame.BackgroundTransparency = 0.05
        NotifFrame.BorderSizePixel = 0
        NotifFrame.Size = UDim2.new(1, 0, 1, 0)
        NotifFrame.Position = UDim2.new(1, 10, 0, 0) -- Mulai dari luar layar (kanan wrapper)
        NotifFrame.ClipsDescendants = true

        local NotifCorner = Instance.new("UICorner")
        NotifCorner.CornerRadius = UDim.new(0, 12)
        NotifCorner.Parent = NotifFrame

        local NotifStroke = Instance.new("UIStroke")
        NotifStroke.Color = Color3.fromRGB(65, 65, 68)
        NotifStroke.Thickness = 0.5
        NotifStroke.Transparency = 0.3
        NotifStroke.Parent = NotifFrame

        -- App Icon (Compact)
        local AppIcon = Instance.new("ImageLabel")
        AppIcon.Parent = NotifFrame
        AppIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
        AppIcon.BackgroundTransparency = 0
        AppIcon.Position = UDim2.new(0, 10, 0, 10)
        AppIcon.Size = UDim2.new(0, 24, 0, 24)
        AppIcon.ZIndex = 2
        AppIcon.Image = iconId or "rbxassetid://78533790239403"
        local AppIconCorner = Instance.new("UICorner")
        AppIconCorner.CornerRadius = UDim.new(0, 6)
        AppIconCorner.Parent = AppIcon

        -- Title (sejajar icon)
        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Parent = NotifFrame
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Position = UDim2.new(0, 42, 0, 8)
        TitleLbl.Size = UDim2.new(1, -90, 0, 16)
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.Text = title
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextSize = 12
        TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.ZIndex = 2

        -- Timestamp (pojok kanan)
        local TimeStamp = Instance.new("TextLabel")
        TimeStamp.Parent = NotifFrame
        TimeStamp.BackgroundTransparency = 1
        TimeStamp.Position = UDim2.new(1, -45, 0, 8)
        TimeStamp.Size = UDim2.new(0, 38, 0, 16)
        TimeStamp.Font = Enum.Font.Gotham
        TimeStamp.Text = "now"
        TimeStamp.TextColor3 = Color3.fromRGB(100, 100, 105)
        TimeStamp.TextSize = 9
        TimeStamp.TextXAlignment = Enum.TextXAlignment.Right
        TimeStamp.ZIndex = 2

        -- Content
        local ContentLbl = Instance.new("TextLabel")
        ContentLbl.Parent = NotifFrame
        ContentLbl.BackgroundTransparency = 1
        ContentLbl.Position = UDim2.new(0, 42, 0, 28)
        ContentLbl.Size = UDim2.new(1, -55, 0, 20)
        ContentLbl.Font = Enum.Font.Gotham
        ContentLbl.Text = content
        ContentLbl.TextColor3 = Color3.fromRGB(160, 160, 165)
        ContentLbl.TextSize = 11
        ContentLbl.TextTruncate = Enum.TextTruncate.AtEnd
        ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
        ContentLbl.ZIndex = 2

        -- Animasi Masuk: Slide dari kanan ke kiri (Lebih lambat & smooth)
        TweenService:Create(NotifFrame, TweenInfo.new(0.85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        -- Hapus setelah durasi: Slide kembali ke kanan
        task.delay(duration, function()
            TweenService:Create(NotifFrame, TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 350, 0, 0)
            }):Play()
            task.wait(0.75)
            NotifWrapper:Destroy()
        end)
    end

    function WindowElements:CreateWatermark(config)
        config = config or {}
        local wmName = config.Name or "Wade Hub"
        local showFPS = config.FPS ~= false
        local showPing = config.Ping ~= false

        local WatermarkFrame = Instance.new("Frame")
        WatermarkFrame.Name = "WadeHub_Watermark"
        WatermarkFrame.Parent = ScreenGui
        WatermarkFrame.BackgroundColor3 = Color3.fromRGB(44, 44, 46)
        WatermarkFrame.BackgroundTransparency = 0.1
        WatermarkFrame.Position = UDim2.new(0, 15, 0, 10)
        WatermarkFrame.Size = UDim2.new(0, 0, 0, 26)
        WatermarkFrame.BorderSizePixel = 0

        local WMCorner = Instance.new("UICorner")
        WMCorner.CornerRadius = UDim.new(0, 8)
        WMCorner.Parent = WatermarkFrame

        local WMStroke = Instance.new("UIStroke")
        WMStroke.Color = Color3.fromRGB(65, 65, 68)
        WMStroke.Thickness = 0.5
        WMStroke.Transparency = 0.3
        WMStroke.Parent = WatermarkFrame

        -- Dot indikator biru kecil (kiri)
        local WMDot = Instance.new("Frame")
        WMDot.Parent = WatermarkFrame
        WMDot.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
        WMDot.BorderSizePixel = 0
        WMDot.Position = UDim2.new(0, 8, 0.5, -3)
        WMDot.Size = UDim2.new(0, 6, 0, 6)
        local WMDotCorner = Instance.new("UICorner")
        WMDotCorner.CornerRadius = UDim.new(1, 0)
        WMDotCorner.Parent = WMDot

        local WMLabel = Instance.new("TextLabel")
        WMLabel.Parent = WatermarkFrame
        WMLabel.BackgroundTransparency = 1
        WMLabel.Position = UDim2.new(0, 20, 0, 0)
        WMLabel.Size = UDim2.new(1, -25, 1, 0)
        WMLabel.Font = Enum.Font.GothamBold
        WMLabel.Text = wmName
        WMLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
        WMLabel.TextSize = 11
        WMLabel.TextXAlignment = Enum.TextXAlignment.Left

        -- Klik untuk Toggle (Collapse / Expand)
        local WMClickArea = Instance.new("TextButton")
        WMClickArea.Parent = WatermarkFrame
        WMClickArea.BackgroundTransparency = 1
        WMClickArea.Size = UDim2.new(1, 0, 1, 0)
        WMClickArea.Text = ""
        WMClickArea.ZIndex = 3

        local wmExpanded = true
        local expandedSize = UDim2.new(0, 235, 0, 26)
        local collapsedSize = UDim2.new(0, 95, 0, 26)

        -- Animasi masuk (mulai dari 0, expand ke ukuran penuh)
        TweenService:Create(WatermarkFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = expandedSize
        }):Play()

        -- Live FPS, Ping, & Uptime updater
        local RunService = game:GetService("RunService")
        local Stats = game:GetService("Stats")
        local fpsCount = 0
        local lastTime = tick()
        local scriptStartTime = os.time()
        local showTime = config.Time ~= false
        local cachedFullText = wmName

        local updateConn = RunService.RenderStepped:Connect(function()
            fpsCount = fpsCount + 1
            if tick() - lastTime >= 1 then
                local fps = fpsCount
                fpsCount = 0
                lastTime = tick()

                local parts = {wmName}
                if showFPS then
                    table.insert(parts, fps .. " FPS")
                end
                if showPing then
                    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                    table.insert(parts, ping .. "ms")
                end
                if showTime then
                    local elapsed = os.time() - scriptStartTime
                    local hours = math.floor(elapsed / 3600)
                    local mins = math.floor((elapsed % 3600) / 60)
                    local secs = elapsed % 60
                    table.insert(parts, string.format("%02d:%02d:%02d", hours, mins, secs))
                end

                cachedFullText = table.concat(parts, "  |  ")
                if wmExpanded then
                    WMLabel.Text = cachedFullText
                end
            end
        end)
        table.insert(allConnections, updateConn)

        -- Toggle: Klik untuk collapse/expand
        WMClickArea.MouseButton1Click:Connect(function()
            wmExpanded = not wmExpanded
            local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            if wmExpanded then
                WMLabel.Text = cachedFullText
                TweenService:Create(WatermarkFrame, tweenInfo, {Size = expandedSize}):Play()
            else
                WMLabel.Text = wmName
                TweenService:Create(WatermarkFrame, tweenInfo, {Size = collapsedSize}):Play()
            end
        end)
    end

    function WindowElements:CreateTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName .. "_Button"
        TabButton.Parent = TabContainer
        TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 0, 35)
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.Text = tabName
        TabButton.TextColor3 = Color3.fromRGB(180, 180, 185)
        TabButton.TextSize = 14
        TabButton.TextTruncate = Enum.TextTruncate.AtEnd
        TabButton.AutoButtonColor = false

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
        TabContent.Visible = false

        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Parent = TabContent
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 8)

        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.Parent = TabContent
        ContentPadding.PaddingTop = UDim.new(0, 5)
        ContentPadding.PaddingBottom = UDim.new(0, 5)

        -- Logika Pindah Tab (Animasi Warna & Visibility)
        TabButton.MouseButton1Click:Connect(function()
            if currentActiveTab and currentActiveTab.Content == TabContent then return end

            if currentActiveTab then
                TweenService:Create(currentActiveTab.Button, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 48), TextColor3 = Color3.fromRGB(180, 180, 185)}):Play()
                currentActiveTab.Content.Visible = false
            end

            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50, 50, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            
            -- Mac OS Smooth Slide-in Transition
            TabContent.Visible = true
            TabContent.Position = UDim2.new(0, 0, 0, 15)
            TweenService:Create(TabContent, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
            
            currentActiveTab = {Button = TabButton, Content = TabContent}
        end)

        -- Auto-select tab pertama secara instan
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

            local Arrow = Instance.new("TextLabel")
            Arrow.Parent = SectionBtn
            Arrow.BackgroundTransparency = 1
            Arrow.Position = UDim2.new(0, 0, 0, 0)
            Arrow.Size = UDim2.new(0, 15, 1, 0)
            Arrow.Font = Enum.Font.GothamBold
            Arrow.Text = "v"
            Arrow.TextColor3 = Color3.fromRGB(10, 132, 255)
            Arrow.TextSize = 12
            Arrow.Rotation = defaultOpen and 0 or -90

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

            local isOpen = defaultOpen
            SectionBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                SectionContainer.Visible = isOpen
                TweenService:Create(Arrow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Rotation = isOpen and 0 or -90}):Play()
            end)
        end

        -- Fase 3: Elemen Dasar
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

            -- Efek klik (animasi)
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

            InputBox.Focused:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(10, 132, 255)}):Play()
            end)

            InputBox.FocusLost:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(70, 70, 75)}):Play()
                callback(InputBox.Text)
            end)
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
                callback(state)
            end

            if default then startPulse() end

            ClickButton.MouseButton1Click:Connect(function()
                SetState(not state)
            end)

            if config.Flag then
                configRegistry[config.Flag] = {
                    Type = "Toggle",
                    GetValue = function() return state end,
                    SetValue = function(val) SetState(val) end
                }
            end
        end
        function TabElements:CreateSlider(config)
            local sliderName = config.Name or "Slider"
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or min
            local callback = config.Callback or function() end

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
            Title.Position = UDim2.new(0, 15, 0, 5)
            Title.Size = UDim2.new(1, -70, 0, 20)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = sliderName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local ValueText = Instance.new("TextLabel")
            ValueText.Parent = SliderFrame
            ValueText.BackgroundTransparency = 1
            ValueText.Position = UDim2.new(1, -50, 0, 5)
            ValueText.Size = UDim2.new(0, 35, 0, 20)
            ValueText.Font = Enum.Font.GothamBold
            ValueText.Text = tostring(default)
            ValueText.TextColor3 = Color3.fromRGB(10, 132, 255)
            ValueText.TextSize = 14
            ValueText.TextXAlignment = Enum.TextXAlignment.Right

            local ValueClickBtn = Instance.new("TextButton")
            ValueClickBtn.Parent = ValueText
            ValueClickBtn.BackgroundTransparency = 1
            ValueClickBtn.Size = UDim2.new(1, 0, 1, 0)
            ValueClickBtn.Text = ""

            local ValueInput = Instance.new("TextBox")
            ValueInput.Parent = SliderFrame
            ValueInput.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
            ValueInput.BorderSizePixel = 0
            ValueInput.Position = UDim2.new(1, -60, 0, 3)
            ValueInput.Size = UDim2.new(0, 45, 0, 24)
            ValueInput.Font = Enum.Font.GothamBold
            ValueInput.Text = tostring(default)
            ValueInput.TextColor3 = Color3.fromRGB(10, 132, 255)
            ValueInput.TextSize = 14
            ValueInput.Visible = false
            local InputCorner = Instance.new("UICorner")
            InputCorner.CornerRadius = UDim.new(0, 4)
            InputCorner.Parent = ValueInput

            local SliderBack = Instance.new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
            SliderBack.BorderSizePixel = 0
            SliderBack.Position = UDim2.new(0, 15, 1, -12)
            SliderBack.Size = UDim2.new(1, -30, 0, 4)
            local BackCorner = Instance.new("UICorner")
            BackCorner.CornerRadius = UDim.new(1, 0)
            BackCorner.Parent = SliderBack

            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBack
            SliderFill.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
            SliderFill.BorderSizePixel = 0
            local percent = (default - min) / (max - min)
            SliderFill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = SliderFill

            local SliderButton = Instance.new("TextButton")
            SliderButton.Parent = SliderBack
            SliderButton.BackgroundTransparency = 1
            SliderButton.Size = UDim2.new(1, 0, 1, 0)
            SliderButton.Text = ""

            local dragging = false
            local currentValue = default

            local function SetValue(val)
                currentValue = math.clamp(tonumber(val) or min, min, max)
                local p = (currentValue - min) / (max - min)
                ValueText.Text = tostring(currentValue)
                TweenService:Create(SliderFill, TweenInfo.new(0.2), {Size = UDim2.new(p, 0, 1, 0)}):Play()
                callback(currentValue)
            end

            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + ((max - min) * pos))
                currentValue = value
                ValueText.Text = tostring(value)
                TweenService:Create(SliderFill, TweenInfo.new(0.1), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
                callback(value)
            end

            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            ValueClickBtn.MouseButton1Click:Connect(function()
                ValueText.Visible = false
                ValueInput.Visible = true
                ValueClickBtn.Visible = false
                ValueInput:CaptureFocus()
            end)

            ValueInput.FocusLost:Connect(function()
                local typed = tonumber(ValueInput.Text)
                if typed then SetValue(typed) end
                ValueInput.Text = ""
                ValueInput.Visible = false
                ValueText.Visible = true
                ValueClickBtn.Visible = true
            end)

            if config.Flag then
                configRegistry[config.Flag] = {
                    Type = "Slider",
                    GetValue = function() return currentValue end,
                    SetValue = function(val) SetValue(val) end
                }
            end
        end
        function TabElements:CreateDropdown(config)
            local dropName = config.Name or "Dropdown"
            local options = config.Options or {}
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
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.Size = UDim2.new(0.5, -15, 1, 0)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = dropName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Parent = TopButton
            SelectedText.BackgroundTransparency = 1
            SelectedText.Position = UDim2.new(0.5, 0, 0, 0)
            SelectedText.Size = UDim2.new(0.5, -35, 1, 0)
            SelectedText.Font = Enum.Font.Gotham
            SelectedText.Text = "Pilih..."
            SelectedText.TextColor3 = Color3.fromRGB(150, 150, 155)
            SelectedText.TextSize = 12
            SelectedText.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedText.TextXAlignment = Enum.TextXAlignment.Right

            local Arrow = Instance.new("TextLabel")
            Arrow.Parent = TopButton
            Arrow.BackgroundTransparency = 1
            Arrow.Position = UDim2.new(1, -25, 0, 0)
            Arrow.Size = UDim2.new(0, 20, 1, 0)
            Arrow.Font = Enum.Font.GothamBold
            Arrow.Text = "v"
            Arrow.TextColor3 = Color3.fromRGB(150, 150, 155)
            Arrow.TextSize = 14

            local OptionContainer = Instance.new("ScrollingFrame")
            OptionContainer.Parent = DropdownFrame
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.BorderSizePixel = 0
            OptionContainer.Position = UDim2.new(0, 0, 0, 40)
            OptionContainer.Size = UDim2.new(1, 0, 1, -40)
            OptionContainer.ScrollBarThickness = 2

            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.Parent = OptionContainer
            OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local isOpen = false
            local currentSelected = nil

            local function toggleDropdown()
                isOpen = not isOpen
                if isOpen then
                    local targetHeight = math.min(40 + (#options * 35), 180)
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 180}):Play()
                else
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
                end
            end

            TopButton.MouseButton1Click:Connect(toggleDropdown)

            local function SelectOption(opt)
                currentSelected = opt
                SelectedText.Text = opt
                SelectedText.TextColor3 = Color3.fromRGB(10, 132, 255)
                callback(opt)
                if isOpen then toggleDropdown() end
            end

            local function RefreshOptions(newOptions)
                options = newOptions
                for _, child in ipairs(OptionContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for _, opt in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Parent = OptionContainer
                    OptBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                    OptBtn.BackgroundTransparency = 1
                    OptBtn.BorderSizePixel = 0
                    OptBtn.Size = UDim2.new(1, 0, 0, 35)
                    OptBtn.Font = Enum.Font.Gotham
                    OptBtn.Text = opt
                    OptBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
                    OptBtn.TextSize = 13

                    OptBtn.MouseEnter:Connect(function()
                        TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                    end)

                    OptBtn.MouseButton1Click:Connect(function()
                        SelectOption(opt)
                    end)
                end
            end

            RefreshOptions(options)

            if config.Flag then
                configRegistry[config.Flag] = {
                    Type = "Dropdown",
                    GetValue = function() return currentSelected end,
                    SetValue = function(val) SelectOption(val) end,
                    Refresh = RefreshOptions
                }
            end

            return {
                Refresh = RefreshOptions
            }
        end
function TabElements:CreateSearchableDropdown(config)
            local dropName = config.Name or "Search Dropdown"
            local options = config.Options or {}
            local callback = config.Callback or function() end

            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = "SearchDropdownFrame"
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
            TopButton.Font = Enum.Font.GothamSemibold
            TopButton.Text = "  " .. dropName
            TopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TopButton.TextSize = 14
            TopButton.TextXAlignment = Enum.TextXAlignment.Left

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Parent = DropdownFrame
            SelectedText.BackgroundTransparency = 1
            SelectedText.Position = UDim2.new(1, -160, 0, 0)
            SelectedText.Size = UDim2.new(0, 145, 0, 40)
            SelectedText.Font = Enum.Font.Gotham
            SelectedText.Text = "..."
            SelectedText.TextColor3 = Color3.fromRGB(150, 150, 155)
            SelectedText.TextSize = 12
            SelectedText.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedText.TextXAlignment = Enum.TextXAlignment.Right

            -- Search Bar
            local SearchFrame = Instance.new("Frame")
            SearchFrame.Parent = DropdownFrame
            SearchFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
            SearchFrame.BorderSizePixel = 0
            SearchFrame.Position = UDim2.new(0, 10, 0, 45)
            SearchFrame.Size = UDim2.new(1, -20, 0, 25)

            local SearchCorner = Instance.new("UICorner")
            SearchCorner.CornerRadius = UDim.new(0, 5)
            SearchCorner.Parent = SearchFrame

            local SearchBox = Instance.new("TextBox")
            SearchBox.Parent = SearchFrame
            SearchBox.BackgroundTransparency = 1
            SearchBox.Size = UDim2.new(1, -10, 1, 0)
            SearchBox.Position = UDim2.new(0, 5, 0, 0)
            SearchBox.Font = Enum.Font.Gotham
            SearchBox.PlaceholderText = "Cari..."
            SearchBox.Text = ""
            SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            SearchBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 75)
            SearchBox.TextSize = 12
            SearchBox.TextXAlignment = Enum.TextXAlignment.Left
            SearchBox.ClearTextOnFocus = false

            local OptionContainer = Instance.new("ScrollingFrame")
            OptionContainer.Parent = DropdownFrame
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.BorderSizePixel = 0
            OptionContainer.Position = UDim2.new(0, 0, 0, 75)
            OptionContainer.Size = UDim2.new(1, 0, 1, -75)
            OptionContainer.ScrollBarThickness = 2

            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.Parent = OptionContainer
            OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local optionButtons = {}
            local isOpen = false

            for _, opt in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Parent = OptionContainer
                OptBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 58)
                OptBtn.BorderSizePixel = 0
                OptBtn.Size = UDim2.new(1, 0, 0, 30)
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.Text = opt
                OptBtn.TextColor3 = Color3.fromRGB(210, 210, 215)
                OptBtn.TextSize = 13
                OptBtn.TextTruncate = Enum.TextTruncate.AtEnd

                OptBtn.MouseButton1Click:Connect(function()
                    SelectedText.Text = opt
                    isOpen = false
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                    SearchBox.Text = ""
                    callback(opt)
                end)

                table.insert(optionButtons, {btn = OptBtn, name = opt})
            end

            -- Filter logic
            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local query = string.lower(SearchBox.Text)
                local visibleCount = 0
                for _, item in ipairs(optionButtons) do
                    local match = query == "" or string.find(string.lower(item.name), query, 1, true)
                    item.btn.Visible = match ~= nil
                    if match then visibleCount = visibleCount + 1 end
                end
                -- Auto-resize canvas
                OptionContainer.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 30)
            end)

            TopButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local totalHeight = 75 + math.clamp(#options * 30, 0, 120)
                local targetSize = isOpen and UDim2.new(1, 0, 0, totalHeight) or UDim2.new(1, 0, 0, 40)
                TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
            end)
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
            TopButton.Font = Enum.Font.GothamSemibold
            TopButton.Text = "  " .. dropName
            TopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TopButton.TextSize = 14
            TopButton.TextXAlignment = Enum.TextXAlignment.Left

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Parent = DropdownFrame
            SelectedText.BackgroundTransparency = 1
            SelectedText.Position = UDim2.new(1, -160, 0, 0)
            SelectedText.Size = UDim2.new(0, 145, 0, 40)
            SelectedText.Font = Enum.Font.Gotham
            SelectedText.Text = #currentSelected .. " Selected"
            SelectedText.TextColor3 = Color3.fromRGB(150, 150, 155)
            SelectedText.TextSize = 12
            SelectedText.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedText.TextXAlignment = Enum.TextXAlignment.Right

            local OptionContainer = Instance.new("ScrollingFrame")
            OptionContainer.Parent = DropdownFrame
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.BorderSizePixel = 0
            OptionContainer.Position = UDim2.new(0, 0, 0, 40)
            OptionContainer.Size = UDim2.new(1, 0, 1, -40)
            OptionContainer.ScrollBarThickness = 2

            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.Parent = OptionContainer
            OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local isOpen = false

            TopButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetSize = isOpen and UDim2.new(1, 0, 0, 40 + math.clamp(#options * 30, 0, 120)) or UDim2.new(1, 0, 0, 40)
                TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
            end)

            for _, opt in ipairs(options) do
                local isSelected = table.find(currentSelected, opt) ~= nil

                local OptBtn = Instance.new("TextButton")
                OptBtn.Parent = OptionContainer
                OptBtn.BackgroundColor3 = isSelected and Color3.fromRGB(70, 70, 75) or Color3.fromRGB(55, 55, 58)
                OptBtn.BorderSizePixel = 0
                OptBtn.Size = UDim2.new(1, 0, 0, 30)
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.Text = opt
                OptBtn.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(210, 210, 215)
                OptBtn.TextSize = 13
                OptBtn.TextTruncate = Enum.TextTruncate.AtEnd

                OptBtn.MouseButton1Click:Connect(function()
                    if table.find(currentSelected, opt) then
                        table.remove(currentSelected, table.find(currentSelected, opt))
                        TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 58), TextColor3 = Color3.fromRGB(210, 210, 215)}):Play()
                    else
                        table.insert(currentSelected, opt)
                        TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 75), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    end
                    SelectedText.Text = #currentSelected .. " Selected"
                    callback(currentSelected)
                end)
            end
        end

        function TabElements:CreateColorPicker(config)
            local cpName = config.Name or "Color Picker"
            local default = config.Color or Color3.fromRGB(255, 255, 255)
            local callback = config.Callback or function() end

            -- Ubah warna awal ke HSV
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
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.Size = UDim2.new(1, -70, 0, 40)
            Title.Font = Enum.Font.GothamSemibold
            Title.Text = cpName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left

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
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = false
                    hueDragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if svDragging then
                        updateSV(input)
                    end
                    if hueDragging then
                        updateHue(input)
                    end
                end
            end)

            -- Animasi Open/Close
            local isOpen = false
            ClickButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetSize = isOpen and UDim2.new(1, 0, 0, 180) or UDim2.new(1, 0, 0, 40)
                TweenService:Create(CPFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
            end)
        end

        return TabElements
    end

    -- === BUILT-IN SETTINGS ===
    local BuiltInSettings = WindowElements:CreateTab("Settings")
    local settingsBtn = TabContainer:FindFirstChild("Settings_Button")
    if settingsBtn then 
        settingsBtn.Parent = Sidebar
        settingsBtn.Position = UDim2.new(0, 0, 1, -35)
    end

    BuiltInSettings:CreateSection({Name = "Local Player", Default = false})

    BuiltInSettings:CreateSlider({
        Name = "WalkSpeed (Kecepatan)",
        Flag = "WalkSpeed",
        Min = 16,
        Max = 300,
        Default = 16,
        Callback = function(value)
            pcall(function()
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
            end)
        end
    })

    BuiltInSettings:CreateSlider({
        Name = "JumpPower (Lompatan)",
        Flag = "JumpPower",
        Min = 50,
        Max = 300,
        Default = 50,
        Callback = function(value)
            pcall(function()
                game.Players.LocalPlayer.Character.Humanoid.UseJumpPower = true
                game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
            end)
        end
    })

    BuiltInSettings:CreateSlider({
        Name = "Gravity (Gravitasi)",
        Flag = "Gravity",
        Min = 0,
        Max = 500,
        Default = 196,
        Callback = function(value)
            workspace.Gravity = value
        end
    })

    local RunService = game:GetService("RunService")
    local noclipConnection = nil

    BuiltInSettings:CreateToggle({
        Name = "Noclip (Tembus Tembok)",
        Flag = "Noclip",
        CurrentValue = false,
        Callback = function(state)
            if state then
                noclipConnection = RunService.Stepped:Connect(function()
                    pcall(function()
                        for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end)
                end)
            else
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
            end
        end
    })

    BuiltInSettings:CreateSlider({
        Name = "Field of View (FOV)",
        Flag = "FOV",
        Min = 70,
        Max = 120,
        Default = 70,
        Callback = function(value)
            pcall(function()
                workspace.CurrentCamera.FieldOfView = value
            end)
        end
    })

    BuiltInSettings:CreateSection("Wade Hub - System")

    BuiltInSettings:CreateSlider({
        Name = "Background Transparency",
        Flag = "BgTransparency",
        Min = 0,
        Max = 100,
        Default = 0,
        Callback = function(val)
            local t = val / 100
            MainFrame.BackgroundTransparency = t
            Sidebar.BackgroundTransparency = t
        end
    })

    -- Toggle Keybind (Sembunyikan / Tampilkan UI)
    local toggleKey = Enum.KeyCode.RightControl
    local uiVisible = true

    BuiltInSettings:CreateKeybind({
        Name = "Toggle UI Keybind",
        Flag = "ToggleUIKeybind",
        CurrentKey = toggleKey,
        Callback = function(newKey)
            toggleKey = Enum.KeyCode[newKey]
        end
    })

    local toggleConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            uiVisible = not uiVisible
            MainFrame.Visible = uiVisible
        end
    end)
    table.insert(allConnections, toggleConn)

    -- Toggle Watermark
    BuiltInSettings:CreateToggle({
        Name = "Show Watermark",
        Flag = "ShowWatermark",
        CurrentValue = true,
        Callback = function(state)
            local wm = ScreenGui:FindFirstChild("WadeHub_Watermark")
            if wm then
                wm.Visible = state
            end
        end
    })

    -- === CONFIG SYSTEM ===
    BuiltInSettings:CreateSection({Name = "Config System", Default = false})

    local HttpService = game:GetService("HttpService")
    local configName = "default"

    BuiltInSettings:CreateTextBox({
        Name = "Config Name",
        Placeholder = "Type config name...",
        Callback = function(text)
            configName = text
        end
    })

    local function initFolder()
        pcall(function()
            if makefolder and not isfolder("WadeHub_Configs") then
                makefolder("WadeHub_Configs")
            end
        end)
    end

    local function getConfigList()
        local list = {}
        pcall(function()
            if listfiles and isfolder("WadeHub_Configs") then
                for _, file in ipairs(listfiles("WadeHub_Configs")) do
                    if file:match("%.json$") then
                        local name = file:match("([^/\\]+)%.json$")
                        if name then table.insert(list, name) end
                    end
                end
            end
        end)
        return #list > 0 and list or {"No Configs Found"}
    end

    local ConfigDropdown = BuiltInSettings:CreateDropdown({
        Name = "Select Config",
        Options = getConfigList(),
        Callback = function(opt)
            if opt ~= "No Configs Found" then
                configName = opt
            end
        end
    })

    BuiltInSettings:CreateButton({
        Name = "Create Config",
        Callback = function()
            pcall(function()
                initFolder()
                local dataToSave = {}
                for flag, config in pairs(configRegistry) do
                    if config.GetValue then
                        dataToSave[flag] = config.GetValue()
                    end
                end
                if writefile then
                    local json = HttpService:JSONEncode(dataToSave)
                    writefile("WadeHub_Configs/" .. configName .. ".json", json)
                    WindowElements:Notify({Title = "Config Created", Content = "Successfully created: " .. configName .. ".json", Duration = 3})
                    -- Kita refresh dropdown agar config baru muncul
                    ConfigDropdown.Refresh(getConfigList())
                end
            end)
        end
    })

    BuiltInSettings:CreateButton({
        Name = "Refresh Config List",
        Callback = function()
            ConfigDropdown.Refresh(getConfigList())
        end
    })

    BuiltInSettings:CreateButton({
        Name = "Load Config",
        Callback = function()
            pcall(function()
                if readfile and configName ~= "No Configs Found" then
                    local content = readfile("WadeHub_Configs/" .. configName .. ".json")
                    local parsed = HttpService:JSONDecode(content)
                    for flag, val in pairs(parsed) do
                        if configRegistry[flag] and configRegistry[flag].SetValue then
                            configRegistry[flag].SetValue(val)
                        end
                    end
                    WindowElements:Notify({Title = "Config Loaded", Content = "Successfully loaded: " .. configName .. ".json", Duration = 3})
                end
            end)
        end
    })

    BuiltInSettings:CreateButton({
        Name = "Delete Config",
        Callback = function()
            pcall(function()
                if delfile and configName ~= "No Configs Found" and configName ~= "default" then
                    delfile("WadeHub_Configs/" .. configName .. ".json")
                    WindowElements:Notify({Title = "Config Deleted", Content = "Berhasil menghapus: " .. configName .. ".json", Duration = 3})
                    ConfigDropdown.Refresh(getConfigList())
                end
            end)
        end
    })

    BuiltInSettings:CreateToggle({
        Name = "Set as Auto Load",
        CurrentValue = false,
        Callback = function(state)
            pcall(function()
                initFolder()
                if state and configName ~= "default" and configName ~= "No Configs Found" then
                    if writefile then
                        writefile("WadeHub_Configs/autoload.txt", configName)
                        WindowElements:Notify({Title = "Auto Load", Content = configName .. " diatur sebagai Auto Load.", Duration = 3})
                    end
                else
                    if writefile then
                        writefile("WadeHub_Configs/autoload.txt", "")
                        WindowElements:Notify({Title = "Auto Load", Content = "Auto Load dimatikan.", Duration = 3})
                    end
                end
            end)
        end
    })

    local autoSaveEnabled = false
    BuiltInSettings:CreateToggle({
        Name = "Auto Save Config",
        CurrentValue = false,
        Callback = function(state)
            autoSaveEnabled = state
        end
    })

    -- Background task to Auto Save config every 5 seconds
    task.spawn(function()
        while task.wait(5) do
            if autoSaveEnabled and configName ~= "default" and configName ~= "No Configs Found" then
                pcall(function()
                    local dataToSave = {}
                    for flag, config in pairs(configRegistry) do
                        if config.GetValue then
                            dataToSave[flag] = config.GetValue()
                        end
                    end
                    if writefile then
                        local json = HttpService:JSONEncode(dataToSave)
                        writefile("WadeHub_Configs/" .. configName .. ".json", json)
                    end
                end)
            end
        end
    end)

    -- Background task to auto load config after UI setup
    task.spawn(function()
        task.wait(1.5)
        pcall(function()
            if readfile and isfile and isfile("WadeHub_Configs/autoload.txt") then
                local savedName = readfile("WadeHub_Configs/autoload.txt")
                if savedName and savedName ~= "" and isfile("WadeHub_Configs/" .. savedName .. ".json") then
                    local content = readfile("WadeHub_Configs/" .. savedName .. ".json")
                    local parsed = HttpService:JSONDecode(content)
                    for flag, val in pairs(parsed) do
                        if configRegistry[flag] and configRegistry[flag].SetValue then
                            configRegistry[flag].SetValue(val)
                        end
                    end
                    WindowElements:Notify({Title = "Auto Load Config", Content = "Berhasil memuat: " .. savedName, Duration = 4})
                end
            end
        end)
    end)

    -- Bawaan Library: Auto Watermark
    WindowElements:CreateWatermark({
        Name = windowName,
        FPS = true,
        Ping = true,
        Time = true
    })

    return WindowElements
end

return WadeHub
