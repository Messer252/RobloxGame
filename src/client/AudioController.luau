local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.CookieTycoon.AudioConfig)
local Score = require(ReplicatedStorage.CookieTycoon.MusicScore)
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
		ready = false, dirty = false, alive = true, revision = 0,
		musicCursor = 0, effectCursor = 0, noteIndex = 1, epoch = os.clock(),
		lastCues = {}, connections = {}, voices = {}, samples = {}, effectEpoch = 0,
	}, AudioController)
	self.folder = Instance.new("Folder")
	self.folder.Name = "CookieCornerAudio"
	self.folder.Parent = SoundService
	self.Changed = Instance.new("BindableEvent")
	self.Changed.Parent = self.folder
	self.musicGroup = group("Music", self.folder)
	self.effectsGroup = group("Effects", self.folder)
	local equalizer = Instance.new("EqualizerSoundEffect")
	equalizer.HighGain = -8
	equalizer.MidGain = -2
	equalizer.Parent = self.musicGroup
	for index = 1, 20 do
		local isMusic = index <= 12
		self.voices[index] = {
			sound = sound("Chime" .. index, Config.BundledChime, isMusic and self.musicGroup or self.effectsGroup, self.folder),
			generation = 0,
		}
	end
	for name, id in pairs(Config.Effects) do
		local uri = assetId(id)
		if uri then self.samples[name] = sound(name, uri, self.effectsGroup, self.folder) end
	end
	local musicUri = assetId(Config.MusicAssetId)
	if musicUri then
		self.track = sound("Cookie Corner Cafe", musicUri, self.musicGroup, self.folder)
		self.track.Looped = true
		self.track.Volume = 1
		table.insert(self.connections, self.track.Loaded:Connect(function()
			if not self.alive then return end
			self:_stopVoices(true)
			if self.ready and self.music then self.track:Play() end
		end))
	end

	local function loadPreferences()
		if self.ready or not player:GetAttribute("DataReady") then return end
		self.ready = true
		if not self.musicTouched then self.music = player:GetAttribute("MusicEnabled") ~= false end
		if not self.effectsTouched then self.effects = player:GetAttribute("EffectsEnabled") ~= false end
		self.epoch = os.clock()
		self:_apply()
		if self.dirty then self:_queueSave() end
	end
	table.insert(self.connections, player:GetAttributeChangedSignal("DataReady"):Connect(loadPreferences))
	loadPreferences()
	table.insert(self.connections, RunService.Heartbeat:Connect(function()
		if not self.ready or not self.music or (self.track and self.track.IsLoaded) then return end
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
		pcall(function() ContentProvider:PreloadAsync(preload) end)
		if self.alive and not self.voices[1].sound.IsLoaded then
			warn("Cookie Corner: bundled chime unavailable. Upload the included WAVs and configure AudioConfig for this experience.")
		end
	end)
	return self
end

function AudioController:_stopVoices(music)
	for index = music and 1 or 13, music and 12 or 20 do
		local voice = self.voices[index]
		voice.generation += 1
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
	if voice.fade then voice.fade:Cancel() end
	voice.sound:Stop()
	voice.sound.PlaybackSpeed = 2 ^ ((midi - Config.ChimeMidi) / 12)
	voice.sound.Volume = volume
	voice.sound.TimePosition = 0
	voice.sound:Play()
	task.delay(math.max(0.03, duration - 0.06), function()
		if not self.alive or voice.generation ~= generation then return end
		voice.fade = TweenService:Create(voice.sound, TweenInfo.new(0.06), { Volume = 0 })
		voice.fade:Play()
		task.delay(0.07, function()
			if self.alive and voice.generation == generation then voice.sound:Stop() end
		end)
	end)
end

function AudioController:_apply()
	TweenService:Create(self.musicGroup, TweenInfo.new(0.15), {
		Volume = self.ready and self.music and Config.MusicVolume or 0,
	}):Play()
	TweenService:Create(self.effectsGroup, TweenInfo.new(0.1), {
		Volume = self.ready and self.effects and Config.EffectsVolume or 0,
	}):Play()
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
	end
	self.Changed:Fire()
end

function AudioController:_queueSave()
	self.revision += 1
	local revision = self.revision
	local function send()
		if not self.alive or revision ~= self.revision or not self.dirty then return end
		if not self.ready or self.player:GetAttribute("PurchasePending") == true then
			task.delay(1, send)
			return
		end
		self.requestAction:FireServer("SetAudioPreferences", { music = self.music, effects = self.effects })
		self.dirty = false
	end
	task.delay(0.4, send)
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

function AudioController:PlayCue(name)
	local cue = Score.Cues[name]
	if not self.alive or not self.ready or not self.effects or not cue then return end
	local now = os.clock()
	if now - (self.lastCues[name] or -math.huge) < (name == "Click" and 0.06 or 0.18) then return end
	self.lastCues[name] = now
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
