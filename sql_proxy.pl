    use strict;
    use HTTP::Daemon;
    use HTTP::Status;
    use LWP::UserAgent;
    use constant COOKIE => 'poneslacookie';
     
    my $d = HTTP::Daemon->new(LocalPort => 8083) || die;
    while (my $c = $d->accept) {
        while (my $r = $c->get_request) {
            my $pet1 = LWP::UserAgent->new;
            $pet1->agent("Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0");
            my $pet1_resp = $pet1->request($r);
            #print $r->as_string;
            if ($pet1_resp->is_success){
                print "PETICION 1: Exito\n";
                my $pet2 = LWP::UserAgent->new;
                $pet2->agent('Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0');
                my $r2 = HTTP::Request->new(POST=>'PON LA URL DEL POST');##########URL del post
                $r2->header('Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8');
                    ##############Parametros de cabecera
                $r2->content('CONTENIDO DEL POST');
                my $pet2_resp = $pet2->request($r2);
                #print $r2->as_string."\n\n";
                if ($pet2_resp->is_success){
                    #print $pet2_resp->as_string."\n\n";
                    print "PETICION 2: Exito\n";
                    manda_tercero();
                    $c->send_response($pet2_resp);
                    print "RESPUESTA ENVIADA\n";
                }
                else{
                    print "HTTP POST error code: ", $pet2_resp->code, "\n";
                    print "HTTP POST error message: ", $pet2_resp->message, "\n";
                }
            }
        }
        $c->close;
        undef($c);
    }
     
    sub manda_tercero{
        my $pet3 = LWP::UserAgent->new;
        $pet3->agent("Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0");
        my $r3 = HTTP::Request->new(POST=>'url del post');
        $r3->header('Content-Type' => 'application/x-www-form-urlencoded');
            ######### parametros de la cabecera
        $r3->content('CONTENIDO DEL POST');
        my $pet3_resp = $pet3->request($r3);
        if ($pet3_resp->is_success){
            print "PETICION 3: Exito\n";
        }
    }
