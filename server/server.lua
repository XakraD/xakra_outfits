local VORPcore = {}
TriggerEvent("getCore", function(core)
	VORPcore = core
end)

RegisterNetEvent('xakra_outfit:GetOutfits')
AddEventHandler('xakra_outfit:GetOutfits', function()
	local _source = source
	local Character = VORPcore.getUser(_source).getUsedCharacter
	local identifier = Character.identifier
	local charIdentifier = Character.charIdentifier

	local comps = Character.comps
	TriggerClientEvent('xakra_outfit:LoadCloths', _source, comps)

	exports["ghmattimysql"]:execute("SELECT * FROM outfits WHERE `identifier` = ? AND `charidentifier` = ?",
		{ identifier, charIdentifier }, function(result)
		if result[1] then
			TriggerClientEvent('xakra_outfit:LoadOutfits', _source, result)
		end
	end)

end)

RegisterNetEvent('xakra_outfit:setOutfit')
AddEventHandler('xakra_outfit:setOutfit', function(result)
	local _source = source
	if result then
		TriggerEvent("vorpcharacter:setPlayerCompChange", _source, result);
	end
end)

RegisterNetEvent('xakra_outfit:deleteOutfit')
AddEventHandler('xakra_outfit:deleteOutfit', function(outfitId)
	local _source = source
	local identifier = Character.identifier

	exports["ghmattimysql"]:execute("DELETE FROM outfits WHERE identifier=? AND id=?", { identifier, outfitId })
end)


