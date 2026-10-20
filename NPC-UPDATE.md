# NPC movement and character update

[Download the updated Studio game](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip). Extract it and open `CookieCorner.rbxlx`.

## Walking fixes

Customers now use short, server-owned pathfinding routes along the public road. Waypoint commands refresh before Roblox's walking timeout. If a route becomes blocked or movement stops making progress, the customer stops and requests another route. Customers pause during bargaining and choose a fresh route afterward, including when the player walks away or a conversation expires.

Customers collide with the map, but not with players, other customers or loose conveyor cookies. They cannot be pushed over by a player or used as a stepping stone. No collision rules between players and the map/cookies have changed. Only an NPC displaced off the road or below the map is repositioned for recovery; normal travel uses Humanoid walking.

NPCs use one consistent local R6 rig instead of replacing the initial character after an avatar-service request. Feet are placed using the actual floor height. Walking animation pairs the left leg with the right arm, blends to rest, and follows horizontal speed. Nearby idle characters gently turn their heads toward the local player. These cosmetic poses run locally, while the server controls movement and interactions.

## Character models

All active NPC roles share fitted sleeves, cuffs, stitched shoes, coordinated clothing and small cookie details. Every accessory follows its body part and has no collision, touch or query surface.

- **Coco:** mint varsity jacket, cookie badge and cap.
- **Hazel:** terracotta cardigan, bob hairstyle and open-frame glasses.
- **Maple:** lavender outfit, scarf and pinned hair bun.
- **Chip:** blue varsity jacket, swept hair and glasses.
- **Ginger:** caramel clothing, knitted hat and cream scarf.
- **Almond:** sage cardigan, chocolate hair and brass accents.
- **Baker Biscuit:** pleated chef hat, cream jacket and stitched mint apron.
- **Bruno Crustforge:** leather apron, rivets, trimmed beard and raised safety goggles.
- **Poppy Crumbkeeper:** new Pack House attendant with a beret and mint/gold uniform. Poppy opens the same pack shop and daily gift as the counter.

The original local models need no new Roblox clothing, mesh, image or animation uploads. Customer personalities and favorite-cookie rolls remain independent of their outfits. Prices, bargaining rewards and save formats are unchanged.

## Updating and testing

Before replacing a customized Studio place, preserve your `AudioConfig` audio IDs, `CardCatalog.ArtSheets`, `ShopCatalog` product/pass IDs, `AssetTextures`, and `AdminConfig` usernames. Publish into the same experience and restart outdated servers. Keep the existing DataStore names.

The automated suite now has **198 Luau tests and 16 Python tests**. Movement regressions cover road boundaries, destination distance, floor-height tolerance, stuck detection, waypoint timeouts, command refresh intervals and opposite-arm/leg poses. Static analysis, compilation and the packager verify **83 source scripts**.

The cloud environment cannot run Roblox's physics, pathfinding service or renderer. Complete this focused Studio test with two clients:

1. Watch all six customers travel and turn for several minutes, especially around the plaza monument. Verify their feet stay above the road and clothing follows their limbs.
2. Start bargaining, wait, sell or walk away, and verify walking resumes. Let a conversation expire and repeat. Another player should see the same customer position.
3. Walk into a customer while they move and while they bargain. They should not tip over or push you. Add a temporary obstacle to the test road and check route recovery; remove it afterward.
4. Inspect Biscuit, Bruno and Poppy from the front and sides. Test their prompts and both market counters. Check labels and animations on mobile and at low graphics quality.
5. Check player-to-world collisions, conveyor transport and hill combat after respawning. Only player-to-customer collision should be disabled.
