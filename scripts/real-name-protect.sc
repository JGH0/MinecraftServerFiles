// Prevents fake players from using protected player names
// Protected: r1noa, JGH_Play, Stebii, itzxthunder, typixbrandy
// Load: /script load real-name-protect

__protected = ['r1noa', 'JGH_Play', 'Stebii', 'itzxthunder', 'typixbrandy'];

__on_player_connects(player) -> (
    name = player ~ 'name';
    if (player ~ 'real' == 1, return());
    if (name in __protected,
        print(player, format('r ✘ "%s" is a protected name — cannot create fake player', name));
        exit()
    )
)
