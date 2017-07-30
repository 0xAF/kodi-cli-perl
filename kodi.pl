#!/usr/bin/env perl
#
# Copyright (C) 2017 Stanislav Lechev <af@0xAF.org>
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
#
use strict;
use warnings;
my $version = "0.1";

my $host = "192.168.1.2";
my $port = "80";
my $user = "username";
my $pass = "password";

my $keymap = {
	'b'			=> 'GUI.ActivateWindow("window": "tvtimers")',
	'c'			=> 'Input.ContextMenu',
	'e'			=> 'GUI.ActivateWindow("window": "tvguide")',
	'f'			=> 'Input.ExecuteAction("action": "fastforward")',
	'h'			=> 'GUI.ActivateWindow("window": "tvchannels")',
	'i'			=> 'Input.ExecuteAction("action": "menu")',
	'j'			=> 'GUI.ActivateWindow("window": "radiochannels")',
	'k'			=> 'GUI.ActivateWindow("window": "tvrecordings")',
	'm'			=> 'Input.ExecuteAction("action": "menu")',
	'n'			=> 'Input.ExecuteAction("action": "playlist")',
	'p'			=> 'Input.ExecuteAction("action": "play")',
	'q'			=> 'Input.ExecuteAction("action": "queue")',
	'r'			=> 'Input.ExecuteAction("action": "rewind")',
	#'s'			=> 'GUI.ActivateWindow("window": "shutdownmenu")', # shutdown dialog blocks the kodi's webserver and the connection hangs
	'x'			=> 'Input.ExecuteAction("action": "stop")',
	'y'			=> 'Input.ExecuteAction("action": "switchplayer")',
	#' '			=> 'Player.PlayPause("playerid": __PLAYER_ID__)',
	' '			=> 'Input.ExecuteAction("action": "playpause")',
	'.'			=> 'Input.ExecuteAction("action": "skipnext")',
	','			=> 'Input.ExecuteAction("action": "skipprevious")',
	"\t"		=> 'GUI.SetFullScreen("fullscreen": "toggle")',
	'-'			=> 'Input.ExecuteAction("action": "volumedown")',
	'+'			=> 'Input.ExecuteAction("action": "volumeup")',
	'='			=> 'Input.ExecuteAction("action": "volumeup")',
	#'0'			=> 'Input.ExecuteAction("action": "number0")',
	#'1'			=> 'Input.ExecuteAction("action": "number1")',
	#'2'			=> 'Input.ExecuteAction("action": "number2")',
	#'3'			=> 'Input.ExecuteAction("action": "number3")',
	#'4'			=> 'Input.ExecuteAction("action": "number4")',
	#'5'			=> 'Input.ExecuteAction("action": "number5")',
	#'6'			=> 'Input.ExecuteAction("action": "number6")',
	#'7'			=> 'Input.ExecuteAction("action": "number7")',
	#'8'			=> 'Input.ExecuteAction("action": "number8")',
	#'9'			=> 'Input.ExecuteAction("action": "number9")',
	'\\'		=> 'GUI.SetFullScreen("fullscreen": "toggle")',
	"\r"		=> 'Input.ExecuteAction("action": "select")',
	"\n"		=> 'Input.ExecuteAction("action": "select")',
	chr(0x7F)	=> 'Input.ExecuteAction("action": "back")', # backspace

	# escape (special) chars
	'home'		=> 'Input.ExecuteAction("action": "firstpage")',
	'end'		=> 'Input.ExecuteAction("action": "lastpage")',
	'pgup'		=> 'Input.ExecuteAction("action": "pageup")',
	'pgdown'	=> 'Input.ExecuteAction("action": "pagedown")',
	'left'		=> 'Input.ExecuteAction("action": "left")',
	'right'		=> 'Input.ExecuteAction("action": "right")',
	'up'		=> 'Input.ExecuteAction("action": "up")',
	'down'		=> 'Input.ExecuteAction("action": "down")',
	'escape'	=> 'Input.ExecuteAction("action": "previousmenu")',

};

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/local/lib/perl5" }
use Term::ReadKey;
ReadMode 4;
END { ReadMode 0; }
use HTTP::Request;
use LWP::UserAgent;

my $debug = (defined $ARGV[0] and $ARGV[0] eq '-d') ? 1 : 0;

printf qq{Kodi CLI v$version.
Copyright (C) 2017 Stanislav Lechev <af\@0xAF.org>

Press a key to send to Kodi.
Press Ctrl-C, Ctrl-D or Ctrl-Q to exit.
Press [`] to send text.
Press F1 to see the keymap.
Press F2 to send RPC command like this:
Input.ExecuteAction("action": "playpause")

};

while (defined (my $key = ReadKey())) {
	my $k = ord $key;
	my $action = '';

	if (0) {
	} elsif ($k == 0x03 || $k == 0x04 || $k == 0x11) { # ctrl-c / ctrl-d / ctrl-q
		last; # exit
	} elsif (defined $keymap->{$key}) { # check the keymap hash
		$action = $keymap->{$key};
	} elsif ($key eq '`') { # send text
		my $text = get_string();
		$action = 'Input.SendText("text": "'.$text.'")' if ($text ne '');
	} elsif ($k == 0x1B) { # special keys, starting with ESC char
		my $sp = ReadKey(-1);
		if (not defined $sp) { # just escape
			$action = $keymap->{escape};
		} else {
			if ( $sp ne '[') {
				debug(sprintf "Don't know what to do with this special char (0x%X)\n", ord $sp);
				next;
			}
			$sp = ord ReadKey(-1);
			if (0) {
			} elsif ($sp == 0x5B) { # Function keys
				my $fn = ord ReadKey(-1);
				if (0) {
				} elsif ($fn == 0x41) { # F1
					print "Available keys:\n";
					foreach my $k (sort keys %{$keymap}) {
						my $kn = $k;
						$kn = '\t' if ($k eq "\t");
						$kn = 'bs' if ($k eq chr(0x7F));
						$kn = '\r' if ($k eq "\r");
						$kn = '\n' if ($k eq "\n");
						$kn = 'space' if ($k eq " ");
						print "$kn\t- $keymap->{$k}\n";
					}
					print "\n\n";
				} elsif ($fn == 0x42) { # F2 - send RPC command
					$action = get_string("Enter RPC Command");
				} else {
					debug(sprintf "Unknown FN Special: [0x%X]\n", $sp);
					while (my $extra = ReadKey(-1)) { # flush the rest chars
						debug(sprintf "Extra: 0x%X\n", ord $extra);
					}
				}
			} elsif ($sp == 0x31) { # home
				ReadKey(-1); # flush
				$action = $keymap->{home};
			} elsif ($sp == 0x32) { # ins
				ReadKey(-1); # flush
				$action = $keymap->{insert};
			} elsif ($sp == 0x33) { # del
				ReadKey(-1); # flush
				$action = $keymap->{delete};
			} elsif ($sp == 0x34) { # end
				ReadKey(-1); # flush
				$action = $keymap->{end};
			} elsif ($sp == 0x35) { # page up
				ReadKey(-1); # flush
				$action = $keymap->{pgup};
			} elsif ($sp == 0x36) { # page down
				ReadKey(-1); # flush
				$action = $keymap->{pgdown};
			} elsif ($sp == 0x41) { # up
				$action = $keymap->{up};
			} elsif ($sp == 0x42) { # down
				$action = $keymap->{down};
			} elsif ($sp == 0x43) { # right
				$action = $keymap->{right};
			} elsif ($sp == 0x44) { # left
				$action = $keymap->{left};
			} else {
				debug(sprintf "Unknown Special: [0x%X]\n", $sp);
				while (my $extra = ReadKey(-1)) { # flush the rest chars
					debug(sprintf "Extra: 0x%X\n", ord $extra);
				}
			}
		}
	} else {
		debug(sprintf "Unknown Key: [%s] [chr: 0x%X]\n", $key, $k);
	}

	kodi($action) if (defined $action and $action ne '');
}

sub kodi {
	my $arg = shift;
	my ($method) = $arg =~ /^([^\(]+)/;
	my ($data) = $arg =~ /\(([^\)]+)\)/;
	$data = '' unless defined $data;
	unless (defined $method) {
		print "\r Unknown action.\e[K\r";
		return;
	}

	#if ($data=~/__PLAYER_ID__/) {
	#	my ($player_id, $player_type) = player();
	#	$data =~ s/__PLAYER_ID__/$player_id/g;
	#	$arg =~ s/__PLAYER_ID__/$player_id/g;
	#}

	my $json = '{"jsonrpc": "2.0", "method": "'.$method.'", "params": { '.$data.' }, "id": 1 }';
	print "\r Sending: $arg\e[K\r";

	my $lwp = LWP::UserAgent->new;
	my $req = HTTP::Request->new(POST => "http://$host:$port/jsonrpc");
	$req->content_type('application/json');
	$req->authorization_basic($user, $pass);
	$req->content($json);
	my $res = $lwp->request($req);
	debug($res->content);
	unless ($res->content =~ /Server closed connection without sending any data back/ or $res->content =~ /"result":/) {
		# problem
		print "Kodi Error: ".$res->content."\n";
		print "Request: $json\n";
	}
}

#sub player {
#	my $lwp = LWP::UserAgent->new;
#	my $req = HTTP::Request->new(POST => "http://$host:$port/jsonrpc");
#	$req->content_type('application/json');
#	$req->authorization_basic($user, $pass);
#	$req->content('{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 99}');
#	my $res = $lwp->request($req);
#	my ($id) = $res->content=~/playerid[^:]*:(\d+)[^,]*,/;
#	my ($type) = $res->content=~/type[^:]*:[^"]*"([^"]+)"/;
#	#p $res->content;
#	return ($id, $type);
#}

sub debug {
	print "\n".join("\n", @_)."\n" if ($debug > 0);
}

sub get_string {
	my $prompt = shift || "Enter text to send";
	printf "\r$prompt (ESC to cancel): ";
	my $text = '';
	while (my $k = ReadKey(0)) {
		last if ($k eq "\n"); # enter
		if (ord $k == 0x1B) { # escape and other special chars will cancel text input
			ReadKey(-1) for (1..5); # flush the rest
			$text = '';
			last;
		} elsif (ord $k == 0x7F) { # backspace
			$text =~ s/^(.*).{1}$/$1/;
			print "\b \b";
		} else {
			$text.= $k;
			print $k;
		}
	}
	print "\r Canceled.\e[K\r" if ($text eq '');
	return $text;
}

# vim: set ts=4 sw=4 ss=4 :
