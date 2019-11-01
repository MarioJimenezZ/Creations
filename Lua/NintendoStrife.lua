-- Script Name: Nintendo Strife
-- Script Ver.: 1.0
-- Author     : Mario Jimenez
-- Date       : December 4, 2014

-- Since there's no GameStart Callback yet --
local NintendoLoaded = false
Callback.Bind('Tick', function()
	if not NintendoLoaded then
		Nintendo = Nintendo()
		NintendoLoaded = true
	end
end)

class 'Nintendo'	
	function Nintendo:__init()
		--> Loads Variables Class
		self.vars    = Variables()
		--> Loads Utility Class
		self.utility = Utility()

		--> Nintendo Menu
		self.menu = MenuConfig('Nintendo', 'Nintendo Menu')
			self.menu:Menu('orbwalk', 'Nintendo Orbwalker')
				self.menu.orbwalk:Boolean('enabled', 'Enable Nintendo Orbwalker', true)

		self.menu:Section('keys', 'Keys Settings')
				self.menu:KeyBinding('comboKey',  'Combo Key',  'X')
				self.menu:KeyBinding('harassKey', 'Harass Key', 'C')
				self.menu:KeyBinding('clearKey',  'Clear  Key', 'V')
		--> Our Tick Function
		Callback.Bind('Tick', function() self:Tick() end)
	end

	function Nintendo:Tick()
		local target = self.utility:Target()
		if Keyboard.KeysDown(self.menu.comboKey:Value()) then
			self.utility:MoveToMouse()
			if target then
				Spells.Q:Cast(target)
				Spells.W:Cast(target)			
			end
		end
	end

class 'Variables'
	function Variables:__init()
		local S = {
			Moxie = {
				['Q'] = {r = 625,   n = 'Z Zap',          t = 'targeted'},
				['W'] = {r = 1000,  n = 'Ball Lightning', t = 'linear'  },
				['E'] = {r = 1000,  n = 'Astral Winds',   t = 'notarget'},
				['R'] = {r = 1200,  n = 'Catastrophe',    t = 'circular'}
			}
		}
		Spells = {
			['Q'] = Spells(0, S['Moxie'].Q.r, S['Moxie'].Q.n, S['Moxie'].Q.t),
			['W'] = Spells(1, S['Moxie'].W.r, S['Moxie'].W.n, S['Moxie'].W.t),
			['E'] = Spells(2, S['Moxie'].E.r, S['Moxie'].E.n, S['Moxie'].E.t),
			['R'] = Spells(3, S['Moxie'].R.r, S['Moxie'].R.n, S['Moxie'].R.t)
		}
	end

class 'Spells'
	function Spells:__init(number, range, name, spelltype)
		self.number   = number
		self.range    = range
		self.name     = name
		self.type     = spelltype
		self.lastCast = 0
	end

	function Spells:Range()
		return self.range
	end

	function Spells:Ready()
		--print(Game.GetLocalPlayer().hero:GetAbility(self.number + 1).isActive)
		--return not Game.GetLocalPlayer().hero:GetAbility(self.number + 1).isActive
		return true
	end

	function Spells:Name()
		return self.name
	end

	function Spells:Cast(target)
		if Game.GetLocalPlayer().hero.pos:DistanceTo(target.pos) < self.range and self:Ready() then
			if self.type == 'targeted' then
				self:CastOnUnit(self.number, target)
			else
				self:CastOnPos(self.number, target.pos)
			end
		end
	end

	function Spells:CastOnUnit(slot, unit)
		local p = Game.CLoLPacket(0x1D)
		p:Encode2(Game.GetLocalPlayer().hero.uid)
		p:Encode2(0)
		p:Encode1(slot)
		p:Encode2(unit.uid)
		p:Encode4(0)
		Game.SendPacket(p)
	end

	function Spells:CastOnPos(slot, pos)
		local p = Game.CLoLPacket(0x1C)
		p:Encode2(Game.GetLocalPlayer().hero.uid)
		p:Encode2(0)
		p:Encode1(slot)
		p:EncodeF(pos.x)
		p:EncodeF(pos.y)
		p:Encode2(0)
		Game.SendPacket(p)
	end

class 'Utility'
	function Utility:__init()
		self.lastMove = 0
	end

	function Utility:MoveToMouse()
		if Game.GetTickCount() - self.lastMove > 100 then
			local mousePos = Game.GetCursor()
			Game.MoveTo(mousePos.x, mousePos.y)
			self.lastMove = Game.GetTickCount()
		end
	end

	function Utility:HeroTable()
		local herotable = {}
		for _, player in pairs(sh.entities) do
			if string.find(player.name, 'Hero') then
				table.insert(herotable, player)
			end
		end
		return herotable
	end

	function Utility:Target()
		local heroes = self:HeroTable()
		local target = nil
		for i, hero in ipairs(heroes) do
			if hero.team ~= Game.GetLocalPlayer().hero.team and hero.valid and hero.health > 0 and (target == nil or hero.health < target.health) then
				target = hero
			end
		end
		return target
	end