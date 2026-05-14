FROM bref/php-82-dev:3

# Install wkhtmltopdf (Amazon Linux 2023)
RUN dnf install -y wget
WORKDIR /tmp
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox-0.12.6.1-3.almalinux9.$(uname -m).rpm
RUN dnf install -y \
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
RUN rpm -ivh wkhtmltox-0.12.6.1-3.almalinux9.$(uname -m).rpm

# Set working directory back to /var/task
WORKDIR /var/task
