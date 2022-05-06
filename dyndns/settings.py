import os
from pathlib import Path

DYNDNS_HOST = os.environ["DYNDNS_HOST"]
AWS_ACCESS_ID = os.environ["AWS_ACCESS_KEY_ID"]
ZONE_ID = os.environ["AWS_ZONE_ID"]
DNS_SERVER = os.environ["DNS_SERVER"]
IPIFY_API_URI = "https://api.ipify.org"

CREDENTIALS_FILE = Path(os.environ["CREDENTIALS_DIRECTORY"]) / "AWS_SECRET_ACCESS_KEY"
AWS_SECRET = CREDENTIALS_FILE.read_text().strip()

print(f"AWS_SECRET = {AWS_SECRET}")
