require("config")
require("stdlib.util")

local fuel = require("scripts.fuel")
local locomotive = require("scripts.locomotive")

local connection_array = {{1.5, 1.5}, {1.5, 0.5}, {1.5, -0.5}, {-1.5, 1.5}, {-1.5, 0.5}, {-1.5, -0.5}}

local public = {}

local function determineConnectivity(loco, exception, forcedFluidName)
	local burner_inventory = loco.burner.inventory
	if burner_inventory[1] and burner_inventory[1].valid_for_read then
		if not fuel.is_fake_item(burner_inventory[1]) then
			return 0
		end
	end
    if burner_inventory[1] and burner_inventory[1].valid_for_read then
        fuel.reconstructFluid(loco.unit_number, burner_inventory[1])
    end

	local legalFluids = {}
    log("train proto " .. serpent.block(loco.prototype))
    log("burner ".. serpent.block(loco.burner))
    for category, _ in pairs(loco.prototype.burner_prototype.fuel_categories) do
		log(category)
        for fluid, _ in pairs(storage.fluid_map[category]) do
            legalFluids[fluid] = true
        end
    end
    log("legal fluids: " .. serpent.block(legalFluids))
    local uid = loco.unit_number
    local proxy = storage.proxies[uid]

	for j = 1, 6 do
		local found_pumps = loco.surface.find_entities_filtered{
			name = "pump",
			position = moveposition(
				{x = round(loco.position.x),y = round(loco.position.y)},
				ori_to_dir(loco.orientation),
				{x = connection_array[j][1], y = connection_array[j][2]}
			)
		}
        log("found ".. #found_pumps .. " pumps")
		if found_pumps[1] and not(found_pumps[1].unit_number == exception) then
            if proxy and proxy.tank then
                proxy.tank.fluidbox.add_linked_connection(j, found_pumps[1], 1717)

                local pumpFluid = found_pumps[1].fluidbox[1]
                local filterFluid = found_pumps[1].fluidbox.get_filter(1)

                log("pump fluid: " .. tostring(serpent.block(filterFluid)))
                log("filter fluid: " .. tostring(serpent.block(filterFluid)))
                if pumpFluid and legalFluids[pumpFluid.name] then
					log("pump has legal fluid, filter set: "..pumpFluid.name)
                    proxy.tank.fluidbox.set_filter(1, {name = pumpFluid.name})
                elseif filterFluid and legalFluids[filterFluid.name] then
					log("pump has legal filter, filter set: "..filterFluid.name)
                    proxy.tank.fluidbox.set_filter(1, {name = filterFluid.name})
                else
                    -- Set the proxy tank filter to some legal fluid
                    -- to prevent illegal fluid entering the proxy tank
					local fluid = nil
					for k, v in pairs(legalFluids) do
						if v then
							fluid = k
						end
					end
					log("pump does not have legal fluid, setting: "..fluid)
                    proxy.tank.fluidbox.set_filter(1, {name = fluid})
                end
				log("tank filter:" .. serpent.block(proxy.tank.fluidbox.get_filter(1)))
            end
		end
	end
end

function public.create_proxy(loco, exception)
--[[ Create proxy_tank for a locomotive and inserting the proxy_tank to storage.proxies
	if proxy_tank successfully created return 0, else return -1 ]]
	local uid = loco.unit_number
    log("creating proxy for loco uid " .. uid)

	if not storage.known_locos[uid] then
		storage.known_locos[uid] = true
		storage.tender_queue[uid % TENDER_UPDATE_TICK+1][uid] = loco
	end

	local proxy = storage.proxies[uid]
	if not(proxy and proxy.tank and proxy.tank.valid) and math.floor(4 * loco.orientation) == 4 * loco.orientation then
		local proxy_tank
		local fluid_amount
		determineConnectivity(loco, exception)
		proxy_tank = loco.surface.create_entity{
			name = storage.loco_tank_pair_list[loco.name],
			position = moveposition(loco.position, ori_to_dir(loco.orientation), {x = 0, y = 0}),
			force = loco.force,
			direction = ori_to_dir(loco.orientation)
		}
		if (not proxy_tank) then
            log("could not create proxy uid " .. uid)
            return -1
        end
		proxy_tank.destructible = false
		local burner_inventory = loco.burner.inventory
		fluid_amount = 0
		if burner_inventory[1] and burner_inventory[1].valid_for_read then
			local fluid = fuel.reconstructFluid(uid, burner_inventory[1])
			if fluid then
				fluid_amount = fluid.amount
				proxy_tank.fluidbox[1] = fluid
			end
		end
		storage.proxies[uid] = {tank = proxy_tank, last_amount = fluid_amount, tick = game.tick}
		local update_tick = uid % SLOW_UPDATE_TICK + 1
		storage.update_tick[uid] = update_tick
		storage.low_prio_loco[update_tick][uid] = loco
		storage.high_prio_loco[uid] = loco
        determineConnectivity(loco, exception)
		log("created proxy uid:" .. uid .. " position " .. serpent.block(proxy_tank.position) .. " direction " .. proxy_tank.direction)
		return 0
	end
    log("did not create proxy uid" .. uid)
	return -1
end

function public.destroy_proxy(loco)
--[[ Update the locomotive then destroy the proxy_tank
	return number of ticks since last fluid change in proxy_tank
	return -1 if locomotive has no proxy_tank ]]
	local uid = loco.unit_number
	local no_update_ticks = locomotive.update_loco_fuel(loco)
	if no_update_ticks >= 0 then
		storage.proxies[uid].tank.destroy()
		storage.low_prio_loco[storage.update_tick[uid]][uid] = nil
	end
	storage.proxies[uid] = nil
	storage.update_tick[uid] = nil
	storage.high_prio_loco[uid] = nil
    log("destroyed proxy " .. uid)
	return no_update_ticks
end

function public.refresh_proxy(loco, exception)
	local proxy = storage.proxies[loco.unit_number]
	if proxy and proxy.tank and proxy.tank.valid then
		determineConnectivity(loco, exception)
		if not (proxy.tank.name == storage.loco_tank_pair_list[loco.name]) then
			local fluid_amount = proxy.tank.fluidbox and proxy.tank.fluidbox[1] and proxy.tank.fluidbox[1].amount
			local fluid_temp   = proxy.tank.fluidbox and proxy.tank.fluidbox[1] and proxy.tank.fluidbox[1].temperature
			proxy.tank.destroy()
			proxy.tank = loco.surface.create_entity{
				name = storage.loco_tank_pair_list[loco.name],--..tank_type,
				position = moveposition(loco.position, ori_to_dir(loco.orientation), {x = 0, y = 0}),
				force = loco.force,
				direction = ori_to_dir(loco.orientation)
			}
			if tank_type > 0 then
				local lock = proxy.tank.fluidbox.get_locked_fluid(1)
				if lock then
					proxy.tank.fluidbox.set_filter(1, { name = lock})
				end
			end
			proxy.tank.destructible = false
			if fluid_name then
				proxy.tank.fluidbox[1] = {name = fluid_name, amount = fluid_amount, temperature = fluid_temp}
			end
		end
	else
		public.create_proxy(loco, exception)
	end
end

function public.forceKillProxy(uid)
	local proxy = storage.proxies[uid]
	if proxy and proxy.tank and proxy.tank.valid then
		proxy.tank.destroy()
	end
	storage.proxies[uid] = nil
end

return public
