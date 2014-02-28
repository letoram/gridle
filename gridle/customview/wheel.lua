--
-- wheel of marquees
--

local restbl = {
	start_angle = 120,
	stop_angle = 160,
	angle = 120,
	cell_sh = math.floor(VRESH * 0.2),
	cell_mh = math.floor(VRESH * 0.1),
	cell_space = 10
};

restbl.create = function(self, constr)
	self.anchor = null_surface(constr.width, constr.height);
	show_image(self.anchor);
	
	local sz = constr.height - (restbl.cell_sh + cell_space);
	restbl.count = 1 + math.floor(sz / (restbl.cell_mh + cell_space)); 
end

restbl.slide = function(self, ds)
	
end

restbl.escape = function(self)
end

restbl.up = function(self, step)
end

restbl.down = function(self, step)
end

restbl.left = function(self, step)

end

restbl.right = function(self, step)

end

restbl.create = function(self, constr)
	
end

restbl.select_random = function(self, fv)
end

restbl.redraw = function(self)
-- assume pos in center, then sweep upwards (-) and downwards (+)
	
	if (#self.list > self.count) then
	end
end

restbl.update_list = function(self, gamelist)
	self.list = gamelist;
	self.pos = 1;
	self:redraw();
end

restbl.trigger_selected = function(self)
	return self.list[self.pos];
end

return restbl;
