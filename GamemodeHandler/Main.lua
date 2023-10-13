local teamDeathMatch = require(script.Parent.GamemodeLogic.TDM)

local module = { }

function module.Main()
	local tdm = teamDeathMatch.new({ game.Players:WaitForChild('kunobypl') }) -- Temp for debugging only.
	
	print('main')
end


return module
