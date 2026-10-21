"""Extract candidate screenshots from screen recordings of Ola / Uber / Rapido.

Saves a frame each time the screen changes noticeably (plus one every few seconds as a
fallback), so each distinct app screen appears once or twice. Frames go to a review
folder, NOT into assets/: pick the right ones, blur personal data, then copy them into
assets/workflows/<app>/<app>_<step id>.png (see assets/workflows/MANIFEST.md).

Usage:
    python tools/extract_frames.py recordings/ola.mp4 --app ola
    python tools/extract_frames.py recordings/*.mp4 --out frames --threshold 12

Requires: opencv-python (cv2).
"""

import argparse
import glob
import os

import cv2


def extract(video_path: str, out_dir: str, threshold: float, max_gap_s: float) -> int:
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"  could not open {video_path}")
        return 0
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    os.makedirs(out_dir, exist_ok=True)
    base = os.path.splitext(os.path.basename(video_path))[0]

    last_saved = None
    last_saved_t = -1e9
    saved = 0
    index = 0
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        t = index / fps
        index += 1
        # Compare small grayscale thumbnails: robust to compression noise.
        small = cv2.cvtColor(cv2.resize(frame, (90, 200)), cv2.COLOR_BGR2GRAY)
        changed = last_saved is None or cv2.absdiff(small, last_saved).mean() > threshold
        if changed or t - last_saved_t > max_gap_s:
            name = f"{base}_{saved:03d}_{t:06.1f}s.png"
            cv2.imwrite(os.path.join(out_dir, name), frame)
            last_saved, last_saved_t = small, t
            saved += 1
    cap.release()
    return saved


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("videos", nargs="+")
    parser.add_argument("--out", default="frames", help="review folder (default: frames/)")
    parser.add_argument("--app", help="sub-folder name, e.g. ola / uber / rapido")
    parser.add_argument("--threshold", type=float, default=10.0,
                        help="mean pixel difference (0-255) that counts as a new screen")
    parser.add_argument("--max-gap", type=float, default=4.0,
                        help="also save a frame at least every N seconds")
    args = parser.parse_args()

    paths = [p for pattern in args.videos for p in glob.glob(pattern)] or args.videos
    for path in paths:
        out = os.path.join(args.out, args.app or os.path.splitext(os.path.basename(path))[0])
        n = extract(path, out, args.threshold, args.max_gap)
        print(f"{path}: {n} frames -> {out}")


if __name__ == "__main__":
    main()
