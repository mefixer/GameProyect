#!/usr/bin/env python3
"""PostToolUse: valida el .gd recién editado con el parser de Godot.

Barato (~2 s) y devuelve el error directo a Claude, sin gastar una ronda de
modelo en decidir validar. Silencio absoluto si el archivo compila.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

RAIZ = Path(os.environ.get("CLAUDE_PROJECT_DIR") or Path(__file__).resolve().parents[2])


def salir(reason: str = "") -> None:
    print(json.dumps({"decision": "block", "reason": reason} if reason else {}))
    sys.exit(0)


def main() -> None:
    try:
        datos = json.load(sys.stdin)
    except Exception:
        salir()

    ruta_str = (datos.get("tool_input") or {}).get("file_path", "")
    if not ruta_str.endswith(".gd"):
        salir()

    ruta = Path(ruta_str)
    if not ruta.is_file():
        salir()

    try:
        r = subprocess.run(
            ["godot", "--headless", "--check-only", "--script", str(ruta)],
            cwd=RAIZ, capture_output=True, text=True, timeout=90,
        )
    except FileNotFoundError:
        salir()          # sin godot instalado: no estorbar
    except subprocess.TimeoutExpired:
        salir(f"La validación de {ruta.name} superó los 90 s. Revisar a mano.")

    if r.returncode == 0:
        salir()

    salida = (r.stdout or "") + (r.stderr or "")
    errores = [ln for ln in salida.splitlines()
               if "SCRIPT ERROR" in ln or "Parse Error" in ln or ln.lstrip().startswith("at:")]
    salir("godot --check-only falló en {}:\n{}".format(
        ruta.name, "\n".join(errores[:20]) or salida[-1500:]))


main()
