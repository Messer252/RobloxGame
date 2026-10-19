# Give yourself and friends admin access

**`unbenator` is already configured as an admin.** Open the updated [Studio ZIP](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip), extract it, and open `CookieCorner.rbxlx` in Roblox Studio.

## Add friends by username

1. With the playtest stopped, open **Explorer → ServerScriptService → Tycoon → AdminConfig**.
2. Add each friend's **Roblox account username** inside `Usernames`, with quotes and a comma:

   ```lua
   Usernames = {
       "unbenator",
       "FriendUsername",
       "AnotherFriend",
   },
   ```

   Replace the friend examples with their real account usernames. Use the name after `@` on their Roblox profile, not their display name. Capitalization does not matter. The server resolves these names through Roblox to numeric account IDs.

3. Publish the place to your existing game's start place.
4. Restart outdated servers and rejoin with the configured account. Friends join the same published experience using their own accounts.
5. Open **Bakery → Admin tools**. Only recognized admins see that entry. It may take a moment while Roblox resolves the configured usernames.

To remove a friend, delete their entry, publish, and restart outdated servers. Admin membership comes from this server configuration, not player save files. There is no public command or client request that can add admins.

## Available tools

Select an online account by its `@username`, then use:

| Tool | Result |
| --- | --- |
| Return player to spawn | Sends them to their claimed bakery's spawn, or the central plaza if they have no plot |
| Kick player | Removes them from the current server after a second confirmation click; they can rejoin |
| Teleport to player | Moves your character beside the selected player |
| Bring player to me | Moves the selected player beside you |
| Add amount to wallet | Adds exactly the entered cash amount to their spendable wallet |
| Add amount to ready earnings | Adds exactly the entered amount to their uncollected earnings, ready to collect |
| My invisibility | Hides/restores your own character; does not require selecting a player |

Admins cannot kick themselves or another admin with these tools. Teleports need living characters. Invisibility hides body parts, accessories, face textures, nameplates, and character visual effects; it retains normal collisions, sounds, and vulnerability. It stays active through respawns in that server, then resets when you leave. Tools equipped while invisible are hidden and restored when unequipped or when visibility returns.

Cash grants require a loaded, available profile. Enter a **positive whole number**; the default maximum is **1,000,000,000 per action**, configurable through `MaxCashGrant`. The server rejects the entire grant if the chosen balance has insufficient space. Income boosts do not multiply admin gifts. A gift changes only the chosen cash balance; it does not grant Robux, paid upgrades, Golden Chips, recipes, or rebirths.

Cash grants queue an early save after about two seconds and are included in normal/final saves. They follow the normal cash reset on rebirth. In a Studio session marked **Preview / not saved**, admin gifts are also temporary. If a profile is loading, saving, or completing a purchase, wait and retry a rejected gift.

## Ownership and stable account IDs

`AutoExperienceOwner = true` automatically recognizes the user who owns a **personally owned experience**. It does not treat a Roblox group ID as a user ID or make group members admins. Group-owned games use the explicit username/ID list, including the configured `unbenator` entry.

For access that survives a friend's username change, move them from `Usernames` into `UserIds` using the numeric account ID from their Roblox profile URL:

```lua
Usernames = { "unbenator" },
UserIds = {
    123456789, -- Replace with your friend's real numeric account ID.
},
```

User IDs identify the same account after a rename. Username entries are resolved again when a server starts, so update/remove old names if someone renames. The same account can appear in both lists, but an ID-only entry is the stable choice.

## Check before sharing

- Join as `unbenator` and a normal player: only the admin should see Admin tools. Test with real accounts in a restricted published experience; Studio's simulated multiplayer accounts can have negative IDs that do not match your real account.
- Test kick cancellation, kick confirmation, spawn return, teleport, and bring-player. Confirm another admin cannot be kicked.
- Grant wallet cash and ready earnings separately. Check the exact amount, invalid amounts, the configured limit, busy-profile rejection, and a full balance. Wait for a save, rejoin, and verify persistence. Rebirth should reset gifted cash normally.
- Toggle invisibility, reset, equip/unequip a tool, then turn it off. Verify the original transparency, accessories, nameplate, and effects restore for other clients too.
- Check mobile/controller controls, player departure during selection, and all eight players in the list.
- If the menu is missing, check the username, the latest published start place, and server Output for **Cookie Corner admin setup** warnings. Invalid/unavailable lookups do not grant access; correct the config or retry in a restarted server.

All requests are checked against a server-owned account-ID set, with a one-second cooldown. Client attributes and hidden buttons do not authorize actions. Successful actions are logged in server Output with the acting account, target, action, and cash amount where applicable. Roblox engine tests are still required for the UI, live name lookup, character appearance, teleporting, and kick behavior.
