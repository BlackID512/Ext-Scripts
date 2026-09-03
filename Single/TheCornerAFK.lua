-- Auto Kick not Friend
-- The Corner Private Server Only

function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

cloneref = missing("function", cloneref, function(...) return ... end)
Services = setmetatable({}, {
	__index = function(self, name)
		local success, cache = pcall(function()
			return cloneref(game:GetService(name))
		end)
		if success then
			rawset(self, name, cache)
			return cache
		else
			error("Invalid Service: " .. tostring(name))
		end
	end
})

Players = Services.Players
ReplicatedStorage = Services.ReplicatedStorage

local me = Players.LocalPlayer
local target = nil
local name = nil
local message = "Halo, aku lagi AFK. (Ini pesan otomatis)"

local TextChatService = game:GetService("TextChatService")
function chatMessage(str)
	str = tostring(str)
	if not isLegacyChat then
		TextChatService.TextChannels.RBXGeneral:SendAsync(str)
	else
		ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		target = player
		name = player.Name
		message = "/ban "..name
		if target:IsFriendsWith(me.UserId) then
			message = "Halo ".. target.DisplayName .. ", aku lagi AFK. (Ini pesan otomatis)"
		end
		chatMessage(message)
		wait(0.1)
		target = nil
	end)
end)
