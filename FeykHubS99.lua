-- Feyk x ChatGPT | Item & Kid ESP with Full UI Control

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 🖼️ UI Base
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "FeykESP_UI"
gui.ResetOnSpawn = false

-- 🔘 Button Creator
local function createButton(name, pos, text, callback)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 130, 0, 30)
	btn.Position = pos
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = text
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.Draggable = true
	btn.AutoButtonColor = false
	btn.Active = true
	btn.Parent = gui
	btn.MouseButton1Click:Connect(function() callback(btn) end)
	return btn
end

-- 🔍 ESP Data
local ESPColor = Color3.fromRGB(255, 255, 255)
local itemFolder = workspace:FindFirstChild("Items") or workspace:FindFirstChild("items")
local kidsFolder = workspace:FindFirstChild("MissingKids")

local allowedItems = {
	["Bolt"] = true,
	["Broken Fan"] = true,
	["Broken Microwave"] = true,
	["Coal"] = true,
	["Fuel Canister"] = true,
	["Item Chest"] = true,
	["Item Chest2"] = true,
	["Old Radio"] = true,
	["Sheet Metal"] = true,
	["Tyre"] = true,
    ["Bandage"] = true
}

local espModels = {}
local kidsESPObjects = {}
local ESPEnabled = false
local KidsESPEnabled = false

-- 📦 ESP Creator
function addESP(model, tableRef)
	if tableRef[model] then return end
	if not model:IsA("Model") and not model:IsA("Part") then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "_ESP_Highlight"
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.FillTransparency = 0.3
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0
	highlight.Adornee = model
	highlight.Enabled = true
	highlight.Parent = model

	local label = Drawing.new("Text")
	label.Visible = false
	label.Center = true
	label.Outline = true
	label.Font = 2
	label.Size = 13
	label.Color = Color3.new(1, 1, 1)
	label.Transparency = 0.5
	label.Text = model.Name

	tableRef[model] = {
		highlight = highlight,
		label = label
	}
end

-- 🧽 ESP Remover
function removeESP(model, tableRef)
	local data = tableRef[model]
	if data then
		if data.highlight then data.highlight:Destroy() end
		if data.label then data.label:Remove() end
		tableRef[model] = nil
	end
end

-- 🔘 Toggle Buttons
createButton("ItemsESP", UDim2.new(0, 10, 0, 20), "ESP: OFF", function(btn)
	ESPEnabled = not ESPEnabled
	btn.Text = "ESP: " .. (ESPEnabled and "ON" or "OFF")
	for model, data in pairs(espModels) do
		if data.highlight then data.highlight.Enabled = ESPEnabled end
	end
end)

createButton("KidsESP", UDim2.new(0, 10, 0, 60), "Kids ESP: OFF", function(btn)
	KidsESPEnabled = not KidsESPEnabled
	btn.Text = "Kids ESP: " .. (KidsESPEnabled and "ON" or "OFF")
	for model, data in pairs(kidsESPObjects) do
		if data.highlight then data.highlight.Enabled = KidsESPEnabled end
	end
end)

-- 👶 Kids ESP from Attributes
function updateKidsESP()
	if not kidsFolder then return end

	-- Cleanup
	for _, data in pairs(kidsESPObjects) do
		if data.part then data.part:Destroy() end
		if data.label then data.label:Remove() end
	end
	kidsESPObjects = {}

	-- Rebuild
	for attrName, attrValue in pairs(kidsFolder:GetAttributes()) do
		if typeof(attrValue) == "Vector3" then
			local part = Instance.new("Part")
			part.Size = Vector3.new(1, 1, 1)
			part.Anchored = true
			part.Transparency = 1
			part.CanCollide = false
			part.Position = attrValue
			part.Name = attrName
			part.Parent = workspace

			addESP(part, kidsESPObjects)
			kidsESPObjects[part].part = part
			kidsESPObjects[part].label.Text = attrName
		end
	end
end

-- 🔄 Fast ESP Refresh
task.spawn(function()
	while true do
		if ESPEnabled and itemFolder then
			for _, model in pairs(itemFolder:GetChildren()) do
				if model:IsA("Model") and allowedItems[model.Name] then
					if not espModels[model] then
						addESP(model, espModels)
					elseif espModels[model].highlight then
						espModels[model].highlight.Enabled = true
					end
				end
			end
		end

		if KidsESPEnabled and kidsFolder then
			updateKidsESP()
		end

		-- Cleanup
		for model in pairs(espModels) do
			if not model:IsDescendantOf(workspace) then
				removeESP(model, espModels)
			end
		end
		for model in pairs(kidsESPObjects) do
			if not model:IsDescendantOf(workspace) then
				removeESP(model, kidsESPObjects)
			end
		end

		wait(2)
	end
end)

-- 🖍️ Draw ESP Labels
RunService.RenderStepped:Connect(function()
	for model, data in pairs(espModels) do
		if ESPEnabled and model and model:IsA("Model") and model.PrimaryPart then
			local pos, onScreen = Camera:WorldToViewportPoint(model.PrimaryPart.Position)
			data.label.Visible = onScreen
			if onScreen then
				data.label.Position = Vector2.new(pos.X, pos.Y - 20)
			end
		else
			if data.label then data.label.Visible = false end
		end
	end

	for model, data in pairs(kidsESPObjects) do 
		if KidsESPEnabled and model and model:IsA("Part") then
			local pos, onScreen = Camera:WorldToViewportPoint(model.Position)
			data.label.Visible = onScreen
			if onScreen then
				data.label.Position = Vector2.new(pos.X, pos.Y - 20)
			end
		else
			if data.label then data.label.Visible = false end
		end
	end
end)