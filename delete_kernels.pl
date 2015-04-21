#!/usr/bin/perl
use strict;
use constant REINICIOS => 10;#Modificar al numero que se quiera

open(ENTRADA,"</home/usuario/.tiempo_limpieza.txt") || die "ERROR: El fichero no se puede abrir";
my $numero=<ENTRADA>;
close(ENTRADA);

if ($numero != REINICIOS) {$numero++}
else
        {
        $numero=0;
	system('dpkg -l \'linux-*\' | sed \'/^ii/!d;/\'"$(uname -r | sed "s/\\(.*\\)-\\([^0-9]\\+\\)/\\1/")"\'/d;s/^[^ ]* [^ ]* \\([^ ]*\\).*/\\1/;/[0-9]/!d\' | xargs apt-get -y purge')
	}


open(SALIDA, ">/home/usuario/.tiempo_limpieza.txt") || die "ERROR: El fichero no se puede escribir";
print SALIDA "$numero\n".localtime."\n";
close(SALIDA);
