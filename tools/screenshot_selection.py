"""Which recorded frame illustrates which guide step, and what must be blurred.

Coordinates are fractions of the frame (left, top, width, height), the same convention
as NormalizedRect in the app. Used by tools/build_screenshots.py.
"""

# (app, step id) -> (source frame relative to saathi_poc/, [blur rects])
SELECTION = {
    # ---------------- Ola ----------------
    ("ola", "open_app"): ("frames_coarse/ola/ola_000_0000.0s.png", []),
    ("ola", "enter_phone"): ("frames_coarse/ola/ola_011_0008.2s.png", []),
    ("ola", "enter_otp"): ("frames_coarse/ola/ola_025_0022.7s.png", [(0.08, 0.232, 0.62, 0.05)]),
    ("ola", "allow_location"): ("frames_coarse/ola/ola_029_0030.3s.png", []),
    ("ola", "find_locations"): ("frames_coarse/ola/ola_037_0037.9s.png", [(0.44, 0.074, 0.42, 0.048)]),
    ("ola", "enter_destination"): ("frames_coarse/ola/ola_043_0067.2s.png", [(0.14, 0.124, 0.84, 0.046)]),
    ("ola", "check_locations"): ("frames_coarse/ola/ola_047_0082.1s.png", [(0.25, 0.08, 0.45, 0.04)]),
    ("ola", "review_rides"): ("frames_coarse/ola/ola_047_0082.1s.png", [(0.25, 0.08, 0.45, 0.04)]),
    ("ola", "check_fare"): ("frames_coarse/ola/ola_059_0091.4s.png", [(0.25, 0.08, 0.45, 0.04)]),
    ("ola", "decide_booking"): ("frames_coarse/ola/ola_059_0091.4s.png", [(0.25, 0.08, 0.45, 0.04)]),
    ("ola", "confirm_pickup"): ("frames_coarse/ola/ola_074_0100.3s.png", [(0.1, 0.84, 0.84, 0.046)]),
    ("ola", "confirm_outcome"): ("frames_coarse/ola/ola_099_0122.5s.png", [
        (0.02, 0.052, 0.96, 0.105),  # ride notification incl. vehicle + ride OTP
        (0.03, 0.343, 0.4, 0.048),  # vehicle plate
        (0.65, 0.335, 0.32, 0.08),  # driver photo + vehicle
        (0.03, 0.413, 0.4, 0.042),  # driver name
    ]),
    # ---------------- Uber ----------------
    ("uber", "open_app"): ("frames_coarse/uber/uber_000_0000.0s.png", []),
    ("uber", "allow_location"): ("frames_coarse/uber/uber_016_0007.0s.png", []),
    ("uber", "enter_phone"): ("frames_coarse/uber/uber_020_0016.0s.png", [(0.37, 0.444, 0.44, 0.046)]),
    ("uber", "enter_otp"): ("frames/uber/uber_037_0039.2s.png", [(0.5, 0.083, 0.28, 0.047), (0.03, 0.163, 0.31, 0.038)]),
    ("uber", "optional_setup"): ("frames_coarse/uber/uber_026_0049.6s.png", []),
    ("uber", "find_locations"): ("frames_coarse/uber/uber_029_0062.0s.png", []),
    ("uber", "enter_destination"): ("frames_coarse/uber/uber_048_0066.2s.png", [(0.15, 0.163, 0.26, 0.038)]),
    ("uber", "check_locations"): ("frames_coarse/uber/uber_050_0075.2s.png", [(0.47, 0.118, 0.27, 0.042)]),
    ("uber", "review_rides"): ("frames_coarse/uber/uber_050_0075.2s.png", [(0.47, 0.118, 0.27, 0.042)]),
    ("uber", "check_fare"): ("frames_coarse/uber/uber_050_0075.2s.png", [(0.47, 0.118, 0.27, 0.042)]),
    ("uber", "decide_booking"): ("frames_coarse/uber/uber_050_0075.2s.png", [(0.47, 0.118, 0.27, 0.042)]),
    ("uber", "confirm_pickup"): ("frames_coarse/uber/uber_079_0116.2s.png", [(0.17, 0.843, 0.27, 0.038)]),
    # ---------------- Rapido ----------------
    ("rapido", "open_app"): ("frames_coarse/rapido/rapido_000_0000.0s.png", []),
    ("rapido", "enter_phone"): ("frames_coarse/rapido/rapido_009_0005.4s.png", []),
    ("rapido", "enter_otp"): ("frames_coarse/rapido/rapido_019_0022.5s.png", [(0.16, 0.163, 0.29, 0.038), (0.04, 0.218, 0.91, 0.068)]),
    ("rapido", "allow_location"): ("frames_coarse/rapido/rapido_035_0026.1s.png", []),
    ("rapido", "find_locations"): ("frames_coarse/rapido/rapido_039_0029.9s.png", [(0.13, 0.094, 0.77, 0.042)]),
    ("rapido", "enter_destination"): ("frames_coarse/rapido/rapido_042_0039.5s.png", []),
    ("rapido", "check_locations"): ("frames_coarse/rapido/rapido_048_0052.2s.png", []),
    ("rapido", "review_rides"): ("frames_coarse/rapido/rapido_048_0052.2s.png", []),
    ("rapido", "check_fare"): ("frames_coarse/rapido/rapido_048_0052.2s.png", []),
    ("rapido", "decide_booking"): ("frames_coarse/rapido/rapido_048_0052.2s.png", []),
}
