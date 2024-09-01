# Use an NVIDIA CUDA image as the base image
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Set the working directory in the container
WORKDIR /app

# Copy the local code, model, and other necessary files to the container
COPY . /app


# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    python3.10 \
    python3-pip \
    python3-dev \
    libgl1-mesa-dev \
    libglib2.0-0 \
    build-essential \
    yasm \
    cmake \
    libtool \
    libc6 \
    libc6-dev \
    unzip \
    wget \
    git \
    libnuma1 \
    libnuma-dev \
    pkg-config \
#    libnvidia-encode-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and install ffnvcodec to satisfy cuvid dependencies
RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && \
    make && \
    make install

# Install Python packages specified in requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Clone FFmpeg repo and compile with nvdec
RUN git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg && \
    cd ffmpeg && \
    ./configure --enable-nonfree --disable-shared --enable-nvenc --enable-cuda --enable-nvdec --enable-cuda-nvcc --enable-cuvid --enable-libnpp --extra-cflags=-Ilocal/include --enable-gpl --enable-version3 --disable-debug --disable-ffplay --disable-indev=sndio --disable-outdev=sndio --enable-fontconfig --enable-gnutls --enable-gray --enable-libass --enable-libfreetype --enable-libfribidi --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopus --enable-libopenjpeg --enable-librtmp --enable-libsoxr --enable-libspeex --enable-libtheora --enable-libvo-amrwbenc --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxvid --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 && \
    make -j$(nproc) && \
    make install

# Create symbolic link and set LD_LIBRARY_PATH
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs/:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
RUN #rm /usr/local/cuda/lib64/stubs/libcuda.so.1

# Expose the port the app runs on
EXPOSE 4000

# Define environment variable for uvicorn
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=4000

# Run the API using uvicorn when the container launches
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4000"]
