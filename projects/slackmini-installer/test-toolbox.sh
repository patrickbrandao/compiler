#!/bin/sh

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

# Exemplo

clear
echo "Tela de exemplo do setup"
colors="blue red green magenta cyan pink yellow white light black gray"
for c in $colors; do
	echoc -n -c $c    "[$c-n] "
	echoc -n -l -c $c "[$c-l] "
	echoc -n -s -c $c "[$c-s] "
	echoc -n -B -c $c "[$c-B] "
	echoc -n -p -c $c "[$c-p]"
	echoc -n -b $c -c white "[$c-b1]"
	echoc -n -b $c -c black "[$c-b2]"
	echo
done
echo
echo -n "Exemplo danger"; echo_danger
echo -n "Exemplo echo_done"; echo_done
echo -n "Exemplo echo_failure"; echo_failure
echo -n "Exemplo echo_skip"; echo_skip
echo -n "Exemplo echo_started"; echo_started
echo -n "Exemplo echo_stopped"; echo_stopped
echo -n "Exemplo echo_success"; echo_success
echo -n "Exemplo echo_warning"; echo_warning
logit "Teste logit"
logit0 "Teste logit zero"
logit1 "Teste logit um"
logit2 "Teste logit" "dois"
logit3 "Teste logit" "dois" "tres"
logita "Teste logit A"
logitb "Teste logit B"
logitc "Teste logit C"
logitg "Teste logit G"
logitp "Teste logit P"
logitr "Teste logit R"
logitw "Teste logit W"
logity "Teste logit Y"

for x in 1 2 3; do
	for i in $(seq 1 1 100); do echo $i; done | shloading -l "label" -t "titulo $x" -m 100 -s $x -d 15000 -n -c
	echo -n "Loading $x concluido"
	sleep 1
done















