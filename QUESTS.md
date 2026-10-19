# Baker Biscuit's treasure hunts

Meet **Baker Biscuit**, the friendly chef beside the central spawn plaza. He offers four short scavenger hunts with **12 original hidden treasures** around the public paths, benches, and meadow. You never need access to somebody else's bakery to finish a hunt.

## How to play

1. Approach Baker Biscuit and use **Talk**. Open the **Quests** tab if needed.
2. Accept the current hunt while standing near him. The tracker lists three items, a short clue for each, and the cash reward.
3. Explore the map. When you find a treasure, use its **Find** interaction. It is an instant press or tap; there is no hold timer.
4. Check the tracker for the remaining clues. Once all three items are found, return to Baker Biscuit and choose **Claim**.
5. Accept his next hunt when you are ready.

You can open the Quests tab anywhere to check your clues. Accepting a hunt or collecting its reward requires standing beside Baker Biscuit.

| Hunt | Treasures | Cash reward |
| --- | --- | --- |
| Plaza Peek | 3 | $500 |
| Baker's Trail | 3 | $2,500 |
| Sweet Detour | 3 | $15,000 |
| Biscuit's Treasure | 3 | $75,000 |

Each hunt pays **once per player**. There are no purchase requirements, random rewards, or repeatable cash claims. Completing all four earns $93,000 in total.

## Your progress

- Each player has their own hunt progress. Finding an item hides it for you while leaving it available to other players.
- Your current hunt, discovered items, and completed hunts save with your bakery profile. They survive leaving, changing servers, and rebirthing.
- A found treasure counts once. Treasures from another hunt do not count toward your current hunt.
- Rewards go into your wallet. If the wallet reaches its limit, the rest goes into your collection register. If both balances are full, the completed hunt waits until there is room for the entire reward.
- Studio session-only previews do not save hunt progress, just like other bakery progress.

## Studio checks before publishing

Start a two-player **Server & Clients** test. Have both players accept the first hunt and find the same item. Check that it disappears only for the player who found it, each tracker shows its own progress, and both players can finish. Check the Find interaction using the mobile simulator too.

Finish a hunt, claim its reward, and interact again to confirm it starts the next hunt without paying again. Leave during a hunt and rejoin the same saved experience to check that the found items stay found. Confirm a rebirth keeps the current hunt and completed rewards.

The server checks that a character is alive and beside the actual treasure before crediting a discovery. It also checks NPC distance before starting or paying a hunt. The client supplies no reward amount or discovery count.

## Updating an existing game

Keep the current `DataStoreName` in **ServerScriptService → Tycoon → Settings**. Existing profiles migrate automatically from save formats 1–3 to **format 4**, which includes hunt progress and preserves purchase receipts.

After publishing, restart outdated servers so everyone uses the new save format. Older game versions must not write newer profiles, because that could lose completion history or allow a reward to repeat. The new profile loader deliberately refuses a save format newer than it understands.

## Changing the hunts

The definitions are in **ReplicatedStorage → CookieTycoon → ChallengeCatalog**. The server-built NPC and treasures are in **ServerScriptService → Tycoon → ChallengeWorld**.

Keep existing hunt IDs, item IDs, and the existing hunt order stable once players have saved progress. Reordering or replacing existing hunts changes what a saved index means. Append future hunts at the end and review save-format compatibility before deploying changes to saved progress.

The current [Workshop update](WORKSHOP.md) removes item waypoints, arrows, distances, and guide beams. Biscuit gives randomized mining, selling, eating, gifting, baking, obby, and occasional search jobs. Earlier active hunts still finish using the clues below.
