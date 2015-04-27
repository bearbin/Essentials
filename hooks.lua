function OnTakeDamage(Receiver, TDI)
	Player = tolua.cast(Receiver,"cPlayer")
	if Receiver:IsPlayer() == true and Player:CanFly() == true and TDI.DamageType == dtFalling then
		return true
	end
end

function OnPlayerRightClick(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ)
	World = Player:GetWorld()
	if (BlockType == E_BLOCK_SIGN) then	
		Read, Line1, Line2, Line3, Line4 = World:GetSignLines( BlockX, BlockY, BlockZ )
		if Line1 == "[SignWarp]" or Line1 == "[Warp]" then
			cPluginManager:Get():ExecuteCommand(Player, "/warp "..Line2)
			return true
		end
	end
end

function OnUpdatingSign(World, BlockX, BlockY, BlockZ, Line1, Line2, Line3, Line4, Player)
	if Line1 == "[SignWarp]" or Line1 == "[Warp]" then
		if (not(Player:HasPermission("warp.createsign") == true)) then
			return true
		elseif (Line2 == "") then
			Player:SendMessageFailure('Must supply a tag for the warp.')
			return true
		end
	elseif Line1 == "[Portal]" then
		if (not(Player:HasPermission("es.createportal") == true)) then
			return true
		elseif (Line2 == "") then
			Player:SendMessageFailure('Must supply a warp to teleport.')
			return true
		end
	end
end

function OnPlayerBreakingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
	if (UsersIni:GetValue(Player:GetName(),   "Jailed") == "true") and (IsDiggingEnabled == false) then 
		Player:SendMessageWarning("You are jailed")
		return true
	else
		return false
	end
end

function OnPlayerPlacingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType)
	if (UsersIni:GetValue(Player:GetName(),   "Jailed") == "true") and (IsPlaceEnabled == false) then 
		Player:SendMessageWarning("You are jailed")
		return true
	else 
		return false
	end
end

function OnExecuteCommand(Player, CommandSplit)
	if Player == nil then
		return false
	elseif (UsersIni:GetValue(Player:GetName(),   "Jailed") == "true") and (AreCommandsEnabled == false) then
		Player:SendMessageWarning("You are jailed") 
		return true
	else 
		return false
	end
end

function OnChat(Player, Message)
	if (UsersIni:GetValue(Player:GetName(),   "Muted") == "true") then 
		Player:SendMessageWarning("You are muted")
		return true
	elseif (UsersIni:GetValue(Player:GetName(),   "Jailed") == "true") and (IsChatEnabled == false) then 
		Player:SendMessageWarning("You are jailed")
		return true
	else 
		return false
	end
end

function OnWorldTick(World, TimeDelta)
	if timer[World:GetName()] == nil then
		timer[World:GetName()] = 0
	elseif timer[World:GetName()] == 20 then
		local ForEachPlayer = function(Player)
			blocktype = Player:GetWorld():GetBlock(Player:GetPosX(), Player:GetPosY() - 2, Player:GetPosZ())
			if blocktype == 63 or blocktype == 78 then
				Read, Line1, Line2, Line3, Line4 = World:GetSignLines( Player:GetPosX(), Player:GetPosY() - 2, Player:GetPosZ(), "", "", "", "" )
				if (Line1 == "[Portal]") then
					if Line4 ~= "" then
						Player:TeleportToCoords(Line2, Line3, Line4)
					else
						cPluginManager:Get():ExecuteCommand(Player, "/warp "..Line2)
				end    
			end
		end           
	end
	World:ForEachPlayer(ForEachPlayer)
	timer[World:GetName()] = 0
	else
	timer[World:GetName()] = timer[World:GetName()] + 1
	end
end
