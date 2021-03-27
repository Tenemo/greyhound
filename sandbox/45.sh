# ls ~ -la | sed -n '/Desktop/,/Picutres/'
# ls ~ -la | sed -n '1,10!p'
# ls ~ -la
# ls ~ -la | sed 's/drwx/costaaaaaaaaam/g'
# ls ~ -la | sed 's/\(\b[A-Z]\)/\(\1\)/g'
# sed -n '/^Second/,${p;/^123/q}' data
# sed '/ABCD/s/$/xxxx/' data
# sed '3s/^/xxxx/' data
# sed '/3/s/^/xxxx/' data
# sed 's/^/aaa/' data | sed 's/$/zzz/' > ./data2
# sed 's/^/aaa/; s/$/zzz/' data > data2
# sed -n '/^..[cC]/p' data
# cat data | sed 's/i/S/'

# awk -f 45.awk < employees

# awk '{ print $3 * $4, $0 }' employees | sort -n
# awk '$3 * $4 > 120 { print $3 * $4, $1, $2 }' employees

# awk 'BEGIN { print length("abcd") } { print $0 }' employees
# sed '/^g/s/g/s/g' < data2

# for x in *.{jpg,jpeg,JPG,JPEG};do mv $x test/${x%.png}test.png;done

# for filename in *.{jpeg,JPG,JPEG}; do
#     mv "${filename}" $(sed 's/\.\w*$/.jpg/' <<< "${filename}")
# done

ifconfig | awk -f 46.awk > interfaces.txt


awk '{ count = $0; while (count > 0) { printf "*"; count = count - 1; } printf ORS; }' < numbers
