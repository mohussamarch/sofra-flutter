"""Retry only a stalled Flutter simulator connection; real test failures fail CI."""
import os
import signal
import subprocess
import sys

simulator_id = sys.argv[1]
command = [
    "flutter", "test", "integration_test/app_flow_test.dart", "-d", simulator_id,
    "--reporter", "expanded", "--verbose", "--timeout", "3m",
]

for attempt in range(1, 3):
    print(f"iOS flow attempt {attempt}/2 (connection and test limit: 4 minutes)", flush=True)
    process = subprocess.Popen(command, start_new_session=True)
    try:
        # A simulator build normally takes about one minute for this prototype.
        # This also bounds hangs before the Dart test framework can start.
        result = process.wait(timeout=240)
    except subprocess.TimeoutExpired:
        print("Flutter did not finish; capturing the simulator before stopping it.", flush=True)
        subprocess.run(["xcrun", "simctl", "io", simulator_id, "screenshot",
                        f"ios-stalled-attempt-{attempt}.png"], check=False, timeout=30)
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        subprocess.run(["xcrun", "simctl", "terminate", simulator_id,
                        "com.example.tabkhaDemo"], check=False, timeout=30)
        if attempt == 2:
            sys.exit("iOS simulator connection timed out twice; see verbose logs and screenshots.")
    else:
        # Never retry a returned test failure or turn it into a passing result.
        sys.exit(result)
