local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Window = WindUI:CreateWindow({
    Folder = "Configs (DO NOT TOUCH)",
    Title = "Allusive",
    Icon = "sparkles",
    Author = "by alchemist ",
    Size = UDim2.fromOffset(500, 350),
    Transparent = false,
    HasOutline = true
})

WindUI:SetTheme("Dark")

Window:EditOpenButton({
    Title = "Open Allusive",
    Icon = "pointer",
    CornerRadius = UDim.new(0, 6),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromRGB(200, 0, 255),
        Color3.fromRGB(0, 200, 255)
    ),
    Draggable = true
})

local ExpTab  = Window:Tab({ Title = "Exploit", Icon = "code" })
local VisuTab = Window:Tab({ Title = "Visual",  Icon = "eye-off" })
local OtheTab = Window:Tab({ Title = "Others",  Icon = "wrench" })

WindUI:Notify({
    Title = "allusive <3",
    Text = "allusive loaded :3",
    Duration = 5,
    Icon = "sparkles"
})

local requiredFields = {
    Friction = true,
    AirStrafeAcceleration = true,
    JumpHeight = true,
    RunDeaccel = true,
    JumpSpeedMultiplier = true,
    JumpCap = true,
    SprintCap = true,
    WalkSpeedMultiplier = true,
    BhopEnabled = true,
    Speed = true,
    AirAcceleration = true,
    RunAccel = true,
    SprintAcceleration = true
}

local function isPlayerModelPresent()
    return LocalPlayer and LocalPlayer.Character ~= nil
end

local function getMatchingTables()
    local matched = {}
    for _, obj in pairs(getgc(true)) do
        if typeof(obj) == "table" then
            local ok = true
            for field in pairs(requiredFields) do
                if rawget(obj, field) == nil then
                    ok = false
                    break
                end
            end
            if ok then
                table.insert(matched, obj)
            end
        end
    end
    return matched
end

local function applyToTables(callback)
    if not isPlayerModelPresent() then return end
    local targets = getMatchingTables()
    if #targets == 0 then return end
    for _, tableObj in ipairs(targets) do
        if tableObj and typeof(tableObj) == "table" then
            pcall(callback, tableObj)
        end
    end
end

local currentSettings = {}

local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        currentSettings[config.field] = input
        applyToTables(function(obj)
            obj[config.field] = val
        end)
    end
end

local speedEnabled = false
local speedValue = 1500

local function setSpeed(val)
    applyToTables(function(obj)
        obj.Speed = val
    end)
end

ExpTab:Toggle({
    Title = "Enable Speed",
    Value = false,
    Callback = function(state)
        speedEnabled = state
        if state then
            setSpeed(speedValue)
        else
            setSpeed(250)
        end
    end
})

ExpTab:Input({
    Title = "Speed Value",
    Icon = "speedometer",
    Placeholder = "0-1500",
    Value = tostring(speedValue),
    Callback = function(text)
        local num = tonumber(text)
        if num and num > 0 then
            speedValue = num
            if speedEnabled then
                setSpeed(speedValue)
            end
        end
    end
})

local infiniteSlideEnabled = false
local slideFrictionValue   = -8
local keys = { "Friction" } 
local plrModel = nil
local cachedTables = nil
local slideConnection = nil

local function hasAll(tbl)
    if type(tbl) ~= "table" then return false end
    for _, k in ipairs(keys) do
        if rawget(tbl, k) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function()
            if hasAll(obj) then return obj end
        end)
        if success and result then
            table.insert(tables, obj)
        end
    end
    return tables
end

local function setFriction(value)
    if not cachedTables then return end
    for _, t in ipairs(cachedTables) do
        pcall(function()
            t.Friction = value
        end)
    end
end

local function updatePlayerModel()
    plrModel = LocalPlayer and LocalPlayer.Character
end

local function onHeartbeat()
    if not plrModel then
        setFriction(5)
        return
    end
    local success, currentState = pcall(function()
        return plrModel:GetAttribute("State")
    end)
    if success and currentState then
        if currentState == "Slide" then
            pcall(function()
                plrModel:SetAttribute("State", "EmotingSlide")
            end)
        elseif currentState == "EmotingSlide" then
            setFriction(slideFrictionValue)
        else
            setFriction(5)
        end
    else
        setFriction(5)
    end
end

ExpTab:Toggle({
    Title = "Infinite Slide",
    Value = false,
    Callback = function(state)
        infiniteSlideEnabled = state
        if slideConnection then
            slideConnection:Disconnect()
            slideConnection = nil
        end
        if state then
            cachedTables = getConfigTables()
            updatePlayerModel()
            slideConnection = RunService.Heartbeat:Connect(onHeartbeat)
        else
            cachedTables = nil
            plrModel = nil
            setFriction(5)
        end
    end
})

ExpTab:Input({
    Title = "Infinite Slide Speed (Negative Only)",
    Value = tostring(slideFrictionValue),
    Placeholder = "-8 (negative only)",
    Callback = function(text)
        local num = tonumber(text)
        if num and num < 0 then
            slideFrictionValue = num
        end
    end
})
