import subprocess

from fastapi import FastAPI, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import cv2

app = FastAPI()

# Add CORS middleware to allow requests from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

RTMP_DESTINATION_URL_SUFFIX = "_output"  # Suffix for destination RTMP URL

class EncodeVideoStreamPayload(BaseModel):
    rtmp_input_url: str


@app.post("/enable")
def encode_video_stream_payload(payload: EncodeVideoStreamPayload, background_tasks: BackgroundTasks):
    if payload_check(payload):
        background_tasks.add_task(encode_video_stream, payload)
        return {"message": "Streaming started successfully"}
    else:
        return {"message": "Invalid payload"}


def payload_check(payload: EncodeVideoStreamPayload):
    # Check if the provided RTMP server is valid
    print("Checking RTMP server...")
    if not is_input_stream_available(payload.rtmp_input_url):
        return False

    return True

def encode_video_stream(payload: EncodeVideoStreamPayload):
    rtmp_input_url = payload.rtmp_input_url
    print("Encoding video stream...")
    output_rtmp_url = rtmp_input_url + RTMP_DESTINATION_URL_SUFFIX

    cap = cv2.VideoCapture(rtmp_input_url)
    width, height = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    process = create_output_stream(output_rtmp_url, width, height)

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break  # If no frame is read, break the loop

            process.stdin.write(frame.tobytes())
    except Exception as e:
        print("An error occurred while encoding the video stream:", str(e))
    finally:
        cap.release()
        process.stdin.close()
        process.wait()
        # cv2.destroyAllWindows()


def create_output_stream(output_rtmp_url: str, width: int, height: int):
    # This is the command from
    command = [
        'ffmpeg',
        '-y',
        '-f', 'rawvideo',
        '-vcodec', 'rawvideo',
        '-pix_fmt', 'bgr24',
        '-s', f'{width}x{height}',
        '-r', '25',
        '-i', '-',
        '-c:v', 'libx264',
        '-pix_fmt', 'yuv420p',
        '-f', 'flv',
        '-fflags', 'nobuffer',
        '-reconnect', '1',
        '-reconnect_streamed', '1',
        '-reconnect_delay_max', '2',
        '-loglevel', 'debug',
        output_rtmp_url
    ]

    process = subprocess.Popen(command, stdin=subprocess.PIPE)

    return process


def is_input_stream_available(rtmp_input_url: str):
    try:
        cap = cv2.VideoCapture(rtmp_input_url)
        if not cap.isOpened():
            return False
        cap.release()
        return True
    except Exception as e:
        print("An error occurred while checking the input stream:", str(e))
        return False
