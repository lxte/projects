if (not game:IsLoaded()) then
	game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TestService = game:GetService("TestService")

-- Variables
local Scanned = ({})
local ScanData = ({})
local Malicious = 0
local LastCount = 0
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Notification
local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/projects/refs/heads/main/UI/NotificationLibrary/Source.luau"))()
local NotificationHandler = NotificationLibrary:New({
	VerticalPosition = "Top",
	HorizontalPosition = "Right",
})

-- Functions
local CheckUsers = function(UserIds: {number}) 
	local Success, Response = pcall(function()
		return game:HttpPost("https://roscoe.rotector.com/v1/lookup/roblox/user", HttpService:JSONEncode({ ids = UserIds }), "application/json")
	end)   

	if (not Success) then
		return warn("Failed to load data", Response)
	end

	return HttpService:JSONDecode(Response).data
end

local GetUsers = function()
	local Scan = ({})

	for _, User in next, Players:GetPlayers() do
		if (not table.find(Scanned, User.UserId) and User ~= LocalPlayer) then
			table.insert(Scan, User.UserId)
		end
	end

	return Scan
end

local GetReasons = function(Data)
	local Concat = ({})

	for Reason, Data in next, Data.reasons do
		table.insert(Concat, Reason)
	end

	return table.concat(Concat, ", ")
end

local UpdateCharacter = function(User: Player, Data)
	local Character = User.Character
	local LocalCharacter = LocalPlayer.Character

	if (Character) then
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		local LocalHumanoid = LocalCharacter and LocalCharacter:FindFirstChildOfClass("Humanoid")
		local Highlight = Instance.new("Highlight", Character)

		Highlight.OutlineColor = Color3.new(255, 255, 255)
		Highlight.OutlineTransparency = 0
		Highlight.FillTransparency = 0.95
		Highlight.FillColor = Color3.new(255, 0, 0)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded

		if (Humanoid) then
			Humanoid.DisplayName = `{ User.DisplayName }\n(Flagged for { GetReasons(Data) })`
			Humanoid.NameDisplayDistance = 100
			Humanoid.HealthDisplayDistance = 100
			Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject

			if (LocalHumanoid) then
				LocalHumanoid.NameDisplayDistance = 100
				LocalHumanoid.HealthDisplayDistance = 100
				LocalHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
			end
		end
	end
end

local SendNotification = function(Title: string, Text: string, Icon: string, Duration: number)
	NotificationHandler:Create({
		Title = Title,
		Description = Text,
		Duration = Duration,
		Image = Icon,
	})
end

local UpdatePlayer = function(UserId: number, Data)
	local User = Players:GetPlayerByUserId(UserId)
	local Name = `{ User.DisplayName } (@{ User.Name })`

	if (Data.flagType ~= 0 and Data.reasons) then
		UpdateCharacter(User, Data)
		SendNotification(Name, GetReasons(Data), Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100), 20)

		warn(Name, HttpService:JSONEncode(Data))
		ScanData[UserId] = Data
		Malicious += 1
		User.CharacterAdded:Connect(function()
			UpdateCharacter(User, Data)
		end)
	end

	table.insert(Scanned, UserId)
end

-- Setup
-- >> Main << --
for UserId, Data in next, CheckUsers(GetUsers()) or ({}) do
	local Success, Result = pcall(UpdatePlayer, UserId, Data)

	if (not Success) then
		warn(Result, debug.traceback())
	end
end

if (Malicious > 0) then
	TestService:Message(`Malicious: { Malicious } / { #Scanned }`)
	LastCount = Malicious
end

SendNotification("Scanned", `Click on players that are flagged to see their activities ({ Malicious }/{ #Scanned } flagged)`, nil, 10)

-- >> Connections << --
Mouse.Button1Down:Connect(function()
	local Target = Mouse.Target

	if (Target) then
		local User = Players:GetPlayerFromCharacter(Target:FindFirstAncestorOfClass("Model"))
		local UserData = User and ScanData[tostring(User.UserId)]

		if (UserData) then
			for Name, Data in next, UserData.reasons do
				SendNotification(Name, Data.message, Players:GetUserThumbnailAsync(User.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100), 20)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(User)
	local Result = CheckUsers({ User.UserId })[1]

	if (Result) then
		UpdatePlayer(User.UserId, Result)
	end

	if (Malicious > 0 and LastCount ~= Malicious) then
		TestService:Message(`Malicious: { Malicious } / { #Scanned }`)
	end
end)

Players.PlayerRemoving:Connect(function(User)
	if (ScanData[User.UserId]) then
		ScanData[User.UserId] = nil
	end
end)
