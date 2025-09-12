local QBCore = exports['qb-core']:GetCoreObject()

-- Helpers
local function IsAdmin(player)
    if not player then return false end
    local src = player.PlayerData and player.PlayerData.source or source
    if QBCore.Functions.HasPermission(src, 'admin') then return true end
    if IsPlayerAceAllowed(src, 'command') then return true end
    return false
end

-- Discord webhook helper
local function sendToDiscord(title, description, color)
    if not Config or not Config.Webhook or Config.Webhook == "" then return end
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 3447003,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, "POST", json.encode({
        username = "WINZ Alerts",
        embeds = embed
    }), { ["Content-Type"] = "application/json" })
end

-- Config
QBCore.Functions.CreateCallback('aklrp-cityhall:getConfig', function(source, cb)
    cb({
        jobs = Config.Jobs,
        prices = Config.Prices,
        payments = Config.PaymentMethods or { 'cash', 'bank' }
    })
end)

-- Admin flag + pending counts
QBCore.Functions.CreateCallback('aklrp-cityhall:getWinzData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local isAdmin = IsAdmin(Player)
    MySQL.scalar('SELECT COUNT(*) FROM winz_food_grants WHERE status = "pending"', {}, function(foodCount)
        MySQL.scalar('SELECT COUNT(*) FROM winz_money_grants WHERE status = "pending"', {}, function(moneyCount)
            cb({ isAdmin = isAdmin, pending = (foodCount or 0) + (moneyCount or 0) })
        end)
    end)
end)

-- Buy item
QBCore.Functions.CreateCallback('aklrp-cityhall:buyItem', function(source, cb, item, method, price)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ok=false, msg="Player not found"}) end
    local cost = tonumber(price) or (Config.Prices[item] or 0)
    if Player.Functions.GetMoney(method) < cost then
        return cb({ok=false, msg="Not enough money"})
    end
    Player.Functions.RemoveMoney(method, cost, 'cityhall-purchase-'..item)
    Player.Functions.AddItem(item, 1)
    cb({ok=true, msg="Purchased "..item.." for $"..cost})
end)

-- Set job
QBCore.Functions.CreateCallback('aklrp-cityhall:setJob', function(source, cb, jobName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ok=false, msg="Player not found"}) end
    if not jobName or not QBCore.Shared.Jobs[jobName] then
        return cb({ok=false, msg="Job not found"})
    end
    Player.Functions.SetJob(jobName, 0)
    cb({ok=true, msg="Job set to "..jobName})
end)

-- Submit Food Grant
QBCore.Functions.CreateCallback('aklrp-cityhall:submitWinz', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ok=false, msg="Player not found"}) end
    MySQL.insert('INSERT INTO winz_food_grants (citizenid, fullname, why_need, what_left_short, phone, amount, status, created_at) VALUES (?,?,?,?,?,?,?, NOW())',
    { Player.PlayerData.citizenid, data.fullname, data.why, data.cause, Player.PlayerData.charinfo and Player.PlayerData.charinfo.phone or "", data.amount, 'pending' },
    function(id)
        -- Send webhook
        sendToDiscord(
            "📢 New WINZ Food Grant Application",
            ("**Player:** %s\n**CitizenID:** %s\n**Phone:** %s\n**Amount:** $%s\n**Reason:** %s\n**Cause:** %s\n**Ref ID:** %s")
                :format(Player.PlayerData.name or Player.PlayerData.charinfo.firstname or "Unknown", Player.PlayerData.citizenid, Player.PlayerData.charinfo and Player.PlayerData.charinfo.phone or "N/A", tostring(data.amount), data.why or "", data.cause or "", tostring(id)),
            3447003
        )
        cb({ok=true, msg="Application submitted. Ref #"..id})
    end)
end)

-- Submit Money Grant
QBCore.Functions.CreateCallback('aklrp-cityhall:submitWinzMoney', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ok=false, msg="Player not found"}) end
    MySQL.insert('INSERT INTO winz_money_grants (citizenid, fullname, purpose, amount, what_left_short, status, created_at) VALUES (?,?,?,?,?,?, NOW())',
    { Player.PlayerData.citizenid, data.fullname, data.reason, data.amount, data.cause, 'pending' },
    function(id)
        -- Send webhook
        sendToDiscord(
            "💰 New WINZ Money Grant Application",
            ("**Player:** %s\n**CitizenID:** %s\n**Amount:** $%s\n**Purpose:** %s\n**Cause:** %s\n**Ref ID:** %s")
                :format(Player.PlayerData.name or Player.PlayerData.charinfo.firstname or "Unknown", Player.PlayerData.citizenid, tostring(data.amount), data.reason or "", data.cause or "", tostring(id)),
            15844367
        )
        cb({ok=true, msg="Application submitted. Ref #"..id})
    end)
end)

-- List applications (admin)
QBCore.Functions.CreateCallback('aklrp-cityhall:listWinz', function(source, cb, status, type_)
    status = status or 'pending'
    type_ = type_ or 'food'
    local tableName = (type_ == 'money') and 'winz_money_grants' or 'winz_food_grants'
    MySQL.query(('SELECT * FROM %s WHERE status = ? ORDER BY created_at DESC'):format(tableName), { status }, function(rows)
        cb({ok=true, rows = rows or {}})
    end)
end)

-- View one application
QBCore.Functions.CreateCallback('aklrp-cityhall:getWinzApplication', function(source, cb, id, type_)
    local tableName = (type_ == 'money') and 'winz_money_grants' or 'winz_food_grants'
    MySQL.single(('SELECT * FROM %s WHERE id = ?'):format(tableName), { id }, function(app)
        if not app then cb({ok=false, msg="Not found"}) else cb({ok=true, app=app}) end
    end)
end)

-- Approve / deny
QBCore.Functions.CreateCallback('aklrp-cityhall:actWinz', function(source, cb, id, action, type_, reason)
    local Admin = QBCore.Functions.GetPlayer(source)
    local tableName = (type_ == 'money') and 'winz_money_grants' or 'winz_food_grants'
    MySQL.single(('SELECT * FROM %s WHERE id=? AND status="pending"'):format(tableName), { id }, function(app)
        if not app then return cb({ok=false, msg="Not found"}) end

        if action == 'approve' then
            MySQL.update(('UPDATE %s SET status="approved", reviewed_by=?, reviewed_at=NOW() WHERE id=?'):format(tableName), { Admin.PlayerData.name, id })
            local tPlayer = QBCore.Functions.GetPlayerByCitizenId(app.citizenid)
            if tPlayer then
                tPlayer.Functions.AddMoney('bank', app.amount, 'WINZ grant approved')
            end
            cb({ok=true, msg="Approved and $"..app.amount.." paid."})

            sendToDiscord(
                "✅ WINZ Application Approved",
                ("**Admin:** %s\n**Player:** %s\n**CitizenID:** %s\n**Amount:** $%s\n**Type:** %s\n**App ID:** %s")
                    :format(Admin.PlayerData.name or "Admin", app.fullname or "", app.citizenid or "", tostring(app.amount or 0), type_ or "unknown", tostring(app.id or id)),
                3066993
            )

        else
            local deny_text = reason or "No reason provided"
            MySQL.update(('UPDATE %s SET status="denied", reviewed_by=?, deny_reason=?, reviewed_at=NOW() WHERE id=?'):format(tableName),
                { Admin.PlayerData.name, deny_text, id })
            cb({ok=true, msg="Denied."})

            sendToDiscord(
                "❌ WINZ Application Denied",
                ("**Admin:** %s\n**Player:** %s\n**CitizenID:** %s\n**Amount:** $%s\n**Type:** %s\n**App ID:** %s\n**Reason:** %s")
                    :format(Admin.PlayerData.name or "Admin", app.fullname or "", app.citizenid or "", tostring(app.amount or 0), type_ or "unknown", tostring(app.id or id), deny_text),
                15158332
            )
        end
    end)
end)
