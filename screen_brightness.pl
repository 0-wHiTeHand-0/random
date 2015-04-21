#!/usr/bin/perl

if (($ARGV[0] ne "inc") && ($ARGV[0] ne "dec")) {die "Necesitas el parametro 'inc' o 'dec'";}

open(MAX,"</sys/class/backlight/intel_backlight/max_brightness") || die "ERROR: El fichero no se puede abrir";#Fichero que contiene el brillo maximo
$VALOR_MAX=<MAX>;
close(MAX);

if ($VALOR_MAX>15) {$VALOR_DEC= int($VALOR_MAX/15);}##### Modificar si se quiere aumentar o disminuir el brillo mas rapido o mas despacio. En este caso para pasar del menor valor al mayor hay que ejecutar 15 veces.
else {$VALOR_DEC=1;}

open(ENTRADA,"</sys/class/backlight/intel_backlight/brightness") || die "ERROR: El fichero no se puede abrir";#Fichero a modificar con el brillo deseado
$linea=<ENTRADA>;
if (($ARGV[0] eq "inc") && (($linea+$VALOR_DEC)<=$VALOR_MAX)) {$linea+=$VALOR_DEC;}
else
	{
	    if (($ARGV[0] eq "dec") && (($linea-$VALOR_DEC)>-1)) {$linea-=$VALOR_DEC;}
	}
close(ENTRADA);

open(SALIDA, ">/sys/class/backlight/intel_backlight/brightness") || die "ERROR: El fichero no se puede escribir";#Fichero a modificar con el brillo deseado
print SALIDA "$linea\n";
close(SALIDA);
