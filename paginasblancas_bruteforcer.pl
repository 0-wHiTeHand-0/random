#!/usr/bin/perl
use strict;
use LWP::Simple;# qw( $ua get );
#$ua->proxy('http','http://localhost:8081');


#if ($#ARGV!=3) {print "ERROR en los parametros. Uso: script.pl <lista.txt>\n\n" }

my $contenido;
open NOMBRES,$ARGV[0];
my $nombre;
my $nombre1;
my $temp;
my $url;
my $i;
my $j=0;

while ( $nombre = <NOMBRES>) {
	$j++;
	chomp($nombre);
	$nombre1=$nombre;
	$nombre=unpack('H*',"$nombre");
	$temp='';
	for ($i=0; $i<length($nombre); $i=$i+2){
		$temp=$temp.'%'.substr($nombre,$i,2);
	}
	$url='http://blancas.paginasamarillas.es/jsp/resultados.jsp?no='.$temp.'&sec=18&lo=Granada&calle=Elvira&numero=98&pgpv=0&tbus=0&nomprov=Granada&idioma=tml_lang';
	$contenido = get($url);
	sleep 2;
	if ($contenido !~ /NO SE ENCONTR/){
		print $nombre1.". Es el ".$j."\n";
	}
}
close(NOMBRES);

#https://es.wikipedia.org/wiki/Wikiproyecto:Nombres_Propios/librodelosnombres
#David
#Angel
#Miguel
#Ana