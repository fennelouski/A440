# A4402.0.0 build3

The Options icon now uses the adaptive primary foreground color. Actual dark-mode UI review found that the inherited fixed green tint was difficult to see over the dark green background. The label-only change preserves the Stop button style and the four original WAV recordings.

Validate by compiling the Release archive and checking its strict signature, bundle/version/build and unchanged audio-resource hashes. The existing UIKit-hosted tests include TonePlayer switching, stopping and simulated interruption; their current execution requires a separate runtime session. Prior14-test evidence is not new verification of this build.

Root owns native runtime and screenshot checks. Confirm Options visibility in light/dark appearance, large text, iPhone/iPad and the play/stop/background flows on build3 before replacing screenshots or uploading. Native UI, audible hardware output and App Store distribution are not established by archive compilation.
