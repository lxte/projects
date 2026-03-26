<div align="center">
<h1>Notification Library</h1>
<h3>A UI library for Roblox with only one purpose - to send custom notifications</h3>
</div>

```lua
local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/projects/refs/heads/main/UI/NotificationLibrary/Source.luau"))()
local NotificationHandler = NotificationLibrary:New({
	BackgroundColor = Color3.fromRGB(68, 71, 0), -- background color of the notification
	-- TitleColor = Color3.fromRGB(), -- title text color
	-- DescriptionColor = Color3.fromRGB(), -- description text color
	-- Mode = "Light", -- either "Dark" or "Light" | very important to set this so it looks better
	VerticalPosition = "Top", -- either "Top" or "Bottom"
	HorizontalPosition = "Right", -- either "Right" or "Left"
})

for Index = 1, 10 do
	NotificationHandler:Create({
		Title = "Title",
		Description = "Very very important description",
		Duration = 3,
		Image = "rbxassetid://11113512609",
	})

	task.wait()
end
```
<div align="center">
<img width="683" height="779" alt="image" src="https://github.com/user-attachments/assets/494ee183-6376-48d9-b1f8-e6ebe4e52606" />
</div>
