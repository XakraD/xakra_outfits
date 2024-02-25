local VORPcore = exports.vorp_core:GetCore()

RegisterNetEvent('xakra_outfit:GetOutfits')
AddEventHandler('xakra_outfit:GetOutfits', function()
	local _source = source
	local Character = VORPcore.getUser(_source).getUsedCharacter
	local identifier = Character.identifier
	local charIdentifier = Character.charIdentifier

	exports.oxmysql:execute("SELECT * FROM outfits WHERE `identifier` = ? AND `charidentifier` = ?", { identifier, charIdentifier }, function(result)
		if result[1] then
			TriggerClientEvent('xakra_outfit:LoadOutfits', _source, { comps = Character.comps, compTints = Character.compTints }, result)
		end
	end)
end)

RegisterNetEvent('xakra_outfit:setOutfit')
AddEventHandler('xakra_outfit:setOutfit', function(Outfit, CacheComps)
	local _source = source

	local Character = VORPcore.getUser(_source).getUsedCharacter 

	Character.updateComps(Outfit.comps)
	Character.updateCompTints(Outfit.compTints or '{}')

	TriggerClientEvent('vorpcharacter:updateCache', _source, false, CacheComps)
end)

RegisterNetEvent('xakra_outfit:deleteOutfit')
AddEventHandler('xakra_outfit:deleteOutfit', function(outfitId)
	local _source = source
	local Character = VORPcore.getUser(_source).getUsedCharacter

	exports.oxmysql:execute("DELETE FROM outfits WHERE identifier = ? AND id = ?", { Character.identifier, outfitId })
end)