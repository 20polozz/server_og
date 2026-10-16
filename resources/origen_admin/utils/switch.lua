function switch(value)
	return function(cases)
		setmetatable(cases, cases)
		
		local f = cases[value]
		if f then
			f()
		end
	end
end