"""Auto-update for the Windows agent.

Queries the Dolibarr module 'sysinfo' config endpoint
(GET /api/index.php/sysinfo/config), which exposes the latest agent
version and its GitHub release update folder. If the remote version is
newer, downloads the installer package into an 'update' folder next to
the running executable. The installer is launched (silent mode) which
stops the service, replaces files (config.json preserved) and exits the
current process.
"""

import logging
import os
import subprocess
import sys
import tempfile

import requests

from agent import sender

logger = logging.getLogger("agent.updater")

AGENT_VERSION = "1.0.0"
OS_KEY = "windows"
PACKAGE_FILENAME = "DolibarrSysinfoAgentSetup.exe"
CONFIG_ENDPOINT = "/sysinfo/config"


def _version_tuple(version):
    parts = []
    for chunk in str(version).split("."):
        digits = "".join(c for c in chunk if c.isdigit())
        parts.append(int(digits) if digits else 0)
    return tuple(parts)


def check_for_update(config):
    """Return the remote update info if a newer version is available."""
    if not config.get("auto_update", True):
        return None
    try:
        resp = requests.get(
            sender.dolibarr_url(config, CONFIG_ENDPOINT),
            headers=sender.auth_headers(config),
            timeout=config.get("timeout_seconds", 30),
            verify=config.get("verify_ssl", True),
        )
        resp.raise_for_status()
        info = (resp.json() or {}).get(OS_KEY) or {}
    except Exception as exc:
        logger.warning("Verification de mise a jour echouee : %s", exc)
        return None
    remote_version = info.get("version")
    update_url = info.get("update_url")
    if not remote_version or not update_url:
        return None
    if _version_tuple(remote_version) <= _version_tuple(AGENT_VERSION):
        return None
    logger.info("Nouvelle version disponible : %s (actuelle %s)", remote_version, AGENT_VERSION)
    return info


def apply_update(config, info):
    """Download the installer and run it silently, then exit the process.

    The Inno Setup installer stops and restarts the service itself and
    preserves config.json (onlyifdoesntexist flag).
    """
    package_url = info["update_url"].rstrip("/") + "/" + PACKAGE_FILENAME
    update_dir = os.path.join(tempfile.gettempdir(), "dolibarr-agent-update")
    os.makedirs(update_dir, exist_ok=True)
    installer_path = os.path.join(update_dir, PACKAGE_FILENAME)
    logger.info("Telechargement de %s", package_url)
    resp = requests.get(
        package_url,
        timeout=config.get("timeout_seconds", 30),
        verify=config.get("verify_ssl", True),
    )
    resp.raise_for_status()
    with open(installer_path, "wb") as f:
        f.write(resp.content)
    logger.info("Mise a jour vers %s : lancement du programme d'installation", info.get("version"))
    subprocess.Popen(
        [installer_path, "/VERYSILENT", "/NORESTART", "/CLOSEAPPLICATIONS"],
        cwd=update_dir,
        creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, "CREATE_NO_WINDOW") else 0,
    )
    sys.exit(0)
