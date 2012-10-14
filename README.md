blamestats.pl
=============

Сбор и агрегация статистики об авторстве в Git-репозитории.

Скрипт подсчитывает число строк, принадлежащих авторам в отдельных файлах согласно `git blame`.
Результат работы --- строки вида `<имя файла>\t<имя автора>\t<число строк>`.

Возможности:
  * агрегация статистики по всем обработанным файлам (ключ `--totals`)
  * объединение статистики по псевдонимам одного и того же автора (ключ `--aliases`)

Подробности см. по `perl blamestats.pl --help` и в коде.

Пример использования::

    $ cd memcached
    $ find . -type f | perl blamestats.pl --stdin --common-exts | head -n 15
    ./assoc.c	Paul Lindner	11
    ./assoc.c	Trond Norbye	92
    ./assoc.c	Brad Fitzpatrick	54
    ./assoc.c	Steven Grimm	81
    ./assoc.c	Dustin Sallings	3
    ./assoc.c	dormando	52
    ./trace.h	Trond Norbye	69
    ./trace.h	dormando	2
    ./doc/protocol.txt	Matt Ingenthron	26
    ./doc/protocol.txt	Paul Lindner	18
    ./doc/protocol.txt	Fordy	1
    ./doc/protocol.txt	Evan Miller	3
    ./doc/protocol.txt	Brad Fitzpatrick	59
    ./doc/protocol.txt	Anatoly Vorobey	298
    ./doc/protocol.txt	Filipe Laborde	2
    $ find . -type f | perl blamestats.pl --stdin --common-exts --totals | sort -t$'\t' -k3nr | head -5
    <total>	Trond Norbye	5852
    <total>	dormando	2410
    <total>	Dustin Sallings	2359
    <total>	Brad Fitzpatrick	1612
    <total>	Steven Grimm	1261
    $

