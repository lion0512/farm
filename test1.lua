local Players = game:GetService("Players")
local player = Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local tweenService = game:GetService("TweenService")
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.Name = "BloxFruitsChestFarm"

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 240, 0, 220)
frame.Position = UDim2.new(0.5, -120, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 25)
title.Text = "Auto Chest Farm v2"
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 13

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
chestCountLabel.Text = "Chests: 0 found | 0 looted"
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
speedLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 11

-- Toggle farm button
local toggleButton = Instance.new("TextButton")
toggleButton.Parent = frame
toggleButton.Size = UDim2.new(1, -10, 0, 25)
toggleButton.Position = UDim2.new(0, 5, 0, 95)
toggleButton.Text = "START FARM"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14

local speedButton = Instance.new("TextButton")
speedButton.Parent = frame
speedButton.Size = UDim2.new(1, -10, 0, 25)
speedButton.Position = UDim2.new(0, 5, 0, 125)
speedButton.Text = "Speed: FAST"
speedButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
speedButton.TextColor3 = Color3.new(1, 1, 1)
speedButton.Font = Enum.Font.SourceSans
speedButton.TextSize = 12

local serverHopButton = Instance.new("TextButton")
serverHopButton.Parent = frame
serverHopButton.Size = UDim2.new(1, -10, 0, 25)
serverHopButton.Position = UDim2.new(0, 5, 0, 155)
serverHopButton.Text = "SERVER HOP (Low Players)"
serverHopButton.BackgroundColor3 = Color3.fromRGB(70, 70, 200)
serverHopButton.TextColor3 = Color3.new(1, 1, 1)
serverHopButton.Font = Enum.Font.SourceSansBold
serverHopButton.TextSize = 12

local hopStatusLabel = Instance.new("TextLabel")
hopStatusLabel.Parent = frame
hopStatusLabel.Size = UDim2.new(1, 0, 0, 30)
hopStatusLabel.Position = UDim2.new(0, 0, 0, 185)
hopStatusLabel.Text = "Server Hop: Ready"
hopStatusLabel.BackgroundTransparency = 1
hopStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
hopStatusLabel.Font = Enum.Font.SourceSans
hopStatusLabel.TextSize = 10

local farmEnabled = false
local lootedChests = {}

-- Speed presets
local speedPresets = {
    {name = "SLOW", teleportDelay = 1.0, openDelay = 0.5, collectDelay = 2.0, scanInterval = 5.0},
    {name = "NORMAL", teleportDelay = 0.5, openDelay = 0.3, collectDelay = 1.0, scanInterval = 3.0},
    {name = "FAST", teleportDelay = 0.2, openDelay = 0.1, collectDelay = 0.5, scanInterval = 1.5},
    {name = "INSANE", teleportDelay = 0.05, openDelay = 0.05, collectDelay = 0.2, scanInterval = 0.8}
}
local currentSpeed = 3

-- CHEST DETECTION: Comprehensive list of chest types in Blox Fruits
local chestNames = {
    "chest", "goldenchest", "silverchest", "bronzechest", "treasurechest",
    "devilfruit", "darkchest", "legendarychest", "mythicalchest", "godchest",
    "commonchest", "rarechest", "epicchest", "piratechest", "marinechest",
    "barrel", "crate", "box", "present", "gift", "loot", "drop",
    "treasure", "reward", "supply", "cache", "hoard", "stash",
    "goldchest", "diamondchest", "crystalchest", "ancientchest",
    "cursedchest", "blessedchest", "secretchest", "hiddenchest",
    "fruit", "sword", "gun", "accessory" -- sometimes spawn as items
}

-- Enhanced chest detection: checks Name, ClassName, attributes, and children
local function isChestObject(obj)
    -- Direct name check
    local name = string.lower(obj.Name)
    for _, keyword in pairs(chestNames) do
        if string.find(name, keyword) then
            return true
        end
    end
    
    -- Check if it has a ProximityPrompt with relevant text
    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
    if not prompt and obj.Parent then
        prompt = obj.Parent:FindFirstChildOfClass("ProximityPrompt")
    end
    if prompt then
        local promptText = string.lower(prompt.ObjectText .. " " .. prompt.ActionText)
        for _, keyword in pairs({"open", "collect", "loot", "search", "take", "grab", "claim", "pick"}) do
            if string.find(promptText, keyword) then
                return true
            end
        end
    end
    
    -- Check for ClickDetector
    if obj:FindFirstChildOfClass("ClickDetector") then
        return true
    end
    if obj.Parent and obj.Parent:FindFirstChildOfClass("ClickDetector") then
        return true
    end
    
    -- Check attributes
    local isLootable = obj:GetAttribute("IsLootable") or obj:GetAttribute("Lootable") or obj:GetAttribute("IsChest")
    if isLootable then
        return true
    end
    
    return false
end

-- Get unique chest ID
local function getChestId(chest)
    local parent = chest.Parent
    if parent and parent ~= workspace then
        return parent:GetFullName()
    end
    return chest:GetFullName()
end

-- Find all chests on the map
local function findAllChests()
    local chests = {}
    local seen = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if isChestObject(obj) then
            if obj:IsA("BasePart") and obj.Transparency < 0.9 and obj.Parent then
                local id = getChestId(obj)
                if not lootedChests[id] and not seen[id] then
                    seen[id] = true
                    table.insert(chests, obj)
                end
            elseif obj:IsA("Model") then
                local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") or obj:FindFirstChild("Handle")
                if primaryPart then
                    local id = getChestId(obj)
                    if not lootedChests[id] and not seen[id] then
                        seen[id] = true
                        table.insert(chests, primaryPart)
                    end
                end
            end
        end
        
        -- Check ProximityPrompt parent objects
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parent = obj.Parent
            if parent and parent ~= workspace then
                if isChestObject(parent) then
                    local chestPart = parent:FindFirstChildWhichIsA("BasePart") or parent:FindFirstChild("Handle")
                    if chestPart then
                        local id = getChestId(parent)
                        if not lootedChests[id] and not seen[id] then
                            seen[id] = true
                            table.insert(chests, chestPart)
                        end
                    end
                end
            end
        end
        
        -- Check ClickDetector parent objects
        if obj:IsA("ClickDetector") then
            local parent = obj.Parent
            if parent and parent ~= workspace then
                local chestPart = parent:FindFirstChildWhichIsA("BasePart") or parent:FindFirstChild("Handle")
                if chestPart then
                    local id = getChestId(parent)
                    if not lootedChests[id] and not seen[id] then
                        seen[id] = true
                        table.insert(chests, chestPart)
                    end
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
    
    pcall(function()
        local tweenInfo = TweenInfo.new(speed.teleportDelay, Enum.EasingStyle.Linear)
        local tween = tweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
        tween:Play()
        tween.Completed:Wait()
    end)
    return true
end

-- Enhanced chest opening
local function openChest(chest)
    local speed = speedPresets[currentSpeed]
    local opened = false
    
    -- Method 1: ProximityPrompt on chest or parent
    local function findAndFirePrompt(obj)
        if not obj then return false end
        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
        if prompt and prompt.Enabled then
            pcall(function() fireproximityprompt(prompt) end)
            return true
        end
        if obj.Parent then
            prompt = obj.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
                pcall(function() fireproximityprompt(prompt) end)
                return true
            end
        end
        -- Check siblings
        if obj.Parent then
            for _, child in pairs(obj.Parent:GetChildren()) do
                if child:IsA("ProximityPrompt") and child.Enabled then
                    pcall(function() fireproximityprompt(child) end)
                    return true
                end
            end
        end
        return false
    end
    
    opened = findAndFirePrompt(chest)
    if not opened then
        opened = findAndFirePrompt(chest.Parent)
    end
    
    -- Method 2: ClickDetector
    if not opened then
        local function findAndFireClickDetector(obj)
            if not obj then return false end
            local cd = obj:FindFirstChildOfClass("ClickDetector")
            if cd then
                pcall(function() fireclickdetector(cd) end)
                return true
            end
            if obj.Parent then
                cd = obj.Parent:FindFirstChildOfClass("ClickDetector")
                if cd then
                    pcall(function() fireclickdetector(cd) end)
                    return true
                end
            end
            return false
        end
        opened = findAndFireClickDetector(chest)
        if not opened then
            opened = findAndFireClickDetector(chest.Parent)
        end
    end
    
    -- Method 3: Touch interest (walk into chest)
    if not opened then
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local root = character.HumanoidRootPart
            local oldPos = root.CFrame
            pcall(function()
                root.CFrame = CFrame.new(chest.Position)
            end)
            wait(0.3)
            pcall(function()
                root.CFrame = oldPos
            end)
        end
    end
    
    -- Method 4: Collect all nearby prompts
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local objRoot = obj.Parent and (obj.Parent:FindFirstChildWhichIsA("BasePart") or obj.Parent:FindFirstChild("Handle"))
                if objRoot then
                    local dist = (root.Position - objRoot.Position).Magnitude
                    if dist < 20 then
                        pcall(function() fireproximityprompt(obj) end)
                    end
                end
            end
        end
    end
    
    wait(speed.collectDelay)
    return true
end

-- Server hop to server with FEWEST players
local function performServerHop()
    hopStatusLabel.Text = "Server Hop: Fetching servers..."
    serverHopButton.Text = "FETCHING..."
    serverHopButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local bestServer = nil
    local lowestPlayers = math.huge
    
    -- Collect servers from multiple pages
    local cursor = ""
    local servers = {}
    
    for page = 1, 3 do
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100&sortOrder=Asc"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success and response then
            local success2, data = pcall(function()
                return httpService:JSONDecode(response)
            end)
            
            if success2 and data and data.data then
                for _, server in pairs(data.data) do
                    if server.id ~= currentJobId and server.playing < server.maxPlayers then
                        table.insert(servers, server)
                        if server.playing < lowestPlayers then
                            lowestPlayers = server.playing
                            bestServer = server
                        end
                    end
                end
                cursor = data.nextPageCursor or ""
                if cursor == "" then break end
            else
                break
            end
        else
            break
        end
    end
    
    if bestServer then
        hopStatusLabel.Text = "Server Hop: " .. lowestPlayers .. " players - Joining..."
        serverHopButton.Text = "JOINING..."
        serverHopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        
        pcall(function()
            teleportService:TeleportToPlaceInstance(placeId, bestServer.id)
        end)
        
        -- Fallback if still in game after 3 seconds
        spawn(function()
            wait(3)
            if player and player.Parent then
                hopStatusLabel.Text = "Server Hop: Teleport fallback..."
                pcall(function()
                    teleportService:Teleport(placeId)
                end)
            end
        end)
    else
        -- No servers found from API, just rejoin
        hopStatusLabel.Text = "Server Hop: Rejoining..."
        serverHopButton.Text = "REJOINING..."
        serverHopButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        wait(0.5)
        pcall(function()
            teleportService:Teleport(placeId)
        end)
    end
    
    -- Reset if teleport fails completely
    spawn(function()
        wait(8)
        if player and player.Parent then
            serverHopButton.Text = "SERVER HOP (Low Players)"
            serverHopButton.BackgroundColor3 = Color3.fromRGB(70, 70, 200)
            hopStatusLabel.Text = "Server Hop: Failed - Try again"
            wait(5)
            hopStatusLabel.Text = "Server Hop: Ready"
        end
    end)
end

-- Server hop button click
serverHopButton.MouseButton1Click:Connect(function()
    performServerHop()
end)

-- Main farm loop
local function farmLoop()
    while farmEnabled do
        local speed = speedPresets[currentSpeed]
        local allChests = findAllChests()
        chestCountLabel.Text = "Chests: " .. #allChests .. " found | " .. tableSize(lootedChests) .. " looted"
        
        if #allChests == 0 then
            statusLabel.Text = "Status: No chests nearby..."
            wait(speed.scanInterval)
        else
            local nearest = findNearestChest(allChests)
            if nearest and nearest.Parent then
                local chestName = nearest.Parent.Name or nearest.Name
                local chestId = getChestId(nearest)
                
                statusLabel.Text = "Status: -> " .. chestName
                teleportTo(nearest)
                
                statusLabel.Text = "Status: Opening " .. chestName
                openChest(nearest)
                
                -- Mark as looted
                lootedChests[chestId] = (lootedChests[chestId] or 0) + 1
                chestCountLabel.Text = "Chests: " .. #allChests .. " found | " .. tableSize(lootedChests) .. " looted"
                
                statusLabel.Text = "Status: Done! Next..."
                wait(speed.scanInterval * 0.2)
            else
                wait(speed.scanInterval)
            end
        end
    end
end

-- Helper: get table size
function tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Toggle farm
toggleButton.MouseButton1Click:Connect(function()
    farmEnabled = not farmEnabled
    if farmEnabled then
        toggleButton.Text = "STOP FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        statusLabel.Text = "Status: Farming started!"
        spawn(farmLoop)
    else
        toggleButton.Text = "START FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "Status: OFF"
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

-- Periodic chest list reset (chests respawn in Blox Fruits)
spawn(function()
    while true do
        wait(240) -- 4 minutes
        if farmEnabled then
            lootedChests = {}
            statusLabel.Text = "Status: Chest list reset"
        end
    end
end)