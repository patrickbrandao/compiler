#!/bin/sh

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

#
# Escolher tipo do teclado
#

if ! cat /proc/cmdline | grep -q 'kbd=' 2> /dev/null ; then

    # pedir o usuario pra escolher um teclado...

    echo
    echo
    setcolor yellow
    echo "<Opcao para carregar um teclado regional (ABNT ou ABNT2)>"
    echo
    setcolor green
    echo "Se voce esta usando um teclado americano (; no lucar de ce-cedilha)"
    echo -n "voce nao precisa alterar nada apenas tecle "; echoc -c red "ENTER"
    echo
    setcolor green
    echo -n "Caso esteja usando um teclado BRASILEIRO / REGIONAL, tecle "; echo -c red "1 e ENTER"
    echo
    setcolor white
    read ONE
    if [ "$ONE" = "1" ]; then
        /usr/lib/setup/SeTkeymap
    fi

else

    # veio do boot a ordem de especificar
    for ARG in `cat /proc/cmdline` ; do
        if [ "`echo $ARG | cut -f1 -d=`" = "kbd" ]; then
            BMAP="`echo $ARG | cut -f2 -d=`.bmap"
        fi 
    done

    tar xzOf /etc/keymaps.tar.gz $BMAP | loadkmap

    unset BMAP

fi