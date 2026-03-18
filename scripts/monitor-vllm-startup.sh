#!/bin/bash
# Monitor vLLM 70B startup progress

echo "Monitoring vLLM 70B startup..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to check if server is ready
check_ready() {
    if curl -s http://localhost:8000/health 2>&1 | grep -q "200 OK"; then
        return 0
    else
        return 1
    fi
}

# Monitor loop
start_time=$(date +%s)
while true; do
    elapsed=$(($(date +%s) - start_time))
    elapsed_min=$((elapsed / 60))
    elapsed_sec=$((elapsed % 60))

    # Clear screen and show status
    clear
    echo "═══════════════════════════════════════════════════════════"
    echo "  vLLM 70B Startup Monitor"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Elapsed time: ${elapsed_min}m ${elapsed_sec}s"
    echo ""

    # Check if ready
    if check_ready; then
        echo "✅ STATUS: READY AND RESPONDING"
        echo ""
        echo "Server is healthy and accepting requests!"
        echo ""
        echo "Next steps:"
        echo "  ./bin/tt-claw restart   # Restart OpenClaw gateway"
        echo "  ./bin/tt-claw tui       # Test in TUI"
        break
    else
        echo "⏳ STATUS: WARMING UP"
        echo ""
        echo "Recent log entries:"
        echo "───────────────────────────────────────────────────────────"
        docker logs tt-inference-server-70b 2>&1 | tail -8
        echo "───────────────────────────────────────────────────────────"
        echo ""
        echo "Typical phases (10-30 minutes total):"
        echo "  1. Hardware init        (~1 min)  ✅ Should be done"
        echo "  2. Model weight loading (~10 min) ← Likely here (silent)"
        echo "  3. Trace compilation    (~20 min) ← Or here (silent)"
        echo "  4. Ready                (done!)"
        echo ""
        echo "Checking again in 30 seconds..."
    fi

    sleep 30
done
