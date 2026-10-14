#!/bin/bash
# Runs inside the Minecraft container (itzg image has rcon-cli + cron built in)

# Wait 5s for server to be ready before first message
sleep 5

rcon-cli say "§6[Server] §eServer restart in 5 minute(s)! §7Save your builds."
sleep 120

rcon-cli say "§6[Server] §eServer restart in 3 minute(s)! §7Save your builds."
sleep 120

rcon-cli say "§6[Server] §eServer restart in 1 minute(s)! §7Save your builds."
sleep 50

rcon-cli say "§6[Server] §cServer restarting NOW! §eSee you in a minute ✨"
sleep 10

rcon-cli stop
