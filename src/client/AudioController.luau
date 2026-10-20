local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.CookieTycoon.AudioConfig)
local Score = require(ReplicatedStorage.CookieTycoon.MusicScore)
local Preferences = require(ReplicatedStorage.CookieTycoon.AudioPreferences)
local Delivery = require(script.Parent.PreferenceDelivery)
local AudioController = {}
AudioController.__index = AudioController

local function assetId(value)
	if type(value) ~= "number" or value <= 0 or value % 1 ~= 0 or value >= 2 ^ 53 then return nil end
	return "rbxassetid://" .. value
end

local function group(name, parent)
	local object = Instance.new("SoundGroup")
	object.Name = name
	object.Volume = 0
	object.Parent = parent
	return object
end

local function sound(name, id, soundGroup, parent)
	local object = Instance.new("Sound")
	object.Name = name
	object.SoundId = id
	object.SoundGroup = soundGroup
	object.Volume = 0
	object.Parent = parent
	return object
end

function AudioController.start(player, requestAction)
	local self = setmetatable({
		player = player, requestAction = requestAction, music = true, effects = true,
		musicVolume = Preferences.DefaultMusicVolume, effectsVolume = Preferences.DefaultEffectsVolume,
		musicStatus = Config.FallbackMusicEnabled and "Ready" or "Unconfigured",
		ready = false, dirty = false, alive = true,
		musicCursor = 0, effectCursor = 0, noteIndex = 1, epoch = os.clock(),
		lastCues = {}, connections = {}, voices = {}, samples = {}, ovenVoices = {}, effectEpoch = 0,
	}, AudioController)
	self.delivery = Delivery.new(function(preferences) requestAction:FireServer("SetAudioPreferences", preferences) end)
	table.insert(self.connections, requestAction.Parent:WaitForChild("AudioPreferencesAck").OnClientEvent:Connect(function(revision)
		if self.delivery:Acknowledge(revision) then self.dirty = false end
	end))
	self.folder = Instance.new("Folder")
	self.folder.Name = "CookieCornerAudio"
	self.folder.Parent = SoundService
	self.Changed = Instance.new("BindableEvent")
	self.Changed.Parent = self.folder
	self.musicGroup = group("Music", self.folder)
	self.effectsGroup = group("Effects", self.folder)
	local equalizer = Instance.new("EqualizerSoundEffect")
	equalizer.Name = "WarmSampler"
	equalizer.HighGain = -40
	equalizer.MidGain = -18
	equalizer.LowGain = -2
	-- Filter only the local sampler; the optional original recording is already mixed.
	for index = 1, 20 do
		local isMusic = index <= 12
		local voiceSound = sound("Chime" .. index, Config.BundledChime, isMusic and self.musicGroup or self.effectsGroup, self.folder)
		if isMusic then equalizer:Clone().Parent = voiceSound end
		self.voices[index] = {
			sound = voiceSound,
			generation = 0,
		}
	end
	equalizer:Destroy()
	for name, id in pairs(Config.Effects) do
		local uri = assetId(id)
		if uri then self.samples[name] = sound(name, uri, self.effectsGroup, self.folder) end
	end
	for index, id in ipairs(Config.OvenPurchaseVoices or {}) do
		local uri = assetId(id)
		if uri then table.insert(self.ovenVoices, sound("BubbyCookieCookie" .. index, uri, self.effectsGroup, self.folder)) end
	end
	local musicUri = assetId(Config.MusicAssetId)
	if musicUri then
		self.musicStatus = "Loading"
		self.track = sound(Config.MusicName, musicUri, self.musicGroup, self.folder)
		self.track.Looped = true
		self.track.Volume = 1
		table.insert(self.connections, self.track.Loaded:Connect(function()
			if not self.alive then return end
			self.musicStatus = "Ready"
			self.Changed:Fire()
			self:_stopVoices(true)
			if self.ready and self.music then self.track:Play() end
		end))
	end

	local function loadPreferences()
		if self.ready or not player:GetAttribute("DataReady") then return end
		self.ready = true
		if not self.musicTouched then self.music = player:GetAttribute("MusicEnabled") ~= false end
		if not self.effectsTouched then self.effects = player:GetAttribute("EffectsEnabled") ~= false end
		local saved = Preferences.normalize({ musicVolume = player:GetAttribute("MusicVolume"), effectsVolume = player:GetAttribute("EffectsVolume") })
		if not self.musicVolumeTouched then self.musicVolume = saved.musicVolume end
		if not self.effectsVolumeTouched then self.effectsVolume = saved.effectsVolume end
		self.epoch = os.clock()
		self:_apply()
		if self.dirty then self:_queueSave() end
	end
	table.insert(self.connections, player:GetAttributeChangedSignal("DataReady"):Connect(loadPreferences))
	loadPreferences()
	table.insert(self.connections, RunService.Heartbeat:Connect(function()
		self.delivery:Step(os.clock(), self.ready and player:GetAttribute("DataReady") == true and player:GetAttribute("PurchasePending") ~= true)
		if not Config.FallbackMusicEnabled or not self.ready or not self.music or self.musicVolume == 0 or (self.track and self.track.IsLoaded) then return end
		local secondsPerBeat = 60 / Score.BPM
		local elapsed = (os.clock() - self.epoch) / secondsPerBeat
		if elapsed >= Score.Beats then
			self.epoch += math.floor(elapsed / Score.Beats) * Score.Beats * secondsPerBeat
			elapsed %= Score.Beats
			self.noteIndex = 1
		end
		while self.noteIndex <= #Score.Notes and Score.Notes[self.noteIndex][1] <= elapsed do
			local note = Score.Notes[self.noteIndex]
			-- Skip stale notes after a stalled frame instead of playing a burst.
			if (elapsed - note[1]) * secondsPerBeat < 0.12 then
				self:_tone(note[2], note[3] * secondsPerBeat, note[4], true)
			end
			self.noteIndex += 1
		end
	end))
	task.spawn(function()
		local preload = { self.voices[1].sound }
		if self.track then table.insert(preload, self.track) end
		for _, sample in pairs(self.samples) do table.insert(preload, sample) end
		for _, voice in ipairs(self.ovenVoices) do table.insert(preload, voice) end
		pcall(function() ContentProvider:PreloadAsync(preload) end)
		if self.alive and #self.ovenVoices > 0 then
			local loaded = false
			for _, voice in ipairs(self.ovenVoices) do if voice.IsLoaded then loaded = true end end
			if not loaded then warn("Cookie Corner: Bubby's oven voices could not load. Check audio IDs, moderation and experience permissions; the normal purchase cue remains available. See AUDIO.md.") end
		end
		if self.alive and not self.voices[1].sound.IsLoaded then
			warn("Cookie Corner: bundled chime unavailable. Upload the included WAVs and configure AudioConfig for this experience.")
		end
		if self.alive and self.track and not self.track.IsLoaded then
			self.musicStatus = Config.FallbackMusicEnabled and "Fallback" or "Unavailable"
			self.Changed:Fire()
			warn("Cookie Corner: optional full-mix music needs its Roblox audio ID and experience permission. See AUDIO.md.")
		end
	end)
	return self
end

function AudioController:_stopVoices(music)
	for index = music and 1 or 13, music and 12 or 20 do
		local voice = self.voices[index]
		voice.generation += 1
		if voice.attack then voice.attack:Cancel() end
		if voice.fade then voice.fade:Cancel() end
		voice.sound:Stop()
	end
end

function AudioController:_tone(midi, duration, volume, music)
	if not self.alive or (music and not self.music) or (not music and not self.effects) then return end
	local cursor
	if music then
		self.musicCursor = self.musicCursor % 12 + 1
		cursor = self.musicCursor
	else
		self.effectCursor = self.effectCursor % 8 + 1
		cursor = self.effectCursor + 12
	end
	local voice = self.voices[cursor]
	voice.generation += 1
	local generation = voice.generation
	if voice.attack then voice.attack:Cancel() end
	if voice.fade then voice.fade:Cancel() end
	voice.sound:Stop()
	voice.sound.PlaybackSpeed = 2 ^ ((midi - Config.ChimeMidi) / 12)
	voice.sound.Volume = music and 0 or volume
	voice.sound.TimePosition = 0
	voice.sound:Play()
	if music then
		-- Remove the ping's sharp onset and let the low notes bloom quietly.
		voice.attack = TweenService:Create(voice.sound, TweenInfo.new(Config.MusicAttackSeconds), { Volume = volume })
		voice.attack:Play()
	end
	local release = music and Config.MusicReleaseSeconds or 0.06
	task.delay(math.max(0.03, duration - release), function()
		if not self.alive or voice.generation ~= generation then return end
		if voice.attack then voice.attack:Cancel() end
		voice.fade = TweenService:Create(voice.sound, TweenInfo.new(release), { Volume = 0 })
		voice.fade:Play()
		task.delay(release + 0.01, function()
			if self.alive and voice.generation == generation then voice.sound:Stop() end
		end)
	end)
end

function AudioController:_apply()
	if self.musicFade then self.musicFade:Cancel() end
	if self.effectsFade then self.effectsFade:Cancel() end
	self.musicFade = TweenService:Create(self.musicGroup, TweenInfo.new(0.08), { Volume = self.ready and self.music and self.musicVolume or 0 })
	self.effectsFade = TweenService:Create(self.effectsGroup, TweenInfo.new(0.08), { Volume = self.ready and self.effects and self.effectsVolume or 0 })
	self.musicFade:Play()
	self.effectsFade:Play()
	if not self.music then
		self:_stopVoices(true)
		if self.track then self.track:Pause() end
	elseif self.ready and self.track and self.track.IsLoaded then
		self.track:Resume()
		if not self.track.IsPlaying then self.track:Play() end
	end
	if not self.effects then
		self:_stopVoices(false)
		for _, sample in pairs(self.samples) do sample:Stop() end
		for _, voice in ipairs(self.ovenVoices) do voice:Stop() end
	end
	self.Changed:Fire()
end

function AudioController:_queueSave()
	self.delivery:Queue({
		music = self.music, effects = self.effects,
		musicVolume = self.musicVolume, effectsVolume = self.effectsVolume,
	}, os.clock())
end

function AudioController:SetMusicEnabled(enabled)
	self.musicTouched = true
	self.music = enabled == true
	self.dirty = true
	self:_apply()
	self:_queueSave()
end

function AudioController:SetEffectsEnabled(enabled)
	self.effectsTouched = true
	self.effects = enabled == true
	if not self.effects then self.effectEpoch += 1 end
	self.dirty = true
	self:_apply()
	self:_queueSave()
end

function AudioController:SetVolume(channel, value)
	if (channel ~= "music" and channel ~= "effects") or not Preferences.validVolume(value) then return end
	self[channel .. "VolumeTouched"] = true
	self[channel .. "Volume"] = math.floor(math.clamp(value, 0, 1) * 100 + 0.5) / 100
	self.dirty = true
	self:_apply()
	self:_queueSave()
end

function AudioController:_playOvenVoice()
	local loaded, fresh = {}, {}
	for _, voice in ipairs(self.ovenVoices) do
		if voice.IsLoaded then
			table.insert(loaded, voice)
			if voice.SoundId ~= self.lastOvenVoice then table.insert(fresh, voice) end
		end
	end
	-- Avoid an immediate repeat when another recording is ready. Unavailable
	-- recordings never delay a purchase or suppress the normal fallback cue.
	local choices = #fresh > 0 and fresh or loaded
	if #choices == 0 then return false end
	local chosen = choices[math.random(#choices)]
	for _, voice in ipairs(self.ovenVoices) do voice:Stop() end
	self.lastOvenVoice = chosen.SoundId
	chosen.Volume, chosen.PlaybackSpeed, chosen.TimePosition = .8, 1, 0
	chosen:Play()
	return true
end

function AudioController:PlayCue(name)
	local cue = Score.Cues[name]
	if not self.alive or not self.ready or not self.effects or self.effectsVolume == 0 or not cue then return end
	local now = os.clock()
	if now - (self.lastCues[name] or -math.huge) < (name == "Click" and 0.06 or 0.18) then return end
	self.lastCues[name] = now
	if name == "BuyRecipe" and self:_playOvenVoice() then return end
	local sample = self.samples[name]
	if sample and sample.IsLoaded then
		sample.Volume = name == "Click" and 0.35 or 0.8
		sample:Stop()
		sample:Play()
		return
	end
	local epoch = self.effectEpoch
	for _, note in ipairs(cue) do
		task.delay(note[1], function()
			if self.alive and self.effectEpoch == epoch then self:_tone(note[2], note[3], note[4], false) end
		end)
	end
end

function AudioController:Destroy()
	self.alive = false
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	self.folder:Destroy()
end

return AudioController
