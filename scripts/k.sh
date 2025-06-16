#!/bin/bash

# Security: Validate kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl not found" >&2
    exit 1
fi

# Input validation
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <kubectl-command> [args...]" >&2
    exit 1
fi

# Security: Block potentially dangerous kubectl operations
readonly BLOCKED_OPERATIONS=(
    "delete"
    "create"
    "apply"
    "replace"
    "patch"
    "edit"
    "exec"
    "proxy"
    "port-forward"
)

KUBECTL_CMD="$1"
for blocked in "${BLOCKED_OPERATIONS[@]}"; do
    if [[ "$KUBECTL_CMD" == "$blocked" ]]; then
        echo "Error: kubectl $blocked operation is not permitted for security reasons" >&2
        exit 1
    fi
done

# Security: Limit to read-only operations and basic cluster info
readonly ALLOWED_OPERATIONS=(
    "get"
    "describe"
    "logs"
    "top"
    "version"
    "cluster-info"
    "config"
    "api-resources"
    "api-versions"
)

if [[ ! " ${ALLOWED_OPERATIONS[*]} " =~ " ${KUBECTL_CMD} " ]]; then
    echo "Error: kubectl $KUBECTL_CMD operation is not in the allowed list" >&2
    echo "Allowed operations: ${ALLOWED_OPERATIONS[*]}" >&2
    exit 1
fi

# Execute with timeout to prevent hanging
timeout 30 kubectl "$@"
