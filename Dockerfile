# Use an NVIDIA CUDA image as the base image
FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04

# Set the working directory in the container
WORKDIR /app

# Copy the local code, model, and other necessary files to the container
COPY . /app

# Install system dependencies
RUN apt-get update && apt-get install -y gcc python3-dev libgl1-mesa-dev libglib2.0-0 ffmpeg && rm -rf /var/lib/apt/lists/*

# Install Python packages specified in requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port the app runs on
EXPOSE 4000

# Define environment variable for uvicorn
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=4000

# Run the API using uvicorn when the container launches
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4000"]
