# ASMR FOOD RUN 🍓🎧

A portrait-mode arcade runner for Android, built with Godot 4.4+.

## Implemented in the current prototype

- Portrait layout and three-lane runner gameplay.
- Large left/right controls and swipe lane switching.
- Character selection before a run: girl, boy, bunny, panda, monkey, and fox.
- Character-specific food pools:
  - People: burgers, salad, apples, strawberries.
  - Bunny: carrots, lettuce, apples.
  - Panda: bamboo and apples.
  - Monkey: bananas, mangoes, strawberries.
  - Fox: berries, apples, carrots.
- Simple illustrated food pickups.
- Background music with an on-screen music on/off button.
- Sound settings with separate music and effects volume sliders.
- Synthesized arcade music and short food/action sound effects.
- Timed rounds, progress indicator, feedback, and result screen.

## Current limitations

This is an evolving prototype. Character art is simple procedural 2D drawing, not a finished illustration pack. Food effects are synthesized tones rather than recorded, realistic ASMR recordings. Character-specific eating animations, richer splash and juice particles, unlockable characters, and the final store icon still need further work.

## Technology

- Godot 4.4+
- GDScript
- Android export through GitHub Actions
- Portrait orientation

## Run locally

Open the project in Godot 4.4 or newer and run `scenes/main.tscn`.

## Android build

Open the repository's **Actions** tab and select the latest **Build FOOD DASH Android APK** run. A successful run publishes an ARM64 APK artifact for modern Android phones.

## Project status

The existing lane-runner foundation is being expanded into **ASMR FOOD RUN**. The repository name has not been changed yet; that can be done later without interrupting development.
