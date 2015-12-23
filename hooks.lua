function OnTakeDamage(Receiver, TDI)
	--Avoid fall damage if player is flying
	Player = tolua.cast(Receiver,"cPlayer")
	if Receiver:IsPlayer() == true and Player:CanFly() == true and TDI.DamageType == dtFalling then
		return true
	end
end

function OnPlayerRightClick(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ)
	World = Player:GetWorld()
        if(not(Player:GetEquippedItem():IsCustomNameEmpty())) then
		local pluginManager = cRoot:Get():GetPluginManager()
		pluginManager:ExecuteCommand( Player, Player:GetEquippedItem().m_CustomName )
		return true
	end
	--Check for a sign
	if (BlockType == E_BLOCK_SIGN) then	
		Read, Line1, Line2, Line3, Line4 = World:GetSignLines( BlockX, BlockY, BlockZ)
		--If the sign is written like it should, teleport the player
		if Line1 == "[SignWarp]" or Line1 == "[Warp]" then
			cPluginManager:Get():ExecuteCommand(Player, "/warp "..Line2)
			return true
		--If the sign is written like it should, enchant the item
		elseif Line1 == "[Enchant]" and Line2 ~= "" and Line3 ~= "" and Line4 ~= "" then
			HeldItem = Player:GetEquippedItem();
			HeldItemType = HeldItem.m_ItemType;
			ItemEnchant = HeldItem.m_Enchantments;
			level = Player:GetXpLevel();
			Enchantment = cEnchantments:StringToEnchantmentID(Line2);
			MaxLevel = Line3;
			LevelNeeded = Line4;
			CurrentItemLevel = HeldItem.m_Enchantments:GetLevel(Enchantment);
			NextLevel = CurrentItemLevel + 1;
			toremove = tonumber(Line4) * NextLevel
			if CurrentItemLevel == tonumber(Line3) or level < tonumber(Line4) then
				return false
			else
				if IsEnchantable() == true then
					ItemEnchant:SetLevel(Enchantment, NextLevel)
					Player:GetInventory():SetHotbarSlot(Player:GetInventory():GetEquippedSlotNum(), HeldItem)
					Player:DeltaExperience(-toremove * 17)
					Player:SendMessageSuccess("Successfully enchanted item")
				else
					Player:SendMessageWarning("This item is not enchantable")
				end
			end
		--If the sign is written like it should, execute the command
		elseif Line1 == "[Command]" then
			if Line3 ~= "" then
				if Line4 ~= "" then
					cPluginManager:Get():ExecuteCommand(Player, Line2..Line3..Line4)
					return true
				end
				cPluginManager:Get():ExecuteCommand(Player, Line2..Line3)
				return true
			end
			cPluginManager:Get():ExecuteCommand(Player, Line2)
			return true
		end
	end
end

function OnUpdatingSign(World, BlockX, BlockY, BlockZ, Line1, Line2, Line3, Line4, Player)
	--Avoid creating of warp signs by non-allowed users
	if Line1 == "[SignWarp]" or Line1 == "[Warp]" then
		if (not(Player:HasPermission("es.warpsign") == true)) then
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
	elseif Line1 == "[Enchant]" then
		if (not(Player:HasPermission("es.enchantsign") == true)) then
			return true
		end
	elseif Line1 == "[Command]" then
		if (not(Player:HasPermission("es.commandsign") == true)) then
			return true
		elseif (Line2 == "") then
			Player:SendMessageFailure('Must supply a command to execute.')
			return true
		end
	end
end

function OnPlayerBreakingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
	if (Jailed[Player:GetUUID()] == true) and (IsDiggingEnabled == false) then 
		Player:SendMessageWarning("You are jailed")
		return true
	else
		return false
	end
end

function OnPlayerPlacingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType)
	if (Jailed[Player:GetUUID()] == true) and (IsPlaceEnabled == false) then 
		Player:SendMessageWarning("You are jailed")
		return true
	else 
		return false
	end
end

function OnExecuteCommand(Player, CommandSplit, EntierCommand)
	if Player == nil then
		return false
	elseif (Jailed[Player:GetUUID()] == true) and (AreCommandsEnabled == false) then
		Player:SendMessageWarning("You are jailed") 
		return true
	else
		if #SocialSpyList ~= 0 then
			for PlayerUUID, value in pairs(SocialSpyList) do
				cRoot:DoWithPlayerByUUID(PlayerUUID, function(SocialSpyPlayer) return SocialSpyPlayer:SendMessagePrivateMsg(EntierCommand, Player) end)
			end
		end
		return false
	end
end

function OnChat(Player, Message)
	if Muted[Player:GetUUID()] == true then 
		Player:SendMessageWarning("You are muted")
		return true
	elseif (Jailed[Player:GetUUID()] == true) and (IsChatEnabled == false) then 
		Player:SendMessageWarning("You are jailed")
		return true
	else 
		return false
	end
end

function OnWorldTick(World, TimeDelta)
	--Tps checking code--
	local WorldTps = TpsCache[World:GetName()]
	if (WorldTps == nil) then
		WorldTps = {}
		TpsCache[World:GetName()] = WorldTps
	end

	if (#WorldTps >= 10) then
		table.remove(WorldTps, 1)
	end

	table.insert(WorldTps, 1000 / TimeDelta)
	--Check each 20 seconds if there's a sign above the player, if there is, teleport
	if timer[World:GetName()] == nil then
		timer[World:GetName()] = 0
	elseif timer[World:GetName()] == 20 then
		local ForEachPlayer = function(Player)
			blocktype = Player:GetWorld():GetBlock(Player:GetPosX(), Player:GetPosY() - 2, Player:GetPosZ())
			if blocktype == 63 or blocktype == 78 then
				Read, Line1, Line2, Line3, Line4 = World:GetSignLines( Player:GetPosX(), Player:GetPosY() - 2, Player:GetPosZ())
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


function OnTick(TimeDelta)
	if (#GlobalTps >= 10) then
		table.remove(GlobalTps, 1)
	end

	table.insert(GlobalTps, 1000 / TimeDelta)
end

function OnEntityTeleport(Entity, OldPosition, NewPosition)
	if Entity:IsPlayer() then
		Player = tolua.cast(Entity, "cPlayer")
		BackCoords[Player:GetName()] = Vector3d(OldPosition)
	end
	return false
end

function OnKilled(Victim, TDI, DeathMessage)
	if Victim:IsPlayer() then
		Player = tolua.cast(Victim, "cPlayer")
		BackCoords = Vector3d(Player:GetPosX(), Player:GetPosY(), Player:GetPosZ())
	end
end

function OnPlayerJoined(Player)
	CheckPlayer(Player)
end
