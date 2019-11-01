-- Script Name : NintendoLeague
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : Feb 9, 2015


--> Starts Bundle
Callback.Bind('GameStart', function() Start:GameStart() end)

class 'Start'
	function Start:GameStart()
		--> Global Table
		_G.Nintendo        = {}
		--> Utility Class
		Nintendo.Utils     = Util()
		--> WayPoint Manager Class
		Nintendo.WayPoints = WayPoints()
		--> Packet Class
		Nintendo.Packets   = Packets()
		--> Object Class
		Nintendo.Objects   = Objects()
		--> Callbacks/Supported Heroes Tables
		Variables()
		--> Initiates Menu
		Nintendo.Menu      = Menu('Nintendo - '..myHero.charName)
		--> Prevents from loading with heroes not supported
		if Callbacks[myHero.charName] ~= nil then
			--> Hero Class
			Nintendo.Hero      = Callbacks[myHero.charName].class()
			--> Summoner Spells
			Nintendo.Spells    = SummonerSpells()
			--> Items Class
			Nintendo.Items     = Items()
			--> Drawer Class
			Nintendo.Drawer    = Drawer()
			--> WardJumper
			Nintendo.Jumper    = WardJump()
			--> OrbWalking Class
			Nintendo.Walk      = Orbwalk()
			--> Custom Prediction
			Nintendo.Predict   = Predict()
			--> Custom Farming Callback
			if Callbacks[myHero.charName].Farming then
				Farming()
			end
			--> Nintendo Target
			Callback.Bind('Tick', function()
				Nintendo.Target = Nintendo.Utils:Target()
			end)
			--> Enables Bilbo's Prediction
			--BasicPrediction.EnablePrediction()
			--> Loads Version and Prints to Chat
			Nintendo.Version = Version()
		end
	end

class 'Jax'
	function Jax:__init()
		self.E = {using = false}
		--> Binds SendPacket
		Callback.Bind('SendPacket', function(packet) self:SendPacket(packet) end)
		--> Binds RecvPacket
		Callback.Bind('RecvPacket', function(packet) self:RecvPacket(packet) end)
		--> Binds Tick
		Callback.Bind('Tick', function() self:Tick() end)
	end

	function Jax:Tick()
		if Nintendo.Target then
			if Keyboard.KeysDown(Nintendo.Menu:Values('Combo')) then
				self:Combo(Nintendo.Target)
			end
			if Keyboard.KeysDown(Nintendo.Menu:Values('Harass')) then
				Combat:JaxHarass(Nintendo.Target)
			end
		end
	end

	function Jax:SendPacket(packet)
		if not self.E.using then
			if packet and packet.header == 0x9A and packet:Decode4() == myHero.networkID then
				local Idk = packet:Decode1()
				local spellId = packet:Decode1()
				if spellId == 2 then
					self.E.using = true
					--print('started using E')
				end
			end
		end
	end

	function Jax:RecvPacket(packet)
		if packet.header == 0x7B then
			packet.pos = 1
			if packet:Decode4() == myHero.networkID then
 				packet.pos = 6
 				if packet:Decode4() == 63364661 then
 					self.E.using = false
 					--print('Ended Using E')
 				end
 			end
 		end
	end

	function Jax:Combo(target)
		if not self.E.using then
			if myHero:DistanceTo(target) < 700 then
				myHero:CastSpell(2)
			end
		end
		Spells.Q:Cast(target)
		Spells.W:Cast(target)
		if self.E.using and Nintendo.Utils:CountEnemiesAround(myHero, Spells.E:Range()) > 0 then
			myHero:CastSpell(2)
		end
		if (myHero.health < (myHero.maxHealth / 2)) or (Nintendo.Utils:CountEnemiesAround(myHero, 800) > 1) then
			Spells.R:Cast(target)
		end
	end

	function Jax:Harass(target)
		Spells.Q:Cast(target)
		Spells.W:Cast(target)
		Spells.E:Cast(target)
	end

class 'Katarina'
	function Katarina:__init()
		self.Q = {throwing = false, last = 0}
		self.R = {using    = false, last = 0}
		self.targetswithQ = {}
		--> Katarina Menu
		-- Q
		Nintendo.Menu:Self().spellQ:Boolean('comboP',  'Proc Q Mark in Combo',  true)
		Nintendo.Menu:Self().spellQ:Boolean('harassP', 'Proc Q Mark in Harass', true)
		Nintendo.Menu:Self().spellQ:Boolean('auto', 'Auto Q if Enemy in Range', false)
		-- W
		Nintendo.Menu:Self().spellW:Boolean('auto', 'Auto W if Enemy in Range', true)
		--> Binds SendPacket
		Callback.Bind('SendPacket', function(packet) self:SendPacket(packet) end)
		--> Binds RecvPacket
		Callback.Bind('RecvPacket', function(packet) self:RecvPacket(packet) end)
		--> Binds ProcessSpell
		Callback.Bind('ProcessSpell', function(unit, spell) self:Spells(unit, spell) end)
		--> Binds Tick
		Callback.Bind('Tick', function() self:Tick() end)
		--> Binds Draws
		Callback.Bind('Draw', function() self:Draw() end)
		--> Binds WndMsg
		Callback.Bind('WndMsg', function(msg, key)
			if self.R.using and key == 2 then
				self.R.using = false
			end
		end)
	end

	function Katarina:Tick()
		if not self.R.using and Nintendo.Target then
			self:AutoSkills()
			if Keyboard.KeysDown(Nintendo.Menu:Values('Combo'))  then
				self:Combo(Nintendo.Target)
			end
			if Keyboard.KeysDown(Nintendo.Menu:Values('Harass')) then
				self:Harass(Nintendo.Target)
			end
		end
		if Nintendo.Menu:Values('KillSteal') then
			--self:KillSteal()
		end
		if Keyboard.KeysDown(Nintendo.Menu:Values('Clear')) then
			Combat:Clear()
		end
		if self.Q.throwing then
			if (Nintendo.Utils:Clock() - self.Q.last) > 0.5 then
				self.Q.throwing = false
			end
		end
	end

	function Katarina:Draw()
		if Nintendo.Menu:Utils().draw.drawDmg:Value() and not myHero.dead then
			for _, enemy in ipairs(Nintendo.Objects:EnemyHeroes()) do
				if Nintendo.Utils:Valid(enemy) then
					local combo = {0, 1, 2}
					local extraDmg = 0
					if Spells.Q:Ready() then
						extraDmg = extraDmg + self:QBuffDmg(enemy)
					end
					if Spells.R:Ready() then
						extraDmg = extraDmg + (Combo:GetDmg({3}, enemy))
					end
					local totalDmg = math.round(Combo:GetDmg(combo, enemy) + extraDmg)
					Nintendo.Drawer:MaxDmg(enemy, totalDmg)
				end
			end
		end
	end

	function Katarina:QBuff(unit)
		for _, target in ipairs(self.targetswithQ) do
			if unit == target then
				return true
			end
		end
		return false
	end

	function Katarina:QBuffDmg(unit)
		local p = {dmg = {15,  30, 45,  60,   75},  apscaling = .15} -- QPassive Dmg
		local spellDmg  = p.dmg[myHero:GetSpellData(0).level] or 0
		local apscaling = p.apscaling or 0
		local totaldmg  = spellDmg + (apscaling * myHero.ap)
		return unit and myHero:CalcMagicDamage(unit, totaldmg)
	end

	function Katarina:Spells(unit, spell)
		if unit.isMe and spell.name == 'KatarinaQ' then
			self.Q.throwing = true
			self.Q.last     = os.clock()
		end
	end

	function Katarina:SendPacket(packet)
		if self.R.using then
			if Nintendo.Target and Combo:GetDmg({2,0,1}, Nintendo.Target) >= Nintendo.Target.health then
				return 
			elseif packet and packet:Decode4() == myHero.networkID then
				packet:Block()
			end
		else
			if packet and packet.header == 0x9A and packet:Decode4() == myHero.networkID then
				local Idk = packet:Decode1()
				local spellId = packet:Decode1()
				if spellId == 3 then
					self.R.using = true
					self.R.last  = Nintendo.Utils:Clock()
					--print('started using R')
				end
			end
		end
	end

	function Katarina:RecvPacket(packet)
		if packet.header == 0xB7 then
			packet.pos = 1
			local target = Game.ObjectByNetworkId(packet:Decode4())
			packet.pos = 9
			local id = packet:Decode4()
			packet.pos = 25
			local source = Game.ObjectByNetworkId(packet:Decode4())
			if source == myHero and target and target.type == myHero.type and id == (84848667 or 28814379) then
				self.Q.throwing = false
				table.insert(self.targetswithQ, target)
				--print('Q Gained Buff: '..target.charName)
			end 
		elseif packet.header == 0x7B then
 			packet.pos = 1
 			local target = Game.ObjectByNetworkId(packet:Decode4())
 			packet.pos = 6
 			local id = packet:Decode4()
 			if target == myHero and id == 3334932 then
 				self.R.using = false
 				--print('Ended Using R')
 			elseif target and target ~= myHero and target.type == myHero.type and id == (84848667 or 28814379) then
 				for i, hero in pairs(self.targetswithQ) do
 					if hero == target then
	 					table.remove(self.targetswithQ, i)
	 					--print('Q Lost Buff: '..target.charName)	
	 				end
 				end
 			end
 		end
	end

	function Katarina:AutoSkills()
		for _, enemy in ipairs(Nintendo.Objects:EnemyHeroes()) do
			if Nintendo.Utils:Valid(enemy) then
				if Nintendo.Menu:Self().spellQ.auto:Value() then
					Spells.Q:Cast(enemy)
				end
				if Nintendo.Menu:Self().spellW.auto:Value() then
					Spells.W:Cast(enemy)
				end
			end
		end
	end

	function Katarina:Combo(target)
		if Nintendo.Menu:Values('ComboQ') then
			Spells.Q:Cast(target)
		end		
		if Nintendo.Menu:Values('ComboW') then 
			Spells.W:Cast(target)
		end

		if Nintendo.Menu:Values('ComboE') then
			if Nintendo.Menu:Self().spellQ.comboP:Value() then
				if self:QBuff(target) or not self.Q.throwing then
					Spells.E:Cast(target)
				end
			else
				Spells.E:Cast(target)
			end
		end
		if not Spells.Q:Ready() and not Spells.W:Ready() and not Spells.E:Ready() and Nintendo.Menu:Values('ComboR') then
			Spells.R:Cast(target)
		end
	end

	function Katarina:Harass(target)
		if Nintendo.Menu:Values('HarassQ') then
			Spells.Q:Cast(target)
		end
		if Nintendo.Menu:Values('HarassW') then
			Spells.W:Cast(target)
		end
		if Nintendo.Menu:Values('HarassE') then
			if Nintendo.Menu:Self().spellQ.harassP:Value() then
				if self:QBuff(target) or (not Spells.Q:Ready() and not self.Q.throwing) then
					Spells.E:Cast(target)
				end
			else
				Spells.E:Cast(target)
			end
		end
	end

	function Katarina:KillSteal()
		local KillCombo  = {}
		if Spells.Q:Ready() then
			table.insert(KillCombo, 0)
		end
		if Spells.W:Ready() then
			table.insert(KillCombo, 1)
		end
		if Spells.E:Ready() then
			table.insert(KillCombo, 2)
		end
		for _, enemy in ipairs(Nintendo.Objects:EnemyHeroes()) do
			local QBuffDmg = (self:QBuff(enemy) and self:QBuffDmg(enemy)) or 0
			if Nintendo.Utils:Valid(enemy, 700) and (Combo:GetDmg(KillCombo, enemy) + QBuffDmg) >= enemy.health then
				Combo:Cast(KillCombo, enemy)
			end
		end
	end

class 'LeeSin'
	function LeeSin:__init()
		--> Binds Tick
		Callback.Bind('Tick', function() self:Tick() end)
	end

	function LeeSin:Tick()
		if Nintendo.Target then
			if Keyboard.KeysDown(Nintendo.Menu:Values('Combo')) then
				Spells.Q:Cast(Nintendo.Target)
			end
		end
	end

class 'Morgana'
	function Morgana:__init()
		--> Binds Tick
		Callback.Bind('Tick', function() self:Tick() end)
	end

	function Morgana:Tick()
		if Nintendo.Target then
			if Keyboard.KeysDown(Nintendo.Menu:Values('Combo')) then
				--Spells.Q:Cast(Nintendo.Target)
			end
		end
	end

class 'Zilean'
	function Zilean:__init()
		--> Q
		Nintendo.Menu:Self().spellQ:Boolean('auto', 'Auto Q if Enemy in Range', true)
		Nintendo.Menu:Self().spellQ:Slider('mana', 'mana', 50, 0, 100, 1)
		--> W
		Nintendo.Menu:Self().spellW:Slider('cd', 'Dont W if Q CD <', 2, 0, 5, .5)
		-->Binds Tick
		Callback.Bind('Tick', function() self:Tick() end)
	end

	function Zilean:Tick()
		if Nintendo.Target then
			if Keyboard.KeysDown(Nintendo.Menu:Values('Combo')) then
				self:Combo(Nintendo.Target)
			end
			if Keyboard.KeysDown(Nintendo.Menu:Values('Harass')) then
				self:Harass(Nintendo.Target)
			end
		end
		self:AutoSkills()
		if Nintendo.Menu:Values('KillSteal') then
			self:KillSteal()
		end
		if Keyboard.KeysDown(Nintendo.Menu:Values('Clear')) then
			Combat:Clear()
		end
	end

	function Zilean:AutoSkills()
		for _, enemy in ipairs(Nintendo.Objects:EnemyHeroes()) do
			if Nintendo.Utils:Valid(enemy) and myHero.mana >= (myHero.maxMana * (Nintendo.Menu:Self().spellQ.mana:Value() / 100)) then
				if Nintendo.Menu:Self().spellQ.auto:Value() then
					Spells.Q:Cast(enemy)
				end
			end
		end
	end

	function Zilean:KillSteal()
		for _, enemy in ipairs(Nintendo.Objects:EnemyHeroes()) do
			local qDmg = Combo:GetDmg({0}, enemy)
			if enemy.health <= qDmg then
				Spells.Q:Cast(enemy)
			end
		end
	end

	function Zilean:Combo(target)
		if Nintendo.Menu:Values('ComboQ') then
			Spells.Q:Cast(target)
		end		
		if Nintendo.Menu:Values('ComboW') then
			if Spells.Q:Data().currentCd > Nintendo.Menu:Self().spellW.cd:Value() then
				Spells.W:Cast(target)
			end
		end
		if Nintendo.Menu:Values('ComboE') then
			Spells.E:Cast(target)
		end
	end

	function Zilean:Harass(target)
		if Nintendo.Menu:Values('HarassQ') then
			Spells.Q:Cast(target)
		end		
		if Nintendo.Menu:Values('HarassW') then
			if Spells.Q:Data().currentCd > Nintendo.Menu:Self().spellW.cd:Value() then
				Spells.W:Cast(target)
			end
		end
		if Nintendo.Menu:Values('HarassE') then
			Spells.E:Cast(target)
		end
	end		

class 'Version'
	function Version:__init()
		self.vers = {
			Bundle   = 1.10,
			Jax      = 1.03,
			Katarina = 1.10,
			LeeSin   = 1.0,
			Morgana  = 1.0,
			Zilean   = 1.0
		}
		print('Nintendo Bundle Loaded! Bundle Ver: '..self.vers.Bundle..' Champion : '..myHero.charName..' Version :'..self.vers[myHero.charName])
	end

-- Mostly Imported from BoL 1 Packet lib --
class 'Packets'
	function Packets:__init()
		self.headers = {
			['GainBuff']    = 0xB7,
			['UpdateBuff1'] = 0x1C,
			['UpdateBuff2'] = 0x2F,
			['LoseBuff']    = 0x7B,
			['FoW1']        = 0x17,
			['FoW2']        = 0x67,
			['Dash']        = 0x64,
			['FoWDash']     = 0xBB,
			['GainVision']  = 0xAE,
			['LoseVision']  = 0x35,
			['HideUnit']    = 0x51,
			['WayPoint']    = 0xBA,
			['WayPoints']   = 0x61
		}
	end

	function Packets:Header(name)
		return self.headers[name]
	end

	function Packets:DecodeWaypoints(packet, waypointCount)
		local wayPoints = {}
    	if math.ceil(waypointCount) ~= math.floor(waypointCount) then
    		waypointCount = math.floor(waypointCount)
        	packet:Decode1()
    	end
    	local modifierBits = {0, 0}
    	for i = 1, math.ceil((waypointCount - 1) / 4) do
    		local bitMask = packet:Decode1()
        	for j = 1, 8 do
            	table.insert(modifierBits, bit.band(bitMask, 1))
            	bitMask = bit.rshift(bitMask, 1)
        	end
    	end
    	for i = 1, waypointCount do
	    	table.insert(wayPoints, self:GetNextWayPoint(packet, modifierBits))
    	end
    	return wayPoints
	end

	function Packets:GetNextWayPoint(packet, modifierBits)
		coord = Geometry.Point(self:GetNextGridCoord(packet, modifierBits, coord and coord.x or 0), self:GetNextGridCoord(packet, modifierBits, coord and coord.y or 0) )
		return Geometry.Point(2 * coord.x + Nintendo.Utils:GetMap().grid.width, 2 * coord.y + Nintendo.Utils:GetMap().grid.height)
	end

	function Packets:GetNextGridCoord(packet, modifierBits, relativeCoord)
		if table.remove(modifierBits, 1) == 1 then
    		return relativeCoord + self:UnsignedToSigned(packet:Decode1(), 1)
    	else
    		return self:UnsignedToSigned(packet:Decode2(), 2)
    	end
	end

	function Packets:UnsignedToSigned(value, byteCount)
		local byteCount = 2 ^ ( 8 * byteCount)
    	return value >= byteCount / 2 and value - byteCount or value
	end

class 'Variables'
	function Variables:__init()
		Callbacks = { 
			Jax      = { Farming = false, dmg = PHYSICAL, class = function () Jax() end     },
			Katarina = { Farming = true,  dmg = MAGIC,    class = function () Katarina() end},
			LeeSin   = { Farming = false, dmg = PHYSICAL, class = function () LeeSin() end  },
			Morgana  = { Farming = false, dmg = MAGIC,    class = function () Morgana()end  },
			Zilean   = { Farming = false, dmg = MAGIC,    class = function () Zilean() end  }
		}
		if Callbacks[myHero.charName] then
			local S = {
				Jax = {
					['Q'] = {r = 700,  n = 'Leap Strike',        t = 'targeted'},
					['W'] = {r = 170,  n = 'Empower',            t = 'notarget'},
					['E'] = {r = 180,  n = 'Counter Strike',     t = 'notarget'},
					['R'] = {r = 500,  n = 'Grandmasters Might', t = 'notarget'}
				},
				Katarina = {
					['Q'] = {r = 675,  n = 'Bouncing Blades',    t = 'targeted'},
					['W'] = {r = 400,  n = 'Sinister Steel',     t = 'notarget'},
					['E'] = {r = 700,  n = 'Shunpo',             t = 'targeted'},
					['R'] = {r = 550,  n = 'Death Lotus',        t = 'notarget'}
				},
				LeeSin = {
					['Q'] = {r = 1100, n = 'Sonic Wave',         t = 'linear',   s = 1200, d = .1515, w = 70, c = true},
					['W'] = {r = 700,  n = 'Safe Guard',         t = 'targeted'},
					['E'] = {r = 350,  n = 'Tempest',            t = 'notarget'},
					['R'] = {r = 375,  n = 'Dragons Rage',       t = 'targeted'}
				},
				Morgana = {
					['Q'] = {r = 1300, n = 'Dark Binding',       t = 'linear',   s = 1200, d = .4, w = 70, c = true},
					['W'] = {r = 900,  n = 'Tormented Soil',     t = 'circular', s = 20,   d = .67,   w = 280},
					['E'] = {r = 750,  n = 'Black Shield',       t = 'targeted'},
					['R'] = {r = 625,  n = 'Soul Shackles',      t = 'notarget'}
				},
				Zilean = {
					['Q'] = {r = 700,  n = 'Time Bomb',          t = 'targeted'},
					['W'] = {r = 700,  n = 'Rewing',             t = 'notarget'},
					['E'] = {r = 700,  n = 'Time Warp',          t = 'targeted'},
					['R'] = {r = 900,  n = 'Chrono Shift',       t = 'targeted'}
				}
			}
			Spells = {
				['Q'] = Spells(0, S[myHero.charName].Q.r, S[myHero.charName].Q.n, S[myHero.charName].Q.t, S[myHero.charName].Q.s, S[myHero.charName].Q.d, S[myHero.charName].Q.w, S[myHero.charName].Q.c),
				['W'] = Spells(1, S[myHero.charName].W.r, S[myHero.charName].W.n, S[myHero.charName].W.t, S[myHero.charName].W.s, S[myHero.charName].W.d, S[myHero.charName].W.w, S[myHero.charName].W.c),
				['E'] = Spells(2, S[myHero.charName].E.r, S[myHero.charName].E.n, S[myHero.charName].E.t, S[myHero.charName].E.s, S[myHero.charName].E.d, S[myHero.charName].E.w, S[myHero.charName].E.c),
				['R'] = Spells(3, S[myHero.charName].R.r, S[myHero.charName].R.n, S[myHero.charName].R.t, S[myHero.charName].R.s, S[myHero.charName].R.d, S[myHero.charName].R.w, S[myHero.charName].R.c),
			}
			Globals = { NintendoMenu = false }		
		end
	end

class 'Menu'
	function Menu:__init(name)
		self.MenuVars = {
			Jax      = {comboQ  = true, comboW  = true,  comboE  = true,  comboR  = true,
						harassQ = true, harassW = true,  harassE = false,
			  			clearQ  = true, clearW  = true,  clearE  = true},

			Katarina = {comboQ  = true, comboW  = true,  comboE  = true,  comboR  = true,
						harassQ = true, harassW = true,  harassE = false,
			  			clearQ  = true, clearW  = true,  clearE  = true},

			LeeSin   = {comboQ  = true, comboW  = true,  comboE  = true,  comboR  = true,
						harassQ = true, harassW = true,  harassE = false,
			  			clearQ  = true, clearW  = true,  clearE  = true},
			
			Morgana  = {comboQ  = true, comboW  = true,  comboE  = false, comboR  = true,
						harassQ = true, harassW = true,  harassE = false,
			  			clearQ  = true, clearW  = true,  clearE  = false},

			Zilean   = {comboQ  = true, comboW  = true,  comboE  = true, comboR  = false,
						harassQ = true, harassW = true,  harassE = false,
			  			clearQ  = true, clearW  = false, clearE  = false}
		}
		self.NintendoMenu = MenuConfig('Skeem'..myHero.charName, name)
			self.NintendoMenu:Section('skills', 'Skills Settings')
				self.NintendoMenu:Menu('spellQ', 'Q - '..Spells.Q:Name())
					self.NintendoMenu.spellQ:Section('usage', 'Usage')
						self.NintendoMenu.spellQ:Boolean('comboQ',  'Use in Combo',  self.MenuVars[myHero.charName].comboQ )
						self.NintendoMenu.spellQ:Boolean('harassQ', 'Use in Harass', self.MenuVars[myHero.charName].harassQ)
						self.NintendoMenu.spellQ:Boolean('clearQ',  'Use in Clear',  self.MenuVars[myHero.charName].clearQ )
				
				self.NintendoMenu:Menu('spellW', 'W - '..Spells.W:Name())
					self.NintendoMenu.spellW:Section('usage', 'Usage')
						self.NintendoMenu.spellW:Boolean('comboW',  'Use in Combo',  self.MenuVars[myHero.charName].comboW )
						self.NintendoMenu.spellW:Boolean('harassW', 'Use in Harass', self.MenuVars[myHero.charName].harassW)
						self.NintendoMenu.spellW:Boolean('clearW',  'Use in Clear',  self.MenuVars[myHero.charName].clearW )

				self.NintendoMenu:Menu('spellE', 'E - '..Spells.E:Name())
					self.NintendoMenu.spellE:Section('usage', 'Usage')
						self.NintendoMenu.spellE:Boolean('comboE',  'Use in Combo',  self.MenuVars[myHero.charName].comboE )
						self.NintendoMenu.spellE:Boolean('harassE', 'Use in Harass', self.MenuVars[myHero.charName].harassE)
						self.NintendoMenu.spellE:Boolean('clearE',  'Use in Clear',  self.MenuVars[myHero.charName].clearE )
			
				self.NintendoMenu:Menu('spellR', 'R - '..Spells.R:Name())
					self.NintendoMenu.spellR:Section('usage', 'Usage')
					self.NintendoMenu.spellR:Boolean('comboR',  'Use in Combo',  self.MenuVars[myHero.charName].comboR )

			self.NintendoMenu:Section('keys', 'Keys Settings')
				self.NintendoMenu:KeyBinding('comboKey',  'Combo Key',  'X')
				self.NintendoMenu:KeyBinding('harassKey', 'Harass Key', 'C')
				self.NintendoMenu:KeyBinding('clearKey',  'Clear  Key', 'V')

			self.NintendoMenu:Section('kill', 'Kill Settings')
				self.NintendoMenu:Boolean('steal', 'Enable KillSteal', true)
			
		self.NintendoUtils = MenuConfig('NUtils'..myHero.charName, 'Nintendo - Utilities ['..myHero.charName..']')
			self.NintendoUtils:Section('Utilities', 'Utilities')
			self.NintendoUtils:TargetSelector('nts', 'Nintendo Target', LESS_CAST, Nintendo.Utils:MaxRange(), 'Magic')

		self.NintendoMenu:Icon('fa-gamepad')
		--self.NintendoMenu.nts:Icon('fa-bullseye')
		Globals.NintendoMenu = true
	end

	function Menu:Self()
		return self.NintendoMenu
	end

	function Menu:Utils()
		return self.NintendoUtils
	end

	function Menu:Target(customrange, condition)
		return self.NintendoMenu.nts:GetTarget(customrange, condition)
	end

	function Menu:Values(key)
		local Keys = {
			AutoIgnite  = self.NintendoUtils.summoners and self.NintendoUtils.summoners.autoIgnite:Value(),
			Combo       = self.NintendoMenu.comboKey:Value(),
			ComboQ      = self.NintendoMenu.spellQ.comboQ:Value(),
			ComboW      = self.NintendoMenu.spellW.comboW:Value(),
			ComboE      = self.NintendoMenu.spellE.comboE:Value(),
			ComboR      = self.NintendoMenu.spellR.comboR:Value(),
			Clear       = self.NintendoMenu.clearKey:Value(),
			ClearQ      = self.NintendoMenu.spellQ.clearQ:Value(),
			ClearW      = self.NintendoMenu.spellW.clearW:Value(),
			ClearE      = self.NintendoMenu.spellE.clearE:Value(),
			DrawQ       = self.NintendoUtils.draw and self.NintendoUtils.draw.drawQ:Value(),
			DrawW       = self.NintendoUtils.draw and self.NintendoUtils.draw.drawW:Value(),
			DrawE       = self.NintendoUtils.draw and self.NintendoUtils.draw.drawE:Value(),
			DrawR       = self.NintendoUtils.draw and self.NintendoUtils.draw.drawR:Value(),
			DrawDisable = self.NintendoUtils.draw and self.NintendoUtils.draw.disable:Value(),
			FarmKey     = self.NintendoUtils.farm and self.NintendoUtils.farm.farmKey:Value(),
			FarmQ       = self.NintendoUtils.farm and self.NintendoUtils.farm.farmQ:Value(),
			FarmW       = self.NintendoUtils.farm and self.NintendoUtils.farm.farmW:Value(),
			FarmE       = self.NintendoUtils.farm and self.NintendoUtils.farm.farmE:Value(),
			Harass      = self.NintendoMenu.harassKey:Value(),
			HarassQ     = self.NintendoMenu.spellQ.harassQ:Value(),
			HarassW     = self.NintendoMenu.spellW.harassW:Value(),
			HarassE     = self.NintendoMenu.spellE.harassE:Value(),
			JumpKey     = self.NintendoUtils.wardjump and self.NintendoUtils.wardjump.jumpKey:Value(),
			JumpAllies  = self.NintendoUtils.wardjump and self.NintendoUtils.wardjump.allies:Value(),
			JumpMinions = self.NintendoUtils.wardjump and self.NintendoUtils.wardjump.minions:Value(),
			JumpMax     = self.NintendoUtils.wardjump and self.NintendoUtils.wardjump.maxrange:Value(),
			KillSteal   = self.NintendoMenu.steal:Value(),
			Orbwalk     = self.NintendoUtils.orbwalk and self.NintendoUtils.orbwalk.enabled:Value(),
			CarryMode   = self.NintendoUtils.orbwalk and self.NintendoUtils.orbwalk.carryMode:Value(),
			MixedMode   = self.NintendoUtils.orbwalk and self.NintendoUtils.orbwalk.mixedMode:Value(),
			ClearMode   = self.NintendoUtils.orbwalk and self.NintendoUtils.orbwalk.clearMode:Value(),
		}
		return Keys[key]
	end

class 'RecvPackets'

	function RecvPackets:Katarina(packet)
		if packet.header == 0x7B then
 			packet.pos = 1
 			if packet:Decode4() == myHero.networkID then
 				packet.pos = 6
 				if packet:Decode4() == 3334932 then
 					R.using = false
 					--print('Ended Using R')
 				end 					
 			end
 		end
	end

class 'Spells'
	function Spells:__init(number, range, name, spelltype, speed, delay, width , collision)
		self.number = number
		self.range  = range
		self.name   = name
		self.type   = spelltype
		self.col    = collision or false
		self.speed  = speed or 0
		self.delay  = delay or 0
		self.with   = width  or 0
		self.type   = spelltype
	end

	function Spells:Data()
		return myHero:GetSpellData(self.number)
	end

	function Spells:Range()
		return self.range
	end

	function Spells:Ready()
		return myHero:GetSpellData(self.number).currentCd == 0 and myHero:GetSpellData(self.number).level > 0
	end

	function Spells:Name()
		return self.name
	end

	function Spells:Cast(target)
		if (self.name == 'Ignite' or myHero:CanUseSpell(self.number) == 0) and Nintendo.Utils:Valid(target, self.range) then
			if self.type == 'targeted' then
				self:PacketCast(target, self.number)
				--myHero:CastSpell(self.number, target)
			elseif self.type == 'notarget' then
				myHero:CastSpell(self.number)
			elseif self.type == 'linear' then
				--local castpos, hc = Nintendo.Predict:VIP(target, self.delay, self.width, self.range, self.speed, myHero)
				local pos, hitchance = Nintendo.Predict:WTF(target, self.delay, self.speed, self.width, self.range, myHero)
				if pos ~= nil then
					print(hitchance)
					myHero:CastSpell(self.number, pos.x, pos.z)
				end
			end
		end
	end

	function Spells:PacketCast(target, spellId)
		local packet = Network.EnetPacket(0x9A)
		packet.channel = 1
		packet.flag = 0
		packet:Encode4(myHero.networkID)
		packet:Encode1(spellId)
		packet:EncodeF(myHero.x)
		packet:EncodeF(myHero.y)
		packet:EncodeF(target.x)
		packet:EncodeF(target.y)
		packet:Encode4(target.networkID)
		--packet:Hide()
		packet:Send()
	end

class 'SummonerSpells'
	function SummonerSpells:__init()
		self.ignite = myHero:GetSpellData(Game.Slots.SUMMONER_1).name == 'summonerdot' and Game.Slots.SUMMONER_1 or myHero:GetSpellData(Game.Slots.SUMMONER_2).name == 'summonerdot' and Game.Slots.SUMMONER_2 or nil
		self.list= {
			summonerflash        = {name="Flash",        range=400,  enabled = false},
			summonerhaste        = {name="Ghost",        range=0,    enabled = false},
			summonerdot          = {name="Ignite",       range=600,  enabled = true , callback = 'IgniteTick'},
			summonerbarrier      = {name="Barrier",      range=0,    enabled = false},
			summonersmite        = {name="Smite",        range=625,  enabled = false},
			summonerexhaust      = {name="Exhaust",      range=650,  enabled = false},
			summonerheal         = {name="Heal",         range=700,  enabled = false},
			summonerteleport     = {name="Teleport",     range=0,    enabled = false},
			summonerboost        = {name="Cleanse",      range=0,    enabled = false},
			summonermana         = {name="Clarity",      range=600,  enabled = false},
			summonerclairvoyance = {name="Clairvoyance", range=0,    enabled = false},
			summonerrevive       = {name="Revive",       range=0,    enabled = false},
			summonerodingarrison = {name="Garrison",     range=1000, enabled = false}
		}
		--[[ disabled until more spells are supported
			for spell, info in pairs(self.list) do
			if info.enabled then
				local slot = myHero:GetSpellData(Game.Slots.SUMMONER_1).name == spell and Game.Slots.SUMMONER_1 or myHero:GetSpellData(Game.Slots.SUMMONER_2).name == spell and Game.Slots.SUMMONER_2 or nil
				if slot ~= nil then
					Callback.Bind('Tick', function() self[info.callback] end)
				end
			end
		end]]--
		if Globals.NintendoMenu and self:IgniteExists() then
			Nintendo.Menu:Utils():Menu('summoners', 'Nintendo Summoners')
				Nintendo.Menu:Utils().summoners:Boolean('autoIgnite', 'Use Auto Ignite', true)

			Nintendo.Menu:Utils().summoners:Icon('fa-ambulance')
			Callback.Bind('Tick', function () self:IgniteTick() end)
		end
	end

	function SummonerSpells:IgniteExists()
		return self.ignite ~= nil
	end

	function SummonerSpells:IgniteDmg()
		return 50 + (20 * myHero.level)
	end

	function SummonerSpells:IgniteReady()
		return self.ignite ~= nil and myHero:CanUseSpell(self.ignite) == 0
	end

	function SummonerSpells:IgniteTick()
		if Nintendo.Menu:Values('AutoIgnite') and self:IgniteReady() then
			for _, enemy in ipairs(Nintendo.Objects:EnemyHeroes()) do
				if Nintendo.Utils:Valid(enemy, 600) and self:IgniteDmg() > enemy.health then
					myHero:CastSpell(self.ignite, enemy)
				end
			end
		end
	end

class 'Orbwalk'
	function Orbwalk:__init(range)
		self.Resets = { 
			['Jax'] = { [2] = true }
		}
		self.lastAA     = 0
		self.windUp     = 3
		self.animation  = 0.6
		self.updated    = false
		self.range      = range or myHero.range + Nintendo.Utils:GetHitBox(myHero)
		if Globals.NintendoMenu then
			Nintendo.Menu:Utils():Menu('orbwalk', 'Nintendo Orbwalker')
				Nintendo.Menu:Utils().orbwalk:Boolean('enabled', 'Enable Nintendo Orbwalker', true)
				Nintendo.Menu:Utils().orbwalk:Boolean('carryMode', 'Enable in Carry  Mode', true)
				Nintendo.Menu:Utils().orbwalk:Boolean('mixedMode', 'Enable in Harass Mode', true)
				Nintendo.Menu:Utils().orbwalk:Boolean('clearMode', 'Enable in Clear  Mode', true)

			Nintendo.Menu:Utils().orbwalk:Icon('fa-male')
			Callback.Bind('Tick', function() self:Tick() end)
			Callback.Bind('RecvPacket', function(packet) self:RecvPacket(packet) end)
			Callback.Bind('SendPacket', function(packet) self:SendPacket(packet) end)
			Callback.Bind('ProcessSpell', function(unit, spell) self:Process(unit, spell)  end)
		end
	end

	function Orbwalk:Orb(target)
		local trueRange = self.range + Nintendo.Utils:GetHitBox(target)

		if self:CanAttack() and Nintendo.Utils:Valid(target, trueRange) then
			self:Attack(target)
		elseif self:CanMove() then 
			myHero:Move(mousePos.x, mousePos.z)
		end
	end

	function Orbwalk:Clear()
		local target = nil
		for _, minion in pairs(Nintendo.Objects:EnemyMinions()) do
			if target == nil and Nintendo.Utils:Valid(minion, Nintendo.Utils:MaxRange()) then
				target = minion
			end
		end
		for _, jungle in pairs(Nintendo.Objects:NeutralMinions()) do
			if target == nil and Nintendo.Utils:Valid(jungle, Nintendo.Utils:MaxRange()) then
				target = jungle
			end
		end
		self:Orb(target)
	end

	function Orbwalk:CanAttack()
		if self.lastAA <= Nintendo.Utils:Clock() then
			return (Nintendo.Utils:Clock() + Nintendo.Utils:Latency()  > self.lastAA + self:AnimationTime())
		end
		return false
	end

	function Orbwalk:Attack(target)
		self.lastAA = Nintendo.Utils:Clock() + Nintendo.Utils:Latency()
		myHero:Attack(target)
	end

	function Orbwalk:ResetAA()
		self.lastAA = 0
	end
	
	function Orbwalk:CanMove()
		if self.lastAA <= Nintendo.Utils:Clock() then
			return (Nintendo.Utils:Clock() + Nintendo.Utils:Latency() > self.lastAA + self:WindUpTime())
		end
	end

	function Orbwalk:CanMove()
		if self.lastAA <= Nintendo.Utils:Clock() then
			return (Nintendo.Utils:Clock() + Nintendo.Utils:Latency() > self.lastAA + self:WindUpTime())
		end
	end

	function Orbwalk:AnimationTime()
		return (1 / (myHero.attackSpeed * self.animation))
	end

	function Orbwalk:WindUpTime()
		return (1 / (myHero.attackSpeed * self.windUp))
	end

	function Orbwalk:Process(unit, spell)
		if unit.isMe and spell.name:lower():find("attack") then
			if not self.updated then
				self.animation = 1 / (spell.animationTime * myHero.attackSpeed)
				self.windUp    = 1 / (spell.windUpTime    * myHero.attackSpeed)
				self.updated   = true
			end
			self.lastAA = Nintendo.Utils:Clock() - Nintendo.Utils:Latency()
		end
	end

	function Orbwalk:RecvPacket(packet)
 		if packet.header == 0x34 then
 			packet.pos = 1
 			if packet:Decode4() == myHero.networkID then
 				packet.pos = 9
 				if packet:Decode1() == 0x11 then
 					self:ResetAA()
 				end
 			end
 		end
	end

	function Orbwalk:SendPacket(packet)

	end

	function Orbwalk:Tick()
		if Nintendo.Menu:Values('Orbwalk') then
			if (Keyboard.KeysDown(Nintendo.Menu:Values('Combo'))  and Nintendo.Menu:Values('CarryMode')) or
		   	   (Keyboard.KeysDown(Nintendo.Menu:Values('Harass')) and Nintendo.Menu:Values('MixedMode')) then
				self:Orb(Nintendo.Target)
			end
			if Keyboard.KeysDown(Nintendo.Menu:Values('Clear')) and Nintendo.Menu:Values('ClearMode') then
				self:Clear()
			end
		end
	end

class 'Items'
	function Items:__init()
		self.Items = {
			['BFT']	        = 3188,
			['BRK']			= 3153,
			['BWC']			= 3144,
			['DFG']			= 3128,
			['HXG']			= 3146,
			['ODYNVEIL']	= 3180,
			['DVN']			= 3131,
			['ENT']			= 3184,
			['HYDRA']		= 3074,
			['TIAMAT']		= 3077,
			['YGB']			= 3142,
			['RST']         = 2045,
			['GST']         = 2049,
			['VWD']         = 2043,
			['SWD']         = 2044,
		}
		Callback.Bind('Tick', function () self:Tick() end)
	end

	function Items:Ready(item)
		if item ~= 'TRK' then
			for name, id in pairs(self.Items) do
				local slot = self:GetInventorySlot(id) or nil
				if item == name and slot and myHero:CanUseSpell(slot) == 0 then
					return true
				end
			end
		else
			return myHero:GetItem(Game.Slots.ITEM_7) ~= nil and myHero:CanUseSpell(Game.Slots.ITEM_7) == 0 and (myHero:GetItem(Game.Slots.ITEM_7).id == 3340 or myHero:GetItem(Game.Slots.ITEM_7).id == 3350)
		end
	end

	function Items:CastAll(target)
		if Nintendo.Utils:Valid(target, 600) then
			for name, itemid in pairs(self.Items) do
				local itemSlot = self:GetInventorySlot(itemid) or nil
				if itemSlot ~= nil and myHero:CanUseSpell(itemSlot) == 0 then
					myHero:CastSpell(itemSlot, target)
				end
			end
		end
	end

	function Items:GetInventorySlot(item)
        for i=0,6 do
	        if myHero:GetItem(Game.Slots.ITEM_1 + i) and myHero:GetItem(Game.Slots.ITEM_1 + i).id == item then
	        	return Game.Slots.ITEM_1 + i
	        end
	    end
    end

    function Items:HaveTrinket()
    	return myHero:GetItem(Game.Slots.ITEM_7) ~= nil and myHero:GetItem(Game.Slots.ITEM_7).id == 3340 or myHero:GetItem(Game.Slots.ITEM_7).id == 3350
    end

    function Items:Cast(item, target, needpos)
    	for name, id in pairs(self.Items) do
    		if item == name and self:Ready(name) then
    			local slot = self:GetInventorySlot(id)
    			if not target then
    				myHero:CastSpell(slot)
    			elseif target and not needpos then
    				myHero:CastSpell(slot, target)
    			elseif target and needpos then
    				myHero:CastSpell(slot, target, needpos)
    			end
    		end
    	end
    end

    function Items:Tick()
    	if Nintendo.Target and Nintendo.Menu:Values('Combo') then
    		self:CastAll(Nintendo.Target)
    	end
    end

class 'WardJump'
	function WardJump:__init()
		self.characters = { 
			Jax      = { skill = 0, range = 700},
			Katarina = { skill = 2, range = 700}
		}
		if self.characters[myHero.charName] then
			self.info = {casted = false, jumped = false}
			self.wards = {}
			if Globals.NintendoMenu then
				Nintendo.Menu:Utils():Menu('wardjump', 'Nintendo Jumper')
					Nintendo.Menu:Utils().wardjump:Boolean('allies',   'Jump to Allies',   true)
					Nintendo.Menu:Utils().wardjump:Boolean('minions',  'Jump to Minions',  true)
					Nintendo.Menu:Utils().wardjump:Boolean('maxrange', 'Jump at maxrange', true)
					Nintendo.Menu:Utils().wardjump:KeyBinding('jumpKey', 'Jump Key', 'G')

				Nintendo.Menu:Utils().wardjump:Icon('fa-paper-plane')

			end
			Callback.Bind('Tick', function () self:Tick() end)
			Callback.Bind('CreateObj', function(obj) self:CreateObj(obj) end)
			Callback.Bind('DeleteObj', function(obj) self:DeleteObj(obj) end)
			for i = 0,Game.ObjectCount() do
  				local obj = Game.Object(i)
  				if obj ~= nil and obj.valid and (string.find(obj.name, "Ward") ~= nil or string.find(obj.name, "Wriggle") ~= nil or string.find(obj.name, "Trinket")) then 
					table.insert(self.wards, obj)
				end
			end
		end
	end

	function WardJump:Tick()
		if Keyboard.KeysDown(Nintendo.Menu:Values('JumpKey')) then
			myHero:Move(mousePos.x, mousePos.z)
			if not Nintendo.Menu:Values('JumpMax') and myHero:DistanceTo(mousePos) < 600 then
				self:Jump(mousePos.x, mousePos.z)
				self.info.jumped = false
				self.info.casted = false
			else
				local Pos = myHero.visionPos + (mousePos - myHero.visionPos):Normalize()*590
				self:Jump(Pos.x, Pos.z)
				self.info.jumped = false
				self.info.casted = false
			end
		end
	end

	function WardJump:CreateObj(obj)
		if obj ~= nil and obj.valid and (string.find(obj.name, "Ward") ~= nil or string.find(obj.name, "Wriggle") ~= nil or string.find(obj.name, "Trinket")) then 
			table.insert(self.wards, obj)
		end
	end

	function WardJump:DeleteObj(obj)
		for i, ward in pairs(self.wards) do
			if not ward.valid or obj.name == ward.name then
				table.remove(self.wards, i)
			end
		end
	end

	function WardJump:CheckObject(obj)
		if myHero:DistanceTo(obj) < self.characters[myHero.charName].range then
			if obj:DistanceTo(mousePos) < 400 then
				myHero:CastSpell(self.characters[myHero.charName].skill, obj)
				self.info.jumped = true
			end
		end
	end

	function WardJump:Jump(x, y)
		if myHero:CanUseSpell(self.characters[myHero.charName].skill) == 0 then
			if Nintendo.Menu:Values('JumpAllies') then
				for _, ally in pairs(Nintendo.Objects:AllyHeroes()) do
					self:CheckObject(ally)
				end
			end
			if Nintendo.Menu:Values('JumpMinions') then
				for _, minion in pairs(Nintendo.Objects:AllyMinions()) do
					if Nintendo.Utils:Valid(minion) then
						self:CheckObject(minion)
					end
				end
			end
			for _, ward in pairs(self.wards) do
				self:CheckObject(ward)
			end
			if not self.info.jumped and not self.info.casted then
				local WardSlot = Nintendo.Items:Ready('TRK') and Game.Slots.ITEM_7 or
								 Nintendo.Items:Ready('RST') and Nintendo.Items:GetInventorySlot(2045) or
								 Nintendo.Items:Ready('GST') and Nintendo.Items:GetInventorySlot(2049) or
								 Nintendo.Items:Ready('SWD') and Nintendo.Items:GetInventorySlot(2044) or nil
								 --Nintendo.Items:Ready('VWD') and Nintendo.Items:GetInventorySlot(2043) or 
				if WardSlot ~= nil then
					myHero:CastSpell(WardSlot, x, y)
					self.info.casted = true
				end
			end
		end
	end

class 'Combat'
	
	function Combat:Clear()
		local target = nil
		for _, minion in pairs(Nintendo.Objects:EnemyMinions()) do
			if target == nil and Nintendo.Utils:Valid(minion, Nintendo.Utils:MaxRange()) then
				target = minion
			end
		end
		for _, minion in pairs(Nintendo.Objects:NeutralMinions()) do
			if target == nil and Nintendo.Utils:Valid(jungle, Nintendo.Utils:MaxRange()) then
				target = jungle
			end
		end
		if target ~= nil then
			if Nintendo.Menu:Values('ClearQ') then
				Spells.Q:Cast(target)
			end
			if Nintendo.Menu:Values('ClearW') then
				Spells.W:Cast(target)
			end
			if Nintendo.Menu:Values('ClearE') then
				Spells.E:Cast(target)
			end
		end
	end

class 'Combo'
	function Combo:Available(combo)
		local count = 0
		for _, spell in ipairs(combo) do
			count = count + 1
			if myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 then
				count = count - 1
			end
		end
		return count == 0
	end

	function Combo:GetDmg(combo, target)
		local DmgTable = {
			Katarina = {
				[0]    = {dmg = {60,  85, 110, 135, 160},  apscaling = .45                 }, -- dmg without mark
				[1]    = {dmg = {40,  75, 110, 145, 180},  apscaling = .25, adscaling = .6 },
				[2]    = {dmg = {60,  85, 110, 135, 160},  apscaling = .4                  },
				[3]    = {dmg = {40,  57.5, 75},           apscaling = .25, adscaling = .37}  -- dmg per dagger
			},
			Zilean   = {
				[0]    = {dmg = {90,  145, 200, 260, 320}, apscaling = .90                 }, -- dmg without mark
			}
		} 
		local ComboDmg = 0
		local TrueDmg  = Nintendo.Menu:Values('AutoIgnite') and Nintendo.Spells:IgniteReady() and Nintendo.Spells:IgniteDmg() or 0
		for _, skill in pairs(combo) do
			if myHero:GetSpellData(skill).currentCd == 0 and myHero:GetSpellData(skill).level > 0 then
				local spellDmg  = DmgTable[myHero.charName][skill].dmg[myHero:GetSpellData(skill).level] or 0
				local apscaling = DmgTable[myHero.charName][skill].apscaling or 0
				local adscaling = DmgTable[myHero.charName][skill].adscaling or 0
				ComboDmg = (ComboDmg + spellDmg) + (apscaling * myHero.ap) + (adscaling * myHero.addDamage)
			end
		end
		return target and (myHero:CalcMagicDamage(target, ComboDmg) + TrueDmg) or 0
	end

	function Combo:Cast(combo, target)
		for _, spell in ipairs(combo) do
			local skill = Nintendo.Utils:NumberToString(spell)
			Spells[skill]:Cast(target)
		end
	end

class 'Farming'
	function Farming:__init()
		local farmDefaults = {
			Katarina = { FarmQ = true, FarmW = true, FarmE = false}
		}
		if Globals.NintendoMenu then
			Nintendo.Menu:Utils():Menu('farm', 'Nintendo Farmer')
				Nintendo.Menu:Utils().farm:Boolean('farmQ', 'Farm With '..Spells.Q:Name(), farmDefaults[myHero.charName].FarmQ)
				Nintendo.Menu:Utils().farm:Boolean('farmW', 'Farm With '..Spells.W:Name(), farmDefaults[myHero.charName].FarmW)
				Nintendo.Menu:Utils().farm:Boolean('farmE', 'Farm With '..Spells.E:Name(), farmDefaults[myHero.charName].FarmE)
				Nintendo.Menu:Utils().farm:KeyBinding('farmKey', 'On Key Farm', 'C')

			Nintendo.Menu:Utils().farm:Icon('fa-tree')
		end
		Callback.Bind('Tick', function() self:Tick() end)
	end

	function Farming:Tick()
		if Keyboard.KeysDown(Nintendo.Menu:Values('FarmKey')) then
			self:FarmKillableMinions()
		end
	end

	function Farming:FarmKillableMinions()
		for _, minion in pairs(Nintendo.Objects:EnemyMinions()) do
			local QFarm = Nintendo.Utils:Valid(minion, Spells.Q:Range()) and Spells.Q:Ready() and Nintendo.Menu:Values('FarmQ') and Combo:GetDmg({0}, minion) >= minion.health
			local WFarm = Nintendo.Utils:Valid(minion, Spells.W:Range()) and Spells.W:Ready() and Nintendo.Menu:Values('FarmW') and Combo:GetDmg({1}, minion) >= minion.health
			local EFarm = Nintendo.Utils:Valid(minion, Spells.E:Range()) and Spells.E:Ready() and Nintendo.Menu:Values('FarmE') and Combo:GetDmg({2}, minion) >= minion.health
			if QFarm then
				myHero:CastSpell(0, minion)
			elseif WFarm then
				myHero:CastSpell(1, minion)
			elseif EFarm then
				myHero:CastSpell(2, minion)
			end
		end
	end

class 'Drawer'
	function Drawer:__init()
		self.colors = {
		--  Color                      Value                  --
        	Aqua        = Graphics.RGBA(0, 255, 255, 255),
        	Azure       = Graphics.RGBA(240, 255, 255, 255),
        	Beige       = Graphics.RGBA(245, 245, 196, 255),
        	Black       = Graphics.RGBA(0, 0, 0, 255),
        	Blue        = Graphics.RGBA(0, 0, 255, 255),
        	Brown       = Graphics.RGBA(165, 42, 42, 255),
	        Cyan        = Graphics.RGBA(0, 255, 255, 255),
    	    DarkBlue    = Graphics.RGBA(0, 0, 139, 255),
        	DarkCyan    = Graphics.RGBA(0, 139, 139, 255),
        	DarkGray    = Graphics.RGBA(169, 169, 169, 255),
        	DarkGreen   = Graphics.RGBA(0, 100, 0, 255),
        	DarkOrange  = Graphics.RGBA(255, 140, 0, 255),        
        	DarkRed     = Graphics.RGBA(139, 0, 0, 255),        
        	DarkViolet  = Graphics.RGBA(148, 0, 211, 255),
        	Gold        = Graphics.RGBA(255, 215, 0, 255),
        	Gray        = Graphics.RGBA(128, 128, 128, 255),
        	Green       = Graphics.RGBA(0, 255, 0, 255),
        	LightBlue   = Graphics.RGBA(173, 216, 230, 255),
        	LightCyan   = Graphics.RGBA(240, 128, 128, 255),
        	LightGray   = Graphics.RGBA(211, 211, 211, 255),
        	LightGreen  = Graphics.RGBA(144, 238, 144, 255),
        	LightPink   = Graphics.RGBA(255, 182, 193, 255),
        	LightRed    = Graphics.RGBA(255, 69, 0, 255),
        	LightYellow = Graphics.RGBA(255, 255, 224, 255),
        	Lime        = Graphics.RGBA(0, 255, 0, 255),
        	Maroon      = Graphics.RGBA(128, 0, 0, 255),
        	Red         = Graphics.RGBA(255, 0, 0, 255),
        	Yellow      = Graphics.RGBA(255, 255, 0, 255),
        	Green       = Graphics.RGBA(0, 255, 0, 255),
        	White       = Graphics.RGBA(255, 255, 255, 255),
    	}
    	self.HPBarOffsets = { 
			['Darius']   = { x = 63 },
			['Fizz']     = { x = 63 },
			['JarvanIV'] = { x = 71 },
			['Renekton'] = { x = 45 },
			['XinZhao']  = { x = 71 },	
			['Thresh']   = { x = 61 }
		}
    	self.drawVars = {
			Jax      = { Q = 'Blue',       W = 'Blue'  ,   E = 'Blue',       R = 'Blue', DrawQ = true,  DrawW = false, DrawE = false, DrawR = false},
			Katarina = { Q = 'Yellow',     W = 'DarkCyan', E = 'Red',        R = 'Blue', DrawQ = false, DrawW = true,  DrawE = true,  DrawR = false},
			LeeSin   = { Q = 'Blue',       W = 'Blue'  ,   E = 'Blue',       R = 'Blue', DrawQ = true,  DrawW = false, DrawE = false, DrawR = false},
			Morgana  = { Q = 'DarkViolet', W = 'DarkCyan', E = 'Red',        R = 'Blue', DrawQ = true,  DrawW = false, DrawE = false, DrawR = false},
			Zilean   = { Q = 'DarkBlue',   W = 'DarkCyan', E = 'LightBlue',  R = 'Gold', DrawQ = true,  DrawW = false, DrawE = false, DrawR = true }
		}
		self.drawDmg = {
			Katarina = {
				[0] = { damage = {0, 2, 1   }, text = 'Q+W+E' },
				[1] = { damage = {0, 2, 1, 3}, text = 'Q+W+E+R'}
			}
		}
		self.DrawDmg = false
		if Globals.NintendoMenu then
			Nintendo.Menu:Utils():Menu('draw', 'Nintendo Drawer')
				Nintendo.Menu:Utils().draw:Section('ranges', 'Ranes')
					Nintendo.Menu:Utils().draw:Boolean('drawQ', 'Draw '..Spells.Q:Name()..'(Q)', self.drawVars[myHero.charName].DrawQ)
					Nintendo.Menu:Utils().draw:Boolean('drawW', 'Draw '..Spells.W:Name()..'(W)', self.drawVars[myHero.charName].DrawW)
					Nintendo.Menu:Utils().draw:Boolean('drawE', 'Draw '..Spells.E:Name()..'(E)', self.drawVars[myHero.charName].DrawE)
					Nintendo.Menu:Utils().draw:Boolean('drawR', 'Draw '..Spells.R:Name()..'(R)', self.drawVars[myHero.charName].DrawR)
				Nintendo.Menu:Utils().draw:Section('damage', 'Damage')
					Nintendo.Menu:Utils().draw:Boolean('drawDmg', 'Draw Max Dmg', true)	
				Nintendo.Menu:Utils().draw:Boolean('disable', 'Disable All Drawings', false)
			
			Nintendo.Menu:Utils().draw:Icon('fa-tint')
			Callback.Bind('Draw', function() self:Draw() end)
		end
		if self.drawDmg[myHero.charName] then
			self.DrawDmg = true
		end
	end

	function Drawer:Color(color)
		return self.colors[color]
	end

	function Drawer:Draw()
		if not myHero.dead and not Nintendo.Menu:Values('DrawDisable') then
			if Spells.Q:Ready() and Nintendo.Menu:Values('DrawQ') then
				Graphics.DrawCircle(myHero, Spells.Q:Range(), self.colors[self.drawVars[myHero.charName].Q])
			end
			if Spells.W:Ready() and Nintendo.Menu:Values('DrawW') then
				Graphics.DrawCircle(myHero, Spells.W:Range(), self.colors[self.drawVars[myHero.charName].W])
			end
			if Spells.E:Ready() and Nintendo.Menu:Values('DrawE') then
				Graphics.DrawCircle(myHero, Spells.E:Range(), self.colors[self.drawVars[myHero.charName].E])
			end
			if Spells.E:Ready() and Nintendo.Menu:Values('DrawR') then
				Graphics.DrawCircle(myHero, Spells.R:Range(), self.colors[self.drawVars[myHero.charName].R])
			end
			--[[if self.DrawDmg[myHero.charName] then
				for _, enemy in pairs(Nintendo.Objects:EnemyHeroes()) do
					if Nintendo.Utils:Valid(enemy) then
						for i, combo in pairs(self.drawDmg[myHero.charName]) do
							if Combo:Available(combo.damage) then
								self:DrawDmgOnHP(Combo:GetDmg(combo.damage), 10 + (i*2), combo.text, enemy)
							end
						end
					end
				end
			end]]--
		end
	end

	function Drawer:GetHPBarPos(hero)
		local barPos = Game.GetUnitHPBarPos(hero)
		local barPosOffset = {}
  		barPosOffset.x = math.floor((- 0.5) * 50 - 5)
		barPosOffset.y = math.floor((Game.GetUnitHPBarOffset(hero).y - 0.5  ) * 50 - 5 )	
		local coolOffset = tostring(Game.GetUnitHPBarOffset(hero).y)
		local x = 39
		local y = 25
		if self.HPBarOffsets[hero.charName] ~= nil then
			x = HPBarOffsets[hero.charName].x
		end
		if hero.team ~= myHero.team then
			if coolOffset == "-1.6000000238419" then
				y = 19
			elseif coolOffset == "-1" then
				y = 21
			elseif coolOffset == "-0.80000001192093" then
				y = 21.3
			elseif coolOffset == "-0.60000002384186" then
				y = 22
			elseif coolOffset == "-0.5" then
				y = 22.3
			elseif coolOffset == "-0.40000000596046" then
				y = 22.5
			elseif coolOffset == "-0.30000001192093" then
				y = 23
			elseif coolOffset == "-0.1000000149012" then
				y = 23
			elseif coolOffset == "0" then
				y = 22.8
			elseif coolOffset == "0.5" then
				y = 25.4
			else
				y = 23.6 + (coolOffset * 3)
			end		
		end
		barPos.x = math.round(barPos.x + barPosOffset.x - x)
		barPos.y = math.floor(barPos.y + barPosOffset.y + y)
		if hero.team == TEAM_ENEMY then
			barPos.y = barPos.y + 3
		end
		local StartPos = Geometry.Vector2(barPos.x, barPos.y)
		local EndPos   = Geometry.Vector2(barPos.x + 105, barPos.y)
		return StartPos, EndPos
	end

	function Drawer:DrawDmgOnHP(damage, line, text, unit)
		local thedmg = 0
		if damage >= unit.maxHealth then
			thedmg = unit.maxHealth-1
		else
			thedmg=damage
		end
		local StartPos, EndPos = self:GetHPBarPos(unit)
		local Offs_X = (StartPos.x + ((unit.health-thedmg)/unit.maxHealth) * (EndPos.x - StartPos.x))
		if Offs_X < StartPos.x then Offs_X = StartPos.x end
		local mytrans = 350 - math.round(255*((unit.health-thedmg)/unit.maxHealth)) ---   255 * 0.5
		if mytrans >= 255 then mytrans=254 end
		local my_bluepart = math.round(400*((unit.health-thedmg)/unit.maxHealth))
		if my_bluepart >= 255 then my_bluepart=254 end
		Graphics.DrawLine(Geometry.Vector2(Offs_X, StartPos.y-(line*3)), Geometry.Vector2(Offs_X, StartPos.y-2), 2, Graphics.ARGB(mytrans, 255,my_bluepart,0))
		Graphics.DrawText(tostring(text),15,Offs_X,StartPos.y-(line*3)-5, Graphics.ARGB(mytrans, 255,my_bluepart,0))  --ARGB(mytrans, 255,255,255)
	end

	function Drawer:MaxDmg(unit, damage)
		local s, e = self:GetHPBarPos(unit)
		local TextColor = (damage >= unit.health and Graphics.RGBA(139, 0, 0, 255)) or (damage >= (unit.maxHealth/2) and Graphics.RGBA(255, 255, 224, 255)) or Graphics.RGBA(173, 216, 230, 255)
		local unitHealth = math.round(unit.health)
		local lePos = { x = e.x + 26, y = s.y}
		Graphics.DrawText("DMG: "..damage, 12, lePos.x, lePos.y, TextColor)
		Graphics.DrawText("HEALTH: "..unitHealth, 12, lePos.x, lePos.y+10, TextColor)
		self:Circle3D(unit.x, unit.y-50, unit.z, 20, 2, TextColor)
	end

	function Drawer:Circle3D(x, y, z, radius, width, color, quality)
    	radius = radius or 300
    	quality = quality and 2 * math.pi / quality or 2 * math.pi / (radius / 5)
    	local points = {}
    	for theta = 0, 2 * math.pi + quality, quality do
        	local c = Graphics.WorldToScreen(Geometry.Vector3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        	points[#points + 1] = Geometry.Vector2(c.x, c.y)
    	end
    	Graphics.DrawLines(points, width or 1, color or self:Color('Green'))
	end

--> Really had to make this class since Obj Lib is unusable :O
class 'Objects'
	function Objects:__init()
		self.enemyMinions   = {}
		self.allyMinions    = {}
		self.neutralMinions = {}

		for i = 0, Game.ObjectCount() do
  			local obj = Game.Object(i)
  			if obj ~= nil and obj.valid then
				local EnemyMinion   = obj.charName:lower():find('blue_minion') and Nintendo.Utils:Team(obj) == 'Enemy' or obj.charName:lower():find('red_minion')
				local AllyMinion    = obj.charName:lower():find('red_minion')  and Nintendo.Utils:Team(obj) == 'Ally'  or obj.charName:lower():find('blue_minion')
				local NeutralMinion = obj.charName:lower():find('neutral')
  				if EnemyMinion then
					table.insert(self.enemyMinions, obj)
				elseif AllyMinion then
					table.insert(self.allyMinions, obj)
				elseif NeutralMinion then
					table.insert(self.neutralMinions, obj)
				end
			end
		end

    	Callback.Bind('CreateObj', function(obj) self:Create(obj) end)
		Callback.Bind('DeleteObj', function(obj) self:Delete(obj) end)
	end

	function Objects:AllyMinions()
		return self.allyMinions
	end

	function Objects:EnemyMinions()
		return self.enemyMinions
	end

	function Objects:NeutralMinions()
		return self.neutralMinions
	end

	function Objects:EnemyHeroes()
		local EnemyTable = {}
		for i = 1, Game.HeroCount() do
			local enemy = Game.Hero(i)
			if enemy.team ~= myHero.team then
				table.insert(EnemyTable, enemy)
			end
		end
		return EnemyTable
	end

	function Objects:AllyHeroes()
		local AllyTable = {}
		for i = 1, Game.HeroCount() do
			local ally = Game.Hero(i)
			if ally.team == myHero.team then
				table.insert(AllyTable, ally)
			end
		end
		return AllyTable
	end

	function Objects:Create(obj)
		if obj and obj.valid then
			local EnemyMinion   = obj.charName:lower():find('blue_minion') and Nintendo.Utils:Team(obj) == 'Enemy' or obj.charName:lower():find('red_minion')
			local AllyMinion    = obj.charName:lower():find('red_minion')  and Nintendo.Utils:Team(obj) == 'Ally'  or obj.charName:lower():find('blue_minion')
			local NeutralMinion = obj.charName:lower():find('neutral')
  			if EnemyMinion then
				table.insert(self.enemyMinions, obj)
			elseif AllyMinion then
				table.insert(self.allyMinions, obj)
			elseif NeutralMinion then
				table.insert(self.neutralMinions, obj)
			end
		end
	end

	function Objects:Delete(obj)
		--[[if obj and obj.valid then
			for i, minion in pairs(self.enemyMinions) do
				if obj.name == minion.name then
					table.remove(self.enemyMinions, i)
				end
			end
			for i, minion in pairs(self.allyMinions) do
				if obj.name == minion.name then
					table.remove(self.allyMinions, i)
				end
			end
			for i, minion in pairs(self.neutralMinions) do
				if obj.name == minion.name then
					table.remove(self.neutralMinions, i)
				end
			end
		end]]--		
	end

class 'Util'
	function Util:__init()
		self.map = nil
	end

	function Util:Clock()
		return os.clock()
	end

	function Util:CountEnemiesAround(unit, range)
		local totalenemies = 0
		for _, enemy in ipairs(Nintendo.Objects:EnemyHeroes()) do
			if self:Valid(enemy) and enemy:DistanceTo(unit) <= range then
				totalenemies = totalenemies + 1
			end
		end
		return totalenemies
	end

	function Util:GetHitBox(unit)
		return unit ~= nil and unit.boundingRadius or 65
	end

	-- by Bilbao --
	function Util:GetMap()
		if self.map ~= nil then return self.map end
		local MapData = {
			SummonersRift = { name = "Summoner's Rift", min = { x = -538, y = -165 }, max = { x = 14279, y = 14527 }, x = 14817, y = 14692,	grid = { width = 13982 / 2, height = 14446 / 2 },},
			TheTwistedTreeline = { name = "The Twisted Treeline", min = { x = -996, y = -1239 }, max = { x = 14120, y = 13877 }, x = 15116,	y = 15116, grid = { width = 15436 / 2, height = 14474 / 2 },},
			ProvingGround = { name = "The Proving Grounds",	min = { x = -56, y = -38 },	max = { x = 12820, y = 12839 },	x = 12876,	y = 12877, grid = { width = 12948 / 2, height = 12812 / 2 },},
			CrystalScar = {	name = "The Crystal Scar", min = { x = -15, y = 0 }, max = { x = 13911, y = 13703 }, x = 13926, y = 13703,	grid = { width = 13894 / 2, height = 13218 / 2 },},
			TwistedTreelineBeta = {	name = "The Twisted Treeline Beta",	min = { x = 0, y = 0 },	max = { x = 15398, y = 15398 },	x = 15398,	y = 15398,	grid = { width = 15416 / 2, height = 14454 / 2 },},
			HowlingAbyss = {name = "Howling Abyss",	min = { x = -56, y = -38 },	max = { x = 12820, y = 12839 },	x = 12876,	y = 12877,	grid = { width = 13120 / 2, height = 12618 / 2 },},
			SummonersRift_S5 = {name = "Summoner's Rift_S5", min = { x = 0, y = 0 }, max = { x = 14716, y = 14824 }, x = 14716,	y = 14824, grid = { width = 14716 / 2, height = 14824 / 2 },},
		}
		for i = 1, Game.ObjectCount() do
			local Obj = Game.Object(i)
			if Obj and Obj.valid then			
				if math.floor(Obj.x) 		== -175 and math.floor(Obj.y)	== 163 and math.floor(Obj.z) == 1056 then self.map = MapData.SummonersRift return MapData.SummonersRift				
				elseif math.floor(Obj.x)	== -217 and math.floor(Obj.y)	== 276 and math.floor(Obj.z) == 7039 then self.map = MapData.TheTwistedTreeline return MapData.TheTwistedTreeline
				elseif math.floor(Obj.x) 	== 556 and math.floor(Obj.y)	== 191 and math.floor(Obj.z) == 1887 then self.map = MapData.ProvingGround return MapData.ProvingGround		
				elseif math.floor(Obj.x) 	== 16 and math.floor(Obj.y)		== 168 and math.floor(Obj.z) == 4452 then self.map = MapData.CrystalScar return MapData.CrystalScar
				elseif math.floor(Obj.x) 	== 1313 and math.floor(Obj.y)	== 123 and math.floor(Obj.z) == 8005 then self.map = MapData.TwistedTreelineBeta return MapData.TwistedTreelineBeta
				elseif math.floor(Obj.x) 	== 497 and math.floor(Obj.y)	== -40 and math.floor(Obj.z) == 1932 then self.map = MapData.HowlingAbyss return MapData.HowlingAbyss
				elseif math.floor(Obj.x) 	== 232 and math.floor(Obj.y)	== 163 and math.floor(Obj.z) == 1277 then self.map = MapData.SummonersRift_S5 return MapData.SummonersRift_S5
				end
			end
		end
	end

	function Util:Latency()
		return Game.Latency() / 2000
	end

	function Util:MaxRange()
		local maxRange = nil
		for _, spell in pairs(Spells) do
			if maxRange == nil or (spell:Ready() and spell:Range() > maxRange) then
				maxRange = spell:Range()
			end
		end
		return (maxRange > myHero.range and maxRange) or myHero.range
	end

	function Util:NumberToString(number)
		local strings = {[0] = 'Q', [1] = 'W', [2] = 'E', [3] = 'R'}
		return strings[number]
	end

	function Util:Target()
		for _, enemy in ipairs(Nintendo.Objects:EnemyHeroes()) do
			if self:Valid(enemy, Util:MaxRange()) then
				return enemy
			end
		end
	end

	function Util:Team(unit)
		return unit.team == myHero.team and 'Ally' or 'Enemy'
	end

	function Util:Valid(target, dist)
		return target ~= nil and not target.dead and target.valid and target.visible and (dist == nil or myHero:DistanceTo(target) < dist)
	end

class 'WayPoints'

    function WayPoints:__init(draw)
        self.map = nil
        self.headers = {
            WayPoint    = 0xBA, -- R_WAYPOINT
            WayPoints   = 0x61  -- R_WAYPOINTS
        }
        self.WayPoints    = {}
        self.WayPointVisibility = {}
        self.RawWayPoints = {}
        self.WayPointRate = {}
        self.LastDestination = {}
        self.RecordTime   = 1.5 -- after how long we remove waypoints
        Callback.Bind('RecvPacket', function(packet) self:RecvPacket(packet) end)
        Callback.Bind('GainVision', function (unit) self:GainVision(unit) end)
        if draw then Callback.Bind('Draw', function() self:Draw() end) end
        Callback.Bind('Tick', function() self:Tick() end)
        for i = 1, Game.HeroCount() do
            local unit = Game.Hero(i)
            if unit.valid then
            	self.WayPointRate[unit.networkID] = Queue()
            end
        end
    end

    function WayPoints:Tick()
        for nid, WayPoints in pairs(self.WayPoints) do
            local i = 1
            while i <= #self.WayPoints[nid] do
                if self.WayPoints[nid][i]['time'] + self.RecordTime < Game.Timer() then
                    table.remove(self.WayPoints[nid], i)
                else
                    i = i + 1
                end
            end
        end
        
        for i = 1, Game.HeroCount() do
            local unit = Game.Hero(i)
            if self.WayPoints[unit.networkID] ~= nil then
                for nid, waypoint in pairs(self.WayPoints[unit.networkID]) do
                    local curDest = self.WayPoints[unit.networkID][#self.WayPoints[unit.networkID]].waypoint
                    if self.LastDestination[unit.networkID] == nil then self.LastDestination[unit.networkID] = Geometry.Vector2(unit.pos.x, unit.pos.z) end                 
                    if self.LastDestination[unit.networkID]:DistanceTo(curDest) > 0 then                        
                        self.LastDestination[unit.networkID] = curDest
                         for _k, _v in ipairs(Callback.GetCallbacks('WayPoints_NewPath')) do
                            _v(unit, self.RawWayPoints[unit.networkID])
                        end
                    end                 
                end
            end
        end
    end

    function GainVision(unit)
    	if unit and unit.valid then
    		self.WayPointVisibility[unit.networkID] = nil	
    	end
    end

    function WayPoints:Draw()
        for i = 1, Game.HeroCount() do
            local unit = Game.Hero(i)
            if self.WayPoints[unit.networkID] ~= nil then
                for nid, waypoint in pairs(self.WayPoints[unit.networkID]) do 
                    Render.GameCircle(waypoint.waypoint.x,mousePos.y,waypoint.waypoint.y, 100, Graphics.ARGB(0xFF,0xFF,0xFF,0xFF):ToNumber()):Draw()
                    --Graphics.DrawText(unit.charName .. " - WPR: " .. self:GetCurrentWayPointRate(unit), 20, 100, 100 + (i * 25), Graphics.ARGB(0xFF,0xFF,0xFF,0xFF))
                    --Graphics.DrawText(unit.charName .. " - Spread: " .. self:GetWayPointSpread(unit), 20, 100, 100 + (i * 25), Graphics.ARGB(0xFF,0xFF,0xFF,0xFF))
                end
            end
        end
    end

    function WayPoints:RecvPacket(p)
        if p.header == self.headers.WayPoint then
            p.pos = 1
            local crap = {}
            local networkId = p:Decode4()
            local unit      = Game.ObjectByNetworkId(networkId)
            if unit and unit.valid then
                local cLen, cNet = 0, networkId
                repeat
                    cLen = p:Decode2()
                    for i=1, 6+cLen do
                        table.insert(crap, p:Decode1())
                    end
                    local nwId = p:Decode4()
                   cNet = nwID ~= 0 and nwId or cNet
                until cLen==0
                for i = 1, 13 do
                    --often     02 ?? ?? C? 45 ?? ?? ?? C3 ?? ?? ?? 45
                    --sometimes 00 00 00 80 8F 00 00 00 00 00 00 00 00
                    table.insert(crap, p:Decode1())
                end
                local sequense = p:Decode4()
                table.insert(crap, p:Decode1())
                local waypointCount = p:Decode1()/2
                if self.WayPoints[unit.networkID] == nil then
                    self.WayPoints[unit.networkID] = {}
                end
                local AddWaypoints = self:DecodeWaypoints(p, waypointCount)
                self.RawWayPoints[unit.networkID] = AddWaypoints
                if AddWaypoints and #AddWaypoints >= 1 then
                    table.insert(self.WayPoints[unit.networkID], {unit = unit, waypoint = AddWaypoints[#AddWaypoints], time = Game.Timer(), n = #AddWaypoints})
                end
            end
        elseif p.header == self.headers.WayPoints then
            p.pos = 5
            local sequense  = p:Decode4()
            local unitCount = p:Decode2()
            for h = 1, unitCount do
                local waypointCount = p:Decode1() / 2
                local networkId     = p:Decode4()
                local unit          = Game.ObjectByNetworkId(networkId)
                if unit and unit.valid then
                    if self.WayPoints[unit.networkID] == nil then
                        self.WayPoints[unit.networkID] = {}
                    end
                    local AddWaypoints = self:DecodeWaypoints(p, waypointCount)
                    if self.RawWayPoints[unit.networkID] then
                    	local wps = self.RawWayPoints[unit.networkID]
   	                	local lwp, found = wps[#wps], false
       	            	for i = #AddWaypoints - 1, math.max(2, #AddWaypoints - 3), -1 do
       	            		local A, B = Geometry.Vector2(AddWaypoints[i].x, AddWaypoints[i].y) Geometry.Vector2(AddWaypoints[i +1].x, AddWaypoints[i +1].y)
       	            		if lwp and A and B and self:GetDistance(lwp, Geometry.Vector2(lwp.x, lwp.y):ProjectOnLineSegment(A, B)) < 32 then found = true break end
       	            	end
       	            	--if not found then self.WayPointRate[unit.networkID]:pushleft(Nintendo.Utils:Clock()) end
       	            	--if #self.WayPointRate[unit.networkID] > 20 then self.WayPointRate[unit.networkID]:popright() end
       	            end
                    self.RawWayPoints[unit.networkID] = AddWaypoints
                    if AddWaypoints and #AddWaypoints >= 1 then
                        table.insert(self.WayPoints[unit.networkID], {unit = unit, waypoint = AddWaypoints[#AddWaypoints], time = Game.Timer(), n = #AddWaypoints})
                    end
                end
            end
        end
    end

    function WayPoints:RawWayPoints(unit)
    	return self.RawWayPoints[unit.networkID]
    end

    function WayPoints:GetCurrentWayPoints(unit)
        local wayPoints, lineSegment, distanceSqr, fPoint = self.RawWayPoints[unit.NetworkID], 0, math.huge, nil
		if not wayPoints and not unit then
			return { { x = unit.x, y = unit.z } }
		elseif not wayPoints and unit then
			return { { x = unit.x, y = unit.z } }
		end
		for i = 1, #wayPoints - 1 do
			local p1, bool = Geometry.Vector2(wayPoints[i].x, wayPoints[i].y):ProjectOnLineSegment(Geometry.Vector2(wayPoints[i + 1].x, wayPoints[i + 1].y), unit.pos:To2D())
			local distanceSegmentSqr = p1:DistanceTo(unit.pos:To2D())
			if distanceSegmentSqr <= distanceSqr then
				fPoint = p1
				lineSegment = i
				distanceSqr = distanceSegmentSqr
			else
				break --not necessary, but makes it faster
			end
		end
		local result = { fPoint or { x = unit.x, y = unit.z } }
		for i = lineSegment + 1, #wayPoints do
			result[#result + 1] = wayPoints[i]
		end
		if #result == 2 and Geometry.Vector2(result[1].x, result[1].y):DistanceTo(Geometry.Vector2(result[2].x, result[2].y)) < 20 then result[2] = nil end
		return result
    end

    function WayPoints:GetSimulatedWayPoints(unit, fromT, toT)
	    local wayPoints, fromT, toT = self:GetCurrentWayPoints(unit), fromT or 0, toT or math.huge
	    local invisDur = (not unit.visible and self.WayPointVisibility[unit.networkID]) and Nintendo.Utils:Clock() - self.WayPointVisibility[unit.networkID] or ((not unit.visible and not self.WayPointVisibility[unit.networkID]) and math.huge or 0)
    	fromT = fromT + invisDur
    	local tTime, fTime, result = 0, 0, {}
    	for i = 1, #wayPoints - 1 do
        	local A, B = Geometry.Vector2(wayPoints[i].x, wayPoints[i].y) Geometry.Vector2(wayPoints[i + 1].x, wayPoints[i + 1].y)
        	local dist = A:DistanceTo(B)
        	local cTime = dist / unit.ms
        	if tTime + cTime >= fromT then
            	if #result == 0 then
                	fTime = fromT - tTime
                	result[1] = { x = A.x + unit.ms * fTime * ((B.x - A.x) / dist), y = A.y + unit.ms * fTime * ((B.y - A.y) / dist) }
            	end
            	if tTime + cTime >= toT then
                	result[#result + 1] = { x = A.x + unit.ms * (toT - tTime) * ((B.x - A.x) / dist), y = A.y + unit.ms * (toT - tTime) * ((B.y - A.y) / dist) }
                	fTime = fTime + toT - tTime
                	break
            	else
                	result[#result + 1] = B
                	fTime = fTime + cTime
            	end
        	end
        	tTime = tTime + cTime
    	end
    	if #result == 0 and (tTime >= toT or invisDur) then result[1] = wayPoints[#wayPoints] end
    	return result, fTime
    end
    
    function WayPoints:GetCurrentWayPointRate(unit, time)
	    local lastChanges = self.WayPointRate[unit.networkID]
    	if not lastChanges then return 0 end
    	local time, rate = time or 1, 0
    	for i = 1, #lastChanges do
        	local t = lastChanges[i]
        	if Nintendo.Utils:Clock() - t >= time then break end
        	rate = rate + 1
    	end
    	return rate
    end
    
    function WayPoints:GetWayPointSpread(unit, time)
        local maxSpread = 0
        time = time or 1
        local Now = Game.Timer()
        local Rawpoints = self.WayPoints[unit.networkID]
        local savedRawpoints = {}
        for i, wp in pairs(Rawpoints) do
            if (Now - wp['time']) <= time then table.insert(savedRawpoints, wp) end
        end 
        for i, wpA in pairs(savedRawpoints) do
            for h, wpB in pairs(savedRawpoints) do                  
                local Dist = wpB['waypoint']:DistanceTo(wpA['waypoint'])
                if Dist >= maxSpread then
                    maxSpread = Dist
                end
            end 
        end
        return maxSpread
    end

    function WayPoints:DecodeWaypoints(packet, waypointCount)
        local wayPoints = {}
        if math.ceil(waypointCount) ~= math.floor(waypointCount) then
            waypointCount = math.floor(waypointCount)
            packet:Decode1()
        end
        local modifierBits = {0, 0}
        for i = 1, math.ceil((waypointCount - 1) / 4) do
            local bitMask = packet:Decode1()
            for j = 1, 8 do
                table.insert(modifierBits, bit.band(bitMask, 1))
                bitMask = bit.rshift(bitMask, 1)
            end
        end
        for i = 1, waypointCount do
            table.insert(wayPoints, self:GetNextWayPoint(packet, modifierBits))
        end
        return wayPoints
    end

    function WayPoints:GetNextWayPoint(packet, modifierBits)
        coord = Geometry.Vector2(self:GetNextGridCoord(packet, modifierBits, coord and coord.x or 0), self:GetNextGridCoord(packet, modifierBits, coord and coord.y or 0) )
        return Geometry.Vector2(2 * coord.x + Nintendo.Utils:GetMap().grid.width, 2 * coord.y + Nintendo.Utils:GetMap().grid.height)
    end

    function WayPoints:GetNextGridCoord(packet, modifierBits, relativeCoord)
        if table.remove(modifierBits, 1) == 1 then
            return relativeCoord + self:UnsignedToSigned(packet:Decode1(), 1)
        else
            return self:UnsignedToSigned(packet:Decode2(), 2)
        end
    end

    function WayPoints:UnsignedToSigned(value, byteCount)
        local byteCount = 2 ^ ( 8 * byteCount)
        return value >= byteCount / 2 and value - byteCount or value
    end

    function WayPoints:Circle3D(x, y, z, radius, width, color, quality)
        radius = radius or 300
        quality = quality and 2 * math.pi / quality or 2 * math.pi / (radius / 5)
        local points = {}
        for theta = 0, 2 * math.pi + quality, quality do
            local c = Graphics.WorldToScreen(Geometry.Vector3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
            points[#points + 1] = Geometry.Vector2(c.x, c.y)
        end
        Graphics.DrawLines(points, width or 1, color)
    end

    function WayPoints:GetDistanceSqr(p1, p2)
        p2 = p2 or myHero.pos
        return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
    end

    function WayPoints:GetDistance(p1, p2)
        return math.sqrt(self:GetDistanceSqr(p1, p2))
    end

class 'Predict'
	function Predict:__init(draw)
		self.WaypointsTime    = 5
		self.RawWayPoints     = {}
		self.TargetsVisible   = {}
		self.TargetsWayPoints = {}
		self.TargetsImmobile  = {}
		self.TargetsDashing   = {}
		self.TargetsSlowed    = {}
		self.DontShoot        = {}
		self.DontShoot2       = {}
		self.DontShootUntil   = {}
		self.Cache            = {}
		self.WayPointVisibility = {}		

		--[[Spells that don't allow movement (durations approx)]]
		self.spells = {
			{name = "katarinar", duration = 1}, --Katarinas R
			{name = "drain", duration = 1}, --Fiddle W
			{name = "crowstorm", duration = 1}, --Fiddle R
			{name = "consume", duration = 0.5}, --Nunu Q
			{name = "absolutezero", duration = 1}, --Nunu R
			{name = "rocketgrab", duration = 0.5}, --Blitzcrank Q
			{name = "staticfield", duration = 0.5}, --Blitzcrank R
			{name = "cassiopeiapetrifyinggaze", duration = 0.5}, --Cassio's R
			{name = "ezrealtrueshotbarrage", duration = 1}, --Ezreal's R
			{name = "galioidolofdurand", duration = 1}, --Ezreal's R
			{name = "luxmalicecannon", duration = 1}, --Lux R
			{name = "reapthewhirlwind", duration = 1}, --Jannas R
			{name = "jinxw", duration = 0.6}, --jinxW
			{name = "jinxr", duration = 0.6}, --jinxR
			{name = "missfortunebullettime", duration = 1}, --MissFortuneR
			{name = "shenstandunited", duration = 1}, --ShenR
			{name = "threshe", duration = 0.4}, --ThreshE
			{name = "threshrpenta", duration = 0.75}, --ThreshR
			{name = "infiniteduress", duration = 1}, --Warwick R
			{name = "meditate", duration = 1} --yi W
		}
		self.dashAboutToHappend =	{
			{name = "ahritumble", duration = 0.25},--ahri's r
			{name = "akalishadowdance", duration = 0.25},--akali r
			{name = "headbutt", duration = 0.25},--alistar w
			{name = "caitlynentrapment", duration = 0.25},--caitlyn e
			{name = "carpetbomb", duration = 0.25},--corki w
			{name = "dianateleport", duration = 0.25},--diana r
			{name = "fizzpiercingstrike", duration = 0.25},--fizz q
			{name = "fizzjump", duration = 0.25},--fizz e
			{name = "gragasbodyslam", duration = 0.25},--gragas e
			{name = "gravesmove", duration = 0.25},--graves e
			{name = "ireliagatotsu", duration = 0.25},--irelia q
			{name = "jarvanivdragonstrike", duration = 0.25},--jarvan q
			{name = "jaxleapstrike", duration = 0.25},--jax q
			{name = "khazixe", duration = 0.25},--khazix e and e evolved
			{name = "leblancslide", duration = 0.25},--leblanc w
			{name = "leblancslidem", duration = 0.25},--leblanc w (r)
			{name = "blindmonkqtwo", duration = 0.25},--lee sin q 
			{name = "blindmonkwone", duration = 0.25},--lee sin w
			{name = "luciane", duration = 0.25},--lucian e
			{name = "maokaiunstablegrowth", duration = 0.25},--maokai w
			{name = "nocturneparanoia2", duration = 0.25},--nocturne r
			{name = "pantheon_leapbash", duration = 0.25},--pantheon e?
			{name = "renektonsliceanddice", duration = 0.25},--renekton e
			{name = "riventricleave", duration = 0.25},--riven q
			{name = "rivenfeint", duration = 0.25},--riven e
			{name = "sejuaniarcticassault", duration = 0.25},--sejuani q
			{name = "shenshadowdash", duration = 0.25},--shen e
			{name = "shyvanatransformcast", duration = 0.25},--shyvana r
			{name = "rocketjump", duration = 0.25},--tristana w
			{name = "slashcast", duration = 0.25},--tryndamere e
			{name = "vaynetumble", duration = 0.25},--vayne q
			{name = "viq", duration = 0.25},--vi q
			{name = "monkeykingnimbus", duration = 0.25},--wukong q
			{name = "xenzhaosweep", duration = 0.25},--xin xhao q
			{name = "yasuodashwrapper", duration = 0.25},--yasuo e
		}
		self.blinks = {
			{name = "ezrealarcaneshift", range = 475, delay = 0.25, delay2=0.8},--Ezreals E
			{name = "deceive", range = 400, delay = 0.25, delay2=0.8}, --Shacos Q
			{name = "riftwalk", range = 700, delay = 0.25, delay2=0.8},--KassadinR
			{name = "gate", range = 5500, delay = 1.5, delay2=1.5},--Twisted fate R
			{name = "katarinae", range = math.huge, delay = 0.25, delay2=0.8},--Katarinas E
			{name = "elisespideredescent", range = math.huge, delay = 0.25, delay2=0.8},--Elise E
			{name = "elisespidere", range = math.huge, delay = 0.25, delay2=0.8},--Elise insta E
		}
		Callback.Bind('OnGainVision', function(unit) self:GainVision(unit) end)
		Callback.Bind("WayPoints_NewPath", function(unit, waypoints) self:NewWayPoints(unit, waypoints) end)
		--Callback.Bind('OnLoseVision', function(unit) self:LoseVision(unit) end)
		Callback.Bind('OnDash', function(unit, dash) self:Dash(unit, dash) end)
		Callback.Bind('ProcessSpell', function(unit, spell) self:ProcessSpell(unit, spell) end)
		if draw then Callback.Bind('Draw', function() self:Draw() end) end
		Callback.Bind('Tick', function() self:Tick() end)
	end

	function Predict:Tick()
		for nid, targetWayPoints in pairs(self.TargetsWayPoints) do
			local i = 1
			while i <= #self.TargetsWayPoints[nid] do
				if self.TargetsWayPoints[nid][i]['time'] + self.WaypointsTime < Util:Clock() then
					table.remove(self.TargetsWayPoints[nid], i)
				else
					i = i + 1
				end
			end
		end
		for i, unit in ipairs(Nintendo.Objects:EnemyHeroes()) do
			for j = 1, unit.buffCount do
				local buff = unit:GetBuff(j)
				if buff.valid and buff.name == 'Stun' then
					if self.TargetsImmobile[unit.networkID] and self.TargetsImmobile[unit.networkID] < Util:Clock() then
						self.TargetsImmobile[unit.networkID] = Util:Clock() + (buff.endT - buff.startT)
					end
				end
			end
		end
	end

	function Predict:Draw()
		for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
			if hero.valid and hero.visible and hero.team ~= myHero.team  then
				local vipos, hc = self:VIP(hero, .25, 40, 1100, 1400, myHero)
				local pos, hitchance, castpos = self:CastPosition(hero, .25, 40, 1100, 1400, myHero, false, 'linear')
				if vipos  and hc > 0.3 and Keyboard.KeysDown(Nintendo.Menu:Values('Combo')) and self:GetDistance(hero, myHero) <= 1100 then
					--myHero:CastSpell(0, vipos.x, vipos.z)
				end
				if pos  and hitchance >= 2 and Keyboard.KeysDown(Nintendo.Menu:Values('Combo')) and self:GetDistance(hero, myHero) <= 1100 then
					myHero:CastSpell(0, pos.x, pos.z)
				end
				if self.TargetsWayPoints[hero.networkID] ~= nil then
               		for nid, waypoint in pairs(self.TargetsWayPoints[hero.networkID]) do
	           	    	Render.GameCircle(waypoint.waypoint.x,mousePos.y,waypoint.waypoint.y, 100, Graphics.ARGB(0xFF,0xFF,0xFF,0xFF):ToNumber()):Draw()
	           	    end
				end
			end
		end
	end

	function Predict:NewWayPoints(unit, waypoints)
		if unit and unit.valid and unit.networkID ~= 0 and unit.type == myHero.type then
			self.DontShootUntil[unit.networkID] = false
			if self.TargetsWayPoints[unit.networkID] == nil then
				self.TargetsWayPoints[unit.networkID] = {}
			end
			local AddWaypoints = Nintendo.WayPoints:GetCurrentWayPoints(unit)
			self.RawWayPoints[unit.networkID] = AddWaypoints
			if AddWaypoints and #AddWaypoints >= 1 then
				table.insert(self.TargetsWayPoints[unit.networkID], {unitPos = unit.pos, waypoint = AddWaypoints[#AddWaypoints], time = Util:Clock(), n = #AddWaypoints})
			end
		end
	end

	function Predict:GainVision(unit)
		if unit.type == myHero.type then
			self.TargetsVisible[unit.networkID]      = Util:Clock()
			self.WayPointVisibility[unit.networkID]  = nil
		end
	end

	function Predict:LoseVision(unit)
		if unit.type == myHero.type then
			self.TargetsVisible[unit.NetworkID]      = math.huge
			self.WayPointVisibility[unit.networkID]  = Nintendo.Utils:Clock()
		end
	end

	function Predict:Dash(unit, dash)
		if unit.type == myHero.type then
			dash.endPos = dash.target and dash.target.pos or dash.endPos
			dash.startT = Util:Clock() + Util:Latency()
			dash.endT   = dash.startT  + dash.duration
			self.TargetsDashing[unit.networkID] = dash
			self.DontShootUntil[unit.networkID] = true
		end
	end

	function Predict:ProcessSpell(unit, spell)
		if unit and unit.type == myHero.type then
			for i, s in ipairs(self.spells) do
				if spell.name:lower() == s.name then
					self.TargetsImmobile[unit.networkID] = Util:Clock() + s.duration
					return
				end
			end
			for i, s in ipairs(self.blinks) do
				local landPos = unit:DistanceTo(spell.endPos) < s.range and spell.endPos or unit.pos + s.range * (Geometry.Vector3(spell.endPos) - unit.pos):Normalize()
				if spell.name:lower() == s.name and not Game.IsWall(spell.endPos) then
					self.TargetsDashing[unit.networkID] = {isblink = true, duration = s.delay, endT = Util:Clock() + s.delay, endT2 = Util:Clock() + s.delay2, startPos = unit.pos, endPos = landPos}
					return
				end
			end
			for i, s in ipairs(self.dashAboutToHappend) do
				if spell.name:lower() == s.name then
					self.DontShoot2[unit.networkID] = Util:Clock() + s.duration
				end
			end
		end
	end

	function Predict:NewPred(target, delay, radius, radius, range, speed, from)
		if self.TargetsWayPoints[hero.networkID] ~= nil then
            for nid, waypoint in pairs(self.TargetsWayPoints[target.networkID]) do
            end
        end
	end

	function Predict:WTF(target, delay, speed, radius, range, from)
		local pos, hitTime = nil, nil
		local tdist = 0
		local wayPoints     = Nintendo.WayPoints:GetCurrentWayPoints(target)
		local wayPointsRate = Nintendo.WayPoints:GetCurrentWayPointRate(target, 1)
		for i = math.max(startIndex or 1, 1), math.min(#wayPoints, endIndex or math.huge) - 1 do
        	tdist = tdist + self:GetDistance(points[i], points[i + 1])
        end
        if wayPointsRate > 1 then
        	local speed = (1 + ((0.2195) * wayPointsRate))
        	if speed < 1 then speed = 1 end
        	pos, hitTime = self:GetPrediction(target, speed, delay, from)
        elseif wayPointsRate < 2 then
        	pos, hitTime = self:GetPrediction(target, 1, delay, from)
        end
        if pos ~= nil then
        	print('hi')
        	local function sum(t) local n = 0 for i, v in pairs(t) do n = n + v end return n end
            local hitChance = 0
            local hC = {}
            local wps, arrival = Nintendo.WayPoints:GetSimulatedWayPoints(target)
            hC[#hC + 1] = self.target.visible and 1 or (arrival ~= 0 and 0.5 or 0)
            if self.target.visible then
            	local rate = 1 - math.max(0, (rate22 - 1)) / 5
                hC[#hC + 1] = rate; hC[#hC + 1] = rate; hC[#hC + 1] = rate
                if t then hC[#hC + 1] = math.min(math.max(0, 1 - t / 1), 1) end
            end
           	hitChance = math.min(1, math.max(0, sum(hC) / #hC))
            return pos, t, hitChance
        end
        return nil
	end

	function Predict:GetPrediction(target, speed, delay, from)
		local fast = speed*speed
	    local tss  = ((speed)/200) or 1
        if tss < 1 then tss = 1 end
	    local kk = delay - (0.01 * speed)
        if kk <= 0 then kk = 0 end 
        local delayfast = kk
		if speedDelay < 0 then speedDelay = 0 end
    	local wayPoints, hitPosition, hitTime = Nintendo.WayPoints:GetSimulatedWayPoints(target, delayfast + Nintendo.Utils:Latency()), nil, nil    
    	if #wayPoints == 1 or fast >= 20000 or fast == math.huge then --Target not moving
        	hitPosition = { x = wayPoints[1].x, y = target.y, z = wayPoints[1].y };
        	hitTime = Geometry.Vector2(wayPoints[1].x, wayPoints[1].y):DistanceTo(from.pos:To2D()) / speed
    	else --Target Moving
        	local travelTimeA = 0
        	local source = from.pos
        	for i = 1, #wayPoints - 1 do
            	local A, B = Geometry.Vector2(wayPoints[i].x, wayPoints[i].y),  Geometry.Vector2(wayPoints[i + 1].x, wayPoints[i +1].y)
            	local wayPointDist = A:DistanceTo(B)
                local travelTimeB = travelTimeA + wayPointDist / target.ms
                local v1, v2 = target.ms, fast
                local r, S, j, K = source.x - A.x, v1 * (B.x - A.x) / wayPointDist, source.z - A.y, v1 * (B.y - A.y) / wayPointDist
                local vv, jK, rS, SS, KK = v2 * v2, j * K, r * S, S * S, K * K
                local t = (jK + rS - math.sqrt(j * j * (vv - 1) + SS + 2 * jK * rS + r * r * (vv - KK))) / (KK + SS - vv)
                if travelTimeA <= t and t <= travelTimeB then
                    hitPosition = { x = A.x + t * S, y = target.y, z = A.y + t * K }
                    hitTime = t
                    break
                end
            	travelTimeA = travelTimeB
        	end
    	end
    	if hitPosition then
    		local vec = from.pos - Geometry.Vector3(hitPosition.x, from.pos.y, hitPosition.z)
        	return vac, hitTime
    	end
	end

	function Predict:GetHitChance(target, delay, radius, range, speed, from)
    	local pos, t = self:VIP(target, delay, radius, range, speed, from)
    	if self.Cache[target.networkID] and self.Cache[target.networkID].Chance then return self.Cache[target.networkID].Chance end
    	local function sum(t) local n = 0 for i, v in pairs(t) do n = n + v end return n end
    	local hitChance = 0
    	local hC = {}
    	--Track if the enemy arrived at its last waypoint and is invisible (lower hitchance)
    	local wps, arrival = Nintendo.WayPoints:GetSimulatedWayPoints(target)
    	hC[#hC + 1] = target.visible and 1 or (arrival ~= 0 and 0.5 or 0)
    	if target.visible then
        	--Track how often the enemy moves. If he constantly moves, the hitchance is lower
        	local rate = 1 - math.max(0, (Nintendo.WayPoints:GetCurrentWayPointRate(target) - 1)) / 5
        	hC[#hC + 1] = rate; hC[#hC + 1] = rate; hC[#hC + 1] = rate
        	--Track the time the spell needs to hit the target. the higher it is, the lower the hitchance
        	if t then hC[#hC + 1] = math.min(math.max(0, 1 - t / 1), 1) end
    	end
    	--Generate a value between 0 (no chance) and 100 (you'll hit for sure)
    	hitChance = math.min(1, math.max(0, sum(hC) / #hC))
    	if self.Cache[target.networkID] then self.Cache[target.networkID].Chance = hitChance end
    	return hitChance
	end

	function Predict:CastPosition(unit, delay, radius, range, speed, from, collision, spelltype)
		range = range and range - 4 or math.huge
		radius = radius or 1
		speed = speed and speed or math.huge
		from = from and from or myHero
		local IsFromMyHero = self:GetDistance(from, myHero) < 50 and true or false
		delay = delay + (0.07 + Nintendo.Utils:Latency())	
		local Position, CastPosition, HitChance = unit.pos, unit.pos, 0
		local TargetDashing, CanHitDashing, DashPosition = self:IsDashing(unit, delay, radius, speed, from)
		local TargetImmobile, ImmobilePos, ImmobileCastPosition = self:IsImmobile(unit, delay, radius, speed, from, spelltype)
		local VisibleSince = self.TargetsVisible[unit.networkID] and self.TargetsVisible[unit.networkID] or Nintendo.Utils:Clock()
		
		if unit.type ~= myHero.type then
			Position, CastPosition = self:Position(unit, delay, radius, speed, from, spelltype)
			HitChance = 2
		else
			if self.DontShoot[unit.networkID] and self.DontShoot[unit.networkID] > Nintendo.Utils:Clock() then
				Position, CastPosition = unit.pos,  unit.pos
				HitChance = 0
			elseif TargetDashing then
				if CanHitDashing then
					HitChance = 5
					print('Hero HitChance 5: Dashing')
				else
					HitChance = 0
				end 
				Position, CastPosition = DashPosition, DashPosition
			elseif self.DontShoot2[unit.networkID] and self.DontShoot2[unit.networkID] > Nintendo.Utils:Clock() then
				Position, CastPosition = unit.pos,  unit.pos
				HitChance = 7
			elseif TargetImmobile then
				Position, CastPosition = ImmobilePos, ImmobileCastPosition
				HitChance = 4
				print('HitChance 7: TargetsImmobile')
			else
				CastPosition, HitChance, Position = self:WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
			end
		end
		--[[Out of range]]
		if IsFromMyHero then
			if (spelltype == 'linear' and self:GetDistance(from,Position) >= range) then
				HitChance = 0
			end
			if (spelltype == 'circular' and self:GetDistance(from,Position) >= (range + radius)) then
				HitChance = 0
			end
		end
		return CastPosition, HitChance, Position
	end

	function Predict:Position(unit, delay, radius, speed, from, spelltype)
		local Waypoints = {}
		local Position, CastPosition = unit.pos, unit.pos
		local t
	
		Waypoints = self:GetCurrentWayPoints(unit)
		local Waypointslength = self:GetWaypointsLength(Waypoints)
		if #Waypoints == 1 then
			Position, CastPosition = Geometry.Vector3(Waypoints[1].x, 0, Waypoints[1].y), Geometry.Vector3(Waypoints[1].x, 0, Waypoints[1].y)
			return Position, CastPosition
		elseif (Waypointslength - delay * unit.ms + radius) >= 0 then
			local tA = 0
			Waypoints = self:CutWaypoints(Waypoints, delay * unit.ms - radius)
			if speed ~= math.huge then
				for i = 1, #Waypoints - 1 do
					local A, B =Geometry.Vector2(Waypoints[i].x, Waypoints[i].y), Geometry.Vector2(Waypoints[i+1].x, Waypoints[i+1].y)
					if i == #Waypoints - 1 then
						B = B + radius * (B - A):Normalize()
					end
					local t1, p1, t2, p2 = A:Interception(B, unit.ms, from.pos:To2D(), speed)
					local tB = tA / unit.ms
					t1, t2 = (t1 and tA <= t1 and t1 <= (tB - tA)) and t1 or nil, (t2 and tA <= t2 and t2 <= (tB - tA)) and t2 or nil
					t = t1 and t2 and math.min(t1, t2) or t1 or t2
					if t then
						CastPosition = t==t1 and Geometry.Vector3(p1.x, 0, p1.y) or Geometry.Vector3(p2.x, 0, p2.y)
						break
					end
					tA = tB
				end
			else
				t = 0
				CastPosition = Geometry.Vector3(Waypoints[1].x, 0, Waypoints[1].y)
			end
			if t then
				if (self:GetWaypointsLength(Waypoints) - t * unit.ms - radius) >= 0 then
					Waypoints = self:CutWaypoints(Waypoints, radius + t * unit.ms)
					Position = Geometry.Vector3(Waypoints[1].x, 0, Waypoints[1].y)
				else
					Position = CastPosition
				end
			elseif unit.type ~= myHero.type then
				CastPosition = Geometry.Vector3(Waypoints[#Waypoints].x, 0, Waypoints[#Waypoints].y)
				Position = CastPosition
			end
		elseif unit.type ~= myHero.type then
			CastPosition = Geometry.Vector3(Waypoints[#Waypoints].x, 0, Waypoints[#Waypoints].y)
			Position = CastPosition
		end
		if t and self:IsSlowed(unit, 0, math.huge, from) and not self:isSlowed(unit, t, math.huge, from) and Position then
			CastPosition = Position
		end
		return Position, CastPosition
	end

	function Predict:IsImmobile(unit, delay, radius, speed, from, spelltype)
		if self.TargetsImmobile[unit.networkID] then
			local extraDelay = speed == math.huge and 0 or (unit:DistanceTo(from) / speed)
			if self.TargetsImmobile[unit.networkID] > (Util:Clock() + delay + extraDelay) and spelltype == 'circular' then
				return true, unit.pos, unit.pos, unit.pos + (radius/3) * (Geometry.Vector3(from - unit.pos)):Normalize()
			elseif self.TargetsImmobile[unit.networkID] + (radius / unit.ms) > (Util:Clock() + delay + extraDelay) then
				return true, unit.pos, unit.pos
			end
		end
		return false, unit.pos, unit.pos
	end

	function Predict:IsDashing(unit, delay, radius, speed, from)
		local targetDashing = false
		local canHit = false
		local position
		if self.TargetsDashing[unit.networkID] then
			local dash = self.TargetsDashing[unit.networkID]
			if dash.endT >= Util:Clock() then
				targetDashing = true
				if dash.isblink then
					if (dash.endT - Util:Clock()) <= (delay + from:DistanceTo(dash.endPos)/speed) then
						position = Geometry.Vector3(dash.endPos.x, 0, dash.endPos.z)
						canHit   = (unit.ms * (delay + from:DistanceTo(dash.endPos)/speed - (dash.endT2 - Util:Clock()))) < radius
					end
					if ((dash.endT - Util:Clock()) >= (delay + from:DistanceTo(dash.startPos)/speed)) and not canHit then
						position = Geometry.Vector3(dash.startPos.x, 0, dash.startPos.z)
						canHit   = true
					end
				else
					local t1, p1, t2, p2, dis = Geometry.Vector2(dash.startPos.x, dash.startPos.y):Interception(Geometry.Vector2(dash.endPos.x, dash.endPos.y), dash.speed, Geometry.Vector2(from.x, from.z), (Util:Clock() - dash.startT) + delay)
					t1, t2 = (t1 and 0 <= t1 and t1 <= (dash.endT - Nintendo.Utils:Clock() - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <=  (dash.endT - Nintendo.Utils:Clock() - delay)) and t2 or nil 
					local t = t1 and t2 and math.min(t1,t2) or t1 or t2
					if t then
						position = t==t1 and Geometry.Vector3(p1.x, 0, p1.y) or Geometry.Vector3(p2.x, 0, p2.y)
						canHit = true
					else
						position = Geometry.Vector3(dash.endPos.x, 0, dash.endPos.z)
						canHit = (unit.ms * (delay + self:GetDistance(from, Position)/speed) - (dash.endT - Util:Clock())) < radius
					end
				end
			end
		end
		return targetDashing, canHit, position
	end

	function Predict:IsImmobile(unit, delay, radius, speed, from, spelltype)
		if self.TargetsImmobile[unit.networkID] then
			local ExtraDelay = speed == math.huge and  0 or (from:DistanceTo(unit) / speed)
			if (self.TargetsImmobile[unit.networkID] > (Nintendo.Utils:Clock() + delay + ExtraDelay) and spelltype == "circular") then
				return true, unit.pos, Geometry.Vector3(unit.x, unit.y, unit.z) + (radius/3) * (Geometry.Vector3(from.x, from.y, from.z) - unit.pos):Normalize()
			elseif (self.TargetsImmobile[unit.networkID] + (radius / unit.ms)) > (Nintendo.Utils:Clock() + delay + ExtraDelay) then
				return true, unit.pos, unit.pos
			end
		end
		return false, unit.pos, unit.pos
	end

	function Predict:IsSlowed(unit, delay, speed, from)
		if self.TargetsSlowed[unit.networkID] then
			if self.TargetsSlowed[unit.networkID] > (Nintendo.Utils:Clock() + delay + self:GetDistance(unit, from) / speed) then
				return true
			end
		end
		return false
	end

	function Predict:WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
		local Position, CastPosition, HitChance
		local SavedWayPoints = self.TargetsWayPoints[unit.networkID] or {}
		local CurrentWayPoints = self:GetCurrentWayPoints(unit)
		local VisibleSince = self.TargetsVisible[unit.networkID] and self.TargetsVisible[unit.networkID] or Nintendo.Utils:Clock()

		HitChance = 1
		Position, CastPosition = self:Position(unit, delay, radius, speed, from, spelltype)

		if self:CountWaypoints(unit.networkID, Nintendo.Utils:Clock() - 0.1) >= 1 or self:CountWaypoints(unit.networkID, Nintendo.Utils:Clock() - 1) == 1 then
			HitChance = 2
		end	
		local N = 2
		local t1 = 0.5
		if self:CountWaypoints(unit.networkID, Nintendo.Utils:Clock() - 0.75) >= N then
			local angle = self:MaxAngle(unit, CurrentWayPoints[#CurrentWayPoints], Nintendo.Utils:Clock() - t1)
			if angle > 90 then
				HitChance = 1
			elseif angle < 30 and self:CountWaypoints(unit.networkID, Nintendo.Utils:Clock() - 0.1) >= 1 then
				HitChance = 2
			end
		end	
		N = 1
		if self:CountWaypoints(unit.networkID, Nintendo.Utils:Clock() - N) == 0 then
			HitChance = 2
		end
		if #CurrentWayPoints <= 1 and Nintendo.Utils:Clock() - VisibleSince > 1 then
			HitChance = 2
		end	
		if self:IsSlowed(unit, delay, speed, from) then
			HitChance = 2
		end
		if Position and CastPosition and ((radius / unit.ms >= delay + self:GetDistance(from, CastPosition)/speed) or (radius / unit.ms >= delay + self:GetDistance(from, Position)/speed)) then
			print('HitChance = 3 WayPoints')
			HitChance = 3
		end
		--[[Angle too wide]]
		if unit.pos:To2D():Angle(Geometry.Vector2(CastPosition.x, CastPosition.y)) > 60 then
			HitChance = 1
		end
		if not Position or not CastPosition then
			HitChance = 0
			CastPosition = Geometry.Vector3(CurrentWayPoints[#CurrentWayPoints].x, 0, CurrentWayPoints[#CurrentWayPoints].y)
			Position = CastPosition
		end
		if myHero:DistanceTo(unit) < 250 then
			HitChance = 2
			Position, CastPosition = self:Position(unit, delay*0.5, radius, speed*2, from, spelltype)
			Position = CastPosition
		end
		if #SavedWayPoints == 0 and (Nintendo.Utils:Clock() - VisibleSince) > 3 then
			HitChance = 2
		end
		if self.DontShootUntil[unit.networkID] then
			HitChance = 0
			CastPosition = Geometry.Vector3(unit.x, 0, unit.z)
			Position = CastPosition
		end
		return CastPosition, HitChance, Position
	end

	function Predict:GetWaypoints(NetworkID, from, to)
		local Result = {}
		to = to and to or Util:Clock()
		if self.TargetsWayPoints[NetworkID] then
			for i, waypoint in ipairs(self.TargetsWayPoints[NetworkID]) do
				if from <= waypoint.time and to >= waypoint.time then
					table.insert(Result, waypoint)
				end
			end
		end
		return Result, #Result
	end

	function Predict:CountWaypoints(NetworkID, from, to)
		local R, N = self:GetWaypoints(NetworkID, from, to)
		return N
	end

	function Predict:GetWaypointsLength(Waypoints)
		local result = 0
		for i = 1, #Waypoints -1 do
			result = result + Geometry.Vector2(Waypoints[i].x, Waypoints[i].y):DistanceTo(Geometry.Vector2(Waypoints[i + 1].x, Waypoints[i + 1].y))
		end
		return result
	end

	function Predict:CutWaypoints(Waypoints, distance)
		local result = {}
		local remaining = distance
		if distance > 0 then
			for i = 1, #Waypoints -1 do
				local A, B = Waypoints[i], Waypoints[i + 1]
				local dist = Geometry.Vector2(A.x, A.y):DistanceTo(Geometry.Vector2(B.x, B.y))
				if dist >= remaining then
					result[1] = Geometry.Vector2(A.x, A.y) + remaining * (Geometry.Vector2(B.x, B.y) - Geometry.Vector2(A.x, A.y)):Normalize()
					for j = i + 1, #Waypoints do
						result[j - i + 1] = Waypoints[j]
					end
					remaining = 0
					break
				else
					remaining = remaining - dist
				end
			end
		else
			local A, B = Waypoints[1], Waypoints[2]
			result = Waypoints
			result[1] = Geometry.Vector2(A.x, A.y) - distance * (Geometry.Vector2(B.x, B.y) - Geometry.Vector2(A.x, A.y)):Normalize()
		end
		return result
	end

	function Predict:GetCurrentWayPoints(unit)
		local wayPoints, lineSegment, distanceSqr, fPoint = self.RawWayPoints[unit.networkId], 0, math.huge, nil
		if not wayPoints and not unit then
			return { { x = unit.x, y = unit.z } }
		elseif not wayPoints and unit then
			return { { x = unit.x, y = unit.z } }
		end
		for i = 1, #wayPoints - 1 do
			local p1, bool = Geometry.Vector2(wayPoints[i].x, wayPoints[i].y):ProjectOnLineSegment(Geometry.Vector2(wayPoints[i + 1].x, wayPoints[i + 1].y), unit.pos:To2D())
			local distanceSegmentSqr = p1:DistanceTo(unit.pos:To2D())
			if distanceSegmentSqr <= distanceSqr then
				fPoint = p1
				lineSegment = i
				distanceSqr = distanceSegmentSqr
			else
				break --not necessary, but makes it faster
			end
		end
		local result = { fPoint or { x = unit.x, y = unit.z } }
		for i = lineSegment + 1, #wayPoints do
			result[#result + 1] = wayPoints[i]
		end
		if #result == 2 and Geometry.Vector2(result[1].x, result[1].y):DistanceTo(Geometry.Vector2(result[2].x, result[2].y)) < 20 then result[2] = nil end
		return result
	end

	function Predict:GetDistanceSqr(p1, p2)
    	p2 = p2 or myHero.pos
    	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
	end

	function Predict:GetDistance(p1, p2)
    	return math.sqrt(self:GetDistanceSqr(p1, p2))
	end

	function Predict:MaxAngle(unit, currentwaypoint, from)
		local WPtable, n = self:GetWaypoints(unit.networkID, from)
		local Max = 0
		local CV = (Geometry.Vector2(currentwaypoint.x, currentwaypoint.y) - unit.pos:To2D())
		for i, waypoint in ipairs(WPtable) do
			local angle = CV:Angle(Geometry.Vector2(waypoint.waypoint.x, waypoint.waypoint.y) - Geometry.Vector2(waypoint.unitPos.x, waypoint.unitPos.y))
				if angle > Max then
					Max = angle
				end
		end
		return Max
	end

-- Imported Callbacks --
Callback.Bind('GameStart', function()
	-- OnDash --
	OnDashCallback = function(unit, dash)
		for k, v in ipairs(Callback.GetCallbacks('OnDash')) do
			v(unit, dash)
		end
	end
	-- GainBuff --
	OnGainBuffCallback = function(unit, buff)
		for k, v in ipairs(Callback.GetCallbacks('OnGainBuff')) do
			v(unit, buff)
		end
	end
	-- UpdateBuff --
	OnUpdateBuffCallback = function(unit, buff)
		for k, v in ipairs(Callback.GetCallbacks('OnUpdateBuff')) do
			v(unit, buff)
		end
	end
	-- OnLoseBuff --
	OnLoseBuffCallback = function(unit, buff)
		for k, v in ipairs(Callback.GetCallbacks('OnLoseBuff')) do
			v(unit, buff)
		end
	end
	-- OnGainVision --
	OnGainVisionCallback = function(unit)
		for k, v in ipairs(Callback.GetCallbacks('OnGainVision')) do
			v(unit)
		end	
	end
	-- OnLoseVision --
	OnLoseVisionCallback = function(unit)
		for k, v in ipairs(Callback.GetCallbacks('OnLoseVision')) do
			v(unit)
		end
	end
	-- OnShowUnit --
	OnShowUnitCallback = function(unit)
		for k, v in ipairs(Callback.GetCallbacks('OnShowUnit')) do
			v(unit)
		end	
	end
	-- OnHideUnit --
	OnHideUnitCallback = function(unit)
		for k, v in ipairs(Callback.GetCallbacks('OnHideUnit')) do
			v(unit)
		end	
	end
	Callback.Bind("RecvPacket", function(p)
		if p.header == Nintendo.Packets:Header('GainVision') then
			p.pos = 1
			local unit = Game.ObjectByNetworkId(p:Decode4())
			if unit and unit.valid then
				--print('Gained Vision'.. unit.name)
				OnGainVisionCallback(unit)
			end
		elseif p.header == Nintendo.Packets:Header('LoseVision') then
			p.pos = 1
			local unit = Game.ObjectByNetworkId(p:Decode4())
			if unit then
				--print('Lost Vision'..unit.name)
				OnLoseVisionCallback(unit)
			end
		elseif p.header == (Nintendo.Packets:Header('WayPoint') or Nintendo.Packets:Header('WayPoints'))  then
			p.pos = 1
			local unit = Game.ObjectByNetworkId(p:Decode4())
			if unit and unit.valid then
				--print('Showed Unit'..unit.name)
				OnShowUnitCallback(unit)
			end
		elseif p.header == Nintendo.Packets:Header('HideUnit') then
			p.pos = 1
			local unit = Game.ObjectByNetworkId(p:Decode4())
			if unit then
				--print('Hid'..unit.name)
				OnHideUnitCallback(unit)
			end
		elseif p.header == Nintendo.Packets:Header('GainBuff') then
			local b, c = {}, {}
			p.pos = 1
			b.Target = Game.ObjectByNetworkId(p:Decode4())
			b.Slot = p:Decode1() + 1
			b.Type = p:Decode1()
			b.Stacks = p:Decode1()
			b.Visible = p:Decode1()
			b.ID = p:Decode4()
			c.crap = p:Decode4() -- 2. time Target.networkid
			c.crap2 = p:Decode4() -- idk, useless
			b.Duration = p:DecodeF()
			b.Source = Game.ObjectByNetworkId(p:Decode4())
			--------------------------
			b.Start = Game.Timer()
			b.End = Game.Timer() + b.Duration
			if b.Target ~= nil then 
				Utility.DelayAction(function()
					local Buff = b			
					local tmpBuff = b.Target:GetBuff(b.Slot)
					Buff.name = tmpBuff.name or ""
					OnGainBuffCallback(Buff.Target, Buff)
				end, 1)
			end
		elseif p.header == Nintendo.Packets:Header('UpdateBuff1') then
			local b = {}
			p.pos = 1
			b.Target	= Game.ObjectByNetworkId(p:Decode4())
			b.Slot		= p:Decode1() + 1
			b.Stacks	= p:Decode1()
			b.Duration	= p:DecodeF()
			b.Past		= p:DecodeF()
			b.Source	= Game.ObjectByNetworkId(p:Decode4())
			--------------------------
			b.Start		= Game.Timer()
			b.End		= Game.Timer() + b.Duration
			b.End = Game.Timer() + b.Duration
			if b.Target ~= nil then 
				Utility.DelayAction(function()
					local Buff = b			
					local tmpBuff = b.Target:GetBuff(b.Slot)
					Buff.name = tmpBuff.name or ""
					OnUpdateBuffCallback(Buff.Target, Buff)
				end, 1)
			end
		elseif p.header == Nintendo.Packets:Header('UpdateBuff2') then
			local b = {}
			p.pos = 1	
			b.Target	= Game.ObjectByNetworkId(p:Decode4())
			b.Slot		= p:Decode1() + 1
			b.Past		= p:DecodeF()
			b.Duration	= p:DecodeF()
			b.Source	= Game.ObjectByNetworkId(p:Decode4())
			---------------------------
			b.Stacks	= 1
			b.Start		= Game.Timer()
			b.End		= Game.Timer() + b.Duration
			if b.Target ~= nil then 
				Utility.DelayAction(function()
					local Buff = b			
					local tmpBuff = b.Target:GetBuff(b.Slot) or nil
					if tmpBuff then
						Buff.name = tmpBuff.name or ""
						OnUpdateBuffCallback(Buff.Target, Buff)
					end
				end, 1)
			end
		elseif p.header == Nintendo.Packets:Header('LoseBuff') then
			local b = {}
			p.pos = 1
			b.Target	= Game.ObjectByNetworkId(p:Decode4())
			b.Slot		= p:Decode1() + 1
			b.ID		= p:Decode4()
			b.Duration	= p:DecodeF()
			------------------------
			b.Stacks	= 1
			-- Replace Duration with 0 because the buff is over.
			b.Duration	= 0
			b.Start		= 0
			b.End		= Game.Timer() - 1
			if b.Target ~= nil then 
				Utility.DelayAction(function()
					local Buff = b			
					local tmpBuff = b.Target:GetBuff(b.Slot)
					Buff.name = tmpBuff.name or ""
					OnLoseBuffCallback(Buff.Target, Buff)
				end, 1)
			end
		elseif p.header == Nintendo.Packets:Header('Dash') then
			p.pos = 11
        	local waypointCount = p:Decode1()/2
        	local networkID = p:Decode4()
        	local speed = p:DecodeF()
        	p.pos = 24 
        	local x = p:DecodeF()
        	local z = p:DecodeF()
        	p.pos = 33
        	local targetTo = Game.ObjectByNetworkId(p:Decode4())
        	local target = Game.ObjectByNetworkId(networkID)
        	if target and target.valid then 
            	p.pos = 49
            	local wayPoints = Packets:DecodeWaypoints(p, waypointCount)
            	local startPos = Geometry.Vector3(x, target.y, z)
            	endPos = Geometry.Vector3(wayPoints[#wayPoints].x, target.y, wayPoints[#wayPoints].y)
            	distance = endPos:DistanceTo(startPos)
            	time = distance / speed
            	OnDashCallback(target, {startPos = startPos, endPos = endPos, distance = distance, speed = speed, target = targetTo, duration = time, startT = Game.Timer(), endT=Game.Timer()+time})
        	end 
		elseif p.header == Nintendo.Packets:Header('FoWDash') then
			p.pos = 30
        	local mode = p:Decode1()
        	if mode == 1 then 
            	p.pos = 35
            	local waypointCount = p:Decode1()/2
            	local networkID = p:Decode4()
            	local speed = p:DecodeF()
            	p.pos = p.pos + 4
            	local x = p:DecodeF()
            	local z = p:DecodeF()
           		p.pos = p.pos + 1
            	local targetTo = Game.ObjectByNetworkId(p:Decode4())
            	local target = Game.ObjectByNetworkId(networkID)
            	if target and target.valid then 
	                p.pos = 73
    	            wayPoints = Nintendo.Packets:DecodeWayPoints(p,waypointCount)
        	        startPos = Geometry.Vector3(x, target.y, z)
            	    endPos = Geomtry.Vector3(wayPoints[#wayPoints].x, target.y, wayPoints[#wayPoints].y)
                	distance = endPos:DistanceTo(startPos)
                	time = distance / speed
                	OnDashCallback(target, {startPos = startPos, endPos = endPos, distance = distance, speed = speed, target = targetTo, duration = time, startT = Game.Timer(), endT=Game.Timer()+time})
            	end 
        	end
    	end
    end)
	function math.close(a, b, eps)
    	assert(type(a) == "number" and type(b) == "number", "math.close: wrong argument types (at least 2 <number> expected)")
   		eps = eps or 1e-9
    	return math.abs(a - b) <= eps
	end
end)


--[[
    Class: Queue
    Performance optimized implementation of a queue, much faster as if you use table.insert and table.remove
        Members:
            pushleft
            pushright
            popleft
            popright
        Sample:
            local myQueue = Queue()
            myQueue:pushleft("a"); myQueue:pushright(2);
            for i=1, #myQueue, 1 do
                PrintChat(tostring(myQueue[i]))
            end
        Notes:
            Don't use ipairs or pairs!
            It's a queue, dont try to insert values by yourself, only use the push functions to add values
]]
function Queue()
    local _queue = { first = 0, last = -1, list = {} }
    _queue.pushleft = function(self, value)
        self.first = self.first - 1
        self.list[self.first] = value
    end
    _queue.pushright = function(self, value)
        self.last = self.last + 1
        self.list[self.last] = value
    end
    _queue.popleft = function(self)
        if self.first > self.last then error("Queue is empty") end
        local value = self.list[self.first]
        self.list[self.first] = nil
        self.first = self.first + 1
        return value
    end
    _queue.popright = function(self)
        if self.first > self.last then error("Queue is empty") end
        local value = self.list[self.last]
        self.list[self.last] = nil
        self.last = self.last - 1
        return value
    end
    setmetatable(_queue,
        {
            __index = function(self, key)
                if type(key) == "number" then
                    return self.list[key + self.first - 1]
                end
            end,
            __newindex = function(self, key, value)
                error("Cant assign value to Queue, use Queue:pushleft or Queue:pushright instead")
            end,
            __len = function(self)
                return self.last - self.first + 1
            end,
        })
    return _queue
end

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end