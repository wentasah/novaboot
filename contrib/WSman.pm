#!/usr/bin/perl -w
#Supporting script for novaboot, this script handle communication with AMT computer
package WSman; 
use LWP::UserAgent;
use LWP::Authen::Digest;  
use Exporter;
#use WWW::Mechanize;
our @EXPORT = qw( powerChange );

sub genXML { #IP, username, password, schema, className, pstate
	#AMT numbers for PowerStateChange: 2 on, 4 standby, 7 hibernate, 8 off, 
#10 reset, 11 MNI interupt(on windows->bluescreen;-)) 
	my %pstates = ("on", 2,
				"standby", 4,
				"hibernate", 7,
				"off", 8,
				"reset", 10,
				"MNI", 11);
	my $head="<s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:a=\"http://schemas.xmlsoap.org/ws/2004/08/addressing\" xmlns:w=\"http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd\">
	<s:Header><a:To>http://".$_[0].":16992/wsman</a:To>
	<w:ResourceURI s:mustUnderstand=\"true\">".$_[3]."</w:ResourceURI>
	<a:ReplyTo><a:Address s:mustUnderstand=\"true\">http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</a:Address></a:ReplyTo>
	<a:Action s:mustUnderstand=\"true\">".$_[3].$_[4]."</a:Action>
	<w:MaxEnvelopeSize s:mustUnderstand=\"true\">153600</w:MaxEnvelopeSize>
	<a:MessageID>uuid:709072C9-609C-4B43-B301-075004043C7C</a:MessageID>
	<w:Locale xml:lang=\"en-US\" s:mustUnderstand=\"false\" />
	<w:OperationTimeout>PT60.000S</w:OperationTimeout>
	<w:SelectorSet><w:Selector Name=\"Name\">Intel(r) AMT Power Management Service</w:Selector></w:SelectorSet>
	</s:Header><s:Body>";
	my $body="<p:RequestPowerStateChange_INPUT xmlns:p=\"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_PowerManagementService\">
	<p:PowerState>".$pstates{$_[5]}."</p:PowerState>
	<p:ManagedElement><a:Address>http://".$_[0].":16992/wsman</a:Address>
	<a:ReferenceParameters><w:ResourceURI>http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ComputerSystem</w:ResourceURI>
		<w:SelectorSet><w:Selector Name=\"Name\">ManagedSystem</w:Selector></w:SelectorSet>
	</a:ReferenceParameters></p:ManagedElement>
	</p:RequestPowerStateChange_INPUT>";
	my $footer="</s:Body></s:Envelope>
	";
	my $XML=$head.$body.$footer;
	$XML =~ s/\n/ /;
	$XML =~ s/\t/ /; 
	$XML;
}
  
sub sendPOST{ #ip, username, password, content
	my $host=$_[0];
	my $username=$_[1];
	my $password=$_[2];
	my $content=$_[3];

	my $ua = LWP::UserAgent->new(keep_alive=>1);
	$ua->agent(" ");
	$ua->credentials("$host:16992","Digest:DAC80000000000000000000000000000",  $username => $password); #not sure if realm is identical for every AMT computer, need test
	# Create a request
	my $req = HTTP::Request->new(POST => "http://$host:16992/wsman");
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($content);

	my $res = $ua->request($req);
	$res = $ua->request($req);
	if (!($res->is_success)) {
		die $res->status_line;
	}	
}

sub powerChange  {#IP, username, password, pstate
	my $schema="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_PowerManagementService";
	my $className="/RequestPowerStateChange";
	my $content = genXML($_[0],$_[1],$_[2],$schema,$className,$_[3]);
	sendPOST($_[0], $_[1],$_[2],$content);
}  
