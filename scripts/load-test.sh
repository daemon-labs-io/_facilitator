#!/usr/bin/env bash
set -euo pipefail

# Load test: simulates concurrent file downloads or Docker image pulls
#
# Usage:
#   ./scripts/load-test.sh file  <url>   [clients]
#   ./scripts/load-test.sh pull  <image>  [clients]
#
# Examples:
#   ./scripts/load-test.sh file https://files.labs.dae.mn/image.tar 20
#   ./scripts/load-test.sh pull registry.labs.dae.mn/workshop/app:latest 20

MODE="${1:?Usage: $0 <file|pull> <url|image> [clients]}"
TARGET="${2:?Usage: $0 <file|pull> <url|image> [clients]}"
CLIENTS="${3:-20}"
RESULTS_DIR=$(mktemp -d)
trap 'rm -rf "$RESULTS_DIR"' EXIT

format_duration() {
    local ms=$1
    if [ "$ms" -ge 60000 ]; then
        printf "%dm %ds" $((ms / 60000)) $(( (ms % 60000) / 1000 ))
    elif [ "$ms" -ge 1000 ]; then
        printf "%d.%03ds" $((ms / 1000)) $((ms % 1000))
    else
        printf "%dms" "$ms"
    fi
}

now_ms() {
    date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))'
}

case "$MODE" in
    file)
        echo "Load test: $CLIENTS concurrent file downloads"
        echo "URL: $TARGET"
        echo "---"

        for i in $(seq 1 "$CLIENTS"); do
            (
                start=$(now_ms)
                http_code=$(curl -s -o /dev/null -w "%{http_code}" --insecure "$TARGET")
                end=$(now_ms)
                duration_ms=$((end - start))
                echo "$i $duration_ms $http_code" > "$RESULTS_DIR/client_$i"
            ) &
        done
        ;;

    pull)
        echo "Load test: $CLIENTS concurrent Docker pulls"
        echo "Image: $TARGET"
        echo "---"

        for i in $(seq 1 "$CLIENTS"); do
            (
                # Remove the image first to force a full pull
                docker image rm "$TARGET" >/dev/null 2>&1 || true

                start=$(now_ms)
                if docker pull "$TARGET" >/dev/null 2>&1; then
                    status="ok"
                else
                    status="fail"
                fi
                end=$(now_ms)
                duration_ms=$((end - start))

                # Get image size
                size=$(docker image inspect "$TARGET" --format='{{.Size}}' 2>/dev/null || echo "0")
                echo "$i $duration_ms $status $size" > "$RESULTS_DIR/client_$i"
            ) &
        done
        ;;

    *)
        echo "Unknown mode: $MODE"
        echo "Usage: $0 <file|pull> <url|image> [clients]"
        exit 1
        ;;
esac

echo "Waiting for $CLIENTS operations to complete..."
wait
echo "---"

# Collect and display results
total_ms=0
min_ms=999999999
max_ms=0
failures=0

if [ "$MODE" = "file" ]; then
    printf "%-8s %-12s %-8s\n" "Client" "Time" "Status"
    printf "%-8s %-12s %-8s\n" "------" "----" "------"

    for i in $(seq 1 "$CLIENTS"); do
        read -r client duration_ms http_code < "$RESULTS_DIR/client_$i"

        [ "$http_code" != "200" ] && failures=$((failures + 1))
        total_ms=$((total_ms + duration_ms))
        [ "$duration_ms" -lt "$min_ms" ] && min_ms=$duration_ms
        [ "$duration_ms" -gt "$max_ms" ] && max_ms=$duration_ms

        printf "%-8s %-12s %-8s\n" "$client" "$(format_duration "$duration_ms")" "$http_code"
    done
else
    printf "%-8s %-12s %-10s %-8s\n" "Client" "Time" "Size" "Status"
    printf "%-8s %-12s %-10s %-8s\n" "------" "----" "----" "------"

    for i in $(seq 1 "$CLIENTS"); do
        read -r client duration_ms status size < "$RESULTS_DIR/client_$i"

        [ "$status" != "ok" ] && failures=$((failures + 1))
        total_ms=$((total_ms + duration_ms))
        [ "$duration_ms" -lt "$min_ms" ] && min_ms=$duration_ms
        [ "$duration_ms" -gt "$max_ms" ] && max_ms=$duration_ms

        size_mb=$((size / 1048576))
        printf "%-8s %-12s %-10s %-8s\n" "$client" "$(format_duration "$duration_ms")" "${size_mb}MB" "$status"
    done
fi

avg_ms=$((total_ms / CLIENTS))

echo "---"
echo "Summary"
echo "  Clients:  $CLIENTS"
echo "  Failures: $failures"
printf "  Fastest:  %s\n" "$(format_duration "$min_ms")"
printf "  Slowest:  %s\n" "$(format_duration "$max_ms")"
printf "  Average:  %s\n" "$(format_duration "$avg_ms")"

# Throughput estimate for file mode
if [ "$MODE" = "file" ]; then
    file_size=$(curl -sI --insecure "$TARGET" | grep -i content-length | awk '{print $2}' | tr -d '\r')
    if [ -n "$file_size" ] && [ "$file_size" -gt 0 ] 2>/dev/null; then
        size_mb=$((file_size / 1048576))
        if [ "$avg_ms" -gt 0 ]; then
            avg_mbps=$(( (file_size * 8) / (avg_ms * 1000) ))
            total_mbps=$(( (file_size * 8 * CLIENTS) / (max_ms * 1000) ))
            echo "  File:       ${size_mb}MB"
            echo "  Avg/client: ${avg_mbps} Mbps"
            echo "  Aggregate:  ${total_mbps} Mbps"
        fi
    fi
fi

# Throughput estimate for pull mode
if [ "$MODE" = "pull" ]; then
    size=$(head -1 "$RESULTS_DIR/client_1" | awk '{print $4}')
    if [ -n "$size" ] && [ "$size" -gt 0 ] 2>/dev/null; then
        size_mb=$((size / 1048576))
        if [ "$avg_ms" -gt 0 ]; then
            avg_mbps=$(( (size * 8) / (avg_ms * 1000) ))
            echo "  Image:      ${size_mb}MB"
            echo "  Avg/client: ${avg_mbps} Mbps"
        fi
    fi
fi
