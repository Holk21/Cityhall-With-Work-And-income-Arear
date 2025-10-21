-- Framework detection (Qbox > QBCore)
local Core, IsQbox
do
    if GetResourceState('qbx_core') == 'started' then
        Core = exports['qbx_core']:GetCoreObject()
        IsQbox = true
    else
        Core = exports['qb-core']:GetCoreObject()
        IsQbox = false
    end
end

-- ===== Helpers =====
local function GetPlayer(src)
    return Core.Functions.GetPlayer(src)
end

local function IsAdmin(srcOrPlayer)
    local src = type(srcOrPlayer) == 'number' and srcOrPlayer or srcOrPlayer.PlayerData and srcOrPlayer.PlayerData.source
    if not src then return false end
    if Core.Functions.HasPermission(src, 'admin') then return true end
    if IsPlayerAceAllowed(src, 'command') then return true end
    return false
end

-- ===== Discord Webhook =====
local function sendToDiscord(title, description, color)
    if not Config or not Config.Webhook or Config.Webhook == "" or Config.Webhook == "https://discord.com/api/webhooks/REPLACE_WITH_YOUR_WEBHOOK" then
        return
    end
    local embed = {{
        title = title or "Cityhall",
        description = description or "",
        color = color or 3066993
    }}
    PerformHttpRequest(Config.Webhook, function() end, 'POST',
        json.encode({ username = "Cityhall", embeds = embed }),
        { ['Content-Type'] = 'application/json' }
    )
end

-- ===== Config callback =====
Core.Functions.CreateCallback('aklrp-cityhall:getConfig', function(source, cb)
    cb({
        jobs = Config.Jobs,
        prices = Config.Prices,
        payments = Config.PaymentMethods or { 'cash', 'bank' }
    })
end)

-- ===== WINZ data (admin flag + pending count) =====
Core.Functions.CreateCallback('aklrp-cityhall:getWinzData', function(source, cb)
    local Player = GetPlayer(source)
    local isAdmin = IsAdmin(source)

    local tbl = "aklrp_winz"
    local pending = MySQL.scalar.await(('SELECT COUNT(*) FROM %s WHERE status = ?'):format(tbl), {'pending'}) or 0

    cb({ isAdmin = isAdmin, pending = pending })
end)

-- ===== Buy items (ID / Driver Licence) =====
Core.Functions.CreateCallback('aklrp-cityhall:buyItem', function(source, cb, item, method, price)
    local Player = GetPlayer(source)
    if not Player then return cb({ok=false, msg="No player"}) end

    item   = tostring(item or '')
    method = tostring(method or 'cash')
    price  = tonumber(price or 0) or 0

    if price < 0 or price > 100000 then return cb({ok=false, msg="Invalid price"}) end

    local label = item:gsub('_',' '):gsub('^%l', string.upper)
    local payOk = false

    if method == 'cash' then
        if Player.Functions.RemoveMoney('cash', price, 'cityhall-purchase') then payOk = true end
    else
        if Player.Functions.RemoveMoney('bank', price, 'cityhall-purchase') then payOk = true end
    end

    if not payOk then return cb({ok=false, msg="Not enough money"}) end

    Player.Functions.AddItem(item, 1)
    TriggerClientEvent('inventory:client:ItemBox', source, {name=item, label=label}, "add")

    cb({ok=true, msg= ("Purchased %s"):format(label) })
end)

-- ===== Job center =====
Core.Functions.CreateCallback('aklrp-cityhall:setJob', function(source, cb, jobName)
    local Player = GetPlayer(source)
    if not Player then return cb({ok=false, msg="No player"}) end

    local job = tostring(jobName or '')
    if job == '' then return cb({ok=false, msg="Invalid job"}) end

    local defaultGrade = 0
    for _, j in ipairs(Config.Jobs or {}) do
        if j.name == job then defaultGrade = j.defaultGrade or 0 break end
    end

    Player.Functions.SetJob(job, defaultGrade)
    cb({ok=true, msg=("You are now %s"):format(job)})
end)

-- ===== WINZ: submit application =====
Core.Functions.CreateCallback('aklrp-cityhall:submitWinz', function(source, cb, data)
    local Player = GetPlayer(source)
    if not Player then return cb({ok=false, msg="No player"}) end

    local tbl = "aklrp_winz"
    local citizenid = Player.PlayerData.citizenid
    local amount = tonumber(data and data.amount or 0) or 0
    local type_  = tostring(data and data.type or 'unknown')
    local reason = tostring(data and data.reason or '')

    if amount < 1 or amount > 100000 then
        return cb({ok=false, msg="Invalid amount"})
    end

    local id = MySQL.insert.await(('INSERT INTO %s (citizenid, amount, type, reason, status, created_at) VALUES (?, ?, ?, ?, "pending", NOW())'):format(tbl),
        { citizenid, amount, type_, reason })

    sendToDiscord("📨 WINZ Application Submitted",
        ("**Player:** %s\n**CitizenID:** %s\n**Amount:** $%s\n**Type:** %s\n**App ID:** %s")
        :format(Player.PlayerData.name, citizenid, tostring(amount), type_, tostring(id)),
        3447003)

    cb({ok=true, msg="Application submitted", id=id})
end)

-- ===== WINZ: fetch all (admin) =====
Core.Functions.CreateCallback('aklrp-cityhall:fetchWinz', function(source, cb)
    if not IsAdmin(source) then return cb({ok=false, msg="Not authorized"}) end
    local tbl = "aklrp_winz"
    local rows = MySQL.query.await(('SELECT * FROM %s ORDER BY created_at DESC LIMIT 200'):format(tbl), {})
    cb({ok=true, rows = rows or {}})
end)

-- ===== WINZ: review (approve/deny) =====
Core.Functions.CreateCallback('aklrp-cityhall:reviewWinz', function(source, cb, id, action, reason)
    local Admin = GetPlayer(source)
    if not IsAdmin(Admin) then return cb({ok=false, msg="Not authorized"}) end

    id = tonumber(id) or 0
    if id <= 0 then return cb({ok=false, msg="Invalid ID"}) end

    local tbl = "aklrp_winz"
    local app = MySQL.single.await(('SELECT * FROM %s WHERE id = ?'):format(tbl), { id })
    if not app then return cb({ok=false, msg="Not found"}) end

    local type_ = app.type or 'unknown'
    if action == 'approve' then
        MySQL.update.await(('UPDATE %s SET status="approved", reviewed_by=?, reviewed_reason=?, reviewed_at=NOW() WHERE id=?'):format(tbl),
            { Admin.PlayerData.name, 'approved', id })

        -- Pay
        local target = Core.Functions.GetPlayerByCitizenId(app.citizenid)
        if target then
            target.Functions.AddMoney('bank', tonumber(app.amount) or 0, 'WINZ grant approved')
        end

        cb({ok=true, msg="Approved and paid $"..tostring(app.amount)})
        sendToDiscord("✅ WINZ Application Approved",
            ("**Admin:** %s\n**CitizenID:** %s\n**Amount:** $%s\n**Type:** %s\n**App ID:** %s")
            :format(Admin.PlayerData.name, app.citizenid, tostring(app.amount or 0), type_, tostring(app.id)),
            3066993)
    else
        local deny_text = reason or "No reason provided"
        MySQL.update.await(('UPDATE %s SET status="denied", reviewed_by=?, reviewed_reason=?, reviewed_at=NOW() WHERE id=?'):format(tbl),
            { Admin.PlayerData.name, deny_text, id })

        cb({ok=true, msg="Denied"})
        sendToDiscord("❌ WINZ Application Denied",
            ("**Admin:** %s\n**CitizenID:** %s\n**Amount:** $%s\n**Type:** %s\n**App ID:** %s\n**Reason:** %s")
            :format(Admin.PlayerData.name, app.citizenid, tostring(app.amount or 0), type_, tostring(app.id), deny_text),
            15158332)
    end
end)
