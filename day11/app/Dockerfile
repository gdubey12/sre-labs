FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN useradd --system --no-create-home --shell /usr/sbin/nologin appuser
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

CMD ["python3", "app.py"]
