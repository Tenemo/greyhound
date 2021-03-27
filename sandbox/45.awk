# function abs(num) { return (num > 0 ? num : -num) }
# function max(a,b) { return (a > b ? a : b) }
# function min(a,b) { return (a < b ? a : b) }

# BEGIN { 
#     print min(4,7), abs(-3) 
# }

# $3 > 4 { print $2 }
# $3 > 2 && $3 < 4 { print "NOPE" }
# { print "Wypłata dla", $2, "wynosi", $3 * $4}

# { print NF, $1, $NF }
# { print NR, $0 }

# BEGIN { 
#     print "IMIĘ NAZWISKO STAWKA GODZINY";
# }
# { 
#     print $0
# }

# { pay = pay + $3*$4 }
# END { 
#     print NR, "pracowników";
#     print "całkowita płaca wynosi:", pay;
#     print "średnia płaca wynosi:", pay/NR;
# }
# { 
#     if (NR == 1) {
#         names = $2 
#     } else {
#         names = names " " $2 
#     }
# }
# END { print names }

# {
#     if (NR == 1) {
#         characterCount = characterCount + length($0);
#     }
# }
# END {
#     print "characterCount:", characterCount;
# }
# {
#     lines[NR] = $0
# }
# END {
#     i = NR
#     while (i > 0) {
#         print lines[i], i
#         i = i - 1
#     }
# }

BEGIN {
    descriptionLength = 9;
    isLoopback = 0;
    line count
    print "int_name", "ip_address", "mac_address";
}
{
    if ($0 !~ /LOOPBACK/) {
        print $0
    } else {
        isLoopback = 1
    }
}


# BEGIN {
#     print "int_name ip_address mac_address"
# } 
# NR%9==1 && $1 !~ /lo/  {
#     printf $1 OFS 
# } 
# /inet / && $2 !~ /127/ {
#     printf $2 OFS
# } 
# /ether / {
#     printf $2 ORS
# }
