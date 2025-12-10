"AGWPSGGASAGLAILWGASAIMPGALW"

sequence = "AGWPSGGASAGLAILWGASAIMPGALW"
#print(sequence)

dico = {}
for letter in sequence:
    count = sequence.count(letter)
    if letter in dico:
        continue
    else:
        dico[letter] = count
print(dico)



