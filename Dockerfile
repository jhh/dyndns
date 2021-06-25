FROM python:3.9.5-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY dist/*.whl .
RUN pip install --no-cache-dir *.whl && rm -rf *.whl

CMD [ "python", "-m", "dyndns" ]