# DevSecOps Pipeline Lab

Eine CI/CD-Pipeline, die bei jedem Push und Pull Request automatisch nach Sicherheitsproblemen
sucht, statt das erst ganz am Ende zu prüfen (oder gar nicht).

Ich hab eine kleine Beispiel-App mit ein paar absichtlichen Schwachstellen gebaut (Flask,
Terraform, Docker) und daran gezeigt, wie man typische Problemstellen im Software-Lifecycle
automatisiert findet, statt sie von Hand zu suchen.

## Warum dieses Repo

Mein [`portscan-detection-lab`](https://github.com/ykurdi01/portscan-detection-lab) zeigt
Security auf Netzwerkebene. Hier geht es um die andere Seite, nämlich Security in der
Lieferkette. Code, Dependencies, Secrets, Container-Image und Infrastructure-as-Code werden
alle automatisch über GitHub Actions geprüft, bevor irgendwas deployed wird.

## Pipeline-Stufen

| Stufe | Tool | Prüft | Ergebnis |
|---|---|---|---|
| SAST | [Semgrep](https://semgrep.dev/) | Code auf unsichere Patterns (z. B. Command Injection) | SARIF → GitHub Code Scanning |
| Dependency-Scan | [pip-audit](https://github.com/pypa/pip-audit) | Python-Dependencies auf bekannte CVEs | Findings im Workflow-Log |
| Secret-Scan | [gitleaks](https://github.com/gitleaks/gitleaks) | Commit-Historie auf versehentlich eingecheckte Secrets | SARIF → GitHub Code Scanning |
| Container-Scan | [Trivy](https://github.com/aquasecurity/trivy) | Gebautes Docker-Image auf OS- und Lib-CVEs | SARIF → GitHub Code Scanning |
| IaC-Scan | [Checkov](https://www.checkov.io/) | Terraform-Code auf Fehlkonfigurationen (z. B. offener S3-Bucket) | SARIF → GitHub Code Scanning |

Alle SARIF-Ergebnisse landen im Security-Tab des Repos, unter Security → Code scanning alerts.

```
push / pull_request
        │
        ▼
┌───────────────┐   ┌────────────────┐   ┌──────────────┐
│  SAST          │   │  Dependency    │   │  Secret-Scan │
│  (Semgrep)     │   │  (pip-audit)   │   │  (gitleaks)  │
└───────┬────────┘   └───────┬────────┘   └──────┬───────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                              ▼
                    ┌───────────────────┐
                    │  Docker Build      │
                    └─────────┬──────────┘
                              ▼
                    ┌───────────────────┐      ┌──────────────┐
                    │  Container-Scan    │      │  IaC-Scan    │
                    │  (Trivy)           │      │  (Checkov)   │
                    └─────────┬──────────┘      └──────┬───────┘
                              └───────────┬─────────────┘
                                          ▼
                              GitHub Security Tab (SARIF)
```

## Absichtliche Schwachstellen (zu Demo-Zwecken)

Damit die Scanner überhaupt etwas zu finden haben, hab ich bewusst ein paar ungefährliche
Beispiel-Schwachstellen eingebaut. Die sind nicht für den produktiven Einsatz gedacht.

- `app/app.py` hat einen `/ping`-Endpoint, der Benutzereingaben ungefiltert an `os.system()`
  weiterreicht. Das ist Command Injection und wird von Semgrep erkannt.
- `app/requirements.txt` enthält bewusst eine veraltete `requests`-Version mit bekannten CVEs,
  die pip-audit findet.
- `iac/main.tf` hat einen S3-Bucket mit `acl = "public-read"` und ohne Verschlüsselung oder
  Versionierung. Checkov erkennt das (CKV_AWS_20, CKV_AWS_21, CKV2_AWS_6).

Das Dockerfile selbst ist bewusst sauber gebaut (non-root User, minimales Base-Image,
Multi-Stage-Build). Ich wollte zeigen, dass ich auch die Probleme im Blick habe, die nicht
offensichtlich im Container-Setup stecken, sondern im Code, in den Dependencies und in der IaC.

## Lokal ausführen

```bash
# Dependencies
pip install -r app/requirements.txt

# SAST
pip install semgrep && semgrep --config auto app/

# Dependency-Scan
pip install pip-audit && pip-audit -r app/requirements.txt

# Secret-Scan
docker run -v "$(pwd):/repo" zricethezav/gitleaks:latest detect -s /repo

# Container-Scan (erst bauen)
docker build -t devsecops-lab:local .
trivy image devsecops-lab:local

# IaC-Scan
pip install checkov && checkov -d iac/
```

## Tech-Stack

Python (Flask), Terraform, Docker, GitHub Actions, Semgrep, pip-audit, gitleaks, Trivy, Checkov

## Nächste Ausbaustufen

- [ ] Findings automatisch als PR-Kommentar posten (Anschluss an [`ai-pr-review-agent`](https://github.com/ykurdi01/ai-pr-review-agent))
- [ ] Policy-as-Code mit OPA/Conftest statt nur Checkov
- [ ] Signierte Container-Images (cosign) als zusätzliche Supply-Chain-Stufe
