-- Serializable per-player settings, shared by saves, requests, and playback.
local Preferences = { DefaultMusicVolume = 0.24, DefaultEffectsVolume = 0.55 }

function Preferences.validVolume(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Preferences.normalize(raw)
	raw = type(raw) == "table" and raw or {}
	return {
		music = type(raw.music) ~= "boolean" or raw.music,
		effects = type(raw.effects) ~= "boolean" or raw.effects,
		musicVolume = Preferences.validVolume(raw.musicVolume) and math.clamp(raw.musicVolume, 0, 1) or Preferences.DefaultMusicVolume,
		effectsVolume = Preferences.validVolume(raw.effectsVolume) and math.clamp(raw.effectsVolume, 0, 1) or Preferences.DefaultEffectsVolume,
	}
end

function Preferences.update(current, request)
	if type(request) ~= "table" or type(request.music) ~= "boolean" or type(request.effects) ~= "boolean" then return nil end
	local result = Preferences.normalize(current)
	for _, key in ipairs({ "musicVolume", "effectsVolume" }) do
		if request[key] ~= nil then
			if not Preferences.validVolume(request[key]) then return nil end
			result[key] = math.clamp(request[key], 0, 1)
		end
	end
	result.music, result.effects = request.music, request.effects
	return result
end

return Preferences
