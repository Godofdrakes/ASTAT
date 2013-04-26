--ASTAT
--Godofdrakes, with thanks to DeadWalking.

--[[NOTES
		Exp tracking is broken for now. The names in Player.GetAllProgressionXp are different fron any other instance of the frame name and I'm too lazy to fix it right now.
--]]

require "math"
require "string"
require "table"
require "lib/lib_Slash"
require "lib/lib_InterfaceOptions"
require "lib/lib_Callback2"
require "lib/lib_NavWheel"

--Variables
	--Stats
		local STATS = {}
		local PREP_GLOBAL 	= {KILLS=0, DAMAGE=0, DOWNED=0, DEATHS=0, HEAL=0, REPAIR=0}
		local PREP_FRAME 	= {KILLS=0, DAMAGE=0, DOWNED=0, DEATHS=0, HEAL=0, REPAIR=0, CRITICAL=0, TIME={SEC=0, MIN=0, HOUR=0, DAY=0}, ABILITY={}, EXP={CURRENT=0, LIFETIME=0}}
		local PREP_MOB 		= {FACTION="neutral", KILLS=0, DAMAGE=0, DOWNED=0}
		local TIME_PLAYED	= {SEC=0, MIN=0, HOUR=0, DAY=0}
		local PREP_MISC = {
				HEIGHT		= 0, --Highest point the player has been to.
				MAX_XP		= {COUNT=0, FRAME="none"}, --Tracks what frame has the most XP
				KILLSTREAK	= {COUNT=0, FRAME="none"}, --Used for keeping track of the player's highest killstreak.
				TIME_PLAYED = {SEC=0, MIN=0, HOUR=0, DAY=0}
		}

	--System
		local PLAYERS = {}
		local TEMP = {READY=false, FRAME="none", ARCHTYPE="none", NAME="none", ID=0, ID=0, X=0, Y=0, Z=0, WINDOW="none"}
		local SETTINGS = {
			ASTAT			= true,

			DISPLAY_FRAME	= false,
				FRAME_NAME		= true,
				FRAME_KILLS		= true,
				FRAME_DAMAGE	= true,
				FRAME_DOWNED	= true,
				FRAME_DEATHS	= true,
				FRAME_HEAL		= true,

			DISPLAY_MOB		= false,
				MOB_KILLS		= true,
				MOB_DAMAGE		= true,
				MOB_DOWNED		= true,

			DISPLAY_MISC	= false,
				MISC_HEIGHT		= true,
				MISC_CRIT		= true,
				MISC_XP			= true,
				MISC_STREAK		= true,
				MISC_TIME		= true,

			DEV				= false,
				DEV_KILL 		= true,
				DEV_DAMAGE 		= true,
				DEV_DEATH 		= true,
				DEV_DOWNED 		= true,
				DEV_EXP	 		= true,
				DEV_ABILITY 	= true,
				DEV_FRAME 		= true,
				DEV_LOADED		= true,
				DEV_MESSAGE		= true,
				DEV_READY		= true,
				DEV_WEAPON		= true,

			PVP				= true,
			PVE				= true,
			STATCHECK_TIME	= 5,
		}
		local NAME = {
			ACCORDASSAULT		= "berzerker",
			ASTREKFIRECAT		= "firecat",
			ODMTIGERCLAW		= "tigerclaw",
			ACCORDRECON			= "recon",
			ODMNIGHTHAWK		= "nighthawk",
			ASTREKRAPTOR		= "raptor",
			ACCORDENGINEER		= "bunker",
			ASTREKELECTRON		= "electron",
			ODMBASTION			= "bastion",
			ACCORDBIOTECH		= "medic",
			ASTREKRECLUSE		= "recluse",
			ODMDRAGONFLY		= "dragonfly",
			ACCORDDREADNAUGHT	= "guardian",
			ASTREKRHINO			= "rhino",
			ODMMAMMOTH			= "mammoth",
		}
		local STRINGS = {
			KILLS		= "Kills: ",
			DAMAGE		= "Damage Done: ",
			HEAL		= "Healing Done: ",
			REPAIR		= "Repairs Done: ",
			DOWNED		= "Times Downed: ",
			DEATHS		= "Times Died: ",
			EXP			= "Exp Earned: ",
			ABILITY		= "-- Abilities --",
			WEAPON		= "-- Weapons --",
			MOBS		= "-- Mobs --",
			HEIGHT		= "Highest Altitude: ",
			CRITICAL	= "Critical Hits: ",
			KILLSTREAK	= "Highest Killstreak: ",
		}
		local NAV_INIT = {
			base 			= {sortWeight=1, 	node="astat_base", 						title="ASTAT", 					parent={node="hud_root", 				weight=0}, 	icon={texture="icons", 			region="fashion"},				desc="Stat tracking"},
			player			= {sortWeight=2, 	node="astat_player", 					title="Player",					parent={node="astat_base", 				weight=6}, 	icon={texture="icons", 			region="spawner"},				action="ALL",						desc="All stats"},
			pve 			= {sortWeight=3, 	node="astat_pve", 						title="PvE", 					parent={node="astat_base", 				weight=5}, 	icon={texture="icons", 			region="two_swords"},			action="PVE",						desc="Stats tracked in PvE"},
			pvp 			= {sortWeight=4, 	node="astat_pvp", 						title="PvP", 					parent={node="astat_base", 				weight=4}, 	icon={texture="icons", 			region="sword_and_flag"},		action="PVP",						desc="Stats tracked in PvP"},
			frame 			= {sortWeight=5, 	node="astat_frame", 					title="Battleframes",			parent={node="astat_base", 				weight=3}, 	icon={texture="icons", 			region="battleframe_station"},	desc="Per frame stats"},
			frame_berzerker = {sortWeight=6, 	node="astat_frame_berzerker", 			title="Assault Frames",			parent={node="astat_frame", 			weight=4}, 	icon={texture="battleframes", 	region="berzerker"}},
			berzerker 		= {sortWeight=7, 	node="astat_frame_berzerker_berzerker",	title="Accord", 				parent={node="astat_frame_berzerker", 	weight=2}, 	icon={texture="battleframes", 	region="berzerker"},			action="ACCORDASSAULT"},
			firecat 		= {sortWeight=8, 	node="astat_frame_berzerker_firecat", 	title="FireCat", 				parent={node="astat_frame_berzerker", 	weight=1}, 	icon={texture="battleframes", 	region="berzerker"},			action="ASTREKFIRECAT"},
			tigerclaw 		= {sortWeight=9, 	node="astat_frame_berzerker_tigerclaw",	title="TigerClaw", 				parent={node="astat_frame_berzerker", 	weight=0}, 	icon={texture="battleframes", 	region="berzerker"},			action="ODMTIGERCLAW"},
			frame_recon 	= {sortWeight=10, 	node="astat_frame_recon", 				title="Recon Frames",			parent={node="astat_frame", 			weight=3}, 	icon={texture="battleframes", 	region="recon"}},
			recon 			= {sortWeight=11, 	node="astat_frame_recon_recon", 		title="Accord", 				parent={node="astat_frame_recon", 		weight=2}, 	icon={texture="battleframes", 	region="recon"},				action="ACCORDRECON"},
			nighthawk		= {sortWeight=12, 	node="astat_frame_recon_nighthawk",		title="Nighthawk", 				parent={node="astat_frame_recon", 		weight=1}, 	icon={texture="battleframes", 	region="recon"},				action="ODMNIGHTHAWK"},
			raptor 			= {sortWeight=13, 	node="astat_frame_recon_raptor", 		title="Raptor", 				parent={node="astat_frame_recon", 		weight=0}, 	icon={texture="battleframes", 	region="recon"},				action="ASTREKRAPTOR"},
			frame_bunker 	= {sortWeight=14, 	node="astat_frame_bunker", 				title="Engineer Frames",		parent={node="astat_frame", 			weight=2}, 	icon={texture="battleframes", 	region="bunker"}},
			bunker 			= {sortWeight=15, 	node="astat_frame_bunker_bunker", 		title="Accord", 				parent={node="astat_frame_bunker", 		weight=2}, 	icon={texture="battleframes", 	region="bunker"},				action="ACCORDENGINEER"},
			electron		= {sortWeight=16, 	node="astat_frame_bunker_electron",		title="Electron", 				parent={node="astat_frame_bunker", 		weight=1}, 	icon={texture="battleframes", 	region="bunker"},				action="ASTREKELECTRON"},
			bastion			= {sortWeight=17, 	node="astat_frame_bunker_bastion", 		title="Bastion", 				parent={node="astat_frame_bunker", 		weight=0}, 	icon={texture="battleframes", 	region="bunker"},				action="ODMBASTION"},
			frame_medic 	= {sortWeight=18, 	node="astat_frame_medic", 				title="Biotech Frames",			parent={node="astat_frame", 			weight=1}, 	icon={texture="battleframes", 	region="medic"}},
			medic 			= {sortWeight=19, 	node="astat_frame_medic_medic", 		title="Accord", 				parent={node="astat_frame_medic", 		weight=2},	icon={texture="battleframes", 	region="medic"},				action="ACCORDBIOTECH"},
			recluse 		= {sortWeight=20, 	node="astat_frame_medic_recluse",		title="Recluse", 				parent={node="astat_frame_medic", 		weight=1},	icon={texture="battleframes", 	region="medic"},				action="ASTREKRECLUSE"},
			dragonfly 		= {sortWeight=21, 	node="astat_frame_medic_dragonfly",		title="Dragonfly", 				parent={node="astat_frame_medic", 		weight=0},	icon={texture="battleframes", 	region="medic"},				action="ODMDRAGONFLY"},
			frame_guardian 	= {sortWeight=22, 	node="astat_frame_guardian", 			title="Dreadnaught Frames",		parent={node="astat_frame", 			weight=0}, 	icon={texture="battleframes", 	region="guardian"}},
			guardian 		= {sortWeight=23, 	node="astat_frame_guardian_guardian", 	title="Accord", 				parent={node="astat_frame_guardian", 	weight=2}, 	icon={texture="battleframes", 	region="guardian"},				action="ACCORDDREADNAUGHT"},
			rhino 			= {sortWeight=24, 	node="astat_frame_guardian_rhino", 		title="Rhino",		 			parent={node="astat_frame_guardian", 	weight=1}, 	icon={texture="battleframes", 	region="guardian"},				action="ASTREKRHINO"},
			mammoth 		= {sortWeight=25, 	node="astat_frame_guardian_mammoth", 	title="Mammoth", 				parent={node="astat_frame_guardian", 	weight=0}, 	icon={texture="battleframes", 	region="guardian"},				action="ODMMAMMOTH"},
			mob 			= {sortWeight=29, 	node="astat_mobs", 						title="Mob Stats", 				parent={node="astat_base", 				weight=2}, 	icon={texture="aag_icons", 		region="execute"},				action="MOBS",						desc="Stats on the loacl wildlife."},
			misc 			= {sortWeight=26, 	node="astat_misc", 						title="Misc", 					parent={node="astat_base", 				weight=1}, 	icon={texture="icons",			region="game"},					action="MISC",						desc="Other stats"},
			clear 			= {sortWeight=27, 	node="astat_clear", 					title="Clear all stats",		parent={node="astat_base", 				weight=0},  icon={texture="aag_icons", 		region="execute"},				desc="This cannot be undone!"},
			clear_yes 		= {sortWeight=28, 	node="astat_clear_yes", 				title="Yes", 					parent={node="astat_clear", 			weight=0}, 	icon={texture="icons", 			region="no"}, 					action="clear",						desc="Seriously, no take-backs."},
		}
		local NAV_SORT = {
		}
		for k,v in pairs(NAV_INIT) do
			NAV_SORT[v.sortWeight] = tostring(k)
		end
		local NAV_NODE = {}

	--Timers
		local KILLSTREAK = {
			TIMER	= Callback2.Create(),
			DELAY	= 6,
			COUNT	= 0,
		}
		local STATCHECK = Callback2.Create()

	--Frame
		local dw_MAIN = Component.GetFrame("ASTATMain");
		local dw_INFO = Component.GetWidget("ASTATInfo");
		local dw_BG = Component.GetWidget("ASTATBG");
		local dw_TITLE = Component.GetWidget("ASTATTitle");
		local dw_GROUP = Component.GetWidget("ASTATGroup");

		InterfaceOptions.AddMovableFrame({
			frame = dw_MAIN,
			label = "ASTAT",
			scalable = true,
		})

--Interface Options
	InterfaceOptions.AddCheckBox({id="ASTAT", label="Enable ASTAT", default=SETTINGS.ASTAT, tooltip="Enable/Disable all of ASTAT."})
	InterfaceOptions.AddCheckBox({id="PVE", label="Enable PvE", default=SETTINGS.ASTAT, tooltip="Enable/Disable ASTAT while in PvE."})
	InterfaceOptions.AddCheckBox({id="PVP", label="Enable PvP", default=SETTINGS.ASTAT, tooltip="Enable/Disable ASTAT while in PvP."})
	InterfaceOptions.AddSlider({id="STATCHECK_TIME", label="Check misc stats every", default=SETTINGS.STATCHECK_TIME, min=1, max=60, inc=1, suffix=" sec"})
	--[[Hud Display
		--Frame
			InterfaceOptions.StartGroup({label="Display Frame Stats", checkbox=true, id="DISPLAY_FRAME", default=SETTINGS.DISPLAY_FRAME, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="FRAME_NAME", label="Display frame name", default=SETTINGS.FRAME_NAME, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="FRAME_KILLS", label="Display frame kills", default=SETTINGS.FRAME_KILLS, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="FRAME_DAMAGE", label="Display frame damage done", default=SETTINGS.FRAME_DAMAGE, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="FRAME_DOWNED", label="Display frame times downed", default=SETTINGS.FRAME_DOWNED, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="FRAME_DEATHS", label="Display frame times killed", default=SETTINGS.FRAME_DEATHS, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="FRAME_HEAL", label="Display frame healing/repairs done", default=SETTINGS.FRAME_HEAL, subtab={"HUD Display"}})
			InterfaceOptions.StopGroup({subtab={"HUD Display"}})
		--Mobs
			InterfaceOptions.StartGroup({label="Display Mob Stats", checkbox=true, id="DISPLAY_MOB", default=SETTINGS.DISPLAY_MOB, subtab={"HUD Display"}, tooltip="Displays stats on the last five mobs you've attacked."})
			InterfaceOptions.AddCheckBox({id="MOB_KILLS", label="Display times each mob was killed", default=SETTINGS.MOB_KILLS, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="MOB_DAMAGE", label="Display damage done to each mob", default=SETTINGS.DAMAGE, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="MOB_DOWNED", label="Display times that mob has downed you", default=SETTINGS.DOWNED, subtab={"HUD Display"}})
			InterfaceOptions.StopGroup({subtab={"HUD Display"}})
		--Misc
			InterfaceOptions.StartGroup({label="Display Misc Stats", checkbox=true, id="DISPLAY_MISC", default=SETTINGS.DISPLAY_MISC, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="MISC_HEIGHT", label="Display highest altitude", default=SETTINGS.MISC_HEIGHT, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="MISC_CRIT", label="Display number of critical hits", default=SETTINGS.MISC_CRIT, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="MISC_XP", label="Display what frame has the most lifetime XP", default=SETTINGS.MISC_XP, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="MISC_STREAK", label="Display highest killstreak (max 6sec between kills)", default=SETTINGS.MISC_STREAK, subtab={"HUD Display"}})
			InterfaceOptions.AddCheckBox({id="MISC_TIME", label="Display total time played", default=SETTINGS.MISC_TIME, subtab={"HUD Display"}})
			InterfaceOptions.StopGroup({subtab={"HUD Display"}})--]]
	--Dev
		InterfaceOptions.StartGroup({label="Enable DEV", checkbox=true, id="DEV", default=SETTINGS.DEV, subtab={"DEV"}, tooltip="Logs stuff to the console."})
		InterfaceOptions.AddCheckBox({id="DEV_LOADED", label="MESSAGE.__LOADED", default=SETTINGS.DEV_LOADED, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_KILL", label="OnKill()", default=SETTINGS.DEV_KILL, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_DAMAGE", label="OnDamage()", default=SETTINGS.DEV_DAMAGE, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_DEATH", label="OnDeath()", default=SETTINGS.DEV_DEATH, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_DOWNED", label="OnDowned()", default=SETTINGS.DEV_DOWNED, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_EXP", label="OnExp()", default=SETTINGS.DEV_EXP, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_ABILITY", label="OnAbility()", default=SETTINGS.DEV_ABILITY, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_FRAME", label="OnFrame()", default=SETTINGS.DEV_FRAME, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_READY", label="OnPlayerReady()", default=SETTINGS.DEV_READY, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_WEAPON", label="OnWeaponChange()", default=SETTINGS.DEV_WEAPON, subtab={"DEV"}})
		InterfaceOptions.AddCheckBox({id="DEV_MESSAGE", label="OnMessage()", default=SETTINGS.DEV_MESSAGE, subtab={"DEV"}})
		InterfaceOptions.StopGroup({subtab={"DEV"}})

	InterfaceOptions.NotifyOnLoaded(true)

--Interface Messages
	function OnComponentLoad()
		log("Loading")
		InterfaceOptions.SetCallbackFunc(function(id, val)
			OnMessage({type=id, data=val})
		end, "ASTAT")
	end

	function OnMessage(args)
		if (args.type == "__LOADED") then
			LoadStats()

			InitNavNodes()

			KILLSTREAK.TIMER:Bind(KillStreakCheck)
			KILLSTREAK.TIMER:Schedule(KILLSTREAK.DELAY)

			STATCHECK:Bind(StatCheck)
			STATCHECK:Schedule(SETTINGS.STATCHECK_TIME)

			log("Stats loaded.")
			return nil
		end
		local option = args.type
		local message = args.data
		if (option) then
			if (SETTINGS[option] == nil) then
				warn("Unknown message: "..option.."\n"..tostring(SETTINGS[option]))
				return nil
			end
		end

		SETTINGS[option] = message
		if (SETTINGS.DEV and SETTINGS.DEV_MESSAGE) then log("SETTINGS["..tostring(option).."] = "..tostring(SETTINGS[option]).." (should be "..tostring(message)..")") end
		SetInterfaceOptions()
	end

	function SetInterfaceOptions()
		InterfaceOptions.DisableOption("PVE", not SETTINGS.ASTAT)
		InterfaceOptions.DisableOption("PVP", not SETTINGS.ASTAT)
		InterfaceOptions.DisableOption("STATCHECK_TIME", not SETTINGS.ASTAT)
		--InterfaceOptions.DisableOption("DISPLAY_FRAME", not SETTINGS.ASTAT)
		--InterfaceOptions.DisableOption("DISPLAY_MOB", not SETTINGS.ASTAT)
		--InterfaceOptions.DisableOption("DISPLAY_MISC", not SETTINGS.ASTAT)
		InterfaceOptions.DisableOption("DEV", not SETTINGS.ASTAT)
	end

--Event Functions
	function OnKill(args)
		if (SETTINGS.ASTAT and args["SourceId"] == TEMP.ID) then --It looks like when a grenade from a launcher detonates (and is then removed) it triggers ON_COMBAT_EVENT. This event WON'T have a TargetId.
			if (SETTINGS.DEV and SETTINGS.DEV_KILL) then log("OnKill\n"..tostring(args)) end
			local name = Game.GetTargetInfo(args.TargetId).name
			local ispvp = Game.IsInPvP()
			local faction = Game.GetTargetInfo(args.TargetId).faction
			if (TEMP.READY and (SETTINGS.PVE ~= ispvp or SETTINGS.PVP == ispvp)) then
				--Frame Kills +
					STATS[TEMP.FRAME].KILLS = STATS[TEMP.FRAME].KILLS + 1

				--(PvE and Mob)/PvP Kills +
					if (not ispvp) then
						if (STATS.MOBS[name] == nil) then STATS.MOBS[name] = PREP_MOB; STATS.MOBS[name].FACTION = faction end
						STATS.MOBS[name].KILLS = STATS.MOBS[name].KILLS + 1
						STATS.PVE.KILLS = STATS.PVE.KILLS + 1
					else
						STATS.PVP.KILLS = STATS.PVP.KILLS + 1
					end

				--Killstreak +
					KILLSTREAK.TIMER:Reschedule(KILLSTREAK.DELAY)
					KILLSTREAK.COUNT = KILLSTREAK.COUNT + 1
			end
		end
	end

	function OnDamage(args)
		warn(tostring(args))
		if (SETTINGS.ASTAT and TEMP.READY) then
			if (SETTINGS.DEV and SETTINGS.DEV_DAMAGE and args.entityId) then log("OnDamage\n"..tostring(args)) end
			local name = Game.GetTargetInfo(args["entityId"]).name
			local ispvp = Game.IsInPvP()
			local faction = Game.GetTargetInfo(args["entityId"]).faction
			if (SETTINGS.PVE == (not ispvp) or SETTINGS.PVP == ispvp and args["entityId"] ~= TEMP.ID) then
				--Critical Hits +
					if (args.critical) then
						STATS[TEMP.FRAME].CRITICAL = STATS[TEMP.FRAME].CRITICAL + 1
					end

				--Frame Damage/Heal/Repair +
					if (args["damage"] > 0) then STATS[TEMP.FRAME].DAMAGE = STATS[TEMP.FRAME].DAMAGE + args["damage"]
					elseif (TEMP.ARCHTYPE == "medic") then STATS[TEMP.FRAME].HEAL = STATS[TEMP.FRAME].HEAL + args["damage"]
					elseif (args["damageType"] == "Repair") then STATS[TEMP.FRAME].REPAIR = STATS[TEMP.FRAME].REPAIR + args["damage"]
					end

				--(PvE and Mob)/PvP Damage +
					if (not ispvp) then
						if (STATS.MOBS[name] == nil) then STATS.MOBS[name] = PREP_MOB; STATS.MOBS[name].FACTION = faction end
						STATS.MOBS[name].DAMAGE = STATS.MOBS[name].DAMAGE + 1
						STATS.PVE.DAMAGE = STATS.PVE.DAMAGE + 1
					else
						STATS.PVP.DAMAGE = STATS.PVP.DAMAGE + 1
					end
			end
		end
	end

	function OnDeath(args)
		if (SETTINGS.ASTAT) then
			if (SETTINGS.DEV and SETTINGS.DEV_DEATH) then log("OnDeath\n"..tostring(args)) end
			local ispvp = Game.IsInPvP()
			if (TEMP.READY and (SETTINGS.PVE == (not ispvp) or SETTINGS.PVP == ispvp)) then
				--Frame Deaths +
					STATS[TEMP.FRAME].DEATHS = STATS[TEMP.FRAME].DEATHS + 1

				--PvE/PvP Deaths +
					if (not ispvp) then
						STATS.PVE.DEATHS = STATS.PVE.DEATHS + 1
					else
						STATS.PVP.DEATHS = STATS.PVP.DEATHS + 1
					end
			end
		end
	end

	function OnDowned(args)
		if (SETTINGS.ASTAT) then
			if (SETTINGS.DEV and SETTINGS.DEV_DOWNED) then log("OnDowned\n"..tostring(args)) end
			local name = Game.GetTargetInfo(args.killerId).name
			local ispvp = Game.IsInPvP()
			local faction = Game.GetTargetInfo(args.killerId).faction
			if (TEMP.READY and (SETTINGS.PVE == (not ispvp) or SETTINGS.PVP == ispvp)) then
				--Frame Downs +
					STATS[TEMP.FRAME].DOWNED = STATS[TEMP.FRAME].DOWNED + 1

				--(PvE and Mob)/PvP Downs
					if (not ispvp) then
						if (STATS.MOBS[name] == nil) then STATS.MOBS[name] = PREP_MOB; STATS.MOBS[name].FACTION = faction end
						STATS.MOBS[name].DOWNED = STATS.MOBS[name].DOWNED + 1
						STATS.PVE.DOWNED = STATS.PVE.DOWNED + 1
					else
						STATS.PVP.DOWNED = STATS.PVP.DOWNED + 1
					end
			end
		end
	end

	function OnExp(args)
		--ASTAT doesn't track exp itself. Firefall tracks lifetime and current exp so we just borrow that info.
		--[[if (SETTINGS.ASTAT) then
			if (SETTINGS.DEV and SETTINGS.DEV_EXP) then log("OnExp\n"..tostring(args)) end
			if (TEMP.READY) then
				local exp_table = Player.GetAllProgressionXp()
				for k,v in pairs(exp_table) do
					EXP[normalize(v.name)].LIFETIME = v.lifetime_xp
					EXP[normalize(v.name)].CURRENT = v.current.exp
					if (v.lifetime_xp > STATS.MISC.MAX_XP.COUNT) then STATS.MISC.MAX_XP.COUNT = v.lifetime_xp; STATS.MISC.MAX_XP.COUNT = v.name end
				end
			end
		end--]]
	end

	function OnAbility(args)
		if (SETTINGS.ASTAT) then
			if (SETTINGS.DEV and SETTINGS.DEV_ABILITY) then log("OnAbility\n"..tostring(args)) end
			local name = normalize(Player.GetAbilityInfo(args.id).name)
			if (TEMP.READY and (SETTINGS.PVE == (not ispvp) or SETTINGS.PVP == ispvp)) then
				--Frame Ability +
					if (STATS[TEMP.FRAME].ABILITY[name] == nil) then STATS[TEMP.FRAME].ABILITY[name] = 0 end
					STATS[TEMP.FRAME].ABILITY[name] = STATS[TEMP.FRAME].ABILITY[name] + 1
			end
		end
	end

	function OnFrame(args)
		if (SETTINGS.ASTAT) then
			if (SETTINGS.DEV and SETTINGS.DEV_FRAME) then log("OnFrame\n"..tostring(args)) end
			TEMP.FRAME = normalize(Player.GetCurrentLoadout().name)
			TEMP.ARCHTYPE = Player.GetCurrentLoadout().archtype
			Component.SaveSetting("astat_current_frame", TEMP.FRAME)
			Component.SaveSetting("astat_current_archtype", TEMP.ARCHTYPE)
		end
	end

	function OnPlayerReady(agrs)
		TEMP.ID = Player.GetTargetId()
		TEMP.NAME = normalize(Player.GetInfo())
		WeaponUpdate()
		HealthUpdate()
		EnergyUpdate()
		OnFrame()
		OnExp()
		if (SETTINGS.DEV and SETTINGS.DEV_READY) then
			log("player_Name: "..tostring(TEMP.NAME))
			log("player_ID: "..tostring(TEMP.ID))
		end
		Component.SaveSetting("astat_current_player", TEMP.NAME)
		log("Ready. Tracking stats.")
		TEMP.READY = true
	end

	function OnInputChange(args)
		--Body
	end

	function OnWeaponChange(args)
		if (SETTINGS.ASTAT) then
			if (SETTINGS.DEV and SETTINGS.DEV_WEAPON) then log("OnWeaponChange\n"..tostring(args)) end
		end
	end

	function WeaponUpdate(args)
		if (SETTINGS.ASTAT and TEMP.READY) then
			local weapon_info = {}
			local temp_weap = Player.GetWeaponState(true)
			weapon_info.ammo = temp_weap.Ammo
			weapon_info.clip = temp_weap.Clip
			weapon_info.weapon = Player.GetWeaponInfo().WeaponType

			Component.SaveSetting("astat_current_weapon", weapon_info)
		end
	end

	function HealthUpdate(args)
		if (SETTINGS.ASTAT and TEMP.READY) then
			local vitals_info = Player.GetLifeInfo()

			Component.SaveSetting("astat_current_health", vitals_info)
		end
	end

	function EnergyUpdate(args)
		if (SETTINGS.ASTAT and TEMP.READY) then
			local energy_info = {}
			energy_info.current, energy_info.max = Player.GetEnergy()

			Component.SaveSetting("astat_current_energy", energy_info)
		end
	end

--Save/Load/Clear Stats
	function ClearStats()
		STATS = {}
		PLAYERS[TEMP.NAME] = false
		Component.SaveSetting("ASTAT_PLAYERS", PLAYERS)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_PVP", PREP_GLOBAL)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_PVE", PREP_GLOBAL)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDASSAULT", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKFIRECAT", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMTIGERCLAW", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDRECON", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMNIGHTHAWK", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKRAPTOR", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDENGINEER", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKELECTRON", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMBASTION", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDBIOTECH", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKRECLUSE", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMDRAGONFLY", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDDREADNAUGHT", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKRHINO", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMMAMMOTH", PREP_FRAME)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_TIME_PLAYED", TIME_PLAYED)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_MISC", PREP_MISC)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_MOBS", {})
	end

	function LoadStats()
		PLAYERS					= (Component.GetSetting("ASTAT_NAMES") or {})

		STATS.PVP				= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_PVP") or PREP_GLOBAL) --Load the table
			for k,v in pairs(PREP_GLOBAL) do if (not STATS.PVP[k]) then STATS.PVP[k] = v end end --Ensure tha the table is up to date. Add any mising variables to it.
		STATS.PVE				= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_PVE") or PREP_GLOBAL)
			for k,v in pairs(PREP_GLOBAL) do if (not STATS.PVP[k]) then STATS.PVP[k] = v end end

		STATS.ACCORDASSAULT		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ACCORDASSAULT") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ACCORDASSAULT[k]) then STATS.ACCORDASSAULT[k] = v end end
		STATS.ASTREKFIRECAT		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ASTREKFIRECAT") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ASTREKFIRECAT[k]) then STATS.ASTREKFIRECAT[k] = v end end
		STATS.ODMTIGERCLAW		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ODMTIGERCLAW") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ODMTIGERCLAW[k]) then STATS.ODMTIGERCLAW[k] = v end end

		STATS.ACCORDRECON		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ACCORDRECON") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ACCORDRECON[k]) then STATS.ACCORDRECON[k] = v end end
		STATS.ODMNIGHTHAWK		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ODMNIGHTHAWK") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ODMNIGHTHAWK[k]) then STATS.ODMNIGHTHAWK[k] = v end end
		STATS.ASTREKRAPTOR		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ASTREKRAPTOR") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ASTREKRAPTOR[k]) then STATS.ASTREKRAPTOR[k] = v end end

		STATS.ACCORDENGINEER	= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ACCORDENGINEER") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ACCORDENGINEER[k]) then STATS.ACCORDENGINEER[k] = v end end
		STATS.ASTREKELECTRON	= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ASTREKELECTRON") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ASTREKELECTRON[k]) then STATS.ASTREKELECTRON[k] = v end end
		STATS.ODMBASTION		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ODMBASTION") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ODMBASTION[k]) then STATS.ODMBASTION[k] = v end end

		STATS.ACCORDBIOTECH		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ACCORDBIOTECH") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ACCORDBIOTECH[k]) then STATS.ACCORDBIOTECH[k] = v end end
		STATS.ASTREKRECLUSE		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ASTREKRECLUSE") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ASTREKRECLUSE[k]) then STATS.ASTREKRECLUSE[k] = v end end
		STATS.ODMDRAGONFLY		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ODMDRAGONFLY") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ODMDRAGONFLY[k]) then STATS.ODMDRAGONFLY[k] = v end end

		STATS.ACCORDDREADNAUGHT	= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ACCORDDREADNAUGHT") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ACCORDDREADNAUGHT[k]) then STATS.ACCORDDREADNAUGHT[k] = v end end
		STATS.ASTREKRHINO		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ASTREKRHINO") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ASTREKRHINO[k]) then STATS.ASTREKRHINO[k] = v end end
		STATS.ODMMAMMOTH		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_ODMMAMMOTH") or PREP_FRAME)
			for k,v in pairs(PREP_FRAME) do if (not STATS.ODMMAMMOTH[k]) then STATS.ODMMAMMOTH[k] = v end end

		STATS.TIME_PLAYED		= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_TIME_PLAYED") or TIME_PLAYED)
			for k,v in pairs(TIME_PLAYED) do if (not STATS.TIME_PLAYED[k]) then STATS.TIME_PLAYED[k] = v end end
		STATS.MISC				= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_MISC") or PREP_MISC)
			for k,v in pairs(PREP_MISC) do if (not STATS.MISC[k]) then STATS.MISC[k] = v end end
		STATS.MOBS				= (Component.GetSetting("ASTAT_"..TEMP.NAME.."_MOBS") or {})
	end

	function SaveStats()
		if (not PLAYERS) then PLAYERS = {} end
		PLAYERS[TEMP.NAME] = true
		Component.SaveSetting("ASTAT_PLAYERS", PLAYERS)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_PVP", STATS.PVP)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_PVE", STATS.PVE)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDASSAULT", STATS.ACCORDASSAULT)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKFIRECAT", STATS.ASTREKFIRECAT)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMTIGERCLAW", STATS.ODMTIGERCLAW)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDRECON", STATS.ACCORDRECON)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMNIGHTHAWK", STATS.ODMNIGHTHAWK)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKRAPTOR", STATS.ASTREKRAPTOR)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDENGINEER", STATS.ACCORDENGINEER)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKELECTRON", STATS.ASTREKELECTRON)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMBASTION", STATS.ODMBASTION)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDBIOTECH", STATS.ACCORDBIOTECH)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKRECLUSE", STATS.ASTREKRECLUSE)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMDRAGONFLY", STATS.ODMDRAGONFLY)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ACCORDDREADNAUGHT", STATS.ACCORDDREADNAUGHT)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ASTREKRHINO", STATS.ASTREKRHINO)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_ODMMAMMOTH", STATS.ODMMAMMOTH)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_TIME_PLAYED", STATS.TIME_PLAYED)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_MISC", STATS.MISC)
		Component.SaveSetting("ASTAT_"..TEMP.NAME.."_MOBS", STATS.MOBS)
		Component.GenerateEvent("ASTAT_SAVED", STATS[TEMP.FRAME])
	end

--Stat Display (in chat)
	function ShowStat(stat)
		if (not STATS[stat]) then
			puts("No such stat: "..stat)
			return nil
		end

		if (NAME[stat]) then
			puts("-=- "..(NAME[stat]).." -=-")
			puts(STRINGS.KILLS..STATS[stat].KILLS)
			puts(STRINGS.DAMAGE..STATS[stat].DAMAGE)
			puts(STRINGS.CRITICAL..STATS[stat].CRITICAL)
			if (stat == "ACCORDBIOTECH" or stat == "ASTREKRECLUSE" or stat == "ODMDRAGONFLY") then puts(STRINGS.HEAL..STATS[stat].HEAL)
			if (stat == "ACCORDENGINEER" or stat == "ASTREKELECTRON" or stat == "ODMBASTION") then puts(STRINGS.REPAIR..STATS[stat].REPAIR)
			puts(STRINGS.DOWNED..STATS[stat].DOWNED)
			puts(STRINGS.DEATHS..STATS[stat].DEATHS)
			if (STATS[stat].ABILITY ~= nil and STATS[stat].ABILITY ~= {}) then
				puts("-- Abilities Used")
				for k,v in pairs(STATS[stat].ABILITY) do
					puts(tostring(k).." - "..tostring(v))
				end
			end
			puts("-=- END -=-")
		end

		if (stat = "PVE")
		end

		if (stat = "PVP")
		end

		if (stat = "PLAYER")
		end

		if (stat = "MOBS")
		end
	end

--[[Widgets functions
	function dw_RemoveWidgets()
		-- remove all others
		dw_MAIN:Show(false);
		local countVisible = #dw_currentVisible;
		if #dw_currentVisible > 0 then  dw_currentWindow = nil end
		for _, line in ipairs(dw_currentVisible) do
			Component.RemoveWidget(line.GROUP)
		end
		dw_currentVisible = {};
		dw_currentWindow = nil;
	end

	function dw_CreateWidgets(index,statVal)
		local textName = prep_strings[index];
		if not textName then textName = index end
		--log("dw_CreateWidgets: index: "..tostring(index))
		--log("dw_CreateWidgets: statVal: "..tostring(statVal))

		if index == "height" then
			statVal = math.floor(statVal);
		elseif tostring(type(statVal)) == "number" then
			statVal = math.abs(statVal);
		end

		local moveDown = (10 + (14*((#dw_currentVisible + 1)))+8);	-- DW_ adjust height offset

		local dw_STATLINE = {GROUP=Component.CreateWidget("ASTATText", dw_INFO)}; --DW_ dw_STATLINE can be anything it is local I just wanted it to stand out.
		dw_STATLINE[index] = {};	-- DW_ create a table for each Stat type (i.e. "Kills") for modifying the value on the fly if open.
		dw_STATLINE[index].TYPE = dw_STATLINE.GROUP:GetChild("ASTATType");
		dw_STATLINE[index].VALUE = dw_STATLINE.GROUP:GetChild("ASTATStat");
		Component.FosterWidget(dw_STATLINE.GROUP); -- DW_ adds the widget to the ASTATInfo group. So it can size based on the base ASTATInfo dimensions.
		table.insert(dw_currentVisible,dw_STATLINE); -- DW_ add the widget to the table of opened widgets to remove from dw_RemoveWidgets

		dw_STATLINE[index].TYPE:SetText(textName);
		dw_STATLINE[index].VALUE:SetText(tostring(statVal));

		dw_STATLINE[index].TYPE:SetDims("center-x:_; center-y:_; left:_; top:"..moveDown.."; width:_; height:_"); -- DW_ I have had issue with only SetDims so I perform a move to after.
		dw_STATLINE[index].TYPE:MoveTo("center-x:_; center-y:_; left:_; top:"..moveDown.."; width:_; height:_",0);

		dw_STATLINE[index].VALUE:SetDims("center-x:_; center-y:_; left:_; top:"..moveDown.."; width:_; height:_");
		dw_STATLINE[index].VALUE:MoveTo("center-x:_; center-y:_; left:_; top:"..moveDown.."; width:_; height:_",0);
	end

	function dw_PopulateWidgets(sortTbl)
		local isGlobal = (dw_currentWindow == "player" or dw_currentWindow == "pve" or dw_currentWindow == "pvp"); -- DW_ Check for Global Stats Open
		local isEngi = (dw_currentWindow == "bunker" or dw_currentWindow == "electron" or dw_currentWindow == "bastion"); -- DW_ Check for Engi Stats Open
		local isMedic = (dw_currentWindow == "medic" or dw_currentWindow == "recluse" or dw_currentWindow == "dragonfly"); -- DW_ Check for Medic Stats Open
		local isMisc = (dw_currentWindow == "mobs") -- DW_ Check for Misc Stats Open
		local isWeapon = (dw_currentWindow == "weapon") -- DW_ Check for Weapon Stats Open
		local isMob = (dw_currentWindow == "mobs") -- DW_ Check for Mob Stats Open
		--everything else is a frame.

		local stat = STATS[dw_currentWindow]; -- DW_ shorten our stats list var

		if sortTbl and stat then
			for i,v in ipairs(sortTbl) do
				local showStat = ((v ~= "Repair" and v ~= "Heal") or (isEngi and v == "Repair" or isMedic and v == "Heal") or (isGlobal and (v == "Repair" or v == "Heal")));

				if showStat then
					local statVal = stat[v];	-- DW_ grab the stat Value
					local statIsTbl = nil;
					if statVal and tostring(type(statVal)) == "table" then -- DW_ Remove the Value from the Stat if it is a Table.
						statIsTbl = statVal;
						statVal = "";
					end -- DW_ Remove the Value from the Stat if it is a Table.

					if statVal then -- DW_ Only populate the proper Stats.

						dw_CreateWidgets(v,statVal);

						if statIsTbl then -- DW_ Add Ability Weapon Mob entries.
							--log("************************************************************************************************************")
							log("dw_PopulateWidgets: statIsTbl: "..tostring(statIsTbl))
							for j,k in pairs(statIsTbl) do
								--log("dw_PopulateWidgets: j: "..tostring(j))
								--log("dw_PopulateWidgets:k: "..tostring(k))
								local newVal = k;
								local newIsTbl = nil;
								if tostring(type(newVal)) == "table" then -- DW_ Remove the Value from the Stat if it is a Table.
									newIsTbl = statVal;
									newVal = "";
								end -- DW_ Remove the Value from the Stat if it is a Table.

								if newVal then
									dw_CreateWidgets(j,newVal);

									if newIsTbl then -- DW_ Add Ability Weapon Mob entries.
										--log("************************************************************************************************************")
										--log("dw_PopulateWidgets: newIsTbl: "..tostring(newIsTbl))
										for a,b in pairs(newIsTbl) do
											--log("dw_PopulateWidgets: a: "..tostring(a))
											--log("dw_PopulateWidgets: b: "..tostring(b))
											if b then dw_CreateWidgets(a,b) end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		if #dw_currentVisible > 0 then
			dw_MAIN:SetDims("center-x:_; center-y:_; left:_; top:_; width:_; height:"..(56+((14*#dw_currentVisible)+(2*#dw_currentVisible)))..""); -- DW_ adjust the BG size as needed. Depending on how many widgets were created.
			dw_MAIN:MoveTo("center-x:_; center-y:_; left:_; top:_; width:_; height:"..(56+((14*#dw_currentVisible)+(2*#dw_currentVisible))).."",0);
			dw_MAIN:Show(true);
		end
	end

	function dw_UpdateWidgetText(args)
		if dw_currentWindow then
			local stat = args.stat;
			local statVal = args.value;

			if #dw_currentVisible > 0 then
				local widgetIndex = nil;
				for i,widget in pairs(dw_currentVisible) do
					--log("dw_currentVisible: i: "..tostring(i))
					--log("dw_currentVisible: widget: "..tostring(widget))
					if widget[stat] then widgetIndex = i break end
				end

				if not widgetIndex then -- DW_ Add a new entry if it does not exist. For Weapons,Mobs, and Abilities.
					local statIsTbl = nil;
					if statVal and tostring(type(statVal)) == "table" then -- DW_ Remove the Value from the Stat if it is a Table.
						statIsTbl = statVal;
						statVal = "";
					end -- DW_ Remove the Value from the Stat if it is a Table.

					if not statVal then statVal = "" end -- DW_ just incase. to prevent errors. needed for futrue weapon and mob system.

					dw_CreateWidgets(stat,statVal);
				else
					if stat == "height" then
						dw_currentVisible[widgetIndex][stat].VALUE:SetText(tostring(math.floor(statVal))); -- DW_ update text that is already there.
					else
						dw_currentVisible[widgetIndex][stat].VALUE:SetText(tostring(math.abs(statVal))); -- DW_ update text that is already there.
					end
				end

				dw_MAIN:SetDims("center-x:_; center-y:_; left:_; top:_; width:_; height:"..(56+((14*#dw_currentVisible)+(2*#dw_currentVisible)))..""); -- DW_ adjust the BG size as needed. Depending on how many widgets were created.
				dw_MAIN:MoveTo("center-x:_; center-y:_; left:_; top:_; width:_; height:"..(56+((14*#dw_currentVisible)+(2*#dw_currentVisible))).."",0);
			end
		end
	end--]]

--NavNodes
	function InitNavNodes()
		for k,v in ipairs(NAV_SORT) do
			if (not NAV_NODE[v]) then
				NAV_NODE[v] = NavWheel.CreateNode(NAV_INIT[v].node)
				NAV_NODE[v]:SetTitle(NAV_INIT[v].title)
				NAV_NODE[v]:SetParent(NAV_INIT[v].parent.node, NAV_INIT[v].parent.weight)
				NAV_NODE[v]:GetIcon():SetTexture(NAV_INIT[v].icon.texture, NAV_INIT[v].icon.region)
				if (NAV_INIT[v].desc) then NAV_NODE[v]:SetDescription(NAV_INIT[v].desc) end
				if (STATS[NAV_NODE[v].action]) then
					NAV_NODE[v]:SetAction(function()
						ShowStat(NAV_NODE[v].action)
					end)
				end
			end
		end
	end

	function MobNodes()
		for k,v in pairs(STATS.MOBS) do
			--

		end
	end

--Other Functions
	function StatCheck()
		if (SETTINGS.ASTAT) then
			--Highest Point =
				TEMP.X = Player.GetPosition().x
				TEMP.Y = Player.GetPosition().y
				TEMP.Z = Player.GetPosition().z
				if (TEMP.Z > STATS.MISC.HEIGHT) then STATS.MISC.HEIGHT = TEMP.Z end

			--Time Played +
				STATS.TIME_PLAYED.SEC = STATS.TIME_PLAYED.SEC + SETTINGS.STATCHECK_TIME
				while (STATS.TIME_PLAYED.SEC > 59) do
					STATS.TIME_PLAYED.SEC = STATS.TIME_PLAYED.SEC - 60
					STATS.TIME_PLAYED.MIN = STATS.TIME_PLAYED.MIN + 1
				end

				STATS.TIME_PLAYED.MIN = STATS.TIME_PLAYED.MIN + SETTINGS.STATCHECK_TIME
				while (STATS.TIME_PLAYED.MIN > 59) do
					STATS.TIME_PLAYED.MIN = STATS.TIME_PLAYED.MIN - 60
					STATS.TIME_PLAYED.HOUR = STATS.TIME_PLAYED.HOUR + 1
				end

				STATS.TIME_PLAYED.HOUR = STATS.TIME_PLAYED.HOUR + SETTINGS.STATCHECK_TIME
				while (STATS.TIME_PLAYED.HOUR > 23) do
					STATS.TIME_PLAYED.HOUR = STATS.TIME_PLAYED.HOUR - 24
					STATS.TIME_PLAYED.DAY = STATS.TIME_PLAYED.DAY + 1
				end

			STATCHECK:Reschedule(SETTINGS.STATCHECK_TIME)
			SaveStats()
		end
	end

	function KillStreakCheck()
		if (KILLSTREAK.COUNT > STATS.MISC.KILLSTREAK.COUNT) then STATS.MISC.KILLSTREAK.COUNT = KILLSTREAK.COUNT; STATS.MISC.KILLSTREAK.FRAME = TEMP.FRAME end
		KILLSTREAK.COUNT = 0
	end

	function Puts(buffer)
		Component.GenerateEvent("MY_CHAT_MESSAGE", {channel="system", text=tostring(buffer)})
	end

	function Contains(table, element) --Only supports arrays with no sub-arrays.
	  for k,v in pairs(table) do
	    if v == element then return true end
	  end
	  return false
	end

	function Round(what, precision)
	   return math.floor(what*math.pow(10,precision)+0.5) / math.pow(10,precision)
	end
