local t = {}

local HTTPS = game:GetService("HttpService")

local CurrentPlayers = {}

local Commands = {"kill", "respawn", "kick", "ban", "unban", "owner", "unowner", "administrator", "unadministrator", "moderator", "unmoderator", "walkspeed", "jumppower"}

local configModule = require(script.Parent)

local Prefix = configModule.Prefix
local DefaultPlayers = configModule.DefaultPlayers

local default = {
	["Ranks"] = {
		["Owner"] = false,
		["Administrator"] = false,
		["Moderator"] = false,
		["Banned"] = {false, ""}
	}
}

function t.LoadPlayerData(player, dataStore)
	local toDecode
	local success, err = pcall(function()
		toDecode = dataStore:GetAsync(player.UserId)
	end)
	
	if success and toDecode then
		local toLoad = HTTPS:JSONDecode(toDecode)
		CurrentPlayers[player.Name] = toLoad or default
	else
		CurrentPlayers[player.Name] = default
	end
	
	if CurrentPlayers[player.Name]["Ranks"]["Banned"][1] then
		player:Kick("\nYou Have Been Banned\nFor: "..CurrentPlayers[player.Name]["Ranks"]["Banned"][2])
	end
	
	for rank, tbl in pairs(DefaultPlayers) do
		if rank == "Banned" and table.find(tbl, player.Name) then
			CurrentPlayers[player.Name]["Ranks"]["Banned"][1] = true
			player:Kick("\nYou Have Been Banned\nFor: "..CurrentPlayers[player.Name]["Ranks"]["Banned"][2])
		elseif rank == "Moderators" and table.find(tbl, player.Name) then
			CurrentPlayers[player.Name]["Ranks"]["Moderator"] = true
			t.Notify(player, "You Are A Moderator")
		elseif rank == "Administrators" and table.find(tbl, player.Name) then
			CurrentPlayers[player.Name]["Ranks"]["Administrator"] = true
			t.Notify(player, "You Are An Administrator")
		elseif rank == "Owners" and table.find(tbl, player.Name) then
			CurrentPlayers[player.Name]["Ranks"]["Owner"] = true
			t.Notify(player, "You Are An Owner")
		end
	end
end

function t.SavePlayerData(player, dataStore)
	local toEncode = CurrentPlayers[player.Name]
	local encoded = HTTPS:JSONEncode(toEncode)
	
	pcall(function()
		dataStore:SetAsync(player.UserId, encoded)
	end)
	
	t.RemovePlayerData(player)
end

function t.CreateDataStore(Name)
	if not Name then return end
	
	local DSS = game:GetService("DataStoreService")
	local GDS = DSS:GetDataStore(Name)
	
	return GDS
end

function t.RemovePlayerData(player)
	CurrentPlayers[player.Name] = nil
end

function t.DetectChatMsg(player, msg, gds)
	local count = 0
	for rank,val in pairs(CurrentPlayers[player.Name]["Ranks"]) do
		if val == true then
			count += 1
		end
	end
	
	if count <= 0 then return end
	
	if string.sub(msg, 2, 2) == " " then return end
	
	if string.sub(msg, 1, 1) == Prefix then
		local c
		for _,cmd in pairs(Commands) do
			if string.match(msg:lower(), cmd:lower()) then
				c = cmd
			end
		end
		
		if c then
			if c:lower() == "kill" then
				local target = string.sub(msg, 7, #msg)
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					local targChar = plrTarg.Character or plrTarg.CharacterAdded:Wait()
					targChar:WaitForChild("Humanoid").Health = 0
					targChar:BreakJoints()
				end
			elseif c:lower() == "respawn" then
				local target = string.sub(msg, 10, #msg)
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					plrTarg:LoadCharacter()
				end
			elseif c:lower() == "kick" then
				local plrTarg
				local strArgs = string.split(msg, " ")
				local target = strArgs[2]
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					local reason = string.sub(msg, 8 + #target, #msg)
					plrTarg:Kick("\nYou Have Been Kicked By: "..player.Name.."\nReason: "..reason)
					t.Notify(player, "You Kicked "..plrTarg.Name.."\nFor: "..reason)
				end
			elseif c:lower() == "ban" then
				local plrTarg
				local strArgs = string.split(msg, " ")
				local target = strArgs[2]
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					local reason = string.sub(msg, 7 + #target, #msg)
					t.Ban(player, plrTarg, reason)
					plrTarg:Kick("\nYou Have Been Banned By: "..player.Name.."\nReason: "..reason)
					t.Notify(player, "You Banned "..plrTarg.Name.."\nFor: "..reason)
				end
			elseif c:lower() == "unban" then				
				local target = string.sub(msg, 8, #msg)
				local plrId = game:GetService("Players"):GetUserIdFromNameAsync(target)
				if plrId then
					t.UnBanId(player, plrId, gds, target)
				end
			elseif c:lower() == "owner" then
				local target = string.sub(msg, 8, #msg)
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					t.Owner(player, plrTarg)
				end
			elseif c:lower() == "unowner" then
				local target = string.sub(msg, 10, #msg)
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					t.UnOwner(player, plrTarg)
				end
			elseif c:lower() == "administrator" then
				local target = string.sub(msg, 16, #msg)
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					t.Administrator(player, plrTarg)
				end
			elseif c:lower() == "unadministrator" then
				local target = string.sub(msg, 18, #msg)
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					t.UnAdministrator(player, plrTarg)
				end
			elseif c:lower() == "moderator" then
				local target = string.sub(msg, 12, #msg)
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					t.Moderator(player, plrTarg)
				end
			elseif c:lower() == "unmoderator" then
				local target = string.sub(msg, 14, #msg)
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					t.UnModerator(player, plrTarg)
				end
			elseif c:lower() == "walkspeed" then
				local args = string.split(msg, " ")
				local target = args[2]
				local speed = tonumber(args[3])
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					local targChar = plrTarg.Character or plrTarg.CharacterAdded:Wait()
					targChar:WaitForChild("Humanoid").WalkSpeed = speed
				end
			elseif c:lower() == "jumppower" then
				local args = string.split(msg, " ")
				local target = args[2]
				local speed = tonumber(args[3])
				local plrTarg
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, target) then
						plrTarg = plr
					end
				end
				if plrTarg then
					local targChar = plrTarg.Character or plrTarg.CharacterAdded:Wait()
					targChar:WaitForChild("Humanoid").JumpPower = speed
				end
			end
		end
	end
	count = 0
end

function t.Owner(player, target)
	if not not CurrentPlayers[player]["Ranks"]["Owner"] then return end
	
	if player.Name == target.Name then return end
	
	CurrentPlayers[player.Name]["Ranks"] = {
		["Owner"] = true,
		["Administrator"] = false,
		["Moderator"] = false,
		["Banned"] = false
	}
	t.Notify(player, "You Gave "..target.Name.." Owner Powers")
	t.Notify(target, "You Are Now An Owner")
end

function t.Administrator(player, target)
	if not not CurrentPlayers[player.Name]["Ranks"]["Owner"] then return end
	
	if player.Name == target.Name then return end
	
	CurrentPlayers[player.Name]["Ranks"] = {
		["Owner"] = false,
		["Administrator"] = true,
		["Moderator"] = false,
		["Banned"] = false
	}
	t.Notify(player, "You Gave "..target.Name.." Administrator Powers")
	t.Notify(target, "You Are Now An Administrator")
end

function t.Moderator(player, target)
	if not CurrentPlayers[player.Name]["Ranks"]["Administrator"] or not CurrentPlayers[player.Name]["Ranks"]["Owner"] then return end
	
	if player.Name == target.Name then return end
	
	CurrentPlayers[player.Name]["Ranks"] = {
		["Owner"] = false,
		["Administrator"] = false,
		["Moderator"] = true,
		["Banned"] = false
	}
	t.Notify(player, "You Gave "..target.Name.." Moderator Powers")
	t.Notify(target, "You Are Now A Moderator")
end

function t.UnOwner(player, target)
	if not CurrentPlayers[player.Name]["Ranks"]["Owner"] then return end
	
	if player.Name == target.Name then return end
	
	CurrentPlayers[target.Name]["Ranks"] = {
		["Owner"] = false,
		["Administrator"] = false,
		["Moderator"] = false,
		["Banned"] = false
	}
	
	t.Notify(player, "You Removed "..target.Name.."'s Owner Powers")
	t.Notify(target, "You Are No Longer An Owner")
end

function t.UnAdministrator(player, target)
	if not CurrentPlayers[player.Name]["Ranks"]["Owner"] then return end
	
	if player.Name == target.Name then return end
	
	CurrentPlayers[target.Name]["Ranks"] = {
		["Owner"] = false,
		["Administrator"] = false,
		["Moderator"] = false,
		["Banned"] = false
	}
	
	t.Notify(player, "You Removed "..target.Name.."'s Administrator Powers")
	t.Notify(target, "You Are No Longer An Administrator")
end

function t.UnModerator(player, target)
	if not CurrentPlayers[player.Name]["Ranks"]["Administrator"] or not CurrentPlayers[player.Name]["Ranks"]["Owner"] then return end
	
	if player.Name == target.Name then return end
	
	CurrentPlayers[target.Name]["Ranks"] = {
		["Owner"] = false,
		["Administrator"] = false,
		["Moderator"] = false,
		["Banned"] = false
	}
	
	t.Notify(player, "You Removed "..target.Name.."'s Moderator Powers")
	t.Notify(target, "You Are No Longer A Moderator")
end

function t.Ban(player, target, reason)
	if not CurrentPlayers[player.Name]["Ranks"]["Moderator"] or not CurrentPlayers[player.Name]["Ranks"]["Administrator"] or not CurrentPlayers[player.Name]["Ranks"]["Owner"] then return end
	
	if player.Name == target.Name then return end
	
	local plrMetaData = CurrentPlayers[target.Name]["Ranks"]
	
	if plrMetaData["Moderator"] or plrMetaData["Administrator"] or plrMetaData["Owner"] then return end
	
	CurrentPlayers[target.Name]["Ranks"] = {
		["Owner"] = false,
		["Administrator"] = false,
		["Moderator"] = false,
		["Banned"] = {true, reason}
	}
	
	t.Notify(player, "You Have Banned "..target.Name.."\nFor: "..reason)
end

function t.UnBanId(player, target, dataStore, name)
	if not CurrentPlayers[player.Name]["Ranks"]["Moderator"] or not CurrentPlayers[player.Name]["Ranks"]["Administrator"] or not CurrentPlayers[player.Name]["Ranks"]["Owner"] then return end
	
	if player.UserId == target then return end
	
	local newMetaData = HTTPS:JSONEncode(default)
	
	pcall(function()
		dataStore:SetAsync(target, newMetaData)
	end)
	
	t.Notify(player, "You Unbanned "..name)
end

function t.Notify(player, msg)
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("SendNotifs")
	
	remote:FireClient(player, msg)
end

return t
