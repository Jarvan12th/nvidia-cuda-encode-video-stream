# Use an NVIDIA CUDA image as the base image
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04

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
    && rm -rf /var/lib/apt/lists/*

# Install Python packages specified in requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Clone FFmpeg repo and compile with nvdec
RUN git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg && \
    cd ffmpeg && \
    ./configure --enable-nvdec --enable-cuda-nvcc --enable-cuvid --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 && \
    make -j$(nproc) && \
    make install

# Expose the port the app runs on
EXPOSE 4000

# Define environment variable for uvicorn
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=4000

# Run the API using uvicorn when the container launches
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4000"]
