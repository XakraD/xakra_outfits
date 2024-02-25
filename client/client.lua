local active_menu = false
local pcoords

local originalOutfit = {}
local OutfitsDB = {}

local Cam

TriggerEvent('menuapi:getData', function(call)
    MenuData = call
end)

CreateThread(function() 
    while true do
        pcoords = GetEntityCoords(PlayerPedId())
        Wait(500)
    end
end)

--########################### OPEN OBJECT ###########################
local OpenOutfitPrompt
local OpenOutfitPrompts = GetRandomIntInRange(0, 0xffffff)

CreateThread(function()
    OpenOutfitPrompt = PromptRegisterBegin()
    PromptSetControlAction(OpenOutfitPrompt, Config.OpenMenu)
    local VarString = CreateVarString(10, 'LITERAL_STRING', Config.Texts.Prompt)
    PromptSetText(OpenOutfitPrompt, VarString)
    PromptSetEnabled(OpenOutfitPrompt, true)
    PromptSetVisible(OpenOutfitPrompt, true)
	PromptSetHoldMode(OpenOutfitPrompt, 1000)
	PromptSetGroup(OpenOutfitPrompt, OpenOutfitPrompts)
	PromptRegisterEnd(OpenOutfitPrompt)
end)

CreateThread(function()
    while true do
        for _, object in pairs(Config.Objects) do
            local check_object = DoesObjectOfTypeExistAtCoords(pcoords, 1.0, joaat(object), true)

            while check_object and not active_menu do
                check_object = DoesObjectOfTypeExistAtCoords(pcoords, 1.0, joaat(object), true)

                local label = CreateVarString(10, 'LITERAL_STRING', Config.Texts.Closet)
                PromptSetActiveGroupThisFrame(OpenOutfitPrompts, label)

                if PromptHasHoldModeCompleted(OpenOutfitPrompt) then
					TriggerServerEvent('xakra_outfit:GetOutfits')
					Wait(500)
                end
				
                Wait(0)
            end
        end

        Wait(500)
    end
end)

RegisterNetEvent('xakra_outfit:LoadOutfits')
AddEventHandler('xakra_outfit:LoadOutfits', function(CharacterOutfit, result)
	originalOutfit = CharacterOutfit
	OutfitsDB = result
	OutfitMenu()
end)

function OutfitMenu()
	MenuData.CloseAll()
	active_menu = true
    FreezeEntityPosition(PlayerPedId(), true)
	TaskStandStill(PlayerPedId(), -1)

	if not DoesCamExist(Cam) then
		Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true) 
		AttachCamToEntity(Cam , PlayerPedId(), 0.20, 1.50, 0.20, true)
		SetCamRot(Cam, -10.0, 0.0, GetEntityHeading(PlayerPedId()) - 180)
		RenderScriptCams(true, true, 1000, 1, 0)
	end

	local elements = {}

	for i, v in pairs(OutfitsDB) do
		local outfitName
		if i == "" then 
            outfitName = "Outfit" 
        else 
            outfitName = v.title 
        end

		elements[#elements + 1] = {
			label = outfitName,
			value = i,
		}
	end

	MenuData.Open('default', GetCurrentResourceName(), "OutfitMenu",
		{
			title    = Config.Texts.Closet,
			subtext  = Config.Texts.SubMenu,
			align    = Config.Align,
			elements = elements,
		},

		function(data, menu)
			if data.current.value and not loadingData then
				OutfitSubMenu(data.current.value)
			end
		end,

    function(data, menu)
        menu.close()
        active_menu = false
        FreezeEntityPosition(PlayerPedId(), false)
		ClearPedTasks(PlayerPedId())

		if DoesCamExist(Cam) then
			RenderScriptCams(false, true, 1000, 1, 0)
			DestroyCam(Cam, true)
		end
    end)
end

function OutfitSubMenu(index)
	MenuData.CloseAll()

	PreviewOutfit(OutfitsDB[index])

	local elements = {
		{
			label = Config.Texts.SelectOutfit,
			value = "select",
		},
		{
			label = Config.Texts.DeleteOutfit,
			value = "delete"
		},
	}

	MenuData.Open('default', GetCurrentResourceName(), "OutfitSubMenu",
		{
			title    = Config.Texts.Closet,
			subtext  = Config.Texts.SubMenu,
			align    = Config.Align,
			elements = elements,
            lastmenu = "OutfitMenu",
		},

		function(data, menu)
            if (data.current == "backup") then
                _G[data.trigger]()
				PreviewOutfit(originalOutfit)
            end

			if data.current.value == "select" then
				local comps = {}

				for k, v in pairs(OutfitsDB[index].comps and json.decode(OutfitsDB[index].comps) or {}) do
					comps[k] = { comp = v }
				end
			
				local compTints = OutfitsDB[index].compTints and json.decode(OutfitsDB[index].compTints) or {}

				TriggerServerEvent("xakra_outfit:setOutfit", OutfitsDB[index], ConvertTableComps(comps, IndexTintCompsToNumber(compTints)))

				FreezeEntityPosition(PlayerPedId(), false)
				ClearPedTasks(PlayerPedId())

				if DoesCamExist(Cam) then
					RenderScriptCams(false, true, 1000, 1, 0)
					DestroyCam(Cam, true)
				end

				active_menu = false
				menu.close()
				Wait(500)
			elseif data.current.value == "delete" then
                TriggerServerEvent("xakra_outfit:deleteOutfit", OutfitsDB[index].id)
                OutfitsDB[index] = nil
				PreviewOutfit(originalOutfit)
				OutfitMenu()
				Wait(500)
			end
	    end, 

    function(data, menu)
        menu.close()
    end)
end

--########################### STOP RESOURCE ###########################
AddEventHandler('onResourceStop', function (resourceName)
    if resourceName == GetCurrentResourceName() then
		MenuData.CloseAll()
		FreezeEntityPosition(PlayerPedId(), false)
		ClearPedTasks(PlayerPedId())

		if DoesCamExist(Cam) then
			DestroyCam(Cam, true)
		end
    end
end)

--########################### FUNCTIONS ###########################
function PreviewOutfit(Outfit)
	for i, tag in pairs(HashList) do
		if i ~= 'Hair' and i ~= 'Beard' then
			RemoveTagFromMetaPed(tag)
			UpdatePedVariation()
		end
	end

	local comps = {}

    for k, v in pairs(Outfit.comps and json.decode(Outfit.comps) or {}) do
        comps[k] = { comp = v }
    end

    local compTints = Outfit.compTints and json.decode(Outfit.compTints) or {}
	
	LoadComps(ConvertTableComps(comps, IndexTintCompsToNumber(compTints)))
end

function LoadComps(components, set)
	for category, value in pairs(components) do
		if value.comp ~= -1 then
			local status = not set and "false" or GetResourceKvpString(tostring(value.comp))
			if status == "true" then
				RemoveTagFromMetaPed(Config.HashList[key])
			else
				ApplyShopItemToPed(value.comp, PlayerPedId())
				if category ~= "Boots" then
					UpdateShopItemWearableState(PlayerPedId(), `base`)
				end
				Citizen.InvokeNative(0xAAB86462966168CE, PlayerPedId(), 1)
				UpdatePedVariation()
				IsPedReadyToRender()
				if value.tint0 ~= 0 or value.tint1 ~= 0 or value.tint2 ~= 0 or value.palette ~= 0 then
					local TagData = GetMetaPedData(category == "Boots" and "boots" or category, PlayerPedId())
					if TagData then
						local palette = (value.palette ~= 0) and value.palette or TagData.palette
						SetMetaPedTag(PlayerPedId(), TagData.drawable, TagData.albedo, TagData.normal, TagData.material, palette, value.tint0, value.tint1, value.tint2)
						UpdatePedVariation(PlayerPedId())
					end
				end
			end
		end
	end
end

HashList = {
    Gunbelt     = 0x9B2C8B89,
    Mask        = 0x7505EF42,
    Holster     = 0xB6B6122D,
    Loadouts    = 0x83887E88,
    Coat        = 0xE06D30CE,
    Cloak       = 0x3C1A74CD,
    EyeWear     = 0x5E47CA6,
    Bracelet    = 0x7BC10759,
    Skirt       = 0xA0E3AB7F,
    Poncho      = 0xAF14310B,
    Spats       = 0x514ADCEA,
    NeckTies    = 0x7A96FACA,
    Spurs       = 0x18729F39,
    Pant        = 0x1D4C528A,
    Suspender   = 0x877A2CF7,
    Glove       = 0xEABE0032,
    Satchels    = 0x94504D26,
    GunbeltAccs = 0xF1542D11,
    CoatClosed  = 0x662AC34,
    Buckle      = 0xFAE9107F,
    RingRh      = 0x7A6BBD0B,
    Belt        = 0xA6D134C6,
    Accessories = 0x79D7DF96,
    Shirt       = 0x2026C46D,
    Gauntlets   = 0x91CE9B20,
    Chap        = 0x3107499B,
    NeckWear    = 0x5FC29285,
    Boots       = 0x777EC6EF,
    Vest        = 0x485EE834,
    RingLh      = 0xF16A1D23,
    Hat         = 0x9925C067,
    Dress       = 0xA2926F9B,
    Badge       = 0x3F7F3587,
    armor       = 0x72E6EF74,
    Hair        = 0x864B03AE,
    Beard       = 0xF8016BCA,
    bow         = 0x8E84A2AA,
}