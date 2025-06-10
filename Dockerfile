FROM quay.io/astronomer/astro-runtime:8.8.0

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt