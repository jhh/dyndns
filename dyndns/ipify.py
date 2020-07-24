from requests import get
from requests.exceptions import RequestException
import sys
from .settings import IPIFY_API_URI


def get_ip():
    try:
        resp = get(IPIFY_API_URI)
    except RequestException:
        print("Unable to reach the ipify service.")
        sys.exit(-1)

    if resp.status_code != 200:
        print(f"Invalid status code from ipify: {resp.status_code}.")
        sys.exit(-1)

    return resp.text

