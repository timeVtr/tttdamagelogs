--[[User rights.

	First argument: name of usergroup (e. g. "user" or "admin").

	Second argument: access level. Default value is 2 (will be used if a usergroup isn't here).
	1 : Can't view 'Logs before your death' tab in !report frame
	2 : Can't view logs of active rounds
	3 : Can view logs of active rounds as a spectator
	4 : Can always view logs of active rounds

	Everyone can view logs of previous rounds.

	Third argument: access to RDM Manager tab in Damagelogs (true/false).
]]
--
Damagelog:AddUser("superadmin", 4, true)
Damagelog:AddUser("manager", 4, true)
Damagelog:AddUser("headadmin", 4, true)
Damagelog:AddUser("senioradmin", 4, true)
Damagelog:AddUser("admin", 4, true)
Damagelog:AddUser("trialadmin", 4, true)
Damagelog:AddUser("headmoderator", 4, true)
Damagelog:AddUser("seniormoderator", 4, true)
Damagelog:AddUser("moderator", 4, true)
Damagelog:AddUser("trialmoderator", 4, true)


Damagelog:AddUser("vip", 2, false)
Damagelog:AddUser("user", 2, false)
-- The F-key
Damagelog.Key = KEY_F8
--[[Is a message shown when an alive player opens the menu?
	0 : if you want to only show it to superadmins
	1 : to let others see that you have abusive admins
]]
--
Damagelog.AbuseMessageMode = 0
-- true to enable the RDM Manager, false to disable it
Damagelog.RDM_Manager_Enabled = true
-- Command to open the report menu. Don't forget the quotation marks
Damagelog.RDM_Manager_Command = "!report"
-- Command to open the respond menu while you're alive
Damagelog.Respond_Command = "!respond"
--[[Set to true if you want to enable MySQL (it needs to be configured on config/mysqloo.lua)
	Setting it to false will make the logs use SQLite (garrysmod/sv.db)
]]
--
Damagelog.Use_MySQL = true
--[[Autoslay and Autojail Mode
REQUIRES ULX/SAM ! If you are using ServerGuard, set this to 0 (it will use ServerGuard's autoslay automatically)
- 0 : Disables autoslay
- 1 : Enables the !aslay and !aslayid command for ULX, designed to work with the logs.
	  Works like that : !aslay target number_of_slays reason
	  Example : !aslay tommy228 2 RDMing a traitor
	  Example : !aslayid STEAM_0:0:1234567 2 RDMing a traitor
- 2 : Enables the autojail system instead of autoslay. Replaces the !aslay and !aslay commands by !ajail and !ajailid
]]
--
Damagelog.ULX_AutoslayMode = 1
-- Force autoslain players to be innocents (ULX/SAM only)
-- Do not enable this if another addon interferes with roles (Pointshop roles for example)
Damagelog.ULX_Autoslay_ForceRole = false
-- Default autoslay reasons (ULX, SAM, and ServerGuard)
Damagelog.Autoslay_DefaultReason = "Breaking Rules"
Damagelog.Autoslay_DefaultReason1 = "Attempted RDM"
Damagelog.Autoslay_DefaultReason2 = "RDM"
Damagelog.Autoslay_DefaultReason3 = "RDMx2"
Damagelog.Autoslay_DefaultReason4 = "RDMx3"
Damagelog.Autoslay_DefaultReason5 = "TRDM"
Damagelog.Autoslay_DefaultReason6 = "Revenge RDM"
Damagelog.Autoslay_DefaultReason7 = "Team Kill"
Damagelog.Autoslay_DefaultReason8 = "Targeted"
Damagelog.Autoslay_DefaultReason9 = "Lying"
Damagelog.Autoslay_DefaultReason10 = "Improper Response"
Damagelog.Autoslay_DefaultReason11 = "False Report"
Damagelog.Autoslay_DefaultReason12 = "Leave"

-- Default ban reasons (ULX and ServerGuard)
Damagelog.Ban_DefaultReason1 = "Consistent RDM"
Damagelog.Ban_DefaultReason2 = "Attempted Mass RDM"
Damagelog.Ban_DefaultReason3 = "Mass RDM"
Damagelog.Ban_DefaultReason4 = "Consistent Targeted RDM"
Damagelog.Ban_DefaultReason5 = "Homophobic Slurs"
Damagelog.Ban_DefaultReason6 = "Racial Slurs"
Damagelog.Ban_DefaultReason7 = "Excessive Harassment"
Damagelog.Ban_DefaultReason8 = "Ghosting"
Damagelog.Ban_DefaultReason9 = "Teaming"
Damagelog.Ban_DefaultReason10 = "Advertising"
Damagelog.Ban_DefaultReason11 = "Cheating"
Damagelog.Ban_DefaultReason12 = "DDOS/DOX Threats"
-- The number of days the logs last on the database (to avoid lags when opening the menu)
Damagelog.LogDays = 60
-- Hide the Donate button on the top-right corner
Damagelog.HideDonateButton = true
-- Use the Workshop to download content files
Damagelog.UseWorkshop = true
-- Force a language - When empty use user-defined language
Damagelog.ForcedLanguage = "english"
-- Allow reports even with no staff online
Damagelog.NoStaffReports = true
-- Allow more than 2 reports per round
Damagelog.MoreReportsPerRound = true
-- Allow reports before playing
Damagelog.ReportsBeforePlaying = true
-- Private message prefix from RDM Manager
Damagelog.PrivateMessagePrefix = "[RDM Manager]"



-- Discord Webhooks
-- You can create a webhook on your Discord server that will automatically post messages when a report is created.
-- IMPORTANT:
-- 		Discord blocks webhooks from GMod servers.
--		You will need to proxy your requests through a web server
--		GMod Server -> Web Server -> Discord


-- Webhook mode:
-- 0 - disabled
-- 1 - create messages for new reports when there are no admins online
-- 2 - create messages for every report
Damagelog.DiscordWebhookMode = 1


-- Don't forget to set the value of "ttt_dmglogs_discordurl" convar to your webhook URL in server.cfg
