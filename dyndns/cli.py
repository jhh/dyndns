from dyndns.ipify import get_ip
from dyndns import check, update

def main():
    ip = get_ip()
    check(ip)
    update(ip)

if __name__ == '__main__':
    main()