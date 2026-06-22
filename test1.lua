local Players = game:GetService("Players")
local player = Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local tweenService = game:GetService("TweenService")
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")

-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.Name = "BloxFruitsChestFarm"

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 220, 0, 180)
frame.Position = UDim2.new(0.5, -110, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 25)
title.Text = "Auto Chest Farm + Server Hop"
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 12

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = frame
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 30)
statusLabel.Text = "Status: OFF"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 11

local chestCountLabel = Instance.new("TextLabel")
chestCountLabel.Parent = frame
chestCountLabel.Size = UDim2.new(1, 0, 0, 20)
chestCountLabel.Position = UDim2.new(0, 0, 0, 50)
chestCountLabel.Text = "Chests found: 0 | Looted: 0"
chestCountLabel.BackgroundTransparency = 1
chestCountLabel.TextColor3 = Color3.new(1, 1, 1)
chestCountLabel.Font = Enum.Font.SourceSans
chestCountLabel.TextSize = 11

local speedLabel = Instance.new("TextLabel")
speedLabel.Parent = frame
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 0, 0, 70)
speedLabel.Text = "Loot Speed: FAST"
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.new(0, 255, 0)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 11

local serverHopLabel = Instance.new("TextLabel")
serverHopLabel.Parent = frame
serverHopLabel.Size = UDim2.new(1, 0, 0, 20)
serverHopLabel.Position = UDim2.new(0, 0, 0, 90)
serverHopLabel.Text = "Server Hop: OFF"
serverHopLabel.BackgroundTransparency = 1
serverHopLabel.TextColor3 = Color3.new(1, 1, 1)
serverHopLabel.Font = Enum.Font.SourceSans
serverHopLabel.TextSize = 11

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Parent = frame
toggleButton.Size = UDim2.new(1, -10, 0, 25)
toggleButton.Position = UDim2.new(0, 5, 0, 115)
toggleButton.Text = "START FARM"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14

-- Speed Cycle Button
local speedButton = Instance.new("TextButton")
speedButton.Parent = frame
speedButton.Size = UDim2.new(1, -10, 0, 25)
speedButton.Position = UDim2.new(0, 5, 0, 145)
speedButton.Text = "Speed: FAST"
speedButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
speedButton.TextColor3 = Color3.new(1, 1, 1)
speedButton.Font = Enum.Font.SourceSans
speedButton.TextSize = 12

-- Configuration
local farmEnabled = false
local serverHopEnabled = false
local lootedChests = {}
local totalChestsFound = 0

-- Speed presets (teleport delay, open delay, collect delay, scan interval) in seconds
local speedPresets = {
    {name = "SLOW", teleportDelay = 1.0, openDelay = 0.5, collectDelay = 2.0, scanInterval = 5.0},
    {name = "NORMAL", teleportDelay = 0.5, openDelay = 0.3, collectDelay = 1.0, scanInterval = 3.0},
    {name = "FAST", teleportDelay = 0.2, openDelay = 0.1, collectDelay = 0.5, scanInterval = 1.5},
    {name = "INSANE", teleportDelay = 0.05, openDelay = 0.05, collectDelay = 0.2, scanInterval = 0.8}
}
local currentSpeed = 3 -- Default: FAST

-- Chest keywords for Blox Fruits
local chestKeywords = {"chest", "goldenchest", "silverchest", "bronzechest", "treasurechest", "devilfruit"}

-- Chest identification (unique ID per chest)
local function getChestId(chest)
    return chest:GetFullName()
end

-- Find all chests on the map
local function findAllChests()
    local chests = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        local name = string.lower(obj.Name)
        local isChest = false
        for _, keyword in pairs(chestKeywords) do
            if string.find(name, keyword) then
                isChest = true
                break
            end
        end
        
        if isChest then
            if obj:IsA("BasePart") and obj.Transparency < 1 and obj.Parent then
                local id = getChestId(obj)
                if not lootedChests[id] then
                    table.insert(chests, obj)
                end
            elseif obj:IsA("Model") then
                local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primaryPart then
                    local id = getChestId(obj)
                    if not lootedChests[id] then
                        table.insert(chests, primaryPart)
                    end
                end
            end
        end
        
        -- ProximityPrompt chests
        if obj:IsA("ProximityPrompt") then
            local parentName = string.lower(obj.Parent.Name)
            for _, keyword in pairs(chestKeywords) do
                if string.find(parentName, keyword) then
                    local chestPart = obj.Parent:FindFirstChildWhichIsA("BasePart") or obj.Parent
                    if chestPart and chestPart:IsA("BasePart") then
                        local id = getChestId(chestPart)
                        if not lootedChests[id] then
                            table.insert(chests, chestPart)
                        end
                    end
                    break
                end
            end
        end
    end
    return chests
end

-- Find nearest chest from list
local function findNearestChest(chests)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local root = character.HumanoidRootPart
    local nearest = nil
    local shortestDistance = math.huge
    
    for _, chest in pairs(chests) do
        if chest and chest.Parent then
            local distance = (root.Position - chest.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearest = chest
            end
        end
    end
    return nearest
end

-- Fast teleport
local function teleportTo(part)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    local root = character.HumanoidRootPart
    local speed = speedPresets[currentSpeed]
    
    local targetPos = part.Position + Vector3.new(0, 3, 0)
    local tweenInfo = TweenInfo.new(speed.teleportDelay, Enum.EasingStyle.Linear)
    local tween = tweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
    return true
end

-- Fast chest opening
local function openChest(chest)
    local speed = speedPresets[currentSpeed]
    
    -- Method 1: ProximityPrompt
    local prompt = chest.Parent and chest.Parent:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = chest:FindFirstChildOfClass("ProximityPrompt")
    end
    if prompt then
        fireproximityprompt(prompt)
        wait(speed.openDelay)
        return true
    end
    
    -- Method 2: ClickDetector
    local clickDetector = chest.Parent and chest.Parent:FindFirstChildOfClass("ClickDetector")
    if not clickDetector then
        clickDetector = chest:FindFirstChildOfClass("ClickDetector")
    end
    if clickDetector then
        fireclickdetector(clickDetector)
        wait(speed.openDelay)
        return true
    end
    
    -- Method 3: Virtual click
    local vim = game:GetService("VirtualInputManager")
    vim:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
    wait(0.05)
    vim:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
    wait(speed.openDelay)
    return true
end

-- Server hop function
local function serverHop()
    statusLabel.Text = "Status: Hopping server..."
    serverHopLabel.Text = "Server Hop: HOPPING..."
    
    -- Method 1: Teleport to same place (new server)
    local placeId = game.PlaceId
    local servers = {}
    pcall(function()
        local httpRequest = httpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100"))
        for _, server in pairs(httpRequest.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end)
    
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        teleportService:TeleportToPlaceInstance(placeId, randomServer)
    else
        -- Method 2: Just rejoin same game (gets new server usually)
        teleportService:Teleport(placeId)
    end
end

-- Main farm loop
local function farmLoop()
    while farmEnabled do
        local speed = speedPresets[currentSpeed]
        local allChests = findAllChests()
        totalChestsFound = #allChests
        chestCountLabel.Text = "Chests found: " .. totalChestsFound .. " | Looted: " .. #lootedChests
        
        if #allChests == 0 then
            statusLabel.Text = "Status: All chests looted!"
            chestCountLabel.Text = "Chests found: 0 | Looted: " .. #lootedChests
            
            if serverHopEnabled then
                serverHopLabel.Text = "Server Hop: All looted - Hopping!"
                wait(1)
                serverHop()
                return
            else
                serverHopLabel.Text = "Server Hop: Enable for auto-hop"
                wait(speed.scanInterval)
            end
        else
            local nearest = findNearestChest(allChests)
            if nearest then
                local chestId = getChestId(nearest.Parent or nearest)
                statusLabel.Text = "Status: TP to " .. nearest.Name
                teleportTo(nearest)
                
                statusLabel.Text = "Status: Opening " .. nearest.Name
                openChest(nearest)
                
                wait(speed.collectDelay)
                
                -- Mark as looted
                lootedChests[chestId] = true
                chestCountLabel.Text = "Chests found: " .. #allChests .. " | Looted: " .. #lootedChests
                
                -- Auto collect any drops using ProximityPrompts
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local root = character.HumanoidRootPart
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled then
                            local dist = (root.Position - obj.Parent.Position).Magnitude
                            if dist < 15 then
                                fireproximityprompt(obj)
                            end
                        end
                    end
                end
                
                statusLabel.Text = "Status: Done! Next..."
                wait(speed.scanInterval * 0.3) -- Short wait before next
            else
                wait(speed.scanInterval)
            end
        end
    end
end

-- Toggle farm
toggleButton.MouseButton1Click:Connect(function()
    farmEnabled = not farmEnabled
    if farmEnabled then
        toggleButton.Text = "STOP FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        statusLabel.Text = "Status: Farming started!"
        serverHopEnabled = true -- Auto-enable server hop
        serverHopLabel.Text = "Server Hop: ON (auto)"
        spawn(farmLoop)
    else
        toggleButton.Text = "START FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "Status: OFF"
        serverHopEnabled = false
        serverHopLabel.Text = "Server Hop: OFF"
    end
end)

-- Speed cycle button
speedButton.MouseButton1Click:Connect(function()
    currentSpeed = currentSpeed % #speedPresets + 1
    local preset = speedPresets[currentSpeed]
    speedButton.Text = "Speed: " .. preset.name
    speedLabel.Text = "Loot Speed: " .. preset.name
    
    -- Color code the speed
    if preset.name == "SLOW" then
        speedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif preset.name == "NORMAL" then
        speedLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    elseif preset.name == "FAST" then
        speedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif preset.name == "INSANE" then
        speedLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Reset looted list on character respawn
player.CharacterAdded:Connect(function()
    -- Optional: clear looted list on death (so chests can be re-looted if they respawn)
    -- lootedChests = {}
end)

-- Periodic cleanup of looted list (chests respawn every ~4-5 minutes in Blox Fruits)
spawn(function()
    while true do
        wait(300) -- 5 minutes
        if farmEnabled then
            lootedChests = {} -- Clear so respawned chests are found again
            statusLabel.Text = "Status: Reset looted list (chests respawned)"
        end
    end
end)