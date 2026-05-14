# Build wkhtmltopdf Lambda layer for Amazon Linux 2023 (AL2023)
#
# Uses wkhtmltopdf 0.12.6.1-3 AlmaLinux 9 RPM.
# AlmaLinux 9 links against OpenSSL 3 (libssl.so.3), same as AL2023.
# The old amazonlinux2 RPM used OpenSSL 1.0 (libssl.so.10) and is not working with AL2023.
#
# Bundled libs are derived from running ldd on the binary in a working container.
# Only libs absent from the Lambda AL2023 runtime are included.
#
# Layer structure placed under /opt on Lambda:
#   bin/wkhtmltopdf        — wrapper script (sets LD_LIBRARY_PATH + FONTCONFIG_FILE)
#   bin/wkhtmltopdf.bin    — actual binary
#   bin/wkhtmltoimage      — wrapper script (optional, see below)
#   bin/wkhtmltoimage.bin  — actual binary (optional, see below)
#   lib/                   — shared libs absent from the Lambda AL2023 runtime
#   fonts/                 — DejaVu fonts (Lambda has no fonts by default)
#   fonts.conf             — tells fontconfig to look in /opt/fonts on Lambda

FROM amazonlinux:2023 AS builder

# harfbuzz, glib2, graphite2, libxml2, brotli, xz-libs are transitive deps: 
# not declared in the RPM but required by the binary at runtime.
RUN dnf install -y \
    fontconfig \
    freetype \
    harfbuzz \
    glib2 \
    graphite2 \
    libxml2 \
    brotli \
    xz-libs \
    bzip2-libs \
    libX11 \
    libXext \
    libXrender \
    libXau \
    libxcb \
    libjpeg-turbo \
    libpng \
    cpio \
    zip \
    && dnf clean all

# Downloading for x86_64, Change if building for arm64.
RUN curl -L -o /tmp/wkhtmltox.rpm \
    "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox-0.12.6.1-3.almalinux9.x86_64.rpm"

# Extract via rpm2cpio to avoid dependency conflicts from installing a foreign RPM.
WORKDIR /tmp/wkhtml-extract
RUN rpm2cpio /tmp/wkhtmltox.rpm | cpio -idmv

RUN mkdir -p /layer/bin /layer/lib /layer/fonts


# wkhtmltopdf binary + wrapper
RUN cp /tmp/wkhtml-extract/usr/local/bin/wkhtmltopdf /layer/bin/wkhtmltopdf.bin \
    && chmod +x /layer/bin/wkhtmltopdf.bin

RUN printf '#!/bin/bash\nexport LD_LIBRARY_PATH=/opt/lib:${LD_LIBRARY_PATH}\nexport FONTCONFIG_FILE=/opt/fonts.conf\nexec /opt/bin/wkhtmltopdf.bin "$@"\n' \
    > /layer/bin/wkhtmltopdf \
    && chmod +x /layer/bin/wkhtmltopdf


#######################################
### wkhtmltoimage binary + wrapper
### Uncomment if you need wkhtmltoimage in your Lambda function.

# RUN cp /tmp/wkhtml-extract/usr/local/bin/wkhtmltoimage /layer/bin/wkhtmltoimage.bin \
#     && chmod +x /layer/bin/wkhtmltoimage.bin

# RUN printf '#!/bin/bash\nexport LD_LIBRARY_PATH=/opt/lib:${LD_LIBRARY_PATH}\nexport FONTCONFIG_FILE=/opt/fonts.conf\nexec /opt/bin/wkhtmltoimage.bin "$@"\n' \
#     > /layer/bin/wkhtmltoimage \
#     && chmod +x /layer/bin/wkhtmltoimage

#######################################


# Shared libraries
# Libs present in Lambda AL2023 runtime (NOT bundled):
#   linux-vdso, libc, libm, libpthread, libdl, libgcc_s, libstdc++,
#   libz, libssl.so.3, libcrypto.so.3, ld-linux-x86-64
RUN for lib in \
        /usr/lib64/libjpeg.so.62* \
        /usr/lib64/libpng16.so.16* \
        /usr/lib64/libXrender.so.1* \
        /usr/lib64/libfontconfig.so.1* \
        /usr/lib64/libfreetype.so.6* \
        /usr/lib64/libXext.so.6* \
        /usr/lib64/libX11.so.6* \
        /usr/lib64/libxml2.so.2* \
        /usr/lib64/libbz2.so.1* \
        /usr/lib64/libharfbuzz.so.0* \
        /usr/lib64/libbrotlidec.so.1* \
        /usr/lib64/libbrotlicommon.so.1* \
        /usr/lib64/libxcb.so.1* \
        /usr/lib64/liblzma.so.5* \
        /usr/lib64/libglib-2.0.so.0* \
        /usr/lib64/libgraphite2.so.3* \
        /usr/lib64/libXau.so.6* \
        /usr/lib64/libpcre2-8.so.0* \
    ; do \
        [ -e "$lib" ] && cp -P "$lib" /layer/lib/ || true; \
    done

# Lambda has no fonts, without these, wkhtmltopdf renders text as boxes.
COPY fonts/dejavu/ /layer/fonts/
COPY fonts/fonts.conf /layer/fonts.conf

# Package
WORKDIR /layer
RUN zip -r /layer.zip .

# Final stage
FROM amazonlinux:2023
COPY --from=builder /layer.zip /layer.zip
