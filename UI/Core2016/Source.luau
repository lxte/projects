-- [>] Core2016 by lxte
-- [!] inspired by spec / scot.wtf's Project2016

if (not game:IsLoaded()) then
    game.Loaded:Wait();
end

-- Services
local CoreGui = game:GetService("CoreGui");
local TextChatService = game:GetService("TextChatService");
local Lighting = game:GetService("Lighting");
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local StarterGui = game:GetService("StarterGui");
local Players = game:GetService("Players");

-- Variables
local RobloxGui = CoreGui:WaitForChild("RobloxGui");
local ExperienceChat = CoreGui:WaitForChild("ExperienceChat");
local ExperienceChatApp = ExperienceChat:WaitForChild("appLayout");
local TopBarApp = CoreGui:WaitForChild("TopBarApp"):WaitForChild("TopBarApp");
local UnibarMenu = TopBarApp:WaitForChild("UnibarLeftFrame"):WaitForChild("UnibarMenu");
local MenuIconHolder = TopBarApp:WaitForChild("MenuIconHolder")
local RobloxMenu = MenuIconHolder:WaitForChild("TriggerPoint"):WaitForChild("IconHitArea");
local ChatHolder = UnibarMenu:WaitForChild("2"):WaitForChild("3");

-- Player
local LocalPlayer = Players.LocalPlayer

-- Global
local Core2016 = getgenv().Core2016
local Configuration = getgenv().Config2016 or ({
    OldConsole = true,
    OldGraphics = true,
    OldPlayerList = true,
    OldBubbleChat = true,

    ReplaceAgeGroupMessage = true,
    HideVoiceChatButton = false,
})

-- Luau
local Spawn = task.spawn
local Byte, Sub, Format, Match, Find, Replace = string.byte, string.sub, string.format, string.match, string.find, string.gsub
local Floor, Random = math.floor, math.random
local Discover = table.find

local Connect = (game.Loaded.Connect);
local Clone = (game.Clone);
local Destroy = (game.Destroy);
local Changed = (game.GetPropertyChangedSignal);

-- Functions
local Create = function(Class: string, Properties: { [string]: any })
    local Object = Instance.new(Class);

    for Property, Value in next, (Properties or {}) do
        Object[Property] = Value
    end

    return Object
end

local ColorOffset = 0
local GetPlayerColor = function(PlayerName)
    local Value = 0

    for Index = 1, #PlayerName do
        local NewValue = Byte(Sub(PlayerName, Index, Index));
        local Reverse = (#PlayerName - Index + 1);

        if (#PlayerName % 2 == 1) then
            Reverse -= 1
        end

        if (Reverse % 4 >= 2) then
            NewValue = -NewValue
        end

        Value += NewValue
    end

    local ChatColors = ({
        Color3.new(253/255, 41/255, 67/255),
        Color3.new(1/255, 162/255, 255/255),
        Color3.new(2/255, 184/255, 87/255),
        BrickColor.new("Bright violet").Color,
        BrickColor.new("Bright orange").Color,
        BrickColor.new("Bright yellow").Color,
        BrickColor.new("Light reddish violet").Color,
        BrickColor.new("Brick yellow").Color,
    });
    
    local Color = ChatColors[((Value + ColorOffset) % #ChatColors) + 1]
    return Format("#%02x%02x%02x", Floor(Color.R * 255), Floor(Color.G * 255), Floor(Color.B * 255));
end

-- might just remove this function
local UpdatePosition = function(Button, Position)
    Button.Position = Position
    Connect(Changed(Button, "Position"), function()
        if (Button.Position ~= Position) then
            Button.Position = Position
        end
    end)
end

local GetImage = function(Type: "Backpack" | "Chat" | "Menu", Visible)
    local Images = {
        Backpack = {
            ["true"] = "rbxasset://textures/ui/Backpack/Backpack_Down.png",
            ["false"] = "rbxasset://textures/ui/Backpack/Backpack.png",
        },

        Chat = {
            ["true"] = "rbxasset://textures/ui/Chat/ChatDown.png",
            ["false"] = "rbxasset://textures/ui/Chat/Chat.png",
        },

        Menu = {
            ["true"] = "rbxasset://textures/ui/Menu/HamburgerDown.png",
            ["false"] = "rbxasset://textures/ui/Menu/Hamburger.png",
        },
    }

    return Images[Type][tostring(Visible)]
end

local CreateBackpack = function()
    if (not Core2016) then
        local DotButton = ChatHolder:WaitForChild("nine_dot");
        local Button = Clone(DotButton);

        Button.Parent = ChatHolder
        Button.Name = "_Backpack"
        Button.Visible = true
        
        return Button
    end

    return nil -- so my vscode stops yelling
end

local AddIconSystem = function(Button, Size, Clicked: () -> ())
    if (not Button) then
        return function() end
    end

    local IntegrationIconFrame = Button:FindFirstChild("IntegrationIconFrame", 0.5);
    local RobloxMenu = Button:FindFirstChild("ScalingIcon");
    local Highlighter = Button:FindFirstChild("Highlighter") or Button:FindFirstChild("StateOverlayRound");
    local IntegrationIcon = RobloxMenu or IntegrationIconFrame:FindFirstChild("IntegrationIcon");
    local Icon = nil

    if (IntegrationIcon) then
        local Previous = IntegrationIcon.Parent:FindFirstChild("ICON_IMAGE");

        if (Previous) then
            Icon = Previous
        else
            Icon = Create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = Size or IntegrationIcon.Size,
                Parent = IntegrationIcon.Parent,
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Name = "ICON_IMAGE",
            })

            IntegrationIcon.Visible = false
        end
    end

    if (Clicked) then
        Spawn(function()
            Connect(Button:WaitForChild("IconHitArea_nine_dot").MouseButton1Click, Clicked);
        end)
    end

    if (Highlighter) then
        Highlighter.BackgroundTransparency = 1
        Highlighter.Visible = false
    end

    return function(ImageId: string)
        if (Icon) then
            Icon.Image = ImageId
        else
            warn("Can't set icon", debug.traceback());
        end
    end
end

local UpdateChatCounter = function()
    local Chat = ChatHolder:FindFirstChild("chat");
    local Badges = Chat and Chat:FindFirstChild("5");

    if (Badges) then
        for _, Badge in next, Badges:GetChildren() do
            if (Badge.Name == "Badge") then
                Badge.BackgroundColor3 = Color3.fromRGB(254, 54, 54);
                Badge.Position = UDim2.fromOffset(24, 4);
                Badge.Text.TextColor3 = Color3.fromRGB(255, 255, 255);
                Badge.Text.TextSize = 12
            end
        end
    end
end

-- this is a function because sometimes chat gets disabled and enabled using setcoreguienabled which breaks
local SetupChat = function()
    -- Buttons
    local Chat = ChatHolder:WaitForChild("chat", 2);
    local Backpack = ChatHolder:FindFirstChild("_Backpack")

    -- Objects
    local ChatDetection = ExperienceChatApp:WaitForChild("topBorder");
    local ChatBackground = ExperienceChatApp:WaitForChild("chatInputBar"):WaitForChild("Background");
    local ChatContainer = ChatBackground:WaitForChild("Container");
    local TextContainer = ChatContainer:WaitForChild("TextContainer");
    local TextBoxContainer = TextContainer:WaitForChild("TextBoxContainer", 1);
    local Badges = Chat and Chat:FindFirstChild("5");
    local ContainerPadding = TextContainer:WaitForChild("UIPadding");

    -- Configuration
    local ChatWindow = TextChatService:WaitForChild("ChatWindowConfiguration");
    local ChatInput = TextChatService:WaitForChild("ChatInputBarConfiguration");
    local ChatWindowMain = ExperienceChatApp:WaitForChild("chatWindow", 3);

    -- Icon Systems
    local ChatIconSystem = AddIconSystem(Chat, UDim2.fromOffset(28, 28));

    -- Backpack
    if (Backpack) then
        Backpack.Position = UDim2.fromOffset(48, 0);
    end

    -- Chat Redesign
    ChatWindow.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
    ChatWindow.BackgroundTransparency = 0.6
    ChatWindow.TextSize = 16
    ChatWindow.TextStrokeTransparency = 0.6
    ChatWindow.HeightScale = 0.85
    ChatWindow.WidthScale = 1.1
    ChatWindow.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    ChatInput.BackgroundColor3 = Color3.fromRGB(209, 216, 221);
    ChatInput.BackgroundTransparency = 0.5
    ChatInput.TextColor3 = Color3.fromRGB(25, 25, 25);
    ChatInput.PlaceholderColor3 = Color3.fromRGB(36, 35, 34);
    ChatInput.TextStrokeTransparency = 1
    ChatInput.TextSize = 16
    ChatInput.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    ExperienceChatApp.Position = UDim2.fromOffset(0, -20);
    ExperienceChatApp.topBorder.Image = "rbxassetid://70944149509141"
    ExperienceChatApp.bottomBorder.Image = "rbxassetid://70944149509141"
    ChatBackground:WaitForChild("Corner").CornerRadius = UDim.new(0, 0);
    ChatContainer:WaitForChild("SendButton").Visible = false
    ExperienceChatApp:WaitForChild("bottomBorder").Size = UDim2.new(1, 0, 0, 4);
    ChatBackground.Position = UDim2.fromOffset(-3, -3);
    ChatBackground.Size = UDim2.new(1, 6, 0, 0);
    ContainerPadding.PaddingTop = UDim.new(0, 5);
    ContainerPadding.PaddingBottom = UDim.new(0, 5);
    ChatBackground.Parent.LayoutOrder = 4

    if (TextBoxContainer) then
        TextBoxContainer.Position = UDim2.fromScale(1, 0);
        TextBoxContainer.Size = UDim2.new(1, -8, 0, 0);
        TextBoxContainer:WaitForChild("TextBox").Position = UDim2.fromOffset(-10, 0)
    end

    if (not ExperienceChatApp:FindFirstChild("Seperator")) then
        Create("Frame", {
            Name = "Seperator",
            Parent = ExperienceChatApp,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(10, 1),
            LayoutOrder = 3,
        })
    end

    if (ChatWindowMain) then
        Spawn(function()
            local DotMenu = ChatWindowMain:WaitForChild("TopBanner", 10000):WaitForChild("DotMenu", 10000)
            DotMenu.Visible = false
            Connect(Changed(DotMenu, "Visible"), function()
                DotMenu.Visible = false
            end)
        end)

        -- update the chat player format (Player1: Message -> [Player1]: Message)
        local BottomLockedScrollView = ChatWindowMain:WaitForChild("scrollingView"):WaitForChild("bottomLockedScrollView");
        local ScrollView = BottomLockedScrollView:WaitForChild("RCTScrollView");
        local Chats = ScrollView:WaitForChild("RCTScrollContentView");
        local Padding = BottomLockedScrollView:WaitForChild("padding", 1);

        local UpdateChatMessage = function(Message)
            local TextMessage = Message and Message:FindFirstChild("TextMessage");

            if (TextMessage) then
                local BodyText = TextMessage:FindFirstChild("BodyText");
                local PrefixText = TextMessage:FindFirstChild("PrefixText");
                local UserId = tonumber(Match(Message.Name, "^(%d+)-"));
                local Player = UserId and Players:GetPlayerByUserId(UserId);
                
                if (UserId and Player) then
                    local AgeGroupDifference = Find(BodyText.Text, "🔒 :")
                    local Prefix = (`<font color="{GetPlayerColor(Player.Name)}">[{Player.Name}]:</font>`);
                    local ToReplace = (AgeGroupDifference and "🔒 :") or `{Player.DisplayName}:`
                    local Body = Replace(BodyText.Text, ToReplace, `[{Player.Name}]:`);

                    PrefixText.Text = Prefix
                    BodyText.Text = Body

                    Connect(Changed(PrefixText, "Text"), function()
                        PrefixText.Text = Prefix
                    end)

                    Connect(Changed(BodyText, "Text"), function()
                        BodyText.Text = Body
                    end)

                    if (AgeGroupDifference) then
                        BodyText.TextColor3 = Color3.fromRGB(250, 255, 158);
                    end
                elseif (UserId == 0 and BodyText and Find(BodyText.Text, "Only people in similar age groups can chat with you") and Configuration.ReplaceAgeGroupMessage) then
                    BodyText.Text = "Chat '/?' or '/help' for a list of chat commands."

                    Connect(Changed(BodyText, "Text"), function()
                        BodyText.Text = "Chat '/?' or '/help' for a list of chat commands."
                    end)
                end
            end
        end

        Connect(Chats.ChildAdded, UpdateChatMessage);
        for _, ChatObject in next, Chats:GetChildren() do
            UpdateChatMessage(ChatObject);
        end

        if (Padding) then
            Padding.PaddingBottom = UDim.new(0, 4);
            Padding.PaddingTop = UDim.new(0, -4);
        end

        if (ScrollView) then
            ScrollView.ScrollBarThickness = 1
        end
    end

    if (Chat) then
        UpdatePosition(Chat, UDim2.fromOffset(4, 0));
    end
    
    -- Connections
    if (Badges) then
        UpdateChatCounter();
        Connect(Badges.ChildAdded, UpdateChatCounter);
        Connect(Badges.ChildRemoved, UpdateChatCounter);
    end

    ChatIconSystem(GetImage("Chat", ChatDetection.Visible));
    Connect(Changed(ChatDetection, "Visible"), function()
        ChatIconSystem(GetImage("Chat", ChatDetection.Visible));
    end)
end

-- this the main function that redesigns the coregui
local Redesign = function()
    -- Buttons
    local Remove = ChatHolder:WaitForChild("nine_dot");
    local BackpackButton = ChatHolder:FindFirstChild("_Backpack") or CreateBackpack();
    local Chat = ChatHolder:WaitForChild("chat", 2);

    -- Other
    local Inventory = RobloxGui:WaitForChild("Backpack"):WaitForChild("Inventory");
    local Menu = RobloxGui:WaitForChild("SettingsClippingShield"):WaitForChild("SettingsShield");

    -- Icon Systems
    local RobloxIconSystem = AddIconSystem(RobloxMenu, UDim2.fromOffset(30, 24));
    local BackpackIconSystem = AddIconSystem(BackpackButton, UDim2.fromOffset(24, 30), function()
        task.wait(0.001); keypress(0xC0); keyrelease(0xC0);
    end);

    -- Background
    ChatHolder.Parent:WaitForChild("2").BackgroundTransparency = 1
    RobloxMenu.BackgroundTransparency = 1

    -- Hide dots
    Remove.Visible = false

    -- Positions
    UnibarMenu.Parent.Position = UDim2.new(1, -40, 0, -6);
    MenuIconHolder.Position = UDim2.new(0, 2, 0, -6);

    -- Chat
    if (Chat) then
        SetupChat();
    else
        BackpackButton.Position = UDim2.fromOffset(4, 0);
    end

    -- Connections
    Connect(Changed(RobloxMenu, "BackgroundTransparency"), function()
        RobloxMenu.BackgroundTransparency = 1
    end)

    Connect(ExperienceChatApp.ChildAdded, function(Object)
        if (Object.Name == "chatWindow") then
            SetupChat();
        end
    end)

    Connect(ChatHolder.ChildRemoved, function(Object)
        if (Object.Name == "chat") then
            BackpackButton.Position = UDim2.fromOffset(4, 0);
        end
    end)

    Connect(Changed(Inventory, "Visible"), function()
        BackpackIconSystem(GetImage("Backpack", Inventory.Visible));
    end)

    Connect(Changed(Menu, "Visible"), function()
        RobloxIconSystem(GetImage("Menu", Menu.Visible));
    end)

    Connect(CoreGui.ChildAdded, function(Object)
        if (Object.Name == "TooltipLayer" and Object:IsA("ScreenGui")) then
            Object.Enabled = false
        end
    end)

    -- Icons
    RobloxIconSystem(GetImage("Menu", Menu.Visible));
    BackpackIconSystem(GetImage("Backpack", Inventory.Visible));
end

-- creates the top right info (account name, account age, health)
local AccountContainer = function(Parent)
    local AccountInfo = Create("ImageButton", {
        Position = UDim2.new(1, -170, 0, 0),
        Size = UDim2.new(0, 170, 0, 35),
        Parent = Parent,
        BackgroundTransparency = 1,
    })

    local HealthContainer = Create("Frame", {
        BackgroundColor3 =  Color3.fromRGB(228, 236, 246),
        Position = UDim2.new(0, 7, 1, -7),
        Size = UDim2.new(1, -14, 0, 3),
        Parent = AccountInfo,
        BorderSizePixel = 0,
    })

    local HealthFill = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(27, 252, 107),
        Size = UDim2.fromScale(1, 1),
        Parent = HealthContainer,
        BorderSizePixel = 0,
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 7, 0, 0),
        Size = UDim2.new(1, -14, 0, 18),
        Parent = AccountInfo,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = LocalPlayer.Name,
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 7, 0, 15),
        Size = UDim2.new(1, -14, 0, 9),
        Parent = AccountInfo,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "Account: <13",
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    })

    local UpdateHealthGui = function(Health: number, MaxHealth: number)
        HealthFill.Size = UDim2.fromScale(Health / 100, 1);

        if (Health < MaxHealth) and (Health > MaxHealth / 2) then
            HealthFill.BackgroundColor3 = Color3.new(1 - (Health / MaxHealth) + 0.5, 1, 0)
        else
            HealthFill.BackgroundColor3 = Color3.fromRGB(27, 252, 107)
        end

        if (Health == MaxHealth / 2) then
            HealthFill.BackgroundColor3 = Color3.new(1, 1, 0)
        end

        if (Health < MaxHealth / 2) then
            HealthFill.BackgroundColor3 = Color3.new(1, (Health/MaxHealth) * 2, 0)
        end 
    end

    local UpdateHealth = function()
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
        local Humanoid = Character:WaitForChild("Humanoid");

        if (Humanoid) then
            UpdateHealthGui(Humanoid.Health, Humanoid.MaxHealth);
            Connect(Changed(Humanoid, "Health"), function()
                UpdateHealthGui(Humanoid.Health, Humanoid.MaxHealth);
            end)
        end
    end

    Spawn(function()
        UpdateHealth();
        Connect(LocalPlayer.CharacterAdded, UpdateHealth);
    end)

    return AccountInfo
end

-- Setup
local TopbarBackground, AccountInfo

if (not Core2016) then
    local CustomScreenGui = Create("ScreenGui", {
        Name = "RobloxGui",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })

    TopbarBackground = Create("Frame", {
        Parent = CustomScreenGui,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Color3.fromRGB(31, 31, 31),
    })

    AccountInfo = AccountContainer(TopbarBackground);
end

getgenv().Core2016 = true
Spawn(Redesign);

if (Configuration.OldGraphics) then
    Lighting.GlobalShadows = false
    
    for _, Object in next, Lighting:GetChildren() do
        if (Discover({ "DepthOfFieldEffect", "SunRaysEffect", "BloomEffect", "BlurEffect", "ColorCorrectionEffect", "Atmosphere" }, Object.ClassName)) then
            Destroy(Object);
        end
    end

    Create("ColorCorrectionEffect", {
        Parent = Lighting,
        Saturation = 0,
        Contrast = -0.1,
    })

    if (sethiddenproperty) then
        sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility);
    end
end

if (Configuration.HideVoiceChatButton) then
    Spawn(function()
        ChatHolder:WaitForChild("toggle_mic_mute", 1000).Visible = false
    end)
end

if (Configuration.OldConsole) then
   loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/projects/refs/heads/main/UI/OldConsole/Source.luau"))();
end

if (Configuration.OldBubbleChat) then
    local BubbleChat = TextChatService:WaitForChild("BubbleChatConfiguration");
    
    BubbleChat.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    BubbleChat.TextSize = 23
    BubbleChat.BackgroundTransparency = 0
    BubbleChat.TextColor3 = Color3.fromRGB(27, 42, 53);
    BubbleChat.BackgroundColor3 = Color3.fromRGB(255, 255, 255);

    Spawn(function()
        local CornerRadius, UIPadding = BubbleChat:FindFirstChild("UICorner") or Create("UICorner", {
            Parent = BubbleChat,
            CornerRadius = UDim.new(0, 4),
        }), BubbleChat:FindFirstChild("UIPadding") or Create("UIPadding", {
            Parent = BubbleChat,
        });

        if (CornerRadius) then
            CornerRadius.CornerRadius = UDim.new(0, 5);
        end

        if (UIPadding) then
            for _, Property in next, ({ "PaddingTop", "PaddingBottom", "PaddingRight", "PaddingLeft" }) do
                UIPadding[Property] = UDim.new(0, 6);
            end
        end
    end)
end

if (Configuration.OldPlayerList) then
    local BuildersClub = ({ "rbxassetid://7038283888", "rbxassetid://7038284499", "rbxassetid://7038285281" });
    local GetSize = function(X: number)
        local Viewport = workspace.CurrentCamera.ViewportSize
        return UDim2.new(0, X, 0, math.clamp(Viewport.Y / 2.5, 250, 416))
    end

    local PlayerListContainer = Create("Frame", {
        Name = "PlayerListContainer",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 1, 5),
        Parent = TopbarBackground,
        Size = GetSize(170),
    })

    local ScrollList = Create("ScrollingFrame", {
        Name = "ScrollList",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = PlayerListContainer,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })

    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 2),
        Parent = ScrollList,
    })

    Connect(RunService.RenderStepped, function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false);
        pcall(function() -- would just disable the coregui for health but then the health change effect wont happen (the red stuff around the screen)
            TopBarApp.UnibarLeftFrame.HealthBar.HealthBar.Visible = false
        end)
    end)

    local AddPlayer = function(Player)
        local Open = false
        local PlayerObject = Create("TextButton", {
            Parent = ScrollList,
            Name = Player.Name,
            BackgroundColor3 = Color3.fromRGB(31, 31, 31),
            BackgroundTransparency = 0.500,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 170, 0, 24),
            AutoButtonColor = false,
            TextSize = 14,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = Player.Name,
        })

        local IgnorePaddingFrame = Create("Frame", {
            Parent = PlayerObject,
            Name = "IgnorePaddingFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
        })

        local Icon = Create("ImageLabel", {
            Parent = IgnorePaddingFrame,
            Name = "Icon",
            BackgroundTransparency = 1.000,
            BorderSizePixel = 0,
            Position = UDim2.new(0, -19, 0.02, 4),
            Size = UDim2.new(0, 16, 0, 16),
        })

        Spawn(function()
            if (Player:IsFriendsWith(LocalPlayer.UserId)) then
                Icon.Image = "rbxasset://textures/ui/icon_friends_16.png"
            elseif (Player.UserId == game.CreatorId) then
                Icon.Image = "rbxasset://textures/ui/icon_placeowner.png"
            elseif (Player.MembershipType == Enum.MembershipType.Premium) then
                Icon.Image = BuildersClub[Random(1, #BuildersClub)]
            end
        end)

        Create("UIPadding", {
            Parent = PlayerObject,
            PaddingLeft = UDim.new(0, 23),
        })

        Connect(PlayerObject.MouseButton1Click, function()
            if (not Open) then
                local Descendants = ScrollList:GetDescendants();

                for _, User in next, Descendants do
                    if (User.Name == "PlayerControlsHolder") then
                        Destroy(User);
                    end
                end

                for _, User in next, Descendants do
                    if (User:IsA("TextButton")) then
                        User.BackgroundColor3 = Color3.fromRGB(31, 31, 31);
                    end
                end

                local PlayerControlsHolder = Create("Frame", {
                    Parent = PlayerObject,
                    Name = "PlayerControlsHolder",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(-1, -25, 0, 0),
                    Visible = true,
                })

                local FriendButton = Create("TextButton", {
                    Parent = PlayerControlsHolder,
                    BackgroundColor3 = Color3.fromRGB(31, 31, 31),
                    BackgroundTransparency = 0.500,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 170, 0, 24),
                    AutoButtonColor = true,
                    TextSize = 14,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Text = "Send a friend request",
                })

                local ReportButton = Create("TextButton", {
                    Parent = PlayerControlsHolder,
                    BackgroundColor3 = Color3.fromRGB(31, 31, 31),
                    BackgroundTransparency = 0.500,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 170, 0, 24),
                    AutoButtonColor = true,
                    TextSize = 14,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Text = "Report abuse",
                })

                Create("UIListLayout", {
                    Parent = PlayerControlsHolder,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 2),
                })
                
                Create("UIPadding", {
                    Parent = FriendButton,
                    PaddingLeft = UDim.new(0, 36),
                })

                Create("UIPadding", {
                    Parent = ReportButton,
                    PaddingLeft = UDim.new(0, 36),
                })

                PlayerObject.BackgroundColor3 = Color3.fromRGB(0, 255, 255)                
                Connect(FriendButton.MouseButton1Click, function()
                    local PlayerControlsHolder = PlayerObject:FindFirstChild("PlayerControlsHolder");
                    LocalPlayer:RequestFriendship(Player);

                    if (PlayerControlsHolder) then
                        Destroy(PlayerControlsHolder);
                        PlayerObject.BackgroundColor3 = Color3.fromRGB(31, 31, 31);
                    end

                    Open = false
                end)
            else
                local PlayerControlsHolder = PlayerObject:FindFirstChild("PlayerControlsHolder");
                PlayerObject.BackgroundColor3 = Color3.fromRGB(31, 31, 31);

                if (PlayerControlsHolder) then
                    Destroy(PlayerControlsHolder);
                end
            end

            Open = (not Open);
            PlayerListContainer.Size = GetSize((Open and 327) or 170);
        end)
    end

    for _, Player in next, Players:GetPlayers() do
        AddPlayer(Player);
    end

    Connect(Players.PlayerAdded, function(Player)
        AddPlayer(Player);
    end)

    Connect(Players.PlayerRemoving, function(Player)
        for _, User in next, ScrollList:GetChildren() do
            if (User.Name == Player.Name) then
                Destroy(User);
            end
        end
    end)

    Connect(UserInputService.InputBegan, function(Input, Processed)
        if (Input.KeyCode == Enum.KeyCode.Tab) then
            PlayerListContainer.Visible = (not PlayerListContainer.Visible);
        end
    end)

    if (AccountInfo) then
        Connect(AccountInfo.MouseButton1Click, function()
            PlayerListContainer.Visible = (not PlayerListContainer.Visible);
        end)
    end
end
