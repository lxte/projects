if (not game:IsLoaded()) then
	game.Loaded:Wait();
end

-- Services
local Workspace = (workspace);
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TeleportService = game:GetService("TeleportService");

-- Variables
local Equip = ReplicatedStorage:WaitForChild("GetEquipped", 5);

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local Humanoid = Character:WaitForChild("Humanoid", 5);
local RootPart = Humanoid.RootPart

-- Init
Equip:InvokeServer("Default");

repeat
  task.wait();
until Humanoid.Sit

local SeatPart = (Humanoid.SeatPart);
local Cart = SeatPart and SeatPart:FindFirstAncestorOfClass("Model");

if (Cart) then
  for _ = 1, 10 do
    task.wait(0.1);
    Cart:PivotTo(CFrame.new(-587.462341, -210.403809, 2842.21436));
  end
end

TeleportService:Teleport(game.PlaceId, LocalPlayer);
