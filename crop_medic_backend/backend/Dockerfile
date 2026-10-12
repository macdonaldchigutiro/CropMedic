FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt ./requirements.txt
RUN python -m pip install --upgrade pip && \
    python -m pip install -r requirements.txt

COPY . .

# TLS is normally terminated by the hosting platform/reverse proxy. The app
# still emits HSTS in production. Set CROPMEDIC_FORCE_HTTPS=true only when the
# backend itself must redirect HTTP to HTTPS and proxy scheme headers are known
# to be configured correctly.
ENV CROPMEDIC_ENV=production \
    CROPMEDIC_FORCE_HTTPS=false

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD python -c "import json,sys,urllib.request; d=json.load(urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=5)); sys.exit(0 if d.get('status') == 'ready' else 1)"

CMD ["sh", "-c", "python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers"]
