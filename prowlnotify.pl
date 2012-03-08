use strict;
use warnings;

#####
#
# Version history
# 0.6 - quick n dirty fork to android. set API in config
#
# 0.5 
# 	Merged in the /prowl commands from Dennis with the cleanup
# 	by QuagSim and added channel info to notifications
#
# 0.4
#	Changed to use the screen_away setting set by;
#	http://github.com/QuaqSim/irssi-screen_away
# 0.3
#	Removed auto_away stuff and changed to check for hilight
# 0.2
#	Modify to use new API keys, much better!
# 0.1
#	Initial working version
#

# irssi imports
use Irssi;
use Irssi::Irc;
use vars qw($VERSION %IRSSI %config);

use LWP::UserAgent;

$VERSION = "0.5";

%IRSSI = (
	authors => "Andrew Elwell,Denis Lemire",
	contact => "Andrew.Elwell\@gmail.com",
	name => "prowl",
	description => "Sends messages via prowl (iphone) or notify my android",
	license => "GPLv2",
	url => "https://github.com/Elwell/irssi-prowlnotify",
);

$config{debug} = 0;
$config{API} = "NMA"; # NMA or prowl


sub debug
{
	if ($config{debug}) {
		my $text = shift;
		my $caller = caller;
		Irssi::print('From ' . $caller . ":\n" . $text);
	}
}

sub send_prowl
{
	my ($event, $text) = @_;

	debug("Sending prowl");

	my %options = ();

	$options{'application'} ||= "Irssi";
	$options{'event'} = $event;
	$options{'notification'} = $text;
	$options{'priority'} ||= 0;

	my ($apikey, $requestURL);
	if ($config{API} eq "NMA") {
		$apikey = $ENV{HOME} . "/.NMA_apikey" ;
		$requestURL = "https://www.notifymyandroid.com/publicapi/notify";
	} elsif ($config{API} eq "prowl"){
		$apikey = $ENV{HOME} . "/.prowlkey" ;
		$requestURL = "https://api.prowlapp.com/publicapi/add";
	} else {
		debug("Unsupported API\n");
	}


	# Get the API key from STDIN if one isn't provided via a file or from the command line.

	if (open(APIKEYFILE, $apikey)) {
		$options{apikey} = <APIKEYFILE>;

		chomp $options{apikey};

		close(APIKEYFILE); 
	} else {
		debug ("Unable to open prowl key file\n");
	}

	# URL encode our arguments
	$options{'application'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	$options{'event'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	$options{'notification'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

	# Generate our HTTP request.
	my ($userAgent, $request, $response);
	$userAgent = LWP::UserAgent->new;
	$userAgent->agent("ProwlScript/1.0");


	$request = HTTP::Request->new(POST => $requestURL);
	$request->content_type('application/x-www-form-urlencoded');
	$request->content(sprintf("apikey=%s&application=%s&event=%s&description=%s&priority=%d",
					$options{'apikey'},
					$options{'application'},
					$options{'event'},
					$options{'notification'},
					$options{'priority'}));

	$response = $userAgent->request($request);

	if ($response->is_success) {
		debug ("Notification successfully posted.\n");
	} elsif ($response->code == 401) {
		debug ("Notification not posted: incorrect API key.\n");
	} else {
		debug ("Notification not posted: " . $response->content . "\n");
	}
}

sub msg_pub
{
	my ($server, $data, $nick, $mask, $target) = @_;
	
	if (Irssi::settings_get_bool('screen_away_active') == 1 and Irssi::settings_get_bool('screen_away') == 0) {
		return;
	}
	if ($data =~ /$server->{nick}/i) {
		debug("Got pub msg with my name in $target");
		send_prowl ("Mention $target", $nick . ': ' . $data);
	}

}

sub msg_pri
{
	my ($server, $data, $nick, $address) = @_;

	if (Irssi::settings_get_bool('screen_away_active') == 1 and Irssi::settings_get_bool('screen_away') == 0) {
		return;
	}

	if (Irssi::active_win()->get_active_name() ne $nick) {
		send_prowl ("Private msg", $nick . ': ' . $data);
	}
}

sub cmd_prowl
{
	my ($args, $server, $winit) = @_;

	$args = lc($args);

	if ($args =~/^test$/) {
		Irssi::print("Sending test notification ($config{API})");
		send_prowl ("Test", "If you can read this, it worked.");
	} elsif ($args =~/^debug$/) {
		if ($config{debug}) {
			$config{debug} = 0;
			Irssi::print("Prowl debug disabled");
		} else {
			$config{debug} = 1;
			Irssi::print("Prowl debug enabled");
		}
	} else {
		Irssi::print('Prowl: Say what?!');
	}
}

Irssi::command_bind 'prowl' => \&cmd_prowl;
Irssi::signal_add_last('message public', 'msg_pub');
Irssi::signal_add_last('message private', 'msg_pri');
