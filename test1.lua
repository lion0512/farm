local Players = game:GetService("Players")
local player = Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local tweenService = game:GetService("TweenService")
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")

local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.Name = "BloxFruitsChestFarm"

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 220, 0, 200)
frame.Position = UDim2.new(0.5, -110, 0.5, -100)
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

local retryLabel = Instance.new("TextLabel")
retryLabel.Parent = frame
retryLabel.Size = UDim2.new(1, 0, 0, 20)
retryLabel.Position = UDim2.new(0, 0, 0, 110)
retryLabel.Text = "Hop Attempts: 0"
retryLabel.BackgroundTransparency = 1
retryLabel.TextColor3 = Color3.new(1, 1, 0)
retryLabel.Font = Enum.Font.SourceSans
retryLabel.TextSize = 11

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Parent = frame
toggleButton.Size = UDim2.new(1, -10, 0, 25)
toggleButton.Position = UDim2.new(0, 5, 0, 135)
toggleButton.Text = "START FARM"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14

-- Speed Cycle Button
local speedButton = Instance.new("TextButton")
speedButton.Parent = frame
speedButton.Size = UDim2.new(1, -10, 0, 25)
speedButton.Position = UDim2.new(0, 5, 0, 165)
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
local hopAttempts = 0
local isHopping = false

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

-- Chest identification
local function getChestId(chest)
    return chest:GetFullName()
end

-- Find all chests
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

-- Find nearest chest
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
        pcall(function()
            fireproximityprompt(prompt)
        end)
        wait(speed.openDelay)
        return true
    end
    
    -- Method 2: ClickDetector
    local clickDetector = chest.Parent and chest.Parent:FindFirstChildOfClass("ClickDetector")
    if not clickDetector then
        clickDetector = chest:FindFirstChildOfClass("ClickDetector")
    end
    if clickDetector then
        pcall(function()
            fireclickdetector(clickDetector)
        end)
        wait(speed.openDelay)
        return true
    end
    
    -- Method 3: Virtual input click
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
        wait(0.05)
        vim:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
    end)
    wait(speed.openDelay)
    return true
end

-- PERSISTENT SERVER HOP WITH INFINITE RETRY
local function attemptServerHop()
    if isHopping then return end
    isHopping = true
    hopAttempts = 0
    local placeId = game.PlaceId
    
    statusLabel.Text = "Status: Searching servers..."
    serverHopLabel.Text = "Server Hop: SEARCHING..."
    
    -- Retry loop: keeps trying until a server is found
    spawn(function()
        local serverFound = false
        
        while not serverFound and farmEnabled do
            hopAttempts = hopAttempts + 1
            retryLabel.Text = "Hop Attempts: " .. hopAttempts
            statusLabel.Text = "Status: Attempt #" .. hopAttempts .. " - Finding server..."
            
            -- Method 1: HTTP request to Roblox API for public servers
            local success, result = pcall(function()
                local response = game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100&sortOrder=Asc")
                return httpService:JSONDecode(response)
            end)
            
            if success and result and result.data and #result.data > 0 then
                -- Filter valid servers (not full, not current)
                local validServers = {}
                for _, server in pairs(result.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(validServers, server.id)
                    end
                end
                
                if #validServers > 0 then
                    local randomServer = validServers[math.random(1, #validServers)]
                    statusLabel.Text = "Status: Server found! Hopping..."
                    serverHopLabel.Text = "Server Hop: HOPPING to " .. randomServer
                    retryLabel.Text = "Hop Attempts: " .. hopAttempts .. " - SUCCESS"
                    serverFound = true
                    
                    -- Teleport to the found server
                    pcall(function()
                        teleportService:TeleportToPlaceInstance(placeId, randomServer)
                    end)
                    
                    -- If TeleportToPlaceInstance fails, try standard teleport
                    if farmEnabled then
                        wait(2)
                        pcall(function()
                            teleportService:Teleport(placeId)
                        end)
                    end
                else
                    statusLabel.Text = "Status: No available servers in batch..."
                    retryLabel.Text = "Hop Attempts: " .. hopAttempts .. " - Retrying in 3s..."
                end
            else
                -- Method 1 failed, use Method 2: Direct teleport (gets new server automatically)
                statusLabel.Text = "Status: API failed, using direct teleport..."
                serverHopLabel.Text = "Server Hop: Direct method"
                serverFound = true
                
                pcall(function()
                    teleportService:Teleport(placeId)
                end)
            end
            
            if not serverFound then
                wait(3) -- Wait before retry
            end
        end
        
        -- If we somehow exited the loop without finding a server
        if not serverFound and farmEnabled then
            statusLabel.Text = "Status: Forcing teleport..."
            serverHopLabel.Text = "Server Hop: FORCE METHOD"
            retryLabel.Text = "Hop Attempts: " .. hopAttempts .. " - FORCE"
            pcall(function()
                teleportService:Teleport(placeId)
            end)
        end
        
        isHopping = false
    end)
end

-- Main farm loop
local function farmLoop()
    while farmEnabled and not isHopping do
        local speed = speedPresets[currentSpeed]
        local allChests = findAllChests()
        totalChestsFound = #allChests
        chestCountLabel.Text = "Chests found: " .. totalChestsFound .. " | Looted: " .. table.maxn(lootedChests)
        
        if #allChests == 0 then
            statusLabel.Text = "Status: All chests looted!"
            chestCountLabel.Text = "Chests found: 0 | Looted: " .. table.maxn(lootedChests)
            
            if serverHopEnabled then
                serverHopLabel.Text = "Server Hop: Triggered!"
                attemptServerHop()
                -- Wait for server hop to complete
                while isHopping and farmEnabled do
                    wait(1)
                end
            else
                serverHopLabel.Text = "Server Hop: OFF (enable first)"
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
                chestCountLabel.Text = "Chests found: " .. #allChests .. " | Looted: " .. table.maxn(lootedChests)
                
                -- Auto collect nearby drops
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local root = character.HumanoidRootPart
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled then
                            local dist = (root.Position - obj.Parent.Position).Magnitude
                            if dist < 15 then
                                pcall(function()
                                    fireproximityprompt(obj)
                                end)
                            end
                        end
                    end
                end
                
                statusLabel.Text = "Status: Done! Next..."
                wait(speed.scanInterval * 0.3)
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
        serverHopEnabled = true
        serverHopLabel.Text = "Server Hop: ON (auto)"
        spawn(farmLoop)
    else
        toggleButton.Text = "START FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "Status: OFF"
        serverHopEnabled = false
        serverHopLabel.Text = "Server Hop: OFF"
        isHopping = false
    end
end)

-- Speed cycle button
speedButton.MouseButton1Click:Connect(function()
    currentSpeed = currentSpeed % #speedPresets + 1
    local preset = speedPresets[currentSpeed]
    speedButton.Text = "Speed: " .. preset.name
    speedLabel.Text = "Loot Speed: " .. preset.name
    
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

-- Periodic cleanup of looted list (chests respawn every ~4-5 minutes in Blox Fruits)
spawn(function()
    while true do
        wait(300)
        if farmEnabled then
            lootedChests = {}
            statusLabel.Text = "Status: Reset looted list (respawn)"
        end
    end
end)