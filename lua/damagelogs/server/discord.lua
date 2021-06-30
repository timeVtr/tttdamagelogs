local POST_MODES = {
    DISABLED = 0,
    WHEN_ADMINS_OFFLINE = 1,
    ALWAYS = 2
}

local url = CreateConVar("ttt_dmglogs_discordurl", "", FCVAR_PROTECTED + FCVAR_LUA_SERVER, "TTTDamagelogs - Discord Webhook URL")
local disabled = Damagelog.DiscordWebhookMode == POST_MODES.DISABLED
local emitOnlyWhenAdminsOffline = Damagelog.DiscordWebhookMode == POST_MODES.WHEN_ADMINS_OFFLINE
local limit = 5
local reset = 0

--local use_chttp = pcall(require, "chttp")
--if use_chttp then
--    HTTP = CHTTP
--end

local function SendDiscordMessageOffline(embed)
    local now = os.time(os.date("!*t"))

    if limit == 0 and now < reset then
        local function tcb()
            SendDiscordMessage(embed)
        end

        timer.Simple(reset - now, tcb)
    end

    local function successCallback(status, body, headers)
        limit = headers["X-RateLimit-Remaining"]
        reset = headers["X-RateLimit-Reset"]
    end

    CHTTP({
        method = "POST",
        url = url:GetString(),
        body = util.TableToJSON({
            embeds = {embed}
        }),
        type = "application/json",
        success = successCallback
    })
end

local function SendDiscordMessageAll(embed)
    local now = os.time(os.date("!*t"))

    if limit == 0 and now < reset then
        local function tcb()
            SendDiscordMessage(embed)
        end

        timer.Simple(reset - now, tcb)
    end

    local function successCallback(status, body, headers)
        limit = headers["X-RateLimit-Remaining"]
        reset = headers["X-RateLimit-Reset"]
    end

    CHTTP({
        method = "POST",
        url = "",
        body = util.TableToJSON({
            embeds = {embed}
        }),
        type = "application/json",
        success = successCallback
    })
end

function Damagelog:DiscordMessage(discordUpdate)
    if disabled then
        return
    end

    local data = {
        title = TTTLogTranslate(nil, "webhook_header_report_submitted"):format(discordUpdate.reportId),
        description = TTTLogTranslate(nil, "webhook_ServerInfo"):format(game.GetMap(), discordUpdate.round),
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        fields = {
            {
                name = TTTLogTranslate(nil, "Victim") .. ":",
                value = "[" .. discordUpdate.victim.nick:gsub("([%*_~<>\\@%]])", "\\%1") .. "](https://steamcommunity.com/profiles/" .. util.SteamIDTo64(discordUpdate.victim.steamID) .. ")",
                inline = true
            },
            {
                name = TTTLogTranslate(nil, "ReportedPlayer") .. ":",
                value = "[" .. discordUpdate.attacker.nick:gsub("([%*_~<>\\@%]])", "\\%1") .. "](https://steamcommunity.com/profiles/" .. util.SteamIDTo64(discordUpdate.attacker.steamID) .. ")",
                inline = true
            },
            {
                name = TTTLogTranslate(nil, "VictimsReport") .. ":",
                value = discordUpdate.reportMessage:gsub("([%*_~<>\\@[])", "\\%1")
            }
        },
        color = 0xffff00
    }


    if discordUpdate.responseMessage != nil then
        local forgivenRow = {
            name = TTTLogTranslate(nil, "ReportedPlayerResponse") .. ":",
            value = discordUpdate.responseMessage:gsub("([%*_~<>\\@[])", "\\%1")
        }
        table.insert(data.fields, forgivenRow)
    end


    if discordUpdate.reportForgiven != nil then
        local rowMessage = ""
        if discordUpdate.reportForgiven.forgiven then
            data.title = TTTLogTranslate(nil, "webhook_header_report_forgiven"):format(discordUpdate.reportId)
            data.color = 0x00ff00
            rowMessage = TTTLogTranslate(nil, "webhook_report_forgiven")
        else
            data.title = TTTLogTranslate(nil, "webhook_header_report_kept"):format(discordUpdate.reportId)
            data.color = 0xff0000
            rowMessage = TTTLogTranslate(nil, "webhook_report_kept")
        end

        local forgivenRow = {
            name = TTTLogTranslate(nil, "webhook_report_forgiven_or_kept") .. ":",
            value = rowMessage
        }
        table.insert(data.fields, forgivenRow)
    end


    if discordUpdate.reportHandled ~= nil then
        data.title = TTTLogTranslate(nil, "webhook_header_report_finished"):format(discordUpdate.reportId)
        data.color = 0x0394fc

        local rowMessage = "[" .. discordUpdate.reportHandled.admin.nick:gsub("([%*_~<>\\@%]])", "\\%1") .. "](https://steamcommunity.com/profiles/" .. util.SteamIDTo64(discordUpdate.reportHandled.admin.steamID) .. ")"

        local reportHandlerRow = {
            name = TTTLogTranslate(nil, "webhook_report_finished_by") .. ":",
            value = rowMessage,
            inline = true
        }
        table.insert(data.fields, reportHandlerRow)

        local minutesTaken = math.floor(discordUpdate.reportHandled.secondsTaken / 60)
        local secondsTaken = discordUpdate.reportHandled.secondsTaken % 60
        local reportHandlerTimeRow = {
            name = TTTLogTranslate(nil, "webhook_report_finished_time_taken") .. ":",
            value = string.format("%02d:%02d minutes", minutesTaken, secondsTaken),
            inline = true
        }
         table.insert(data.fields, reportHandlerTimeRow)

        if(discordUpdate.reportHandled.conclusion != nil) then
            local conclusionRow = {
                name = TTTLogTranslate(nil, "webhook_report_finished_conclusion") .. ":",
                value = discordUpdate.reportHandled.conclusion
            }
            table.insert(data.fields, conclusionRow)
        end
    end


    SendDiscordMessageAll(data)
    if (emitOnlyWhenAdminsOffline and not discordUpdate.adminOnline) then
        data.footer = {
            text = TTTLogTranslate(nil, discordUpdate.adminOnline and "webhook_AdminsOnline" or "webhook_NoAdminsOnline")
        }
        SendDiscordMessageOffline(data)
    end
    
end
