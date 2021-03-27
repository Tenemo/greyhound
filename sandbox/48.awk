{
    currentField = 1
    while (currentField <= NF) {
        power = NF - currentField
        if ($currentField != 0) {
            if (currentField != 1) {
                printf "+"
            }
            if (power == 0) {
                printf $currentField
            } else if (power == 1) {
                printf $currentField "x"
            } else {
                printf $currentField "x^" power
            }
        }
        currentField = currentField + 1;
    }
    printf ORS
}