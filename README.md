
# wkhtmltopdf on Amazon Linux 2023

Examples of installing wkhtmltopdf in Amazon Linux 2023 environments, including Bref Lambda containers.

## bref-local-wkhtmltopdf

A local development Docker setup using [Bref](https://bref.sh/) v3 (PHP 8.2) with wkhtmltopdf pre-installed. Useful for developing and testing PDF/image generation locally before deploying to AWS Lambda.

### How it works

**Dockerfile**

Starts from the official `bref/php-82-dev:3` image (based on Amazon Linux 2023) and:

1. Downloads the wkhtmltopdf `0.12.6.1-3` RPM from the AlmaLinux 9 release — compatible with Amazon Linux 2023 since both are based on RHEL 9.
2. Installs the required font and graphics libraries (`fontconfig`, `freetype`, `libX11`, `libXrender`, etc.).
3. Installs the RPM, placing `wkhtmltopdf` and `wkhtmltoimage` at `/usr/local/bin/`.

**docker-compose.yaml**

Runs the built image as a local Bref FPM server:

- Mounts your project directory into `/var/task` for local code sync.
- Exposes port `8000` for local HTTP access.
- Sets `WKHTMLTOPDF_PATH` and `WKHTMLTOIMAGE_PATH` environment variables so your application can locate the binaries.

### Usage

**1. Build and start the container**

```bash
cd bref-local-wkhtmltopdf
docker compose up --build
```

**2. Verify wkhtmltopdf is installed**

```bash
docker compose exec app wkhtmltopdf --version
```

### Notes

- The AlmaLinux 9 RPM is used because Amazon Linux 2023 is RHEL 9-based and does not have a dedicated wkhtmltopdf package.
- The `uname -m` call in the Dockerfile makes the build architecture-aware (`x86_64` or `aarch64`), so it works on both Intel and Apple Silicon (M-series) Macs.
- `BREF_BINARY_RESPONSES=1` is required when returning binary content (PDFs) through the Bref FPM runtime, otherwise the response will be corrupted.

## Install on Amazon Linux 2023

Installing manually on Amazon Linux 2023 process is same as commands specified in above Dockerfile. You could cleanup residue files after installation finishes. Rest shall be good. I am a bit lazy :(

## al2023-lambda-layer

[TODO] ...