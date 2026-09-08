"""Kleine Demo-App für das DevSecOps Pipeline Lab.

Achtung, die App enthält absichtlich eine Command-Injection-Schwachstelle im /ping-Endpoint,
damit der SAST-Scanner (Semgrep) in der Pipeline etwas zu finden hat. Nicht deployen und
nicht mit echtem Traffic betreiben.
"""
import os

from flask import Flask, request

app = Flask(__name__)


@app.route("/")
def index():
    return {"status": "ok", "service": "devsecops-pipeline-lab"}


@app.route("/ping")
def ping():
    # Absichtlich unsicher, die Benutzereingabe landet ungefiltert in einem Shell-Befehl.
    # Semgrep-Regel "dangerous-system-call" bzw. CWE-78 sollte das hier flaggen.
    host = request.args.get("host", "127.0.0.1")
    result = os.system(f"ping -n 1 {host}")  # bewusst verwundbar, nosec-DEMO
    return {"exit_code": result}


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)
