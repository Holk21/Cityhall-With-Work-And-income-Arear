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

-- Target detection (ox_target > qb-target)
local hasOxTarget = (GetResourceState('ox_target') == 'started')
local hasQbTarget = (GetResourceState('qb-target') == 'started')

local isOpen = false

local function openCityHallWith(winzData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = "open",
        jobs     = Config.Jobs,
        prices   = Config.Prices,
        payments = Config.PaymentMethods or Config.AllowedPayments or {'cash','bank'},
        winz     = winzData or { isAdmin = false, pending = 0 }
    })
end

local function OpenCityHall()
    if isOpen then return end
    isOpen = true
    Core.Functions.TriggerCallback('aklrp-cityhall:getWinzData', function(winzData)
        openCityHallWith(winzData)
    end)
end

-- NUI
RegisterNUICallback('close', function(_, cb)
    isOpen = false
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('buyItem', function(data, cb)
    Core.Functions.TriggerCallback('aklrp-cityhall:buyItem', function(res) cb(res) end, data.item, data.method, data.price)
end)

RegisterNUICallback('setJob', function(data, cb)
    Core.Functions.TriggerCallback('aklrp-cityhall:setJob', function(res) cb(res) end, data.job)
end)

RegisterNUICallback('winzSubmit', function(data, cb)
    Core.Functions.TriggerCallback('aklrp-cityhall:submitWinz', function(res) cb(res) end, data)
end)

RegisterNUICallback('winzFetch', function(_, cb)
    Core.Functions.TriggerCallback('aklrp-cityhall:fetchWinz', function(res) cb(res) end)
end)

RegisterNUICallback('winzReview', function(data, cb)
    Core.Functions.TriggerCallback('aklrp-cityhall:reviewWinz', function(res) cb(res) end, data.id, data.action, data.reason)
end)

-- Ped + Target set up
local spawnedPeds = {}

local function addTargetToEntity(entity, label, icon, eventName)
    if hasOxTarget then
        exports.ox_target:addLocalEntity(entity, {
            {
                name = 'aklrp-cityhall:open',
                icon = icon or 'fa-solid fa-clipboard',
                label = label or 'City Hall',
                onSelect = function(_) TriggerEvent(eventName) end
            }
        })
    elseif hasQbTarget then
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    type = "client",
                    icon = icon or "fas fa-clipboard",
                    label = label or "City Hall",
                    event = eventName
                }
            },
            distance = 2.0
        })
    else
        -- Fallback: 3D text + E prompt (kept minimal)
        CreateThread(function()
            local ped = entity
            local shown = false
            while DoesEntityExist(ped) do
                local sleep = 1000
                local ply = PlayerPedId()
                local pcoords = GetEntityCoords(ply)
                local ecoords = GetEntityCoords(ped)
                local dist = #(pcoords - ecoords)
                if dist < 2.0 then
                    sleep = 0
                    if not shown then shown = true end
                    SetTextCentre(true)
                    SetTextFont(4) SetTextScale(0.35, 0.35)
                    SetTextColour(255,255,255,215)
                    BeginTextCommandDisplayText("STRING")
                    AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ Open City Hall")
                    EndTextCommandDisplayText(ecoords.x, ecoords.y, ecoords.z+1.0)
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent(eventName)
                    end
                else
                    if shown then shown = false end
                end
                Wait(sleep)
            end
        end)
    end
end

local function spawnPeds()
    for _, p in ipairs(Config.Peds or {}) do
        local model = joaat(p.model or 'cs_bankman')
        RequestModel(model); while not HasModelLoaded(model) do Wait(0) end
        local ped = CreatePed(0, model, p.coords.xyz, p.coords.w, false, false)
        SetEntityAsMissionEntity(ped, true, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)

        if p.scenario then
            TaskStartScenarioInPlace(ped, p.scenario, 0, true)
        end

        -- optional map blip
        if p.blip and p.blip.enabled then
            local blip = AddBlipForCoord(p.coords.xyz)
            SetBlipSprite(blip, p.blip.sprite or 419)
            SetBlipColour(blip, p.blip.color or 29)
            SetBlipScale(blip, p.blip.scale or 0.8)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(p.blip.name or "Work And Income")
            EndTextCommandSetBlipName(blip)
        end

        addTargetToEntity(ped, p.target and p.target.label or "Talk to WINZ Officer", p.target and p.target.icon or "fa-solid fa-clipboard", "aklrp-cityhall:openWinzByPed")

        spawnedPeds[#spawnedPeds+1] = ped
        SetModelAsNoLongerNeeded(model)
    end
end

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        spawnPeds()
    end
end)

-- Command helpers (optional)
RegisterCommand('cityhall', function() OpenCityHall() end)

RegisterNetEvent("aklrp-cityhall:openWinzByPed", function()
    Core.Functions.TriggerCallback('aklrp-cityhall:getWinzData', function(winzData)
        openCityHallWith(winzData)
    end)
end)
