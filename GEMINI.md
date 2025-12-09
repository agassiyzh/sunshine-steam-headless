# Gemini Context: sunshine-steam-headless

This document provides a comprehensive overview of the `sunshine-steam-headless` project for AI-assisted development.

## 1. Project Overview

This project provides a Dockerized environment for running [Sunshine](https://github.com/LizardByte/Sunshine), an open-source, self-hosted game stream host. The setup is specifically designed to be "headless," meaning it can run on a server without a physical monitor attached.

It leverages an NVIDIA GPU for hardware-accelerated video encoding (NVENC) by using a virtual Xorg server with a dummy display configuration. This makes it ideal for streaming games or a desktop environment from a remote server.

**Key Technologies:**
*   **Containerization:** Docker & Docker Compose
*   **Base Image:** `ubuntu:24.04`
*   **Core Components:**
    *   [Sunshine](https://github.com/LizardByte/Sunshine): The streaming server.
    *   [Xorg](https://www.x.org/wiki/): The display server, configured with a virtual screen.
    *   **NVIDIA Drivers:** The container is set up to use the host's NVIDIA drivers via the `nvidia-container-toolkit`.
    *   **Steam:** Includes `steam-installer`, allowing for game management and launching within the container.
*   **Automation:** A shell script (`entrypoint.sh`) to initialize the environment.
*   **CI/CD:** GitHub Actions workflow (`.github/workflows/docker-publish.yml`) for automatically building, testing, and publishing the Docker image to GitHub Container Registry (GHCR).

## 2. Building and Running

The project is managed primarily through Docker Compose.

### Primary Commands:

*   **Build and Run (Detached Mode):**
    ```bash
    # This command builds the image if it doesn't exist and starts the service.
    docker-compose up --build -d
    ```

*   **View Logs:**
    ```bash
    # Follow the logs of the running container.
    docker logs -f sunshine-headless
    ```

*   **Stop and Remove:**
    ```bash
    # Stop and remove the container defined in the compose file.
    docker-compose down
    ```

## 3. Project Structure & Conventions

*   **`Dockerfile`**: Defines the base image, installs all dependencies (Xorg, PulseAudio, Sunshine, Steam), and sets up the container environment. It copies the `xorg.conf` and `entrypoint.sh` scripts.

*   **`docker-compose.yaml`**: The main orchestration file.
    *   It defines the `sunshine` service.
    *   It uses `build: .` to build the image from the `Dockerfile`.
    *   It enables the NVIDIA runtime (`runtime: nvidia`).
    *   It maps local directories `./config` and `./steam-home` for persistent configuration and user data.
    *   It exposes the necessary Sunshine ports (e.g., 47990).

*   **`entrypoint.sh`**: This is the heart of the container's runtime logic.
    *   It starts essential services like `dbus` and `pulseaudio`.
    *   It dynamically creates a `steam` user to avoid running as root.
    *   It re-executes itself as the `steam` user using `gosu`.
    *   It starts the `Xorg` server in the background using the `xorg.conf` configuration.
    *   Finally, it starts the `sunshine` application, pointing to the persistent `/config` directory. The command now uses an absolute path (`/usr/bin/sunshine`) to prevent `PATH` issues.

*   **`xorg.conf`**: Configures the Xorg server to use the NVIDIA driver with a virtual "dummy" display (`1920x1080`), which is necessary for Sunshine to capture a display and use NVENC without a physical monitor.

*   **CI/CD (`.github/workflows/docker-publish.yml`)**:
    *   The workflow is consolidated into a single job (`build-test-publish`) for efficiency.
    *   **Trigger**: Runs on pushes to `main`, version tags (`v*`), or manual dispatch.
    *   **Process**:
        1.  Builds the Docker image and loads it locally.
        2.  Runs a placeholder test on the local image.
        3.  If the tests succeed, it pushes the image with all relevant tags (e.g., `latest`, branch, version) to `ghcr.io`.
    *   This "test-then-push" strategy is a key convention, ensuring that only validated images are published.
