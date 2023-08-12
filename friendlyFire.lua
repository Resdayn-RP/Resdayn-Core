local friendlyFire = {}

friendlyFire.captureOldHealth = function(eventStatus, pid, cellDescription, objects, targetPlayers)
	for targetPid, targetPlayer in pairs(targetPlayers) do
		if not Players[targetPid] or not Players[targetPid]:IsLoggedIn() then return end

		local targetPlayerName = Players[targetPid].accountName
		if targetPlayerName and targetPlayer.hittingPid and targetPlayer.hit.success then

			if not friendlyFire[targetPid] then friendlyFire[targetPid] = {} end

			friendlyFire[targetPid].health = tes3mp.GetHealthCurrent(targetPid)

			print("Saved " .. " " .. targetPlayerName .. "'s health as value: " .. friendlyFire[targetPid].health)

		end
	end
end

friendlyFire.restoreHealth = function(eventStatus, pid, cellDescription, objects, targetPlayers)
	for targetPid, targetPlayer in pairs(targetPlayers) do
		if not Players[targetPid] or not Players[targetPid]:IsLoggedIn() then return end

		local targetPlayerName = Players[targetPid].accountName

		if targetPlayerName and targetPlayer.hittingPid and targetPlayer.hit.success then
			print("Hit success! Restoring health for: " .. targetPlayerName .. ". Setting health to: " .. friendlyFire[targetPid].health .. " \nAfter receiving damage: " .. targetPlayer.hit.damage .. " From health: " .. friendlyFire[targetPid].health .. "\n vs current health: " .. tes3mp.GetHealthCurrent(targetPid))

			-- Also appears to heal the player over successive hits
			local targetHealthCurrent = tes3mp.GetHealthCurrent(targetPid)
			local targetHealthBase = tes3mp.GetHealthBase(targetPid)
			local Damage = targetPlayer.hit.damage
			local newHealth = targetHealthCurrent + Damage

			if newHealth > targetHealthBase then newhealth = targetHealthBase end

			tes3mp.SetHealthCurrent(targetPid, newHealth)
			tes3mp.SendStatsDynamic(targetPid)
		end
	end
end

customEventHooks.registerValidator("OnObjectHit", friendlyFire.captureOldHealth)
customEventHooks.registerHandler("OnObjectHit", friendlyFire.restoreHealth)

return friendlyFire
