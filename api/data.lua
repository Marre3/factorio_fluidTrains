local public = {}

function public.generateTank(size)
    local proxy_tank = util.table.deepcopy(data.raw["pump"]["pump"])

	proxy_tank.name = "fluidTrains-proxy-tank-"..size
    log("proxy tank name ".. proxy_tank.name)
	proxy_tank.icon = "__core__/graphics/empty.png"
	proxy_tank.icon_size = 1
	proxy_tank.icon_mipmaps = 0
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
	proxy_tank.selection_box = {{-1, -1}, {1, 1}}
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
