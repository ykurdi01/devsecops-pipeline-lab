# Bewusst nach Best Practices gebaut, mit minimalem Base-Image, Multi-Stage-Build
# und non-root User. Die absichtlichen Schwachstellen für die Pipeline liegen im
# App-Code, den Dependencies und der IaC, nicht hier.

FROM python:3.12-slim AS builder
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.12-slim
WORKDIR /app

RUN addgroup --system app && adduser --system --ingroup app app
COPY --from=builder /root/.local /home/app/.local
COPY app/ .

ENV PATH=/home/app/.local/bin:$PATH
USER app

EXPOSE 5000
CMD ["python", "app.py"]
