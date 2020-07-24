from dyndns.ipify import get_ip
from dyndns import check, update

ip = get_ip()
check(ip)
update(ip)
