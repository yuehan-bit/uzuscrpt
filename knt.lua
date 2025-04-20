getgenv().config = {}

local players = game:GetService("Players")
local http_service = game:GetService("HttpService")
local replicated_storage = game:GetService("ReplicatedStorage")
local teleport_service = game:GetService("TeleportService")
local player = players.LocalPlayer
local data_remote_event = replicated_storage.BridgeNet2.dataRemoteEvent


local ctrl_char = {"\a", "\b", "\f", "\n", "\r", "\t", "\v", "\z", "\0", "\1", "\2", "\3", "\4", "\5", "\6", "\7", "\8", "\9"}

local folder = "Uzu"
local name = ("%s - %s Arise Dungeon.lua"):format(player.UserId, game.GameId)
local path = ("%s/%s"):format(folder, name)

repeat task.wait() until player:GetAttribute("Loaded") and workspace.__Extra:FindFirstChild("__Spawns")

function save()
    if not isfolder(folder) then makefolder(folder) end
    writefile(path, http_service:JSONEncode(config))
end

function load()
    if not isfile(path) then return end
    getgenv().config = http_service:JSONDecode(readfile(path))
end

function teleport(position)
    local character = player.Character
    if not character then return end

    character:SetAttribute("InTp", true)
    character:PivotTo(position)
end

local player = game.Players.LocalPlayer
local virtual_user = game:GetService("VirtualUser")

--anti kick
player.Idled:Connect(function()
    virtual_user:CaptureController()
    virtual_user:ClickButton2(Vector2.new())
end)

function get_runes()
    local runes = {}
    
    for i, v in player.leaderstats.Inventory.Items:GetChildren() do
        if not v.Name:match("Rune") then continue end
        if v:GetAttribute("Amount") == 0 then continue end
        table.insert(runes, v.Name)
    end
    table.sort(runes)
    return runes
end


function get_distance(position)
    return player.Character and player:DistanceFromCharacter(position) or math.huge
end

function float()
    local character = player.Character
    local root_part = character and character:FindFirstChild("HumanoidRootPart")
    if not root_part then return end
    root_part.Velocity = Vector3.zero
end

function auto_replay()
    while task.wait() and config.auto_replay do
        if not replicated_storage:GetAttribute("Dungeon") then continue end
        local dungeon_message = replicated_storage:GetAttribute("DungeonMessage")
        local dungeon_end = dungeon_message and dungeon_message:match("Ends")
        local seconds_left = dungeon_message and tonumber(dungeon_message:match("%d+"))
    
        local ticket_amount = player.leaderstats.Inventory.Items.Ticket:GetAttribute("Amount")
        local boss_dead = is_boss_dead()
        getgenv().old_ticket = old_ticket or ticket_amount
    
        if dungeon_end and seconds_left <= 12 or not config.wait_double_dungeon and boss_dead then
            if boss_dead then print("chill"); task.wait(3) end
            start_dungeon()
            send_drops()
            task.wait(9e9)
        end
    end
end

function get_arise_boss()
    local closest, closestDist = nil, math.huge
    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, obj in ipairs(workspace.__Main.__Enemies.Server:GetDescendants()) do
        if obj:IsA("Part") then
            local isBoss = obj:GetAttribute("Scale") == 2.5
            local isDead = obj:GetAttribute("Dead") == true

            if isBoss and isDead then
                local dist = (root.Position - obj.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end

    return closest
end

function auto_arise()
    while task.wait() and config.auto_arise do
        local mob = get_arise_boss()
        if mob then
            data_remote_event:FireServer({{Event = "EnemyCapture", Enemy = mob.Name}, "\4"})
            task.wait(0.001)
        end
    end
end

function kill_boss()
    while task.wait() and config.kill_boss do
        local kmob = get_boss()
        if not kmob then continue end

        if kmob then
        data_remote_event:FireServer({{Event = "EnemyCapture", Enemy = kmob.Name}, "\4"})
        task.wait(0.1)
        end
    end
end

function auto_dungeon()
    while task.wait() and config.auto_dungeon do
        replay_dungeon()

        local mob = get_nearest_mob()
        if not mob then continue end

        float()

        if get_distance(mob:GetPivot().p) > 10 then
            teleport(mob:GetPivot() * CFrame.new(0, 2, 0.1))
            task.wait(0.3)
        end

        data_remote_event:FireServer({{Event = "PunchAttack", Enemy = mob.Name}, "\4"})
    end
end

function get_weapons()
    local weapons = {}

    for _, v in player.leaderstats.Inventory.Weapons:GetChildren() do
        local weapon_name = v:GetAttribute("Name")
        local weapon_rank = v:GetAttribute("Level")

        if v:GetAttribute("Locked") then continue end
        if player.leaderstats.Equips:GetAttribute("Weapon") == v.Name then continue end
        if weapon_name == "DualCrystalSword" then continue end

        weapons[weapon_name] = weapons[weapon_name] or {}
        weapons[weapon_name][weapon_rank] = weapons[weapon_name][weapon_rank] or {}
        table.insert(weapons[weapon_name][weapon_rank], v.Name)
    end
    return weapons
end

function auto_upgrade_weapon()
    while task.wait() and config.auto_upgrade_weapon do
        local weapon_table = get_weapons()

        for weapon, v in weapon_table do
            for rank, v2 in v do
                if #v2 < 3 then continue end
                if rank == 7 then continue end
                data_remote_event:FireServer({{
                    Type=weapon,
                    BuyType="Gems",
                    Weapons={v2[1], v2[2], v2[3]},
                    Event="UpgradeWeapon",
                    Level=rank + 1
                }, "\n"})
                task.wait()
            end
        end
    end
end

function get_brute()
    local dist = math.huge
    local target = nil

    for i, v in workspace.__Main.__Enemies.Server:GetDescendants() do
        local mag = v:IsA("Part") and v:GetAttribute("Scale") == 2 and not v:GetAttribute("Dead") and get_distance(v:GetPivot().p)

        if mag and mag < dist then
            dist = mag
            target = v
        end
    end
    return target
end

function get_normal_mob()
    local dist = math.huge
    local target = nil

    for _, v in workspace.__Main.__Enemies.Server:GetDescendants() do
        local mag = v:IsA("Part") and v:GetAttribute("Scale") == 1 and not v:GetAttribute("Dead") and get_distance(v:GetPivot().p)

        if mag and mag < dist then
            dist = mag
            target = v
        end
    end
    return target
end

function get_nearest_mob()
    local dist = math.huge
    local target = nil

    for _, v in workspace.__Main.__Enemies.Server:GetDescendants() do
        local mag = v:IsA("Part") and v:GetAttribute("Scale") and not v:GetAttribute("Dead") and get_distance(v:GetPivot().p)

        if mag and mag < dist then
            dist = mag
            target = v
        end
    end
    return target
end

function auto_farm()
    while task.wait() and config.auto_farm do
        local mob = get_brute()
        if not mob then continue end

        float()

        if get_distance(mob:GetPivot().p) > 10 then
            teleport(mob:GetPivot() * CFrame.new(0, 2, 0.1))
            task.wait(0.3)
        end

        data_remote_event:FireServer({{Event = "PunchAttack", Enemy = mob.Name}, "\4"})
        task.wait(config.auto_farm_speed or 0.2)
    end
end

function join_castle()
    while task.wait() do
        for i, v in ctrl_char do
            data_remote_event:FireServer({{Event = "JoinCastle", Check = config.auto_skip_floor}, v})
        end
        task.wait(1)
    end
end

function auto_castle()
    while task.wait() and config.auto_castle do
        local minute = os.date("*t").min

        if replicated_storage:GetAttribute("IsCastle") then 
            local castle_room = replicated_storage:GetAttribute("CurrentRoom")

            if castle_room and castle_room > (config.leave_after_floor or 100) and minute >= 45 and minute <= 57 then
                send_drops()
                player:Kick("rejoining, player has reached the floor limit")
                rejoin(87039211657390)
                task.wait(1)
            end    
            continue 
        end
        
        if minute >= 45 and minute <= 57 then
            fire_remote({Event = "CastleAction", Action = "BuyTicket", Type = "Gems"}, nil, "GENERAL_EVENT")
            task.wait(0.5)
            fire_remote({Event = "CastleAction", Action = "Join", Check = config.auto_skip_floor}, nil, "GENERAL_EVENT")
            task.wait(1)
        end
    end
end


function auto_farm_mob()
	while task.wait() and config.auto_farm_mob do
        local nmob = get_normal_mob()
        if not nmob then continue end

        float()

        if get_distance(nmob:GetPivot().p) > 10 then
            teleport(nmob:GetPivot() * CFrame.new(0, 2, 0.1))
            task.wait(0.3)
        end

        data_remote_event:FireServer({{Event = "PunchAttack", Enemy = nmob.Name}, "\4"})
        task.wait(config.auto_farm_speed or 0.2)
    end
end

function auto_rejoin()
    player.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Failed or State == Enum.TeleportState.InProgress then
            teleport_service:Teleport(87039211657390, player)
        end
    end)

    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            wait(2)
            teleport_service:Teleport(87039211657390, player)
        end
    end)
end

-- Reference spawn folder
local spawnsFolder = workspace:WaitForChild("__Extra"):WaitForChild("__Spawns")

-- Grab available spawns
local spawnList = {}
local spawnNames = {}

for _, obj in ipairs(spawnsFolder:GetChildren()) do
    if obj:IsA("BasePart") then
        spawnList[obj.Name] = obj
        table.insert(spawnNames, obj.Name)
    end
end

-- Default values
local teleportToSpawnEnabled = false
local selectedSpawn = nil

-- Enable/disable teleport
function toggleTeleportToSpawn(state)
    teleportToSpawnEnabled = state
end

-- Set and teleport to selected spawn
function setSelectedSpawn(spawn)
    selectedSpawn = spawn
    if teleportToSpawnEnabled and selectedSpawn then
        local character = player.Character
        if not character then return end
        character:SetAttribute("InTp", true)
        character:PivotTo(selectedSpawn.CFrame)
    end
end

task.wait(.1)
load()

if config.auto_rejoin then
    auto_rejoin()
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "KNT | Arise",
    Size = UDim2.fromOffset(550, 480),
    Center = true,
    ShowCustomCursor = false
})

local MainTab = Window:AddTab("Main")
local ConfigTab = Window:AddTab("Config")

-- Feature Containers
local FeaturesBox = MainTab:AddLeftTabbox("Features")
local GeneralTab = FeaturesBox:AddTab("Farm")
local DungeonTab = FeaturesBox:AddTab("Dung")
local CastleTab = FeaturesBox:AddTab("Castle")
local MiscBox = MainTab:AddRightGroupbox("Misc")

-- General Features
GeneralTab:AddToggle("FarmBrute", {
    Text = "Farm Brute",
    Default = false,
    Callback = function(v)
        config.auto_farm = v
        save()
        task.spawn(auto_farm)
        print("Farm Brute enabled:", v)
    end
})

GeneralTab:AddSlider("SpeedValue", {
    Text = "Speed Delay",
    Default = 1.3,
    Min = 0,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        config.auto_farm_speed = Value
        print("Speed set to:", Value)
    end
})

-- Dungeon & Rune Features
DungeonTab:AddToggle("AutoDungeon", {
    Text = "Auto Dungeon",
    Default = config.auto_dungeon,
    Callback = function(v)
        config.auto_dungeon = v
        save()
        task.spawn(auto_dungeon)
    end
})

DungeonTab:AddToggle("UseRune", {
    Text = "Use Rune",
    Default = config.use_rune,
    Callback = function(v)
        config.use_rune = v
        save()
    end
})

DungeonTab:AddDropdown("SelectRune", {
    Text = "Select Rune",
    Values = get_runes(),
    Default = config.selected_rune,
    Callback = function(v)
        config.selected_rune = v
        save()
    end
})

GeneralTab:AddToggle("AutoArise", {
    Text = "Auto Arise Boss",
    Default = config.auto_arise,
    Callback = function(v)
        config.auto_arise = v
        save()
        task.spawn(auto_arise)
    end
})

CastleTab:AddToggle("AutoCastle", {
    Text = "Auto Castle",
    Default = config.auto_castle,
    Callback = function(v)
        config.auto_castle = v
        save()
        task.spawn(auto_castle)
    end
})

CastleTab:AddToggle("", {Text = "Auto Skip Floor", Default = config.auto_skip_floor, Callback = function(v)
    config.auto_skip_floor = v
    save()
end})


GeneralTab:AddToggle("AutoFarmMob", {
    Text = "Auto Farm Mob",
    Default = config.auto_farm_mob,
    Callback = function(v)
        config.auto_farm_mob = v
        save()
        task.spawn(auto_farm_mob)
    end
})

-- Misc Features
MiscBox:AddToggle("AutoUpgradeWeapon", {
    Text = "Auto Upgrade Weapon",
    Default = config.auto_upgrade_weapon,
    Callback = function(v)
        config.auto_upgrade_weapon = v
        save()
        task.spawn(auto_upgrade_weapon)
    end
})

MiscBox:AddToggle("AutoExecute", {
    Text = "Auto Execute",
    Default = config.auto_execute,
    Callback = function(v)
        config.auto_execute = v
        save()
        if v then
            queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/yuehan-bit/uzuscrpt/refs/heads/main/uzuscrpt.lua"))()')
        end
    end
})

MiscBox:AddToggle("AutoRejoin", {
    Text = "Auto Rejoin",
    Default = config.auto_rejoin,
    Callback = function(v)
        config.auto_rejoin = v
        save()
        if v then auto_rejoin() end
    end
})

MiscBox:AddLabel("Anti Kick is ON")

MiscBox:AddBind({
    Text = "Toggle GUI",
    Key = "LeftControl",
    Callback = function()
        Library:Close()
    end
})

-- Teleport
local tp_folder = MiscBox:AddDropdown("TeleportWorld", {
    Text = "Select World",
    Values = {},
    Callback = function(name)
        local spawn = spawnList[name]
        if spawn then
            toggleTeleportToSpawn(true)
            setSelectedSpawn(spawn)
        end
    end
})

-- Setup Spawns
local spawnsFolder = workspace:WaitForChild("__Extra"):FindFirstChild("__Spawns")
if spawnsFolder then
    spawnList = {}
    spawnNames = {}

    for _, obj in ipairs(spawnsFolder:GetChildren()) do
        if obj:IsA("BasePart") then
            spawnList[obj.Name] = obj
            table.insert(spawnNames, obj.Name)
        end
    end

    tp_folder:SetValues(spawnNames)
else
    warn("No '__Spawns' folder found in workspace.__Extra")
end

-- Initialize Library
Library:Init()
