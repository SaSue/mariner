**If you are not running Firmware 4.4.3, then DO NOT install Mariner from this fork.  It is unlikely to
work.**
Check-out releases on this project for a deb file which can be installed if you're running 4.4.3.

🛰️ mariner (BlueFinBima Fork)
==============================

|CI| |docs| |codecov| |Python| |MIT license|

Web interface for controlling MSLA 3D Printers based on ChiTu controllers
remotely.  This fork is to allow Mariner to work with Firmware 4.4.3 which had to be installed
in order to allow ChitBox 1.9 sliced files to be printed.  It was found that Mariner did not
work with this Firmware level because a number of the commands stopped working.

The issue with 4.4.3 was raised as https://github.com/luizribeiro/mariner/issues/453

|Screenshot|

Features
--------

- Web interface with support for both desktop and mobile.
- Upload files to be printed through the web UI over WiFi!
- Remotely check print status: progress, current layer, time left.
- Remotely control the printer: start prints, pause/resume and stop.
- Browse files available for printing.
- Inspect ``.ctb`` files: image preview, print time and slicing settings.

For more details on the feature set, refer to our `Documentation
<https://mariner.readthedocs.io/en/latest/>`_.

Supported Printers
------------------

Mariner supports a wide range of MSLA printers, including printers from the
following manufacturers:

- Anycubic
- Creality
- EPAX
- Elegoo
- Peopoly
- Phrozen
- Voxelab

Please refer to the list of `Supported Printers
<https://mariner.readthedocs.io/en/latest/supported-printers.html>`_
on our documentation for a full list of printer models that have been tested.
If you have access to other printers and want to contribute, please open an
issue.  We're happy to support more printers!

Documentation
-------------

The documentation is available from `Read the Docs
<https://mariner.readthedocs.io/en/latest/>`_. It contains a lot of information
from how to setup the hardware, install the software, troubleshoot issues, and
how to contribute to development.

`This blog
post <https://l9o.dev/posts/controlling-an-elegoo-mars-pro-remotely/>`__
explains the setup end to end with pictures of the modifications done to an
Elegoo Mars Pro.


Docker / ARM64 Installation (Recommended for Raspberry Pi)
----------------------------------------------------------

This fork has been modernized to support **container-based deployment on ARM64
systems**, such as Raspberry Pi (64-bit), instead of legacy ``.deb`` packages.

**If you are not running Firmware 4.4.3, then DO NOT install Mariner from this fork.
It is unlikely to work.**

For older firmware versions, use the original Mariner releases.

Supported Runtime Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **Architecture:** ARM64 (``aarch64``)
- **OS:** Debian Bookworm or compatible
- **Container Runtime:** Docker + Docker Compose
- **Python:** 3.12 (inside container)
- **Node.js:** 20 (build-time only)
- **Frontend:** Webpack (legacy build, OpenSSL workaround applied)
- **Backend Server:** Flask + Waitress

Docker Image (Prebuilt)
~~~~~~~~~~~~~~~~~~~~~~

Docker images are automatically built and published via **GitHub Actions**
to **GitHub Container Registry (GHCR)**.

Image name::

  ghcr.io/sasue/mariner:latest

Tagged releases are also available (e.g. ``v0.2.0``).

Docker Compose Example (Raspberry Pi)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following setup is known to work reliably on Raspberry Pi with
serial-over-UART communication. Pls. ensure to setup the virutal USB Device as described in the original documentation.

Create a docker-compose.yml with the following content and start your container with 

docker compose up -d

::

  version: "3.8"

  services:
    mariner:
      image: ghcr.io/sasue/mariner:latest
      container_name: mariner
      restart: unless-stopped
      init: true

      command: ["mariner"]

      ports:
        - "5000:5000"

      devices:
        - "/dev/serial0:/dev/ttyS0"

      group_add:
        - dialout

      volumes:
        - /mnt/usb:/mnt/usb_share
        - ./config.toml:/etc/mariner/config.toml:ro

      networks:
        - proxy-net

  networks:
    proxy-net:
      external: true

Serial Device Mapping Notes
~~~~~~~~~~~~~~~~~~~~~~~~~~

On Raspberry Pi, the following mapping has proven to be **the most reliable**::

  /dev/serial0 → /dev/ttyS0

If it works reliably — **do not change it**.

If you have an other Serial Device at your Raspi, only change /dev/serial0 to the correct value.

Building the Image Manually (Optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Local builds are **not recommended on Raspberry Pi** due to long build times.
If required, build on a more powerful host::

  docker buildx build \
    --platform linux/arm64 \
    -t mariner:arm64 \
    --load .

Notes on Modernization
~~~~~~~~~~~~~~~~~~~~~

This fork includes several internal improvements:

- Python upgraded to **3.12**
- Fully containerized runtime (no system-wide installs)
- Deterministic dependency locking via Poetry
- ARM64-first deployment
- Hardened frontend build against network timeouts
- Temporary Webpack OpenSSL legacy workaround

These changes are **transparent to end users** and do not alter printer behavior.

.. |CI| image:: https://github.com/luizribeiro/mariner/workflows/CI/badge.svg
   :target: https://github.com/luizribeiro/mariner/actions/workflows/ci.yaml
.. |docs| image:: https://readthedocs.org/projects/mariner/badge/?version=latest
   :target: https://mariner.readthedocs.io/en/latest/?badge=latest
.. |codecov| image:: https://codecov.io/gh/luizribeiro/mariner/branch/master/graph/badge.svg
   :target: https://codecov.io/gh/luizribeiro/mariner
.. |Python| image:: https://img.shields.io/badge/python-3.7%20%7C%203.8%20%7C%203.9-blue
   :target: https://www.python.org/downloads/
.. |MIT license| image:: https://img.shields.io/badge/License-MIT-blue.svg
   :target: https://luizribeiro.mit-license.org/
.. |Screenshot| image:: /docs/_static/screenshot.png
