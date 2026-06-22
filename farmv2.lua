local Players = game:GetService("Players")
local player = Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local virtualInputManager = game:GetService("VirtualInputManager")

-- Global state
local farmEnabled = false
local currentChest = nil
local gui = nil
local frame = nil
local statusLabel = nil
local toggleButton = nil
local farmCoroutine = nil

-- Cleanup function
local function cleanupGUI()
    if gui then
        gui:Destroy()
        gui = nil
    end
    farmEnabled = false
    currentChest = nil
    if farmCoroutine then
        coroutine.close(farmCoroutine)
        farmCoroutine = nil
    end
end

-- Chest keywords (expanded for all Blox Fruits chest variants)
local chestKeywords = {
    "chest", "goldenchest", "silverchest", "bronzechest", 
    "treasurechest", "devilfruit", "goldchest", "silverchest",
    "diamondchest", "crystalchest", "magicchest", "rarechest",
    "legendarychest", "mythicalchest", "darkchest"
}

-- Find nearest valid chest
local function findNearestChest()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local root = character.HumanoidRootPart
    local nearest = nil
    local shortestDistance = 500 -- Max detection range
    
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
            local targetPart = nil
            
            if obj:IsA("BasePart") and obj.Transparency < 1 then
                targetPart = obj
            elseif obj:IsA("Model") then
                targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end
            
            if targetPart then
                -- Verify chest is still valid (has parent, not destroyed)
                if targetPart.Parent and targetPart.Parent ~= workspace then
                    local distance = (root.Position - targetPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearest = targetPart
                    end
                end
            end
        end
        
        -- Check ProximityPrompt chests
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parentName = string.lower(obj.Parent.Name)
            for _, keyword in pairs(chestKeywords) do
                if string.find(parentName, keyword) then
                    local chestPart = obj.Parent:FindFirstChildWhichIsA("BasePart") or obj.Parent
                    if chestPart and chestPart:IsA("BasePart") and chestPart.Parent then
                        local distance = (root.Position - chestPart.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            nearest = chestPart
                        end
                    end
                    break
                end
            end
        end
    end
    
    return nearest
end

-- Instant teleport (no tween for speed)
local function teleportTo(part)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    local root = character.HumanoidRootPart
    
    -- Direct CFrame set for instant teleport
    local targetPos = part.Position + Vector3.new(0, 3, 0)
    root.CFrame = CFrame.new(targetPos)
    return true
end

-- Aggressive chest opening
local function openChest(chest)
    if not chest or not chest.Parent then return false end
    
    -- Method 1: ProximityPrompt
    local prompt = chest.Parent:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = chest:FindFirstChildOfClass("ProximityPrompt")
    end
    if not prompt then
        -- Search siblings and children
        for _, child in pairs(chest.Parent:GetChildren()) do
            if child:IsA("ProximityPrompt") then
                prompt = child
                break
            end
        end
    end
    if prompt and prompt.Enabled then
        pcall(function() fireproximityprompt(prompt) end)
        return true
    end
    
    -- Method 2: ClickDetector
    local click = chest.Parent:FindFirstChildOfClass("ClickDetector")
    if not click then
        click = chest:FindFirstChildOfClass("ClickDetector")
    end
    if click then
        pcall(function() fireclickdetector(click) end)
        return true
    end
    
    -- Method 3: Virtual mouse click at chest position
    local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(chest.Position)
    if onScreen then
        pcall(function()
            virtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 0)
            virtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 0)
        end)
        return true
    end
    
    return false
end

-- Fast farm loop with error handling
local function farmLoop()
    while farmEnabled do
        local success, chest = pcall(findNearestChest)
        
        if success and chest then
            currentChest = chest
            
            if statusLabel then
                statusLabel.Text = "Status: Moving to chest..."
            end
            
            -- Instant teleport
            local tpSuccess = teleportTo(chest)
            
            if tpSuccess then
                wait(0.05) -- Minimal delay before opening
                
                if statusLabel then
                    statusLabel.Text = "Status: Opening..."
                end
                
                -- Try opening multiple times rapidly
                local opened = false
                for i = 1, 3 do
                    opened = openChest(chest)
                    if opened then break end
                    wait(0.05)
                end
                
                if opened and statusLabel then
                    statusLabel.Text = "Status: Opened! Next..."
                end
                
                wait(0.3) -- Fast cooldown before next chest
            end
        else
            if statusLabel then
                statusLabel.Text = "Status: Scanning for chests..."
            end
            wait(1)
        end
        
        -- Safety yield to prevent crash
        runService.Heartbeat:Wait()
    end
end

-- Build GUI
local function buildGUI()
    cleanupGUI()
    
    gui = Instance.new("ScreenGui")
    gui.Name = "BloxFruitsChestFarm_" .. math.random(10000, 99999)
    gui.Parent = game.CoreGui
    gui.ResetOnSpawn = false
    
    frame = Instance.new("Frame")
    frame.Parent = gui
    frame.Size = UDim2.new(0, 220, 0, 100)
    frame.Position = UDim2.new(0.5, -110, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    
    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Text = "Auto Chest Farm - Blox Fruits"
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 12
    
    statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Size = UDim2.new(1, -10, 0, 20)
    statusLabel.Position = UDim2.new(0, 5, 0, 30)
    statusLabel.Text = "Status: Ready"
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    toggleButton = Instance.new("TextButton")
    toggleButton.Parent = frame
    toggleButton.Size = UDim2.new(1, -10, 0, 35)
    toggleButton.Position = UDim2.new(0, 5, 0, 55)
    toggleButton.Text = "START FARM"
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 14
    toggleButton.BorderSizePixel = 0
    
    toggleButton.MouseButton1Click:Connect(function()
        farmEnabled = not farmEnabled
        if farmEnabled then
            toggleButton.Text = "STOP FARM"
            toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            statusLabel.Text = "Status: Farming..."
            farmCoroutine = coroutine.create(farmLoop)
            coroutine.resume(farmCoroutine)
        else
            toggleButton.Text = "START FARM"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            statusLabel.Text = "Status: Stopped"
            currentChest = nil
            if farmCoroutine then
                coroutine.close(farmCoroutine)
                farmCoroutine = nil
            end
        end
    end)
end

-- Handle player respawns and server changes
local function onCharacterAdded(character)
    -- Reset chest targeting but keep farming if enabled
    currentChest = nil
    if statusLabel then
        statusLabel.Text = farmEnabled and "Status: Character respawned, continuing..." or "Status: Ready"
    end
end

local function onPlayerAdded(newPlayer)
    -- When local player is re-added (server hop)
    if newPlayer == player then
        wait(2) -- Wait for game to load
        buildGUI()
        newPlayer.CharacterAdded:Connect(onCharacterAdded)
        if newPlayer.Character then
            onCharacterAdded(newPlayer.Character)
        end
    end
end

-- Initial setup
player.CharacterAdded:Connect(onCharacterAdded)
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        cleanupGUI()
    end
end)

-- Handle game teleports (between islands in Blox Fruits)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    wait(1)
    if farmEnabled and statusLabel then
        statusLabel.Text = "Status: Re-scanning area..."
        currentChest = nil
    end
end)

-- Build initial GUI
buildGUI()
if player.Character then
    onCharacterAdded(player.Character)
end