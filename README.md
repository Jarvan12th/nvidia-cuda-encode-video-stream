# vit-fire-detection

## Install dependencies and build Docker image

```python3 app/main.py```

## Create a virtual environment

```python3 -m venv nvidia-cuda-encode-video-stream```

## Activate the virtual environment

```source nvidia-cuda-encode-video-stream/bin/activate```

## Install dependencies

```pip install -r requirements.txt```

## Command to run the Docker image

```docker run -p 4000:4000 --name nvidia-cuda-encode-video-stream nvidia-cuda-encode-video-stream```