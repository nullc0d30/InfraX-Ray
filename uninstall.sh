#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# InfraX-Ray Uninstaller

echo "Are you sure you want to remove InfraX-Ray? (y/N)"
read -r response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Aborting."
    exit 0
fi

echo "Removing InfraX-Ray directory..."
rm -rf "$(dirname "$0")"

echo "InfraX-Ray removed."
echo "Note: Dependencies installed via apt or go were NOT removed to avoid breaking other tools."
