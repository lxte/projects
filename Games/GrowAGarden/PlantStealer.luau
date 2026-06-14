-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Variables
local Plots = Workspace.Gardens
local LocalPlayer = Players.LocalPlayer

-- Modules
local Networking = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
local FruitValueCalc = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("FruitValueCalc"))

-- Functions
-- << Player >> --
local GetHumanoid = function(Player)
    local Character = Player.Character
    return (Character and Character:FindFirstChildOfClass("Humanoid"))
end

local GetRoot = function(Player)
    local Humanoid = GetHumanoid(Player)
    return (Humanoid and Humanoid.RootPart)
end

local GetPlot = function(Player)
    for _, Plot in next, Plots:GetChildren() do
        if (Plot:GetAttribute("OwnerUserId") == Player.UserId) then
            return Plot
        end
    end
end

local PlotUnlocked = function(Player)
    local Plot = GetPlot(Player)
    local Area = Plot and Plot:FindFirstChild("Visual"):FindFirstChild("PlotSizeReferenceVisual")
    local Unlocked = true

    for _, Touching in next, Workspace:GetPartBoundsInBox(Area.CFrame, Area.Size) do
        if (Touching:IsDescendantOf(Player.Character)) then
            Unlocked = false
            break
        end
    end

    return Unlocked
end

-- << Steal >> --
-- this isnt that accurate still finding something better
local CalculateValue = function(Fruit)
    local FruitName = Fruit:GetAttribute("CorePartName") or Fruit:GetAttribute("PlantName")
    local SizeMultiplier = Fruit:GetAttribute("SizeMulti") or Fruit:GetAttribute("Age")
    local Mutation = Fruit:GetAttribute("Mutation")
    return FruitValueCalc(FruitName, SizeMultiplier, Mutation, LocalPlayer, 1)
end

local GetValuable = function()
    local Value = 0
    local Item = nil

    for _, Plot in next, Plots:GetChildren() do
        local Owner = Players:GetPlayerByUserId(Plot:GetAttribute("OwnerUserId") or LocalPlayer.UserId)
        local Humanoid = Owner and GetHumanoid(Owner)

        if (not Owner or Owner == LocalPlayer) then
            continue
        end

        if (Humanoid and Humanoid.Sit) then
            continue
        end

        for _, Plant in next, Plot.Plants:GetChildren() do
            local Fruits = Plant:FindFirstChild("Fruits")
            local Found = ({})

            if (Fruits) then
                for _, Fruit in next, Fruits:GetChildren() do
                    local HarvestPart = Fruit:FindFirstChild("HarvestPart")
                    local StealPrompt = HarvestPart and HarvestPart:FindFirstChild("StealPrompt")

                    if (not StealPrompt) then
                        continue
                    end

                    Found[Fruit] = CalculateValue(Fruit)
                end
            else
                local HarvestPart = Plant:FindFirstChild("HarvestPart")
                local StealPrompt = HarvestPart and HarvestPart:FindFirstChild("StealPrompt")

                if (not StealPrompt) then -- or Plant:GetAttribute("SeedName") == "Bamboo" || nvm they enabled bamboo stealing
                    continue
                end

                Found[Plant] = CalculateValue(Plant)
            end

            for Fruit, FruitValue in next, Found do
                if (FruitValue > Value) then
                    Value = FruitValue
                    Item = Fruit
                end
            end
        end
    end

    return Item, Value
end

local Fling = function(Player)
    -- improve the fling
	local Flinging = true
    local Root = GetRoot(LocalPlayer)
    local Humanoid = GetHumanoid(LocalPlayer)
	local OldPosition = Root.CFrame

	task.spawn(function()
		local Movel = 0.1
        local Velocity = Root.Velocity

		repeat task.wait()
			Velocity = Root.Velocity
			Root.Velocity = Velocity * 10000 + Vector3.new(0, 10000, 0)
			RunService.RenderStepped:Wait()
			Root.Velocity = Velocity
			RunService.Stepped:Wait()
			Root.Velocity = Velocity + Vector3.new(0, Movel, 0)
			Movel = (Movel * -1)
		until (not Flinging)
	end)

    local _Humanoid = GetHumanoid(Player);
    local _Root = GetRoot(Player);
    local Start = tick();

    if (_Humanoid and _Root) then
        repeat task.wait()
            local Success, _Result = pcall(function()
                sethiddenproperty(Root, "PhysicsRepRootPart", _Root);
            end)

            local Magnitude = _Root.Velocity.Magnitude
            local Direction = (_Humanoid and _Humanoid.MoveDirection) or Vector3.zero
            local PredictionOffset

            if (Magnitude < 5 or Success) then
                PredictionOffset = Vector3.new(0, math.random(-0.5, 0.4), 0);
            else
                PredictionOffset = Direction * (Magnitude / Random.new():NextNumber(0.7, 8)) - Vector3.new(0, math.random(-1, 1), 0);
            end

            local TargetCFrame = CFrame.new(_Root.Position);
            local PredictedCFrame = TargetCFrame * CFrame.new(PredictionOffset);

            Humanoid.Sit = false
            Workspace.CurrentCamera.CameraSubject = _Humanoid
            Root.CFrame = PredictedCFrame * CFrame.Angles(math.random(0, 360), 0, 0)
        until (tick() - Start >= 2) or (_Root.Velocity.Magnitude > 200) or (not Root) or (not Root.Parent) or (not _Root) or (not _Root.Parent)
    end

	Flinging = false
	Root.CFrame = OldPosition
	Workspace.CurrentCamera.CameraSubject = Humanoid

	pcall(function()
		sethiddenproperty(Root, "PhysicsRepRootPart", nil);
	end)
end

local ReturnToPlot = function()
    for Index = 1, 10 do
        local Root = GetRoot(LocalPlayer)

        if (Root) then
            Root.CFrame = GetPlot(LocalPlayer).PlotSizeReference.CFrame        
            task.wait(0.05)
        end
    end
end

local NightTime = function()
    local Night = ReplicatedStorage:FindFirstChild("Night")
    return Night.Value
end

local Steal = function(Fruit, Return)
    if (not NightTime()) then
        return
    end

    local HarvestPart = Fruit:FindFirstChild("HarvestPart")
    local StealPrompt = HarvestPart and HarvestPart:FindFirstChild("StealPrompt")

    if (StealPrompt) then
        local UserId = tonumber(Fruit:GetAttribute("UserId"))
        local PlantId = Fruit:GetAttribute("PlantId")
        local FruitId = Fruit:GetAttribute("FruitId")
        local Owner = Players:GetPlayerByUserId(UserId)

        if (not PlotUnlocked(Owner)) then
            Fling(Owner)
        end

        for Index = 1, 2 do
            local Root = GetRoot(LocalPlayer)

            if (Root) then
                Root.CFrame = HarvestPart.CFrame
                Networking.Steal.BeginSteal:Fire(UserId, PlantId, FruitId or "")
                Networking.Steal.CompleteSteal:Fire()
                task.wait(0.05)
            end
        end

        if (Return) then
            ReturnToPlot()
        end
    end
end

-- Setup
local Mode = "None"

-- this is just for testing because click to steal is pretty useless
if (Mode == "Click") then
    local Old = getgenv().MouseConnection
    local Mouse = LocalPlayer:GetMouse()

    local Filter = ({}) do
        for _, Plot in next, Plots:GetChildren() do
            local Visual = Plot:FindFirstChild("Visual")
            local GardenZoneArea = Visual and Visual:FindFirstChild("GardenZoneArea")
            local GardenZonePart = Visual and Visual:FindFirstChild("GardenZonePart")
            local PlotSizeReferenceVisual = Visual and Visual:FindFirstChild("PlotSizeReferenceVisual")
            local PlotSizeReference = Plot:FindFirstChild("PlotSizeReference")

            pcall(table.insert, Filter, GardenZoneArea)
            pcall(table.insert, Filter, PlotSizeReferenceVisual)
            pcall(table.insert, Filter, PlotSizeReference)
            pcall(table.insert, Filter, GardenZonePart)
        end
    end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = Filter

    if (Old and Old.Connected) then
        Old:Disconnect()
    end

    getgenv().MouseConnection = Mouse.Button1Down:Connect(function()
        local Result = Workspace:Raycast(Mouse.UnitRay.Origin, Mouse.UnitRay.Direction * 1000, Params)
    
        if (not Result or not Result.Instance) then
            return
        end

        print(Result.Instance)

        local Plant = Result.Instance:FindFirstAncestorOfClass("Model")

        if (Plant) then
            Steal(Plant, true)
        end
    end)
else
    repeat
        for Index = 1, 50 do
            local Valuable = GetValuable()
            Steal(Valuable)
        end

        ReturnToPlot()
    until (not NightTime())
end
