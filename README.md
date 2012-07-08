# prowlnotify Irssi Plugin

**prowlnotify** is a simple script to send push notifications from Irssi to the
iPhone via Prowl (http://www.prowlapp.com) or to Android devices via NMA
(https://www.notifymyandroid.com/)

It was originally based on BCOW's awayproxy.pl script which automatically marks
you as away when your last IRC client disconnects from Irssi's proxy. This fork
of Denis Lemire's version removes the proxy and checks for screen_away boolean
flag.

## Installation

  1. Create a text file containing your API key in either in ~/.prowlkey or ~/.NMA_apikey
  2. Copy the script into Irssi's scripts dir (typically ~/.irssi/scripts/)
  3. Edit $config{API} = ""; (line 43) to specify prowl or NMA
  4. /script load prowlnotify.pl
  5. Send yourself a test message with /prowl test


## screen_away
This version of the script depends on the screen_away boolean flag to see if
it should notify or not. it therefore depends on screen_away.pl

## perl dependencies
The Notify My Android API calls are sent via HTTPS. For this to work you need
to have IO::Socket::SSL installed:

     cpan -i IO::Socket::SSL
