#!/bin/bash
# Build the wkhtmltopdf Lambda layer (AL2023 compatible) and output layer.zip
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-$SCRIPT_DIR}"

echo "Building wkhtmltopdf Lambda layer..."
docker build -t wkhtmltopdf-lambda-layer "$SCRIPT_DIR"

echo "Extracting layer.zip to $OUTPUT_DIR..."
docker run --rm -v "$OUTPUT_DIR:/output" wkhtmltopdf-lambda-layer cp /layer.zip /output/layer.zip

echo "Done: $OUTPUT_DIR/layer.zip"
