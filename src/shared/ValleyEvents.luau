local Events = { HillX = -285, HillZ = 400, HillRadius = 24, CaptureSeconds = 8, PayoutSeconds = 10 }
function Events.onHill(x, y, z) return (x - Events.HillX)^2 + (z - Events.HillZ)^2 <= Events.HillRadius^2 and y >= 7 and y <= 21 end
function Events.damage(pin, attack, defense) return math.max(1, math.floor((10 + math.clamp(pin, 1, 5) * 2 + (attack or 0)) * (1 - math.clamp(defense or 0, 0, .45)))) end
function Events.meteorDelay(roll) return 300 + math.min(1500, math.floor(math.clamp(roll, 0, 1) * 1501)) end
function Events.meteorReward(roll) return 100 + math.min(250, math.floor(math.clamp(roll, 0, 1) * 251)) end
return Events
