"""
dyndns
======

Dynamic DNS update script that uses ipify: https://www.ipify.org to get public
IP address and updates AWS Route 53.
"""
import dns.resolver
import boto3
import sys
from .settings import DNS_SERVER, DYNDNS_HOST, ZONE_ID


def check(ip):
    r = dns.resolver.Resolver(configure=False)
    r.nameservers = [DNS_SERVER]
    r53_addr = "none"
    try:
        answers = r.resolve(DYNDNS_HOST)
        r53_addr = answers[0].address
    except Exception as err:
        print(f"DNS lookup error: {err}")

    if ip == r53_addr:
        print("IP address {} has not changed, exiting".format(ip))
        sys.exit(0)
    else:
        print("updating Route 53: curr = {}, dns = {}".format(ip, r53_addr))


def update(ip):
    client = boto3.client("route53")
    try:
        response = client.change_resource_record_sets(
            HostedZoneId=ZONE_ID,
            ChangeBatch={
                "Comment": "Dynamic DNS update of {}".format(DYNDNS_HOST),
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": DYNDNS_HOST,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": ip}],
                        },
                    }
                ],
            },
        )
    except Exception as err:
        print(f"DNS update error: {err}")
        sys.exit(-1)

    print("Route 53 status: {}".format(response["ChangeInfo"]["Status"]))
    print("Route 53 comment: {}".format(response["ChangeInfo"]["Comment"]))
