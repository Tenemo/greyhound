BEGIN {
    descriptionLength = 9;
    isLoopback = 0;
    print "int_name", "ip_address", "mac_address";
}
{
    if (isLoopback) {
        loopbackCount = loopbackCount + 1;
        if (loopbackCount == descriptionLength) {
            isLoopback = 0
        }
    } else {
        if ($0 ~ /LOOPBACK/) {
            isLoopback = 1
            loopbackCount = 1
        } else {
            if (NR % 9 == 1) {
                # Removing colon : from the name of the interface
                printf substr($1, 1, length($1) - 1) " ";
            } else if (NR % 9 == 2) {
                printf $2 " ";
            } else if (NR % 9 == 4) {
                printf $2 ORS;
            }
        }
    }
}
