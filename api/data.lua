local public = {}

function public.generateLocomotive()
	-- Make a copy of the base game's locomotive, then make the needed changes for this mod
	local fluid_locomotive = table.deepcopy(data.raw["locomotive"]["locomotive"])

	fluid_locomotive.name = "Diesel-Locomotive-fluid-locomotive"
	fluid_locomotive.minable.result = "Diesel-Locomotive-fluid-locomotive"

	fluid_locomotive.energy_source = {
		type = "burner",
		fuel_categories = {
			"Diesel-Locomotive-fluid"
		},
		effectivity = 1,
		fuel_inventory_size = 1,
		burnt_inventory_size = 1
	}
	fluid_locomotive.color = {r = 1, g = 0.73, b = 0.07, a = 0.5}
	fluid_locomotive.connection_distance = 3+2/256
	fluid_locomotive.joint_distance = 0.1
	fluid_locomotive.collision_box = {{-0.6, -0.3}, {0.6, 0.3}}
	fluid_locomotive.selection_box = {{-1, -1}, {1, 1}}
	local layers = fluid_locomotive.pictures.rotated.layers
	for i = 1, #layers do
		-- layers[i].shift[2] = layers[i].shift[2] + 1.55
	end
	-- fluid_locomotive.vertical_selection_shift = -2.05

	-- Add new locomotive to the game

	-- TODO
	local capacity = 1500

	local internal_tank = util.table.deepcopy(data.raw["fluid-wagon"]["fluid-wagon"])

	-- internal_tank.name = "internal-tank-" .. capacity
	internal_tank.capacity = capacity

	internal_tank.connection_distance = 0.1
	internal_tank.joint_distance = 0.7-2/256
	internal_tank.collision_box = {{-0.6, -0.7}, {0.6, 0.7}}
	internal_tank.selection_box = {{-1, -1}, {1, 1}}
	internal_tank.tank_count = 2
	internal_tank.pictures = fluid_locomotive.pictures
	fluid_locomotive.pictures = nil
	internal_tank.wheels = nil


	local spacer = util.table.deepcopy(data.raw["cargo-wagon"]["cargo-wagon"])

	spacer.connection_distance = 3
	spacer.joint_distance = 0.1
	spacer.pictures = nil
	spacer.collision_box = {{-0.6, -1}, {0.6, 1}}
	spacer.selection_box = {{-1, -1}, {1, 1}}


	data:extend({spacer})
	data:extend({fluid_locomotive})
	data:extend({internal_tank})
end

function public.generateTank(size)
    local proxy_tank = util.table.deepcopy(data.raw["pump"]["pump"])

	proxy_tank.name = "fluidTrains-proxy-tank-"..size
    log("proxy tank name ".. proxy_tank.name)
	proxy_tank.icon = "__core__/graphics/empty.png"
	proxy_tank.icon_size = 1
	proxy_tank.flags = {"placeable-neutral", "not-on-map"}
	proxy_tank.collision_mask = {
		layers = {}
	}
	proxy_tank.selectable_in_game = false
	proxy_tank.minable = nil
	proxy_tank.next_upgrade = nil  -- Compatibility with other mods altering this value
	proxy_tank.max_health = nil
	proxy_tank.corpse = "small-remnants"
	proxy_tank.collision_box = {{-1.6, -1.6}, {1.6, 1.6}}
	proxy_tank.selection_box = {{-0.1, -0.1}, {0.1, 0.1}}
	proxy_tank.energy_source = {type = "void"}
	proxy_tank.resistances = {}
    proxy_tank.fluid_box.volume = size
	proxy_tank.fluid_box.pipe_covers = nil

	proxy_tank.fluid_box.pipe_connections = {}
	for i = 1, 12 do
		-- Add one pipe connection for each possible pump position
		proxy_tank.fluid_box.pipe_connections[i] = {
			connection_type = "linked",
			linked_connection_id = i,
			flow_direction = "input"
		}
	end
    -- for _, input in pairs(proxy_tank.fluid_box.pipe_connections) do
    --     input.flow_direction = "input"
    -- end

	proxy_tank.fluid_box.base_area = size / 100
	proxy_tank.fluid_box.filter = nil
	proxy_tank.two_direction_only = false
	-- proxy_tank.pictures.picture.sheets =
	-- {
	-- 	{
	-- 		filename = "__core__/graphics/empty.png",
	-- 		frames = 1,
	-- 		width = 1,
	-- 		height = 1,
	-- 		shift = util.by_pixel(0, 0),
	-- 		hr_version =
	-- 		{
	-- 			filename = "__core__/graphics/empty.png",
	-- 			frames = 1,
	-- 			width = 1,
	-- 			height = 1,
	-- 			shift = util.by_pixel(0, 0)
	-- 		}
	-- 	},
	-- 	{
	-- 		filename = "__core__/graphics/empty.png",
	-- 		frames = 1,
	-- 		width = 1,
	-- 		height = 1,
	-- 		shift = util.by_pixel(0, 0),
	-- 		hr_version =
	-- 		{
	-- 			filename = "__core__/graphics/empty.png",
	-- 			frames = 1,
	-- 			width = 1,
	-- 			height = 1,
	-- 			shift = util.by_pixel(0, 0)
	-- 		}
	-- 	}
	-- }
	-- -- proxy_tank.pictures.fluid_background.filename = "__core__/graphics/empty.png"
	-- proxy_tank.pictures.fluid_background.width = 1
	-- proxy_tank.pictures.fluid_background.height = 1
	-- proxy_tank.pictures.window_background.filename = "__core__/graphics/empty.png"
	-- proxy_tank.pictures.window_background.width = 1
	-- proxy_tank.pictures.window_background.height = 1
	-- proxy_tank.pictures.window_background.hr_version = {
	-- 	filename = "__core__/graphics/empty.png",
	--     width = 1,
	--     height = 1
	-- }
	-- proxy_tank.pictures.flow_sprite.filename = "__core__/graphics/empty.png"
	-- proxy_tank.pictures.flow_sprite.width = 1
	-- proxy_tank.pictures.flow_sprite.height = 1
	-- proxy_tank.pictures.gas_flow.filename = "__core__/graphics/empty.png"
	-- proxy_tank.pictures.gas_flow.width = 1
	-- proxy_tank.pictures.gas_flow.height = 1
	-- proxy_tank.pictures.gas_flow.line_length = 1
	-- proxy_tank.pictures.gas_flow.frame_count =1
	-- proxy_tank.pictures.gas_flow.animation_speed = 1
	-- proxy_tank.pictures.gas_flow.hr_version = {
	-- 	filename = "__core__/graphics/empty.png",
	-- 	width = 1,
	-- 	height = 1,
	-- 	line_length = 1,
	-- 	frame_count = 1,
	-- 	animation_speed = 1
	-- }
	proxy_tank.vehicle_impact_sound = nil
	proxy_tank.circuit_wire_connection_points = {}
	proxy_tank.circuit_connector_sprites = {}
	proxy_tank.circuit_wire_max_distance = 0
	proxy_tank.localised_name = "Hidden"
	proxy_tank.order = "proxy-tank-"..size

	data:extend({proxy_tank})

end

return public
