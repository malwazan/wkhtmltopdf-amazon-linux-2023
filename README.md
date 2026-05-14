
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

A Lambda layer that packages wkhtmltopdf for use in AWS Lambda functions running on Amazon Linux 2023. The layer is built inside a Docker container to ensure the binaries and libraries match the Lambda runtime.

### How the layer works

Lambda layers are extracted into `/opt` at runtime. The layer is structured so everything wkhtmltopdf needs is self-contained under `/opt`:

```
/opt/
  bin/
    wkhtmltopdf        ← wrapper script (sets env vars, calls the binary)
    wkhtmltopdf.bin    ← actual binary
  lib/                 ← shared libraries not present in the Lambda AL2023 runtime
  fonts/               ← DejaVu fonts (Lambda has no fonts by default)
  fonts.conf           ← tells fontconfig to look in /opt/fonts
```

Your function calls `/opt/bin/wkhtmltopdf`. The wrapper sets `LD_LIBRARY_PATH=/opt/lib` so the binary finds its bundled libraries, and `FONTCONFIG_FILE=/opt/fonts.conf` so fonts resolve correctly.

### How to build

Run the build script — it builds the Docker image and extracts `layer.zip` to the current directory:

```bash
./build.sh
```

To output `layer.zip` to a specific directory:

```bash
./build.sh /path/to/output
```

Then upload `layer.zip` to AWS Lambda as a new layer version.

### Notes

- The AlmaLinux 9 RPM is used because it links against OpenSSL 3 (`libssl.so.3`), which matches AL2023. The Amazon Linux 2 RPM used OpenSSL 1.0 and will not work.
- Only libraries missing from the Lambda AL2023 runtime are bundled — standard ones like `libc`, `libssl`, and `libz` are already present and excluded.
- `wkhtmltoimage` is included in the RPM but not added to the layer by default. Uncomment the relevant section in the Dockerfile if you need it.
- The layer is built for `x86_64`. To build for `arm64`, update the RPM URL in the Dockerfile.


## How to find libraries required by wkhtmltopdf

Well for me, I did following to find list of all required libs:

```bash
# Run al2023 locally
docker run -it amazonlinux:2023 sh

# Install wget
dnf install -y wget

# Download wkhtmltopdf rpm pkg
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox-0.12.6.1-3.almalinux9.$(uname -m).rpm

# Try extracting...
rpm -ivh wkhtmltox-0.12.6.1-3.almalinux9.$(uname -m).rpm

# It will throw error listing all deps provided below.
# Install them
dnf install -y \
    openssl \
    fontconfig \
    freetype \
    libX11 \
    libXext \
    libXrender \
    libjpeg-turbo \
    libpng \
    mesa-libGL \
    xorg-x11-fonts-Type1 \
    xorg-x11-fonts-75dpi \
    dejavu-sans-fonts

# List all dynamic deps using command
ldd /usr/local/bin/wkhtmltopdf

# It will list all requred deps of wkhtmltopdf.
# Each line means: "wkhtmltopdf needs this .so file, and the system found it at this path".
```

Well here i chatgpt give me the list of libs that I needed to copy, because some libraries already present in lambda runtime (minimal set), so we exclude those and copy the rest.

Otherwise pull lambda al2023 locally and see what's present already:
```bash
docker run --rm public.ecr.aws/lambda/provided:al2023 ls /lib64/
``` 

Or trail and error by deploying to lambda and see if wkhtmltopdf complains about any missing library.
