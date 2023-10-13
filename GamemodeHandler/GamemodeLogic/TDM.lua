Players = game:GetService('Players')
ServerScriptService = game:GetService('ServerScriptService')


local gamemodes = script.Parent
local Gamemode = require(gamemodes.Gamemode)

local utility = require(ServerScriptService.Utility)



type Implementation = {
	__index: Implementation,
	new: (activePlayers: { Player } ) -> TDM,
	
	HandleStarted: ( self: TDM, activePlayers: { Player } ) -> nil,
	HandleEnded: ( self: TDM ) -> nil,
	
	AddPlayer: ( self: TDM, players: { Player } | Player ) -> nil,
	RemovePlayer: ( self: TDM, players: { Player } | Player ) -> nil,
	PlayerAdded: ( self: TDM, player: Player ) -> nil,
	PlayerRemoving: ( self: TDM, player: Player ) -> nil
}

type Prototype = {
	gamemode: Gamemode.Gamemode,
	activePlayers: { Player },
	spectators: { Player },
	roundNumber: number,
	roundInProgress: boolean
}



local TDM: Implementation = { } :: Implementation
TDM.__index = TDM

export type TDM = typeof ( setmetatable( { } :: Prototype, { } :: Implementation ) )


function TDM.new ( activePlayers: { Player } ): TDM
	local self = setmetatable( { } :: Prototype, TDM )
	self.gamemode = Gamemode.new('TDM', 'Team Deathmatch', 15)


	self.gamemode:On('start', self.HandleStarted)
	self.gamemode:On('end', self.HandleEnded)
	
	
	self.gamemode:Start(self, activePlayers) 
	self.activePlayers, self.spectators = { }, { }
	
	self.roundNumber = 1
	self.roundInProgress = false
	
	
	return self
end



function TDM:AddPlayer ( players: { Player } | Player ): nil
	self.activePlayers = self.activePlayers or { }
	
	if typeof (players) == 'table' then
		for i,v in players do self.activePlayers[v] = v end
	else
		self.activePlayers[players] = players
	end
end



function TDM:RemovePlayer ( players: { Player } | Player ): nil
	self.activePlayers = self.activePlayers or { }
	
	if typeof (players) == 'table' then
		for i,v in players do self.activePlayers[v] = nil end
	else
		self.activePlayers[players] = nil
	end
end



function TDM:HandleEnded ( reason: EndResult ): nil
	print(reason)
end



function TDM:HandleStarted ( activePlayers: { Player } ): nil
	-- Add all the current players to the table.
	self:AddPlayer(activePlayers)
	
	for i,v in self.activePlayers do
		local character = if not v.Character or not v.Character.Parent then v.CharacterAdded:Wait() else v.Character
		local humanoid: Humanoid = character:WaitForChild('Humanoid')
		
		self.gamemode.tempStorage.signalConnections[v] = humanoid.Died:Connect(function()
			self.activePlayers[v] = nil
			self.spectators[v] = nil
		end)
	end
	
	
	self.gamemode.tempStorage.signalConnections['plrAdded'] = Players.PlayerAdded:Connect(function(player: Player)
		self:PlayerAdded(player)
	end)
	
	
	self.gamemode.tempStorage.signalConnections['plrRemoving'] = Players.PlayerRemoving:Connect(function(player: Player)
		self:PlayerRemoving(player)
	end)
end



function TDM:PlayerAdded ( player: Player ): nil
	if self.roundInProgress then
		self.spectators[player] = player
	else
		self.activePlayers[player] = player
	end
end



function TDM:PlayerRemoving ( player: Player ): nil
	self.spectators[player] = nil
	self.activePlayers[player] = nil
end



return TDM
