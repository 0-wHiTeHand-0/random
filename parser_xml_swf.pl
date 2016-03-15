use strict;
use warnings;
use XML::Twig;
use Encode qw/encode decode/;
use HTML::Entities qw(decode_entities);

my $f = shift or die "Use: You should download data.swf, and execute:\nswfdump -a data.swf > data.dat\nAnd then:\n$0 data.dat\n";

open(my $fh, '<:encoding(UTF-8)', $f) or die "Could not open file '$f': $!";

my $xml_f = "";
my $pre_row = "";

while (my $row = <$fh>){
	chomp $row;
	if ((index($row, 'action: SetMember') != -1) && (index($pre_row, 'action: Push String') != -1)){
		chop $pre_row;
		$xml_f .= substr($pre_row, index($pre_row, 'String:"')+8);
	}
	$pre_row = $row;
}

my $twig=XML::Twig->new();
$twig->parse($xml_f);

my $entry = $twig->first_elt('entrypoint')->att('objref');
my @scenes = $twig->root->first_child('scenes')->children('scene');
my $scene = undef;

sub c_error{
	print '\n'.$_[0].'\n'."Bye bye...\n";
	exit 1;
}

foreach my $i (@scenes){
	if ($entry eq $i->att('id')){
		$scene = $i;
		last;
	}
}

if (!defined $scene){c_error("Error parsing <scene> fields.")}

my @slides = $scene->first_child('slides')->children('slide');

foreach my $slide (@slides){
	my $interaction = $slide->first_child('interaction');
	
	my $pregunta = $interaction->first_child('description')->first_child('textdata')->att('alttext');
	
	my @answers = $interaction->first_child('answers')->children('answer');
	my @correct_choiceid = ();
	RESP: foreach my $i (@answers){
		if ($i->att('status') eq "correct"){
			if ($i->first_child('evaluate')->first_child->name eq 'and'){
				foreach my $j ($i->first_child('evaluate')->first_child->children('equals')){
					push @correct_choiceid, $j->att('choiceid');
				}
				#$correct_choiceid = $i->first_child('evaluate')->first_child('and')->first_child('equals')->att('choiceid');
			}else{
				push @correct_choiceid, $i->first_child('evaluate')->first_child('equals')->att('choiceid');
			}
			last RESP;
		}
	}
	if (0+@correct_choiceid == 0){c_error("Error parsing response fields.")}
	
	my @choices = $interaction->first_child('choices')->children('choice');
	my @correct_resp = ();
	RESP_1: foreach my $i (@choices){
		RESP_2: foreach my $j (@correct_choiceid){
			if ($i->att('id') eq $j){
				push @correct_resp, $i->first_child('textdata')->att('alttext');
				last RESP_2;
			}
		}
	}
	if (0+@correct_resp == 0){c_error("Error parsing choice fields.")}

	$pregunta=encode("UTF-8", decode_entities($pregunta));
	print "\n<------------ Pregunta ---------->\n$pregunta\n\n<---Respuesta--->\n";
	foreach my $i (@correct_resp){
		print "- ".encode("UTF-8", decode_entities($i))."\n";
	}
}
