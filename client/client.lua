local active_menu = false
local pcoords, loadingData
local OutfitsDB = {}
local Cam

TriggerEvent('menuapi:getData', function(call)
    MenuData = call
end)

Citizen.CreateThread(function() 
    while true do
        pcoords = GetEntityCoords(PlayerPedId())
        Wait(500)
    end
end)

local originalOutfit = {}

RegisterNetEvent('xakra_outfit:LoadCloths')
AddEventHandler('xakra_outfit:LoadCloths', function(cloths)
	ClothesDB = json.decode(cloths)
	originalOutfit = json.decode(cloths)
end)

--########################### OPEN OBJECT ###########################
local OpenOutfitPrompt
local OpenOutfitPrompts = GetRandomIntInRange(0, 0xffffff)

function OutfitOpenMenuPrompt()
    local str = Config.Texts['Prompt']
    OpenOutfitPrompt = PromptRegisterBegin()
    PromptSetControlAction(OpenOutfitPrompt, Config.OpenMenu)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(OpenOutfitPrompt, str)
    PromptSetEnabled(OpenOutfitPrompt, 1)
    PromptSetVisible(OpenOutfitPrompt, 1)
	PromptSetHoldMode(OpenOutfitPrompt, 1000)
	PromptSetGroup(OpenOutfitPrompt, OpenOutfitPrompts)
	Citizen.InvokeNative(0xC5F428EE08FA7F2C,OpenOutfitPrompt,true)
	PromptRegisterEnd(OpenOutfitPrompt)
end

Citizen.CreateThread(function() 
    OutfitOpenMenuPrompt()             
    while true do
        for _, object in pairs(Config.Objects) do
            local check_object = DoesObjectOfTypeExistAtCoords(pcoords, 1.0, joaat(object), true)
            while check_object and not active_menu do
                check_object = DoesObjectOfTypeExistAtCoords(pcoords, 1.0, joaat(object), true)
                local label  = CreateVarString(10, 'LITERAL_STRING', Config.Texts['Closet'])
                PromptSetActiveGroupThisFrame(OpenOutfitPrompts, label)
                if PromptHasHoldModeCompleted(OpenOutfitPrompt) then
                    Wait(500)
					TriggerServerEvent('xakra_outfit:GetOutfits')
                end
                Wait(4)
            end
        end
        Wait(500)
    end
end)


RegisterNetEvent('xakra_outfit:LoadOutfits')
AddEventHandler('xakra_outfit:LoadOutfits', function(result)
	OutfitsDB = result
	OutfitMenu()
end)


function DeleteOutfit(index, id)
	TriggerServerEvent("xakra_outfit:deleteOutfit", id)
	OutfitsDB[index] = nil
end

function PreviewOutfit(index)
	local clothData
	local ped = PlayerPedId()

	if not index then
		clothData = originalOutfit
	else
		clothData = json.decode(OutfitsDB[index].comps)
	end

	loadingData = true

	for _, hash in pairs(CategoryDBName) do
		Citizen.InvokeNative(0xD710A5007C2AC539, ped, hash, 0)
	end

	for category, value in pairs(clothData) do
		if value ~= -1 then
			Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, false, false)
			Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, true, true, false)
		end
	end

	loadingData = false
end

function OutfitMenu()
	MenuData.CloseAll()
	active_menu = true
    FreezeEntityPosition(PlayerPedId(), true)
	TaskStandStill(PlayerPedId(), -1)

	if not DoesCamExist(Cam) then
		Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true) 
		AttachCamToEntity(Cam , PlayerPedId(), 0.20, 1.50, 0.20, true)
		SetCamRot(Cam, -10.0,0.0,GetEntityHeading(PlayerPedId())-180)
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
			id = v.id
		}
	end

	MenuData.Open('default', GetCurrentResourceName(), "OutfitMenu",
		{
			title    = Config.Texts['Closet'],
			subtext  = Config.Texts['SubMenu'],
			align    = Config.Align,
			elements = elements,
		},

		function(data, menu)
			if data.current.value and not loadingData then
				PreviewOutfit(data.current.value)
				OutfitSubMenu(data.current.value, data.current.id)
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

function OutfitSubMenu(index, outfitId)
	MenuData.CloseAll()
	local elements = {}
	local selectedOutfit, id = index, outfitId

	elements = {
		{ label = Config.Texts['SelectOutfit'], value = "select" },
		{ label = Config.Texts['DeleteOutfit'], value = "delete" }
	}
	MenuData.Open('default', GetCurrentResourceName(), "OutfitSubMenu",
		{
			title    = Config.Texts['Closet'],
			subtext  = Config.Texts['SubMenu'],
			align    = Config.Align,
			elements = elements,
            lastmenu = "OutfitMenu",
		},

		function(data, menu)
            if (data.current == "backup") then
                _G[data.trigger]()
				PreviewOutfit(false)
            end

			if data.current.value == "select" then
				TriggerServerEvent("xakra_outfit:setOutfit", OutfitsDB[index].comps)

				FreezeEntityPosition(PlayerPedId(), false)
				ClearPedTasks(PlayerPedId())
				if DoesCamExist(Cam) then
					DestroyCam(Cam, true)
				end

				active_menu = false
				menu.close()
				Wait(500)
			elseif data.current.value == "delete" then
                TriggerServerEvent("xakra_outfit:deleteOutfit", outfitId)
                OutfitsDB[index] = nil
				PreviewOutfit(false)
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

CategoryDBName = {
	Hat = 0x9925C067,
	EyeWear = 0x5E47CA6,
	Neckwear = 0x5FC29285,
	NeckTies = 0x7A96FACA,
	Shirt = 0x2026C46D,
	Suspender = 0x877A2CF7,
	Vest = 0x485EE834,
	Coat = 0xE06D30CE,
	CoatClosed = 0x0662AC34,
	Poncho = 0xAF14310B,
	Cloak = 0x3C1A74CD,
	Glove = 0xEABE0032,
	RingRh = 0x7A6BBD0B,
	RingLh = 0xF16A1D23,
	Bracelet = 0x7BC10759,
	Gunbelt = 0x9B2C8B89,
	Belt = 0xA6D134C6,
	Buckle = 0xFAE9107F,
	Holster = 0xB6B6122D,
	Pant = 0x1D4C528A,
	Skirt = 0xA0E3AB7F,
	Boots = 0x777EC6EF,
	Chap = 0x3107499B,
	Spurs = 0x18729F39,
	Spats = 0x514ADCEA,
	Gauntlets = 0x91CE9B20,
	Loadouts = 0x83887E88,
	Accessories = 0x79D7DF96,
	Satchels = 0x94504D26,
	GunbeltAccs = 0xF1542D11,
	Mask = 0x7505EF42,
}