require("config")
require("stdlib.util")

local locomotive = require("scripts.locomotive")
local fuel = require("scripts.fuel")

local public = {}

local function findTenderWagon(loco_uid, train)
	local index
	for i, carriage in pairs(train.carriages) do
		if carriage.unit_number and carriage.unit_number == loco_uid then
			index = i
		end
	end

	local isFrontMover = false

	for _,l in pairs(train.locomotives["front_movers"]) do
		if l.unit_number == loco_uid then
			isFrontMover = true
		end
	end

	local seekDirection = isFrontMover and 1 or -1
	local directional_locos = isFrontMover and train.locomotives["front_movers"] or train.locomotives["back_movers"]

	local blockMembers = {}
	for _,l in pairs(directional_locos) do
		blockMembers[l.unit_number] = true
	end

	local pointer = index

	while true do
		pointer = pointer + seekDirection
		local candidate = train.carriages[pointer]

		if not candidate then
			return nil
		end

		if not blockMembers[candidate.unit_number] then
			if candidate.prototype.type == "fluid-wagon" then
				return {candidate}
			else
				return nil
			end
		end
	end
end

local function supportsTenders(loco, tenderSettings)
	local options = storage.loco_options[loco.prototype.name]

	local defaultSettings = tenderSettings.tender

	if defaultSettings == "always" then
		return true
	elseif defaultSettings == "only-enabled" then
		return options and options["tender"] == "yes"
	elseif options and options["tender"] ~= "yes" then
		return false
	else
		return true
	end
end

function public.update(unit_number, loco, tenderSettings)
	log("Updating tender uid " .. tostring(unit_number))
	log("locomotive = " .. serpent.block(loco))
	log("tenderSettings = " .. serpent.block(tenderSettings))
	if not supportsTenders(loco, tenderSettings) then
		return
	end

	local demand = locomotive.getFluidDemand(loco)
	log("demand = " .. serpent.block(demand))
	-- if not demand then
	-- 	return
	-- end
	if demand and demand.amount < tenderSettings.threshold then
		return
	end

	local entities
	if tenderSettings.mode == "local" then
		entities = findTenderWagon(unit_number, loco.train)
	else
		entities = loco.train.fluid_wagons
	end

	if not entities or #entities == 0 then
		return
	end

	if demand then
		local amount = 0
		for _,entity in pairs(entities) do
			local localAmount = entity.remove_fluid(demand)
			demand.amount = demand.amount - localAmount
			amount = amount + localAmount
			if demand.amount <= 0 then
				break
			end
		end

		if amount == 0 then
			return
		end

		local item = fuel.convertFluidToItem(
			{name = demand.name, amount = amount, temperature = demand.minimum_temperature},
			fuel.getBurnerFuelCategory(loco.prototype.burner_prototype))

		if not item then
			return
		end

		loco.burner.inventory.insert(item)
	else
		for _,entity in pairs(entities) do
			if entity.type == "fluid-wagon" then
				log("fluid wagon")
				log(serpent.block(entity.fluidbox))
				log(serpent.block(entity.get_fluid_contents()))
				local fluids = entity.get_fluid_count()
				if fluids > 0 then
					local fluid = entity.get_fluid(1)
					for category, _ in pairs(loco.burner.fuel_categories) do
						log(serpent.block(fluid))
						log(category)
						log(serpent.block(storage.fluid_map[category][fluid.name]))
						local fluidItem = fuel.determineItemForFluid(fluid, category)
						log(serpent.block(fluidItem))
						local amount = entity.remove_fluid({name = fluid.name, amount = 100, minimum_temperature = fluid.temperature})
						local item = fuel.convertFluidToItem(
							{name = fluid.name, amount = amount, temperature = fluid.temperature},
							fuel.getBurnerFuelCategory(loco.prototype.burner_prototype)
						)
						if item then
							loco.burner.inventory.insert(item)
						end
						return
					end
				end
			end
		end
	end
end

return public
