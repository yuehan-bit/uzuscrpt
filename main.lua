if not game:IsLoaded() then game.Loaded:Wait() end
get_github_file("global.lua")

player.Idled:Connect(function()
    virtual_user:CaptureController()
    virtual_user:ClickButton2(Vector2.new())
end)

if not getidentity then
    getgenv().require = function() return {} end
end

repeat task.wait() until player:GetAttribute("Loaded") and workspace.__Extra:FindFirstChild("__Spawns") and player.PlayerGui:FindFirstChild("__Disable")

getgenv().config = {auto_show = true}
getgenv().executed_time = os.time()

local data_remote_event = replicated_storage.BridgeNet2.dataRemoteEvent
local bridge_net_2 = require(replicated_storage.BridgeNet2)

local need_to_arise = false
local shorten = get_github_file("util/shorten.lua")

local rewards_old = {}
local drop_image = {}
local drop_list = {}

local potions = {"GemsBoost", "CoinsBoost", "ShadowBoost", "DropsBoost", "ExpBoost"}
local dusts = {"Legendary To Rare", "Common To Rare", "Rare To Legendary", "Rare To Common"}
local ranks = {"E", "D", "C", "B", "A", "S", "SS"}
local utf8_chars = {"\a", "\b", "\f", "\n", "\r", "\t", "\v", "\z", "\0", "\1", "\2", "\3", "\4", "\5", "\6", "\7", "\8", "\9"}

local rewards = {
    EnchCommon = "<:common_dust:1363132409851150347>",
    EnchRare = "<:rare_dust:1363131180966350968>",
    EnchLegendary = "<:legendary_dust:1363132370512908388>",
    Common = "<:common:1363131300189573231>",
    Rare = "<:rare:1363131432133988443>",
    Epic = "<:epic:1363131797675966747>",
    Legendary = "<:legendary:1363131206685954130>",
    Ticket = "<:ticket:1363131366509641839>",
    Rune = "<:rune:1363138032038842498>",
    Coins = "<:cash:1363130954217951394>",
    Gems = "<:gems:1361031515139473549>",
    Relic = "<:relic:1363239439584723206>",
}

local potions_data = {
    GemsBoost = "GemsPotion",
    CoinsBoost = "CoinsPotion",
    ShadowBoost = "ShadowPotion",
    DropsBoost = "DropsPotion",
    ExpBoost = "ExpPotion",
}

local dusts_data = {
    ["Legendary To Rare"] = "EnchRare2",
    ["Common To Rare"] = "EnchRare",
    ["Rare To Legendary"] = "EnchLegendary",
    ["Rare To Common"] = "EnchCommon",
}

local folder = "Uzu"
local name = ("%* - %* arise private.lua"):format(player.UserId, game.GameId)
local path = ("%*/%*"):format(folder, name)

for i, v in player.PlayerGui.__Disable.Menus :GetChildren() do
    v.Parent = player.PlayerGui.Menus
end

player.PlayerGui.__Disable.Menus.ChildAdded:Connect(function(v)
    v.Parent = player.PlayerGui.Menus
end)

repeat task.wait() until #player.PlayerGui.Menus:GetChildren() > 0

function save()
    if not isfolder(folder) then makefolder(folder) end
    writefile(path, http_service:JSONEncode(config))
end

function load()
    if not isfile(path) then return end
    getgenv().config = http_service:JSONDecode(readfile(path))
end

function send_webhook(text, ...)
    return request({Url = ("%*?wait=true"):format(config.webhook_url), Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game.HttpService:JSONEncode({embeds = {...}, content = text})})
end

function fire_remote(args, char, event)
    if getidentity and getidentity() > 3 then
        bridge_net_2.ReferenceBridge(event):Fire(args)
        return   
    end
    getgenv().require = function() return{} end

    if not char then
        for i, v in utf8_chars do
            replicated_storage.BridgeNet2.dataRemoteEvent:FireServer({args, v})
        end
        return
    end
    replicated_storage.BridgeNet2.dataRemoteEvent:FireServer({args, char})
end

function get_farming_data()
    local cash = player.leaderstats:GetAttribute("Coins")
    local gems = player.leaderstats:GetAttribute("Gems")
    local secs = os.time() - executed_time

    getgenv().old_cash_amount = old_cash_amount or cash
    getgenv().old_gems_amount = old_gems_amount or gems

    local info = {
        cash = ("Cash Earned: %*"):format(shorten(cash - old_cash_amount)),
        gems = ("Gems Earned: %*"):format(shorten(gems - old_gems_amount)),
        time = ("Server Time: %02d:%02d:%02d"):format(math.floor(secs / 3600), math.floor((secs % 3600) / 60), math.floor(secs % 60))
    }

    return info.cash, info.gems, info.time
end

function get_spawns()
    local spawns = {}

    for i, v in player.PlayerGui.Menus.Indexer.Main.Worlds:GetChildren() do
        local island_name = v:IsA("ImageButton") and v.Background.Value.Text
        if not island_name or v.Name == "Template" then continue end
        table.insert(spawns, island_name)
    end
    table.sort(spawns)
    return spawns
end

function get_runes()
    local runes = {}

    for i, v in player.PlayerGui.Menus.Inventory.Main.Lists.Items:GetChildren() do
        local item_name = v:IsA("ImageButton") and v.Main.Value.Text
        if not item_name or not item_name:match("Rune") or v.Name == "Template" then continue end
        table.insert(runes, item_name)
    end
    table.sort(runes)
    return runes
end

function get_weapons()
    local weapons = {}

    for i, v in player.leaderstats.Inventory.Weapons:GetChildren() do
        local weapon_name = v:GetAttribute("Name")
        local weapon_rank = v:GetAttribute("Level")
        if player.leaderstats.Equips:GetAttribute("Weapon") == v.Name then continue end
        if weapon_name == "DualCrystalSword" then continue end

        weapons[weapon_name] = weapons[weapon_name] or {}
        weapons[weapon_name][weapon_rank] = weapons[weapon_name][weapon_rank] or {}
        table.insert(weapons[weapon_name][weapon_rank], v.Name)
    end
    return weapons
end

function get_shadows()
    local shadows = {}

    for i, v in player.leaderstats.Inventory.Pets:GetChildren() do
        if v:GetAttribute("Locked") or v:GetAttribute("Equipped") and v:GetAttribute("Rank") >= 8 then continue end
        table.insert(shadows, {id = v, rank = v:GetAttribute("Rank")})
    end
    return shadows
end

function get_rune_id(display)
    for i, v in player.PlayerGui.Menus.Inventory.Main.Lists.Items:GetChildren() do
        local item_name = v:IsA("ImageButton") and v.Main.Value.Text
        if item_name == display then
            return v.Name
        end
    end
    return false
end

function get_mobs(mob_type)
    local dist = math.huge
    local target = nil

    for i, v in workspace.__Main.__Enemies.Server:GetDescendants() do
        local mag = v:IsA("Part") and not v:GetAttribute("Dead") and get_distance(v:GetPivot().p)
        local list = {
            brute = v:GetAttribute("Scale") == 2, 
            castle = v:GetAttribute("Scale") == 3.5, 
            dungeon = v:GetAttribute("IsBoss"),
            nearest = true,
        }

        if list[mob_type] and mag and mag < dist then
            dist = mag
            target = v
        end
    end
    return target
end

function hide_name()
    task.wait(2)
    local root_part = get_humanoid_root_part()
    if not root_part then return end

    root_part.PlayerTag.Main.Title.Text = "@uzu01"
    root_part.PlayerTag.Main.GuildName.Text = ""
    root_part.PlayerTag.Main.GuildIcon.Image = ""    
end

function doing_castle()
    local min = os.date("*t").min
    return min >= 45 and min <= 57 and config.auto_castle
end

function start_dungeon()
    if doing_castle() then return end

    fire_remote({Type = "Gems", Event = "DungeonAction", Action = "BuyTicket"}, nil, "GENERAL_EVENT")
    fire_remote({Event = "DungeonAction", Action = "Create"}, nil, "GENERAL_EVENT")
    
    if config.use_rune and config.selected_runes then
        for i, v in config.selected_runes do
            print(i,v, get_rune_id(v))
            task.wait(0.1)
            fire_remote({Dungeon = player.UserId, Action = "AddItems", Slot = i, Event = "DungeonAction", Item = get_rune_id(v)}, nil, "GENERAL_EVENT")
            task.wait(0.1)
        end
    end

    fire_remote({Dungeon = player.UserId, Event = "DungeonAction", Action = "Start"}, nil, "GENERAL_EVENT")
end

function send_drops()
    if not config.send_webhook or not config.webhook_url then return end

    local list = {}
    local secs = os.time() - executed_time

    for weapon, amount in drop_list do
        table.insert(list, ("+ **%* %*** %*"):format(amount, weapon, drop_image[weapon]))
    end

    table.insert(list, ("\nTime Taken: %02d:%02d:%02d"):format(math.floor(secs / 3600), math.floor((secs % 3600) / 60), math.floor(secs % 60)))
    table.insert(list, ("<t:%*:R>"):format(os.time()))

    send_webhook(("<@%*>"):format(config.user_id), {
        ["type"] = "rich",
        ["color"] = tonumber(0x3aca78),
        ["title"] = "Arise Crossover",
        ["description"] = table.concat(list, "\n"),
    })
end

function is_boss_dead()
    for i, v in workspace.__Main.__Enemies.Server:GetDescendants() do
        if not v:GetAttribute("IsBoss") then continue end
        return v:GetAttribute("Dead")
    end
    return false
end

function can_teleport()
    return config.auto_brute and get_mobs("brute") or config.auto_castle and replicated_storage:GetAttribute("IsCastle") or config.auto_dungeon and replicated_storage:GetAttribute("Dungeon") or config.can_teleport
end

function auto_mob()
    while task.wait() and config.auto_mob do
        local mob_type = config.auto_brute and "brute" or config.auto_castle and "castle" or config.auto_dungeon and "dungeon" or "nearest"
        local mob = get_mobs(mob_type) or get_mobs("nearest")

        if replicated_storage:GetAttribute("IsCastle") and not mob then
            local is_room = workspace.__Main.__World:FindFirstChild(("Room_%*"):format(replicated_storage:GetAttribute("CurrentRoom")))
            if not is_room then continue end
            teleport(is_room:GetPivot())
        end

        if not mob or need_to_arise then 
            continue 
        end
    
        if can_teleport() and get_distance(mob:GetPivot().p) >= 15 then
            get_character():SetAttribute("InTp", true)
            teleport(mob:GetPivot() * CFrame.new(0, config.y_level or 2, 0.1))
            task.wait(config.kill_speed or 0.5)   
        end
        fire_remote({Event = "PunchAttack", Enemy = mob.Name}, "\4", "ENEMY_EVENT")
    end
end

function auto_castle()
    while task.wait() and config.auto_castle do
        local minute = os.date("*t").min

        if replicated_storage:GetAttribute("IsCastle") then 
            local castle_room = replicated_storage:GetAttribute("CurrentRoom")

            if castle_room and castle_room > (config.leave_after_floor or 100) then
                send_drops()
                player:Kick("rejoining")
                rejoin(87039211657390)
                task.wait(1)
            end    
            continue 
        end
        
        if minute >= 45 and minute <= 57 then
            if not replicated_storage:GetAttribute("IsCastle") and game.PlaceId ~= 87039211657390 then
                player:Kick("rejoining")
                rejoin(87039211657390)
                task.wait(1)
            end

            fire_remote({Event = "CastleAction", Action = "BuyTicket", Type = "Gems"}, nil, "GENERAL_EVENT")
            task.wait(0.5)
            fire_remote({Event = "CastleAction", Action = "Join", Check = config.auto_skip_floor}, nil, "GENERAL_EVENT")
            task.wait(1)
        end
    end
end

function auto_arise_boss()
    while task.wait() and config.auto_arise_boss do
        local tickk = tick()

        for i, v in workspace.__Main.__Enemies.Server:GetDescendants() do
            if not v:IsA("Part") or not v:GetAttribute("Dead") or not v:GetAttribute("IsBoss") then continue end
            need_to_arise = true
            repeat task.wait() 
                teleport(v:GetPivot() * CFrame.new(0, 2, 0.1))
                fire_remote({Event = "EnemyCapture", Enemy = v.Name}, "\4", "ENEMY_EVENT")
            until not config.auto_arise_boss or tick() - tickk >= 2
            v:Destroy()
        end
        need_to_arise = false
    end
end

function auto_upgrade_weapon()
    while task.wait() and config.auto_upgrade_weapon do
        local weapon_table = get_weapons()
    
        for weapon, v in weapon_table do
            for rank, v2 in v do
                if #v2 < 3 then continue end
                if rank == 7 then continue end
                fire_remote({["Type"] = weapon, ["Auto"] = true, ["BuyType"] = "Gems", ["Weapons"] = {v2[1], v2[2], v2[3]}, ["Event"] = "UpgradeWeapon", ["Level"] = rank + 1}, nil, "GENERAL_EVENT")
                task.wait()
            end
        end
    end
end

function auto_sell_shadow()
    local shadows = get_shadows()
    local sell_table = {}
    
    for i, v in config.selected_ranks do
        for i2, v2 in shadows do
            if v2.rank == table.find(ranks, v) then
                table.insert(sell_table, v2.id.Name)
            end
        end
    end
    
    fire_remote({["Event"] = "SellPet",["Pets"] = sell_table}, nil, "PET_EVENT")
end

function auto_dungeon()
    while task.wait() and config.auto_dungeon do
        if not replicated_storage:GetAttribute("Dungeon") then
            start_dungeon()
            task.wait(5)
        end
    end
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

function auto_buy_potion()
    while task.wait() and config.auto_buy_potion do
        for i, v in config.selected_potions do
            local potion = player.leaderstats.Inventory.Items:FindFirstChild(potions_data[v])
            if potion and potion:GetAttribute("Amount") >= 50 then continue end
            fire_remote({["Name"] = v, ["Type"] = "Product", ["SubType"] = "Products", ["Event"] = "TicketShop"}, "\n", "GENERAL_EVENT")
        end
    end
end

function auto_exchange_dust()
    while task.wait() and config.auto_exchange_dust do
        for i, v in config.selected_dust do
            print(i, v, dusts_data[v])
            fire_remote({["Action"] = "Buy", ["Shop"] = "ExchangeShop", ["Item"] = dusts_data[v], ["Event"] = "ItemShopAction"}, "\n", "GENERAL_EVENT")
        end
    end
end

task.spawn(function()
    task.wait(5)

    player.PlayerGui.Menus.Inventory.Main.Lists.Weapons.ChildAdded:Connect(function(v)
        if not replicated_storage:GetAttribute("Dungeon") then return end
        drop_list[v.Main.Value.Text] = (drop_list[v.Main.Value.Text] or 0) + 1
        drop_image[v.Main.Value.Text] = rawget(rewards, v:GetAttribute("Rarity"))
    end)

    player.PlayerGui.Menus.Inventory.Main.Lists.Relics.ChildAdded:Connect(function(v)
        if not replicated_storage:GetAttribute("Dungeon") then return end
        local name = ("Rank %* %*"):format(v.Main.Rank.Text, v.Main.Value.Text)
        drop_list[name] = (drop_list[name] or 0) + 1
        drop_image[name] = rewards["Relic"]
    end)
    
    player.PlayerGui.Menus.Inventory.Main.Lists.Items.ChildAdded:Connect(function(v)
        if not replicated_storage:GetAttribute("Dungeon") then return end
        local drops = v.Name:match("Ench") and v.Name or v.Name:match("Rune") and "Rune" or v.Name:match("Ticket") and "Ticket"
        if not drops then return end
        drop_list[v.Main.Value.Text] = (drop_list[v.Main.Value.Text] or 0) + 1
        drop_image[v.Main.Value.Text] = rewards[drops]
    end)

    player.leaderstats.Inventory.Pets.ChildAdded:Connect(function(v)
        if not config.auto_sell_shadow then return end
        task.spawn(auto_sell_shadow)
    end)
    
    for i, v in player.PlayerGui.Menus.Inventory.Main.Lists.Items:GetChildren() do
        local drops = v.Name:match("Ench") and v.Name or v.Name:match("Rune") and "Rune" or v.Name:match("Ticket") and "Ticket"
        if not drops then continue end
        local old = v:GetAttribute("AmountItems")
    
        player.leaderstats.Inventory.Items[v.Name]:GetAttributeChangedSignal("Amount"):Connect(function()
            drop_list[v.Main.Value.Text] = player.leaderstats.Inventory.Items[v.Name]:GetAttribute("Amount") - old
            drop_image[v.Main.Value.Text] = rewards[drops]
        end)
    end
end)

task.wait(0.5)
load()

local cash, gems, time = get_farming_data()
local gems_label
local cash_label
local time_label

if run_connection then run_connection:Disconnect() end
getgenv().run_connection = run_service.RenderStepped:Connect(function()
    local character = get_character()
    local cash, gems, time = get_farming_data()
    if not character then return end

    character:SetAttribute("InTp", true)

    if gems_label then
        time_label:SetText(time)
        cash_label:SetText(cash)
        gems_label:SetText(gems)
    end
    
    if can_teleport() then
        no_clip()
    end

    local mob = get_mobs("nearest")
    if not mob then return end
    
    for i, v in workspace.__Main.__Pets[player.UserId]:GetChildren() do
        local model = v:FindFirstChildWhichIsA("Model")
        
        if model and get_distance(mob:GetPivot().p) <= 300 then
            model:PivotTo(mob:GetPivot())
        end
    end
end)

local library = get_github_file("library/obsidian.lua")
local window = library:CreateWindow({Title = "uzu01", Footer = "v1.3", ToggleKeybind = Enum.KeyCode.LeftControl, Center = true, ShowCustomCursor = false})
local home = window:AddTab("Main", "tractor")
local webhook = window:AddTab("Webhook", "webhook")

local main_box = home:AddLeftTabbox("")
local mode_box = home:AddLeftTabbox("")
local misc_box = home:AddLeftTabbox("")
local shop_box = home:AddLeftTabbox("")

local tab = {
    main = main_box:AddTab("Main"),
    main_settings = main_box:AddTab("Settings"),

    spawn = misc_box:AddTab("Spawn"),
    misc = misc_box:AddTab("Misc"),

    shop = shop_box:AddTab("Shop"),
    info = shop_box:AddTab("Info"),

    castle = home:AddRightGroupbox("Castle"),
    dungeon = home:AddRightGroupbox("Dungeon"),
    
    webhook = webhook:AddLeftGroupbox("Webhook"),
}

local weap_box = home:AddRightTabbox("")
tab.weapon = weap_box:AddTab("Weapon")
tab.shadow = weap_box:AddTab("Shadow")

tab.main:AddToggle("", {Text = "Enabled", Default = config.auto_mob, Callback = function(v)
    config.auto_mob = v
    save()

    print(v)
    task.spawn(auto_mob)
end})

tab.main:AddToggle("", {Text = "Auto Brute", Default = config.auto_brute, Callback = function(v)
    config.auto_brute = v
    save()
    
    float(v)
end})

tab.main:AddToggle("", {Text = "Can Teleport", Default = config.can_teleport, Callback = function(v)
    config.can_teleport = v
    save()
end})

tab.main_settings:AddSlider("", {Text = "Kill Speed", Default = config.kill_speed, Min = 0, Max = 5, Rounding = 0.1, Suffix = "", Callback = function(v)
    config.kill_speed = v
    save()
end})

tab.main_settings:AddSlider("", {Text = "Y Level", Default = config.y_level, Min = -10, Max = 10, Rounding = 1, Suffix = "", Callback = function(v)
    config.y_level = v
    save()
end})

tab.castle:AddToggle("", {Text = "Auto Castle", Default = config.auto_castle, Callback = function(v)
    config.auto_castle = v
    save()

    task.spawn(auto_castle)
end})

tab.castle:AddToggle("", {Text = "Auto Skip Floor", Default = config.auto_skip_floor, Callback = function(v)
    config.auto_skip_floor = v
    save()
end})

tab.castle:AddToggle("", {Text = "Auto Arise Boss", Default = config.auto_arise_boss, Callback = function(v)
    config.auto_arise_boss = v
    save()

    task.spawn(auto_arise_boss)
end})

tab.castle:AddSlider("", {Text = "Leave After Floor", Default = config.leave_after_floor, Min = 1, Max = 100, Rounding = 1, Suffix = "", Callback = function(v)
    config.leave_after_floor = v
    save()
end})

tab.weapon:AddToggle("", {Text = "Auto Upgrade Weapon", Default = config.auto_upgrade_weapon, Callback = function(v)
    config.auto_upgrade_weapon = v
    save()

    task.spawn(auto_upgrade_weapon)
end})

tab.shadow:AddToggle("", {Text = "Auto Sell Shadow", Default = config.auto_sell_shadow, Callback = function(v)
    config.auto_sell_shadow = v
    save()

    task.spawn(auto_sell_shadow)
end})

tab.shadow:AddDropdown("", {Text = "Rank To Sell", Values = ranks, Default = config.selected_ranks, Multi = true, Callback = function(val)
    config.selected_ranks = {}
    for i, v in val do
        table.insert(config.selected_ranks, i)
    end
    save()
end})

tab.dungeon:AddToggle("", {Text = "Auto Dungeon", Default = config.auto_dungeon, Callback = function(v)
    config.auto_dungeon = v
    save()

    task.spawn(auto_dungeon)
end})

tab.dungeon:AddToggle("", {Text = "Auto Replay", Default = config.auto_replay, Callback = function(v)
    config.auto_replay = v
    save()

    task.spawn(auto_replay)
end})

tab.dungeon:AddToggle("", {Text = "Wait For Double Dungeon", Default = config.wait_double_dungeon, Callback = function(v)
    config.wait_double_dungeon = v
    save()
end})

tab.dungeon:AddToggle("", {Text = "Use Rune", Default = config.use_rune, Callback = function(v)
    config.use_rune = v
    save()
end})

tab.dungeon:AddDropdown("", {Text = "Select Rune", Values = get_runes(), Default = config.selected_runes, Multi = true, Callback = function(val)
    config.selected_runes = {}
    for i, v in val do
        table.insert(config.selected_runes, i)
    end
    save()
end})

tab.dungeon:AddButton("", {Text = "Join Dungeon", Func = function()
    task.spawn(start_dungeon)
end})

tab.spawn:AddDropdown("", {Text = "Teleport Spawn", Values = get_spawns(), Default = nil, Callback = function(val)
    for i, v in player.PlayerGui.Menus.Indexer.Main.Worlds:GetChildren() do
        if v:IsA("ImageButton") and v.Background.Value.Text == val then
            teleport(workspace.__Extra.__Spawns[v.Name].CFrame)
        end
    end
end})

tab.spawn:AddDropdown("", {Text = "Set Spawn", Values = get_spawns(), Default = nil, Callback = function(val)
    for i, v in player.PlayerGui.Menus.Indexer.Main.Worlds:GetChildren() do
        if v:IsA("ImageButton") and v.Background.Value.Text == val then
            fire_remote({Event = "ChangeSpawn", Spawn = v.Name}, nil, "GENERAL_EVENT")
        end
    end
end})

tab.misc:AddToggle("", {Text = "Server Hop", Default = false, Callback = function(v)
    local servers = ("https://games.roblox.com/v1/games/%*/servers/Public?sortOrder=Asc&limit=100"):format(87039211657390)
    
    function list_servers(cursor)
        return http_service:JSONDecode(game:HttpGet(("%*%*"):format(servers, cursor and "&cursor=" .. cursor or "")))
    end

    local server, next_page; repeat
        local servers = list_servers(next_page)
        server = servers.data[1]
        next_page = servers.nextPageCursor
        task.wait(0.5)
    until server

    teleport_service:TeleportToPlaceInstance(87039211657390, server.id, player)
end})

tab.misc:AddToggle("", {Text = "Afk Mode", Default = false, Callback = function(v)
    config.afk_mode = v
    save()

    afk_mode(v)
end})

tab.misc:AddToggle("", {Text = "Hide Name - CLIENT", Default = config.hide_name, Callback = function(v)
    config.hide_name = v
    save()

    task.spawn(hide_name)
end})

tab.misc:AddToggle("", {Text = "Auto Rejoin", Default = config.auto_rejoin, Callback = function(v)
    config.auto_rejoin = v
    save()
end})

tab.misc:AddToggle("", {Text = "Auto Execute", Default = config.auto_execute, Callback = function(v)
    config.auto_execute = v
    save()

    if not v then return end
    queue_on_teleport([[
        getgenv().key = "11ASTCTVY0EYJKnPq5ILQR_ODcVi11MRxpZgAPLZA80f9v4NO3SAriM4xhWm4wVKQaM4TKEX2KT2GL39AA"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/uzu/refs/heads/main/main.lua"))()
    ]])
end})

tab.misc:AddToggle("", {Text = "Auto Hide UI", Default = config.auto_show, Callback = function(v)
    config.auto_show = v
    save()

    if not v then return end
    library:Toggle(not v)
end})

tab.misc:AddButton("", {Text = "Unload UI", Func = function()
    library:Unload()
end})

tab.shop:AddToggle("", {Text = "Auto Buy Potion", Default = config.auto_buy_potion, Callback = function(v)
    config.auto_buy_potion = v
    save()

    task.spawn(auto_buy_potion)
end})

tab.shop:AddDropdown("", {Text = "Select Potion", Values = potions, Default = config.selected_potions, Multi = true, Callback = function(val)
    config.selected_potions = {}
    for i, v in val do
        table.insert(config.selected_potions, i)
    end
    save()
end})

tab.shop:AddToggle("", {Text = "Auto Exchange Dust", Default = config.auto_exchange_dust, Callback = function(v)
    config.auto_exchange_dust = v
    save()

    task.spawn(auto_exchange_dust)
end})

tab.shop:AddDropdown("", {Text = "Select Dust", Values = dusts, Default = config.selected_dust, Multi = true, Callback = function(val)
    config.selected_dust = {}
    for i, v in val do
        table.insert(config.selected_dust, i)
    end
    save()
end})

tab.webhook:AddInput("", {Text = "Webhook Url", Default = config.webhook_url, Placeholder = "https://discord.com/api/webhooks/", Callback = function(v)
    config.webhook_url = v
    save()
end})

tab.webhook:AddInput("", {Text = "User Id", Default = config.user_id, Placeholder = "566100315401879592", Callback = function(v)
    config.user_id = v
    save()
end})

tab.webhook:AddToggle("", {Text = "Send Dungeon Drops", Default = config.send_webhook, Callback = function(v)
    config.send_webhook = v
    save()
end})

time_label = tab.info:AddLabel("Server Time:")
cash_label = tab.info:AddLabel("Cash Earned:")
gems_label = tab.info:AddLabel("Gems Earned:")

for i, v in core_gui.RobloxPromptGui.promptOverlay:GetChildren() do
    if v.Name == "ErrorPrompt" and config.auto_rejoin then
        player:Kick("Rejoining")
        teleport_service:Teleport(87039211657390, player)
    end
end

core_gui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(v)
    if v.Name == "ErrorPrompt" and config.auto_rejoin then
        player:Kick("Rejoining")
        teleport_service:Teleport(87039211657390, player)
    end
end)

print("script laoded")
