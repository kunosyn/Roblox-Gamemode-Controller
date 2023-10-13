ServerScriptService = game:GetService('ServerScriptService')
local utility = require(ServerScriptService.Utility)



export type Implementation = {
	__index: Implementation,
	new: ( name: string, displayName: string, duration: number) -> Gamemode,	
	
	On: ( self: Gamemode, event: string, callback: ( ...any ) -> any ) -> nil,
	Start: ( self: Gamemode, ...any ) -> nil,
	WhileActive: (self: Gamemode, callback: ( ...any ) -> any, seconds: number?, ...any ) -> nil,
	End: ( self: Gamemode, ...any ) -> nil,
	RegisterEvent: ( event: string, callback: ( ...any ) -> any ) -> nil,
	__Fire: ( self: Gamemode, event: string, ...any ) -> nil
}

export type Prototype = {
	name: string, displayName: string, 
	duration: number,
	active: boolean, timeElapsed: number,
	tempStorage: { any },
	__registeredEvents: table, __usedCoroutines: { coroutine }, __callbacks: table
}

export type EndResult = {
	reason: string,
	winner: Team,
	mvp: Player
}


local Gamemode: Implementation = { } :: Implementation
Gamemode.__index = Gamemode

export type Gamemode = typeof( setmetatable( { } :: Prototype, { } :: Implementation ) )


function Gamemode.new ( name: string, displayName: string, duration: number ): Gamemode
	local self = setmetatable( { } :: Prototype, Gamemode )
	
	self.duration = duration
	self.timeElapsed = 0
	self.name = name
	self.displayName = displayName
	
	self.tempStorage = { 
		signalConnections = { } 
	}
	
	self.__registeredEvents, self.__usedCoroutines = { }, { }
	
	
	return self
end

function Gamemode:__Fire ( event: string, ... ): nil
	local callback = self.__registeredEvents[event]
	if callback then callback(...) end
end



function Gamemode:RegisterEvent ( event: string, callback: ( ...any ) -> any ): nil
	self.__registered[event] = callback
end

function Gamemode:On ( event: string, callback: ( ...any ) -> any): nil
	self.__registeredEvents[event] = callback
end



function Gamemode:WhileActive ( callback: ( ...any ) -> any, seconds: number?, ...): nil
	local args = ...
	
	self.__registeredEvents['__active'] = coroutine.create(function ( )
		while task.wait(seconds) and self.active do
			callback(args)
		end
	end)
	
	self.__usedCoroutines['__active'] = self.__registeredEvents['__active']
end



function Gamemode:Start ( ... ): nil
	self.active = true
	self:__Fire('start', ...)
	
	if self.__registeredEvents['__active'] then
		coroutine.resume(self.__registeredEvents['__active'])
	end
	
	self.timeElapsed = 0
	
	self.__usedCoroutines['start'] = coroutine.create(function ( )
		while self.timeElapsed <= self.duration and task.wait(1) do
			self.timeElapsed += 1
		end
		
		self:End({ reason = 'Time Limit', winner = utility.Defender, mvp = nil})
	end)

	coroutine.resume(self.__usedCoroutines['start'])
end



function Gamemode:End ( ... ): nil
	self.active = false
	self:__Fire('end', ...)
	
	for i,v in self.__usedCoroutines do
		coroutine.yield(v)
		coroutine.close(v)
	end
	
	for i,v in self.tempStorage.signalConnections do
		print(typeof (v))
		local conn: RBXScriptConnection = v
		conn:Disconnect()
	end
end



return Gamemode
