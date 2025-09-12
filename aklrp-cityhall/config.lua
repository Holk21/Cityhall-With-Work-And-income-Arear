Config = {}

-- NPC (City Hall Clerk) - Multiple Locations
Config.Peds = {
    {
        model = 'cs_bankman', -- change to your preferred ped
        coords = vec4(-262.55, -962.20, 31.22, 159), -- city hall example
        scenario = 'WORLD_HUMAN_CLIPBOARD', -- set false to disable
        blip = {
            enabled = true,
            name = 'Work And Income',
            sprite = 419,
            color = 29,
            scale = 0.8
        },
        target = {
            usePedTarget = true,
            icon = 'fa-solid fa-id-card',
            label = 'Open Winz',
            boxZone = { coords = vec3(-262.55, -962.20, 31.22), length = 1.6, width = 1.6, heading = 28.0, minZ = 37.22, maxZ = 39.62 }
        }
    }
}

-- Items (make sure they exist in your shared/items.lua)
Config.Items = {
    id_card = 'id_card',
    driver_license = 'driver_license'
}

-- Prices
Config.Prices = {
    id_card = 150,
    driver_license = 500
}

-- Payment methods allowed: 'cash', 'bank'
Config.AllowedPayments = {'cash', 'bank'}

-- Jobs available at the Job Center (non-whitelisted typically)
Config.Jobs = {
    {label = 'Taxi Driver', name = 'taxi', defaultGrade = 0},
    {label = 'Trucker', name = 'trucker', defaultGrade = 0},
    {label = 'Garbage', name = 'garbage', defaultGrade = 0},
    {label = 'Tow', name = 'tow', defaultGrade = 0},
    {label = 'Journalist', name = 'reporter', defaultGrade = 0}
}

-- Restrict job change cooldown (seconds). 0 to disable
Config.JobCooldown = 300

-- Discord webhook for WINZ alerts (replace with your webhook URL)
Config.Webhook = "https://discord.com/api/webhooks/REPLACE_WITH_YOUR_WEBHOOK"
