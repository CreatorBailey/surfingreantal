local QBCore = exports['qb-core']:GetCoreObject()
local SpawnSurfBoard = false


RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

-- Threads

CreateThread(function()
	RequestModel(Config.PedModel)
	  while not HasModelLoaded(Config.PedModel) do
	  Wait(1)
	end
	  surfboardped = CreatePed(2, Config.PedModel, Config.PedLocation, false, false) 
	  SetPedFleeAttributes(surfboardped, 0, 0)
	  SetPedDiesWhenInjured(surfboardped, false)
	  TaskStartScenarioInPlace(surfboardped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
	  SetPedKeepTask(surfboardped, true)
	  SetBlockingOfNonTemporaryEvents(surfboardped, true)
	  SetEntityInvincible(surfboardped, true)
	  FreezeEntityPosition(surfboardped, true)
  end)

CreateThread(function()
	local surfboardblip = AddBlipForCoord(Config.PedLocation)
	SetBlipAsShortRange(blip, true)
	SetBlipSprite(surfboardblip, 471)
	SetBlipColour(surfboardblip, 74)
	SetBlipScale(surfboardblip, 0.7)
	SetBlipDisplay(surfboardblip, 6)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString('SurfBoard Rental')
	EndTextCommandSetBlipName(surfboardblip)
end)


CreateThread(function()
    exports['qb-target']:AddTargetModel(Config.PedModel, {
        options = {
            { 
                type = "client",
                event = "qb-surfboardrentals:client:SurfBoardMenu",
                icon = "fa-solid fa-person-snowboarding",
                label = "Rent SurfBoard",
            },
        },
        distance = 3.0 
    })
end)

-- Events

RegisterNetEvent('qb-surfboardrentals:client:SurfBoardMenu', function()
    local SurfBoardMenu = {
        {
            header = "SurfBoard Rentals",
            txt = "Rent a surfboard for quick transportion!",
            isMenuHeader = true,
        },
        {
            header = "SurfBoard",
            txt =  "$ ".. Config.SurfBoardPrice .. "w/ Tax",
            params = {
                event = "qb-surfboardrentals:client:Spawn",
                args = {
					model = Config.SurfBoardModel
                }
			}
        },
		{
            header = "Return SurfBoard",
            params = {
                event = "qb-surfboardrentals:client:Return",
			}
		},
		{
            header = "< Close",
            params = {
                event = "qb-menu:client:close",
			}
		},
	}
    exports['qb-menu']:openMenu(SurfBoardMenu)
end)

RegisterNetEvent('qb-surfboardrentals:client:Spawn', function(model)
    local model = Config.SurfBoardModel
    local player = PlayerPedId()
    QBCore.Functions.TriggerCallback('qb-surfboardrentals:server:RentCheck', function(CanRent)
        if CanRent then 
		QBCore.Functions.Progressbar("grab_surfboard", "Pulling out SurfBoard..", math.random(4000,6000), false, true, {
			disableMovement = false,
			disableCarMovement = false,
			disableMouse = false,
			disableCombat = false,
		}, {}, {}, {}, function() -- Done
			SurfBoardRentalEmail()
			QBCore.Functions.SpawnVehicle(model, function(veh)
				TaskWarpPedIntoVehicle(player, veh, -1)
				TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(aircraft))
				SetVehicleNumberPlateText(veh, "RENTAL"..tostring(math.random(1000, 9999)))
				exports[Config.FuelSystem]:SetFuel(veh, 100.0)
				SetVehicleEngineOn(veh, false, true)
				SetEntityAsMissionEntity(veh, true, true)
				SpawnSurfBoard = true
			end, Config.SpawnLocation, true)
		end)
        else
            QBCore.Functions.Notify("You don't have enough money..", "error", 2500)
        end
    end, model)
end)


RegisterNetEvent('qb-surfboardrentals:client:Return', function()
    if SpawnSurfBoard then
        local Player = QBCore.Functions.GetPlayerData()
        QBCore.Functions.Notify('Returned SurfBoard!', 'success')
        local car = GetVehiclePedIsIn(PlayerPedId(),true)
        NetworkFadeOutEntity(car, true,false)
        Citizen.Wait(2000)
        QBCore.Functions.DeleteVehicle(car)
    else 
        QBCore.Functions.Notify("No SurfBoard near you.", "error")
    end
    SpawnSurfBoard = false
end)


function SurfBoardRentalEmail()
    TriggerServerEvent('qb-phone:server:sendNewMail', {
    sender = 'Escapism Travel',
    subject = 'SurfBoard Rental',
    message = 'Thank you for renting a surfboard from us! Bring the surfboard back with in 24 hours!',
    })
end



