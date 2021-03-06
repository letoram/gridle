--
-- simple, flat, list + icons view
--
-- expected members:
-- hide(self)
--   hide the navigation graphics (pre- internal launch)
--
-- show(self)
--   show the navigation graphics (post- internal launch)
--
-- create (self, constraints)
--   called once on load
--
-- update_list(self, table)
--   called whenever the list of available games has changed
--
-- navigation functions (mapped to keypresses)
-- up(self, steps)
-- down(self, steps)
-- left(self, steps)
-- right(self, steps)
-- toggle(self) => tbl, return table from list to launch (or nil)
-- current_item(self) => tbl, return table from list (for showing data)
--

local restbl = {};
restbl.name = "list";

restbl.create = function(self, constr)
	if (not constr.font_size) then
		constr.font_size = settings.colourtable.font_size;
	end

	self.constr = constr;
	self.clipregion = null_surface(constr.width, constr.height);
	image_tracetag(self.clipregion, "navi(list).clip");
	show_image(self.clipregion);
	self.selector = fill_surface(constr.width, 
		constr.font_size + 2, 0, 40, 200);
	image_tracetag(self.selector, "navi(list).selector");

-- center-pointed used to calculate origo offset
	self.cpx = math.floor(constr.width  * 0.5);
	self.cpy = math.floor(constr.height * 0.5);
	
	move_image(self.clipregion, -constr.width, constr.y);

-- icon collections etc. for mame and friends.
	local tmp = glob_resource("icons/*.ico", ALL_RESOURCES);
	self.icons = {};
	for ind,val in ipairs(tmp) do
		self.icons[val] = true;
	end

-- use the requested constraints as a clipping region
	link_image(self.selector, self.clipregion);
	image_inherit_order(self.selector, true);
	image_clip_on(self.selector, CLIP_SHALLOW);
	show_image(self.selector);

	self:show();
end

restbl.escape = function(self) 
	return true; 
end

restbl.up     = function(self, step) 
	restbl:step(-1 * step); 
end

restbl.down   = function(self, step) 
	restbl:step(step); 
end

restbl.left   = function(self, step) 
	restbl:step(self.page_size * -1 * step); 
end

restbl.right  = function(self, step) 
	restbl:step(self.page_size * step);
end

restbl.current_item = function(self)
	return self.list[self.cursor];
end

restbl.move_cursor = function(self)
	local page_beg, page_ofs, page_end = self:curpage();
	
	instant_image_transform(self.selector);
	move_image(self.selector, 0, self.menu_lines[page_ofs] - 1, 10);
	blend_image(self.selector, 0.5);
end

restbl.select_random = function(self, fv)
	self.cursor = math.random(1, #data.games);
	self:redraw();
end

restbl.get_linestr = function(self, gametbl)
	local res = gametbl.title;
	local fs = tostring(self.constr.font_size);
	
	if self.icons[gametbl.setname .. ".ico"] then
		res = "\\P" .. fs .. "," .. fs ..",icons/" .. gametbl.setname .. ".ico," .. res;
	elseif self.icons[gametbl.target .. ".ico"] then
		res = "\\P" .. fs .. "," .. fs ..",icons/" .. gametbl.target .. ".ico," .. res;
	end

	return res;	
end

restbl.redraw = function(self)
	if (valid_vid(self.menu)) then
		delete_image(self.menu);
	end
	
	local page_beg, page_ofs, page_end = self:curpage(); 
	local renderstr = self.constr.font .. self.constr.font_size.. " ";

-- self.linestr is responsible for padding with icons etc.
	for ind = page_beg, page_end do
		renderstr = renderstr .. self:get_linestr(self.list[ind]) .. [[\n\r]];
	end

	local menu, lines = render_text( renderstr, 2 );
	self.menu = menu;
	self.menu_lines = lines;

	image_tracetag(self.menu, "navi(list).text");
	link_image(self.menu, self.clipregion);
	image_clip_on(self.menu);
	image_inherit_order(self.menu, true);
	order_image(self.menu, 1);
	blend_image(self.menu, self.constr.opa);

	self:move_cursor();
	return nil;
end

restbl.hide = function(self)
	instant_image_transform(self.clipregion);
	local dim = image_surface_properties(self.clipregion);
	move_image(self.clipregion, -1 * self.constr.pos[1], self.constr.pos[2], 20);
	blend_image(self.clipregion, 0.0, 20);
end

restbl.show = function(self)
	instant_image_transform(self.clipregion);
	local dim = image_surface_properties(self.clipregion);
	move_image(self.clipregion, self.constr.pos[1], self.constr.pos[2], 20);
	order_image(self.clipregion, self.constr.zv);
	blend_image(self.clipregion, 1.0, 20);
end

restbl.calc_page = function(self, number, size, limit)
	local page_start = math.floor( (number - 1) / size) * size;
	local offset     = (number - 1) % size;
	local page_end   = page_start + size;
	
	if (page_end > limit) then
		page_end = limit;
	end

	return page_start + 1, offset + 1, page_end;
end

restbl.curpage = function(self)
	return self:calc_page(self.cursor, self.page_size, #self.list);
end

restbl.step = function(self, stepv)
	local curpg, ign, ign2 = self:curpage();

	local ngn = self.cursor + stepv;
	ngn = ngn < 1 and #self.list or ngn;
	ngn = ngn > #self.list and 1 or ngn;

	self.cursor = ngn;
	local newpg, ign, ign2 = self:curpage();

	if (newpg ~= curpg) then
		self:redraw();	
	else
		self:move_cursor();
	end
end

local function window_height(fontmsg, nlines)
	local heightstr = fontmsg;
	for i=1,nlines do
		heightstr = heightstr .. " Ag\\n\\r"
	end
	txw, txh = text_dimensions(heightstr);

	return txh;
end

restbl.update_list = function(self, gamelist)
	self.list   = gamelist;
	self.cursor = 1;
	self.page_size = math.floor( self.constr.height / self.constr.font_size );
	
	while (self.page_size > 1 and
		window_height(self.constr.font .. 
			self.constr.font_size .. " ", self.page_size) > self.constr.height) do
		self.page_size = self.page_size - 1;
	end

	if (self.page_size < 1) then 
		self.page_size = 0; 
	end
	
	self:redraw();
end

restbl.trigger_selected = function(self) 
	return self.list[ self.cursor ]; 
end

return restbl;
