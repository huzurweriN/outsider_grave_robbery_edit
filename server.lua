---@diagnostic disable: undefined-global
data = {}
local VorpCore = {}
local VorpInv = {}

local JobsTable = {}

TriggerEvent("getCore", function(core)
    VorpCore = core
end)

VorpInv = exports.vorp_inventory:vorp_inventoryApi()
local BccUtils = exports['bcc-utils'].initiate()

local police_alert = exports['bcc-job-alerts']:RegisterAlert({
    name = 'mezar', --The name of the alert
    command = nil, -- the command, this is what players will use with /
    message = 'Mezar Soygunu', -- Message to show to theh police
    messageTime = 30000, -- Time the message will stay on screen (miliseconds)
    job = 'police', -- Job the alert is for
    jobgrade = { 0, 1, 2, 3, 4, 5 }, -- What grades the alert will effect
    icon = "star", -- The icon the alert will use
    hash = -1282792512, -- The radius blip
    radius = 40.0, -- The size of the radius blip
    blipTime = 60000, -- How long the blip will stay for the job (miliseconds)
    blipDelay = 5000, -- Delay time before the job is notified (miliseconds)
    originText = "", -- Text displayed to the user who enacted the command
    originTime = 0 --The time the origintext displays (miliseconds)
})


local TEXTS = Config.Texts
local TEXTURES = Config.Textures

local DiggedGraves = {}

RegisterServerEvent("ricx_grave_robbery:check_shovel")
AddEventHandler("ricx_grave_robbery:check_shovel", function(id, Town)
    local _source = source

    if DiggedGraves[id] == true then
        TriggerClientEvent("Notification:left_grave_robbery", _source, TEXTS.GraveRobbery, TEXTS.GraveRobbed,
            TEXTURES.alert[1], TEXTURES.alert[2], 2000)
        return
    end

    local item = VorpInv.getItem(_source, Config.ShovelItem)
    if item then
        if not next(item.metadata) then
            -- if not metadata we add new values
            local newData = {
                description = "Shovel durability %" .. 100 - 3,
                durability = 100 - 3,
                id = item.id
            }
            VorpInv.setItemMetadata(_source, item.id, newData)
            TriggerClientEvent("ricx_grave_robbery:start_dig", _source, id)
            police_alert:SendAlert(_source)
            TriggerEvent("outsider_alertjobs", Town)
        else
            if item.metadata.durability <= 0 then
                TriggerClientEvent("Notification:left_grave_robbery", _source, TEXTS.GraveRobbery, "Shovel is broken",
                    TEXTURES.alert[1], TEXTURES.alert[2], 2000)
                return
            end

            local newData = {
                description = "Shovel durability %" .. item.metadata.durability - 3,
                durability = item.metadata.durability - 3,
                id = item.metadata.id
            }

            VorpInv.setItemMetadata(_source, item.metadata.id, newData)
            TriggerClientEvent("ricx_grave_robbery:start_dig", _source, id)
            TriggerEvent("outsider_alertjobs", Town)
            police_alert:SendAlert(_source)
        end
    else
        TriggerClientEvent("Notification:left_grave_robbery", _source, TEXTS.GraveRobbery, TEXTS.NoShovel,
            TEXTURES.alert[1], TEXTURES.alert[2], 2000)
    end
end)

local Lines = {
    "You have found nothing the person buried here was poor as hell",
    "All that hard work for nothing damn fool",
    "Why not be a farmer cant find shit with your luck",
    "You thought it was easy? rob somone alive ",
    "God is watching you and has punished you ,just like he pusnished the man in here your next..."

}

RegisterServerEvent("ricx_grave_robbery:reward")
AddEventHandler("ricx_grave_robbery:reward", function(id)
    local _source = source
    Citizen.Wait(math.random(200, 800))

    ---@type table
    local Rewards = Config.Graves[id].Rewards
    local random = math.random(1, #Rewards)


    if DiggedGraves[id] == true then
        TriggerClientEvent("Notification:left_grave_robbery", _source, TEXTS.GraveRobbery, TEXTS.GraveRobbed,
            TEXTURES.alert[1], TEXTURES.alert[2], 2000)
        return
    end

    DiggedGraves[id] = true
    local lucky = 2
    local chance = math.random(1, 5)
    if lucky == chance then
        local Item = Config.Graves[id].Rewards[random].item
        local label = Config.Graves[id].Rewards[random].label
        VorpInv.addItem(_source, Item, 1)
        TriggerClientEvent("Notification:left_grave_robbery", _source, TEXTS.GraveRobbery,
            TEXTS.FoundItem .. "\n+ " .. label
            , TEXTURES.alert[1], TEXTURES.alert[2], 2000)
    else
        local rand = math.random(1, #Lines)
        TriggerClientEvent("Notification:left_grave_robbery", _source, TEXTS.GraveRobbery, Lines[rand],
            TEXTURES.alert[1], TEXTURES.alert[2], 2000)
    end
end)

function CheckTable(table, element)
    for k, v in pairs(table) do
        if v == element then
            return true
        end
    end
    return false
end

RegisterServerEvent("outsider_robbery:sendPlayers", function(source)
    if not source then return end
    local _source = source
    local user = VorpCore.getUser(_source)

    if user then
        local job = user.getUsedCharacter.job                           -- player job

        if CheckTable(Config.JobsToAlert, job) then                     -- if player exist and job equals to config then add to table
            JobsTable[#JobsTable + 1] = { source = _source, job = job } -- id
        end
    end
end)

-- remove player from table when leaving
AddEventHandler('playerDropped', function()
    local _source = source
    for index, value in pairs(JobsTable) do
        if value.source == _source then
            JobsTable[index] = nil
        end
    end
end)

