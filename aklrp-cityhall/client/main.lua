local QBCore = exports['qb-core']:GetCoreObject()
local isOpen = false

local function OpenCityHall()
    if isOpen then return end
    isOpen = true
    QBCore.Functions.TriggerCallback('aklrp-cityhall:getWinzData', function(winzData)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open",
            jobs = Config.Jobs,
            prices = Config.Prices,
            payments = Config.PaymentMethods or {'cash','bank'},
            winz = winzData or { isAdmin = false, pending = 0 }
        })
    end)
end

RegisterCommand('winz', function() OpenCityHall() end, false)

RegisterNUICallback('close', function(_, cb)
    isOpen = false
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('buyItem', function(data, cb)
    QBCore.Functions.TriggerCallback('aklrp-cityhall:buyItem', function(res) cb(res) end, data.item, data.method, data.price)
end)

RegisterNUICallback('setJob', function(data, cb)
    QBCore.Functions.TriggerCallback('aklrp-cityhall:setJob', function(res) cb(res) end, data.job)
end)

RegisterNUICallback('winzSubmit', function(data, cb)
    QBCore.Functions.TriggerCallback('aklrp-cityhall:submitWinz', function(res) cb(res) end, data)
end)

RegisterNUICallback('winzMoneySubmit', function(data, cb)
    QBCore.Functions.TriggerCallback('aklrp-cityhall:submitWinzMoney', function(res) cb(res) end, data)
end)

RegisterNUICallback('winzAdminList', function(data, cb)
    QBCore.Functions.TriggerCallback('aklrp-cityhall:listWinz', function(res) cb(res) end, data.status, data.type)
end)

RegisterNUICallback('winzGetApplication', function(data, cb)
    QBCore.Functions.TriggerCallback('aklrp-cityhall:getWinzApplication', function(res) cb(res) end, data.id, data.type)
end)

RegisterNUICallback('winzAdminAction', function(data, cb)
    QBCore.Functions.TriggerCallback('aklrp-cityhall:actWinz', function(res) cb(res) end, data.id, data.action, data.type, data.reason)
end)

-- ===== WINZ NPC (qb-target) =====
-- Config (change these)
local WINZ_PedModel = `a_f_m_business_02`   -- any ped model
local WINZ_PedCoords = vector4(-265.0, -963.6, 31.2, 200.0) -- x,y,z,h (City Hall area)

local WINZ_Ped -- handle for cleanup

local function loadModel(hash)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(10)
        timeout = timeout + 1
        if timeout > 500 then break end
    end
    return HasModelLoaded(hash)
end

CreateThread(function()
    if not loadModel(WINZ_PedModel) then
        print("^1[WINZ] Failed to load ped model^0")
        return
    end

    WINZ_Ped = CreatePed(0, WINZ_PedModel, WINZ_PedCoords.x, WINZ_PedCoords.y, WINZ_PedCoords.z - 1.0, WINZ_PedCoords.w, false, true)
    SetEntityInvincible(WINZ_Ped, true)
    SetBlockingOfNonTemporaryEvents(WINZ_Ped, true)
    FreezeEntityPosition(WINZ_Ped, true)

    -- Optional: idle scenario so they look alive
    TaskStartScenarioInPlace(WINZ_Ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

    -- qb-target: add third-eye option
    exports['qb-target']:AddTargetEntity(WINZ_Ped, {
        options = {
            {
                type = "client",
                icon = "fas fa-clipboard",
                label = "Talk to WINZ Officer",
                event = "aklrp-cityhall:openWinzByPed"
            }
        },
        distance = 2.0
    })
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if WINZ_Ped and DoesEntityExist(WINZ_Ped) then
        DeletePed(WINZ_Ped)
    end
end)

-- ===== Open NUI from ped (keeps your server callback flow) =====
RegisterNetEvent("aklrp-cityhall:openWinzByPed", function()
    -- Ask server for admin flag & pending counts, then open UI
    local QBCore = exports['qb-core']:GetCoreObject()
    QBCore.Functions.TriggerCallback('aklrp-cityhall:getWinzData', function(winzData)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open",
            jobs = Config.Jobs,
            prices = Config.Prices,
            payments = Config.PaymentMethods or Config.AllowedPayments or {'cash','bank'},
            winz = winzData or { isAdmin = false, pending = 0 }
        })
    end)
end)
