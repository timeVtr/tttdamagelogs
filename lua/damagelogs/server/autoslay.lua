util.AddNetworkString("DL_SlayMessage")
util.AddNetworkString("DL_AutoSlay")
util.AddNetworkString("DL_AutoslaysLeft")
util.AddNetworkString("DL_PlayerLeft")
util.AddNetworkString("DL_SendJails")
local mode = Damagelog.ULX_AutoslayMode

if mode ~= 1 and mode ~= 2 then
    return
end

local aslay = mode == 1

--if not sql.TableExists("damagelog_autoslay") then
--    sql.Query([[CREATE TABLE damagelog_autoslay (
-- 		ply varchar(32) NOT NULL,
-- 		admins tinytext NOT NULL,
-- 		slays SMALLINT UNSIGNED NOT NULL,
-- 		reason tinytext NOT NULL,
-- 		time BIGINT UNSIGNED NOT NULL);
-- 	]])
-- end

-- if not sql.TableExists("damagelog_names") then
--     sql.Query([[CREATE TABLE damagelog_names (
-- 		steamid varchar(32),
-- 		name varchar(255));
-- 	]])
-- end

hook.Add("PlayerAuthed", "DamagelogNames", function(ply, steamid)
    for _, v in ipairs(player.GetHumans()) do
        if v ~= ply then
            net.Start("DL_AutoslaysLeft")
            net.WriteEntity(v)
            net.WriteUInt(v.AutoslaysLeft or 0, 32)
            net.Broadcast()
        end
    end

    local name = ply:Nick()
    --local query = sql.QueryValue("SELECT name FROM damagelog_names WHERE steamid = '" .. steamid .. "' LIMIT 1")
    local query_str = "SELECT name FROM damagelog_names WHERE steamid = '" .. steamid .. "' LIMIT 1"
    local query = Damagelog.database:query(query_str)
    query.onSuccess = function(self)
        local data = self:getData()
		if #data <= 0 then
			local insert_query = "INSERT INTO damagelog_names (`steamid`, `name`) VALUES('" .. steamid .. "', " .. sql.SQLStr(name) .. ");"
			local queryi = Damagelog.database:query(insert_query)
			queryi.onSuccess = function(self)
				print("Adding new player " .. name .. " to damagelog_names")
			end
			queryi:start()
			--sql.Query("INSERT INTO damagelog_names (`steamid`, `name`) VALUES('" .. steamid .. "', " .. sql.SQLStr(name) .. ");")
		else
			local old_name = data[1]["name"]
			if old_name ~= name then
				local update_name_query = "UPDATE damagelog_names SET name = " .. sql.SQLStr(name) .. " WHERE steamid = '" .. steamid .. "' LIMIT 1;" .. ");"
				local queryu = Damagelog.database:query(update_name_query)
				queryu.onSuccess = function(self)
					print("Updated player " .. name .. "' name in damagelog_names")
				end
				queryu:start()
				--sql.Query("UPDATE damagelog_names SET name = " .. sql.SQLStr(name) .. " WHERE steamid = '" .. steamid .. "' LIMIT 1;")
			end
		end
    end
    query:start()

    local get_autoslay_query_str = "SELECT slays FROM damagelog_autoslay WHERE ply = '" .. steamid .. "' LIMIT 1;"
    local get_autoslay_query = Damagelog.database:query(get_autoslay_query_str)
    get_autoslay_query.onSuccess = function(self) 
		local data = self:getData()
		if #data <= 0 then
			ply.AutoslaysLeft = 0
			net.Start("DL_AutoslaysLeft")
			net.WriteEntity(ply)
			net.WriteUInt(0, 32)
			net.Broadcast()
		else
			local c = data[1]["slays"]
			if not tonumber(c) then
				c = 0
			end
			ply.AutoslaysLeft = c
			net.Start("DL_AutoslaysLeft")
			net.WriteEntity(ply)
			net.WriteUInt(c, 32)
			net.Broadcast()
		end
	end
	get_autoslay_query:start()
	--local c = sql.Query("SELECT slays FROM damagelog_autoslay WHERE ply = '" .. steamid .. "' LIMIT 1;")

    --if not tonumber(c) then
    --    c = 0
    --end


end)

function Damagelog:GetName(steamid)
    for _, v in ipairs(player.GetHumans()) do
        if v:SteamID() == steamid then
            return v:Nick()
        end
    end

    --local query = sql.QueryValue("SELECT name FROM damagelog_names WHERE steamid = '" .. steamid .. "' LIMIT 1;")
    --[[local steamid_query_str = "SELECT name FROM damagelog_names WHERE steamid = '" .. steamid .. "' LIMIT 1;"
    local steamid_query = Damagelog.database:query(steamid_query_str)
    steamid_query.onSuccess = function(self) 
		local data = self:getData()
		local player_name = data[1]["name"]
	end 
	steamid_query:start()
	
	return query or "<Error>"]]--
	return "OFFLINE"
end

function Damagelog.SlayMessage(ply, message)
    net.Start("DL_SlayMessage")
    net.WriteString(message)
    net.Send(ply)
end

function Damagelog:CreateSlayList(tbl)
    if #tbl == 1 then
        return self:GetName(tbl[1])
    else
        local result = ""

        for i = 1, #tbl do
            if i == #tbl then
                result = result .. " and " .. self:GetName(tbl[i])
            elseif i == 1 then
                result = self:GetName(tbl[i])
            else
                result = result .. ", " .. self:GetName(tbl[i])
            end
        end

        return result
    end
end

-- ty evolve
function Damagelog:FormatTime(t)
    if t < 0 then
        -- 24 * 3600
        -- 24 * 3600 * 7
        -- 24 * 3600 * 30
        return "Forever"
    elseif t < 60 then
        if t == 1 then
            return "one second"
        else
            return t .. " seconds"
        end
    elseif t < 3600 then
        if math.Round(t / 60) == 1 then
            return "one minute"
        else
            return math.Round(t / 60) .. " minutes"
        end
    elseif t < 86400 then
        if math.Round(t / 3600) == 1 then
            return "one hour"
        else
            return math.Round(t / 3600) .. " hours"
        end
    elseif t < 604800 then
        if math.Round(t / 86400) == 1 then
            return "one day"
        else
            return math.Round(t / 86400) .. " days"
        end
    elseif t < 2592000 then
        if math.Round(t / 604800) == 1 then
            return "one week"
        else
            return math.Round(t / 604800) .. " weeks"
        end
    else
        if math.Round(t / 2592000) == 1 then
            return "one month"
        else
            return math.Round(t / 2592000) .. " months"
        end
    end
end

local function NetworkSlays(steamid, number)
    for _, v in ipairs(player.GetHumans()) do
        if v:SteamID() == steamid then
            v.AutoslaysLeft = number
            net.Start("DL_AutoslaysLeft")
            net.WriteEntity(v)
            net.WriteUInt(number, 32)
            net.Broadcast()

            return
        end
    end
end

function Damagelog:SetSlays(admin, steamid, slays, reason, target)
    if reason == "" then
        reason = Damagelog.Autoslay_DefaultReason
    end

    if slays == 0 then
		local removeslay_query_str = "DELETE FROM damagelog_autoslay WHERE ply = '" .. steamid .. "';"
		local removeslay_query = Damagelog.database:query(removeslay_query_str)
		removeslay_query:start()
		
        --sql.Query("DELETE FROM damagelog_autoslay WHERE ply = '" .. steamid .. "';")
        local name = self:GetName(steamid)

        if target then
            --ulx.fancyLogAdmin(admin, aslay and "#A removed the autoslays of #T." or "#A removed the autojails of #T.", target)
            D3A.Chat.Broadcast(admin:NameID() .. " has removed " .. target:NameID() .. "'s autoslays!" )
            --D3A.Chat.Broadcast(admin:NameID() .. " has autoslayed " .. target:NameID() .. " for " .. supp[1]:GetAutoSlay() .. " rounds. Reason: " .. reason )
        else
            --ulx.fancyLogAdmin(admin, aslay and "#A removed the autoslays of #s." or "#A removed the jails of #s.", steamid)
            D3A.Chat.Broadcast(admin:Name() .. " has removed " .. steamid .. "'s autoslays!" )
        end

        NetworkSlays(steamid, 0)
    else
		local some_query_str = "SELECT * FROM damagelog_autoslay WHERE ply = '" .. steamid .. "' LIMIT 1"
		local some_query = Damagelog.database:query(some_query_str)
		some_query.onSuccess = function(self)
			local data = self:getData()
			if #data > 0 then
				local adminid

				if IsValid(admin) and type(admin) == "Player" then
					adminid = admin:SteamID()
				else
					adminid = "Console"
				end

				local old_slays = tonumber(data[1]["slays"])
				local old_steamids = util.JSONToTable(data[1]["admins"]) or {}
				local new_steamids = table.Copy(old_steamids)

				if not table.HasValue(new_steamids, adminid) then
					table.insert(new_steamids, adminid)
				end

				if old_slays == slays then
					local list = Damagelog:CreateSlayList(old_steamids)
					local nick = Damagelog:GetName(steamid)
					local msg

					if target then
						if aslay then
							msg = target:NameID() .. " was already autoslain "
						else
							msg = target:NameID() .. " was already autojailed "
							--msg = "#T was already autojailed "
						end

					   D3A.Chat.Broadcast(msg .. slays .. " time(s) by " .. admin:NameID() .. " for " .. reason)
					else
						if aslay then
							--msg = "#s was already autoslain "
							msg = steamid .. " was already autoslain "
						else
							--msg = "#s was already autojailed "
							msg = steamid .. " was already autoslain "
						end

						D3A.Chat.Broadcast(msg .. slays .. " time(s) by " .. admin:NameID() .. " for " .. reason)
					end
				else
					local difference = slays - old_slays
					--sql.Query(string.format("UPDATE damagelog_autoslay SET admins = %s, slays = %i, reason = %s, time = %s WHERE ply = '%s' LIMIT 1;", sql.SQLStr(new_admins), slays, sql.SQLStr(reason), tostring(os.time()), steamid))
					local update_slays_query_str = string.format("UPDATE damagelog_autoslay SET admins = %s, slays = %i, reason = %s, time = %s WHERE ply = '%s' LIMIT 1;", sql.SQLStr(new_admins), slays, sql.SQLStr(reason), tostring(os.time()), steamid)
					local update_slays_query = Damagelog.database:query(update_slays_query_str)
					update_slays_query:start()
					local list = Damagelog:CreateSlayList(old_steamids)
					local nick = Damagelog:GetName(steamid)
					local msg

					if target then
						if aslay then
							--msg = " autoslays to #T (#s). He was previously autoslain "
							msg = " autoslays to " .. target:NameID() .. ". He was previously autoslain "
						else
							msg = " autojails to " .. target:NameID() .. ". He was previously autojailed "
						end

						D3A.Chat.Broadcast(admin:NameID() .. (difference > 0 and " added " or " removed ") .. math.abs(difference) .. msg .. old_slays .. " time(s)")
					else
						if aslay then
							msg = " autoslays to " .. steamid .. ". He was previously autoslain "
						else
							msg = " autojails to " .. steamid .. ". He was previously autojailed "
						end

						--ulx.fancyLogAdmin(admin, "#A " .. (difference > 0 and "added " or "removed ") .. math.abs(difference) .. msg .. old_slays .. " time(s) by #s.", steamid, reason, list)
						D3A.Chat.Broadcast(admin:NameID() .. (difference > 0 and " added " or " removed ") .. math.abs(difference) .. msg .. old_slays .. " time(s)")
					end

					NetworkSlays(steamid, slays)
				end
			else
				local admins

				if IsValid(admin) and type(admin) == "Player" then
					admins = util.TableToJSON({admin:SteamID()})
				else
					admins = util.TableToJSON({"Console"})
				end

				--sql.Query(string.format("INSERT INTO damagelog_autoslay (`admins`, `ply`, `slays`, `reason`, `time`) VALUES (%s, '%s', %i, %s, %s);", sql.SQLStr(admins), steamid, slays, sql.SQLStr(reason), tostring(os.time())))
				local autoslay_query_str = string.format("INSERT INTO damagelog_autoslay (`admins`, `ply`, `slays`, `reason`, `time`) VALUES (%s, '%s', %i, %s, %s);", sql.SQLStr(admins), steamid, slays, sql.SQLStr(reason), tostring(os.time())) 
				local autoslay_query = Damagelog.database:query(autoslay_query_str)
				autoslay_query:start()
				
				local msg

				if target then
					if aslay then
						--msg = " autoslays to #T (#s)"
						msg = " autoslays to " .. target:NameID() .. ". Reason: "
						msg = " autoslays to " .. target:NameID() .. ". Reason: "
					else
						--msg = " autojails to #T (#s)"
						msg = " autojails to " .. target:NameID().. ". Reason: "
					end

					D3A.Chat.Broadcast(admin:NameID() .. " added " .. slays .. msg .. reason)
				else
					if aslay then
						--msg = " autoslays to #s (#s)"
						msg = " autoslays to " .. steamid .. ". Reason: "
					else
						--msg = " autojails to #s (#s)"
						msg = " autojails to " .. steamid .. ". Reason: "
					end

					D3A.Chat.Broadcast(admin:NameID() .. " added " .. slays .. msg .. reason)
				end

				NetworkSlays(steamid, slays)
			end
		end
		some_query:start()
        --local data = sql.QueryRow("SELECT * FROM damagelog_autoslay WHERE ply = '" .. steamid .. "' LIMIT 1")
    end
end

local mdl1 = Model("models/props_building_details/Storefront_Template001a_Bars.mdl")

local jail = {
    {
        pos = Vector(0, 0, -5),
        ang = Angle(90, 0, 0),
        mdl = mdl1
    },
    {
        pos = Vector(0, 0, 97),
        ang = Angle(90, 0, 0),
        mdl = mdl1
    },
    {
        pos = Vector(21, 31, 46),
        ang = Angle(0, 90, 0),
        mdl = mdl1
    },
    {
        pos = Vector(21, -31, 46),
        ang = Angle(0, 90, 0),
        mdl = mdl1
    },
    {
        pos = Vector(-21, 31, 46),
        ang = Angle(0, 90, 0),
        mdl = mdl1
    },
    {
        pos = Vector(-21, -31, 46),
        ang = Angle(0, 90, 0),
        mdl = mdl1
    },
    {
        pos = Vector(-52, 0, 46),
        ang = Angle(0, 0, 0),
        mdl = mdl1
    },
    {
        pos = Vector(52, 0, 46),
        ang = Angle(0, 0, 0),
        mdl = mdl1
    }
}

hook.Add("TTTBeginRound", "Damagelog_AutoSlay", function()
    for _, v in ipairs(player.GetHumans()) do
        if v:IsActive() then
            timer.Simple(1, function()
                v:SetNWBool("PlayedSRound", true)
            end)

            local data = sql.QueryRow("SELECT * FROM damagelog_autoslay WHERE ply = '" .. v:SteamID() .. "' LIMIT 1")
			local slay_query_str = "SELECT * FROM damagelog_autoslay WHERE ply = '" .. v:SteamID() .. "' LIMIT 1"
			local slay_query = Damagelog.database:query(slay_query_str)
			slay_query.onSuccess = function(self) 
				local data = self:getData()
				if #data > 0 then
					if aslay then
						timer.Simple(0.5, function()
							hook.Run("DL_AslayHook", v)
						end)

						v:Kill()
					--[[else
						local pos = v:GetPos()
						local walls = {}

						for _, info in ipairs(jail) do
							local ent = ents.Create("prop_physics")
							ent:SetModel(info.mdl)
							ent:SetPos(pos + info.pos)
							ent:SetAngles(info.ang)
							ent:Spawn()
							ent:GetPhysicsObject():EnableMotion(false)
							ent:SetCustomCollisionCheck(true)
							ent.jailWall = true
							table.insert(walls, ent)
						end

						timer.Simple(1, function()
							net.Start("DL_SendJails")
							net.WriteUInt(#walls, 32)

							for _, v2 in ipairs(walls) do
								net.WriteEntity(v2)
							end

							local filter = RecipientFilter()
							filter:AddAllPlayers()

							if IsValid(v) then
								filter:RemovePlayer(v)
							end

							net.Send(filter)
						end)

						local function unjail()
							for _, ent in ipairs(walls) do
								if IsValid(ent) then
									ent:Remove()
								end
							end

							if not IsValid(v) then
								return
							end

							v.jail = nil
						end

						v.jail = {
							pos = pos,
							unjail = unjail
						}]]--
					end

					local admins = util.JSONToTable(data[1]["admins"]) or {}
					local slays = data[1]["slays"]
					local reason = data[1]["reason"]
					local _time = data[1]["time"]
					slays = slays - 1

					if slays <= 0 then
						local delete_slays_query_str = "DELETE FROM damagelog_autoslay WHERE ply = '" .. v:SteamID() .. "';"
						--sql.Query("DELETE FROM damagelog_autoslay WHERE ply = '" .. v:SteamID() .. "';")
						local delete_slays_query = Damagelog.database:query(delete_slays_query_str)
						delete_slays_query:start()
						NetworkSlays(steamid, 0)
						v.AutoslaysLeft = 0
					else
						local update_slays_query_str = "UPDATE damagelog_autoslay SET slays = slays - 1 WHERE ply = '" .. v:SteamID() .. "';"
						--sql.Query("UPDATE damagelog_autoslay SET slays = slays - 1 WHERE ply = '" .. v:SteamID() .. "';")
						local update_slays_query = Damagelog.database:query(update_slays_query_str)
						update_slays_query:start()
						NetworkSlays(steamid, slays - 1)

						if tonumber(v.AutoslaysLeft) then
							v.AutoslaysLeft = v.AutoslaysLeft - 1
						end
					end

					local list = Damagelog:CreateSlayList(admins)
					net.Start("DL_AutoSlay")
					net.WriteEntity(v)
					net.WriteString(list)
					net.WriteString(reason)
					net.WriteString(Damagelog:FormatTime(tonumber(os.time()) - tonumber(_time)))
					net.WriteUInt(v.AutoslaysLeft, 32)
					net.Broadcast()
					--D3A.Chat.Broadcast(v:NameID() .. " was autoslain by " .. list .. ". Reason: " .. reason .. ". " .. v.AutoslaysLeft .. " autoslay" .. (v.AutoslaysLeft > 1 and "s" or "") .. " left." )

					if IsValid(v.server_ragdoll) then
						local ply = player.GetBySteamID(v.server_ragdoll.sid)

						if not IsValid(ply) then
							return
						end

						ply:SetCleanRound(false)
						ply:SetNWBool("body_found", true)

						if not ROLES and ply:GetRole() == ROLE_TRAITOR or ROLES and ply:HasTeamRole(TEAM_TRAITOR) then
							SendConfirmedTraitors(GetInnocentFilter(false))
						end

						CORPSE.SetFound(v.server_ragdoll, true)
						v.server_ragdoll:Remove()
					end
				end
			end
			slay_query:start()
        end
    end
end)

hook.Add("PlayerDisconnected", "Autoslay_Message", function(ply)
    if tonumber(ply.AutoslaysLeft) and ply.AutoslaysLeft > 0 then
        net.Start("DL_PlayerLeft")
        net.WriteString(ply:Nick())
        net.WriteString(ply:SteamID())
        net.WriteUInt(ply.AutoslaysLeft, 32)
        net.Broadcast()
		D3A.Chat.Broadcast(ply:NameID() .. " has disconnected with " .. ply.AutoslaysLeft .. " autoslay".. (ply.AutoslaysLeft > 1 and "s" or "") .. " left!")
    end
end)

if Damagelog.ULX_Autoslay_ForceRole then
    hook.Add("Initialize", "Autoslay_ForceRole", function()
        if not ROLES then
            local function GetTraitorCount(ply_count)
                local traitor_count = math.floor(ply_count * GetConVar("ttt_traitor_pct"):GetFloat())
                traitor_count = math.Clamp(traitor_count, 1, GetConVar("ttt_traitor_max"):GetInt())

                return traitor_count
            end

            local function GetDetectiveCount(ply_count)
                if ply_count < GetConVar("ttt_detective_min_players"):GetInt() then
                    return 0
                end

                local det_count = math.floor(ply_count * GetConVar("ttt_detective_pct"):GetFloat())
                det_count = math.Clamp(det_count, 1, GetConVar("ttt_detective_max"):GetInt())

                return det_count
            end

            function SelectRoles()
                local choices = {}

                local prev_roles = {
                    [ROLE_INNOCENT] = {},
                    [ROLE_TRAITOR] = {},
                    [ROLE_DETECTIVE] = {}
                }

                if not GAMEMODE.LastRole then
                    GAMEMODE.LastRole = {}
                end

                for _, v in ipairs(player.GetHumans()) do
                    if IsValid(v) and (not v:IsSpec()) and not (v.AutoslaysLeft and tonumber(v.AutoslaysLeft) > 0) then
                        local r = GAMEMODE.LastRole[v:SteamID()] or v:GetRole() or ROLE_INNOCENT
                        table.insert(prev_roles[r], v)
                        table.insert(choices, v)
                    end

                    v:SetRole(ROLE_INNOCENT)
                end

                local choice_count = #choices
                local traitor_count = GetTraitorCount(choice_count)
                local det_count = GetDetectiveCount(choice_count)

                if choice_count == 0 then
                    return
                end

                local ts = 0

                while ts < traitor_count do
                    local pick = math.random(1, #choices)
                    local pply = choices[pick]

                    if IsValid(pply) and ((not table.HasValue(prev_roles[ROLE_TRAITOR], pply)) or (math.random(1, 3) == 2)) then
                        pply:SetRole(ROLE_TRAITOR)
                        table.remove(choices, pick)
                        ts = ts + 1
                    end
                end

                local ds = 0
                local min_karma = GetConVar("ttt_detective_karma_min"):GetInt()

                while ds < det_count and #choices >= 1 do
                    if #choices <= (det_count - ds) then
                        for _, pply in pairs(choices) do
                            if IsValid(pply) then
                                pply:SetRole(ROLE_DETECTIVE)
                            end
                        end

                        break
                    end

                    local pick = math.random(1, #choices)
                    local pply = choices[pick]

                    if IsValid(pply) and (pply:GetBaseKarma() > min_karma and table.HasValue(prev_roles[ROLE_INNOCENT], pply) or math.random(1, 3) == 2) then
                        if not pply:GetAvoidDetective() then
                            pply:SetRole(ROLE_DETECTIVE)
                            ds = ds + 1
                        end

                        table.remove(choices, pick)
                    end
                end

                GAMEMODE.LastRole = {}

                for _, ply in ipairs(player.GetHumans()) do
                    ply:SetDefaultCredits()
                    GAMEMODE.LastRole[ply:SteamID()] = ply:GetRole()
                end
            end
        end
    end)
end