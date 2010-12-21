use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '1.0';
%IRSSI = (
    authors     => 'Robin Lee Powell',
    contact     => 'rlpowell@digitalkingdom.org',
    name        => q{Support Script For RLP's Campfire-Over-Jabber Hack},
    description => q{This script is *ONLY* useful if you're using my
Campfire-Over-Jabber hack.

FIXME: link

It's basically a bunch of hacks designed
to make the private messages from the jabber users, each of which
represent an entire campfire *room*, act like they come from a bunch
of different users, at least for some purposes.

To use it, put a space-seperated list of users into the
campfire_hack_nicks setting, like so:

  /set campfire_hack_nicks ey-cf-support ey-cf-sysadmin

It does the following things in a /query room with the same name as
the entries in that setting:

1.  The messages are presented as public messages from a "User" with
a name based on the CampFire name (sort of; it's actually
implemented with the "echo" command so the formatting isn't awful).

2.  Tab completion is messed with so that it'll work with all of the
Campfire users *THAT HAVE SPOKEN SO FAR* in the channel.  The
software has no way to get an actual list of the users normally, but
see below.

3.  If you say just "USER LIST" by itself, my hack responds with a
list of all the users in the channel.  This list is parsed and added
to the list of tab completion speakers.
    
4.  When using tab completion on an empty input buffer, completes to
the nick of the person who spoke most recently.  This can't be done
via another script (i.e. "Complete Last-Spoke"), because no other
part of irssi sees these virtual users.

This script is uses bits of
http://scripts.irssi.org/html/complete_lastspoke.pl.html by Daenyth,
version 2.1

The modifications by Robin Lee Powell would be public domain, but
"Complete Last-Spoke" was GPLv2, so here we are.

It also uses ideas from
http://scripts.irssi.org/html/dictcomplete.pl.html by Juerd and Timo
Sirainen
},

    license     => 'GPL2',
);

my %list_of_speakers;
my %list_of_last_speakers;

sub complete_to_last_nick {
  my ($complist, $window, $word, $linestart, $want_space) = @_;
  ## print "in complete_to_last_nick: $window \n";
  my @hack_nicks = split( /\s+/, Irssi::settings_get_str( 'campfire_hack_nicks' ) );
  return unless grep { $_ eq $window->{active}->{name} } @hack_nicks;

  my $last_speaker = get_last_speaker($window);
  return unless defined $last_speaker;

  my $speakers = get_speakers($window);

  ## print "s for w: ".Dumper($speakers)."\n";
  ## print "ls for w: ".Dumper($last_speaker)."\n";

  my $suffix = '';
  if($linestart eq '' ) {
    $suffix = Irssi::settings_get_str('completion_char');
  }
  if($linestart eq '' && $word eq '') {
    @$complist = $last_speaker . $suffix;
  } else {
    foreach my $name (keys %{$speakers}) {
      ## print "checking: $word , $name \n";
      if( $name =~ m{^$word|\s$word}i ) {
        ## print "complisting $name\n";
        @$complist = $name . $suffix;
        last;
      }
    }
  }
  $$want_space = 1;
  Irssi::signal_stop();
}

sub get_speakers {
  my $window = shift;
  return $list_of_speakers{$window->{active}->{name}};
}

sub get_last_speaker {
  my $window = shift;
  return $list_of_last_speakers{$window->{active}->{name}};
}

sub store_last_speaker_private {
  my ($server, $message, $speaker, $address ) = @_;
  my @hack_nicks = split( /\s+/, Irssi::settings_get_str( 'campfire_hack_nicks' ) );

  use Data::Dumper;
  ## print "bn1: ".Dumper(\@hack_nicks)."\n";
  ## print "s: $speaker\n";
  ## print "stuff: ".Dumper(\@_)."\n";

  if( grep { $_ eq $speaker } @hack_nicks ) {
    my ($new_speaker, $new_message) = ( $message =~ m{^([^:]*):\s*(.*)} );
    chomp( $new_speaker );

    if( $new_speaker eq 'USER LIST' ) {
      foreach my $name (split( /\s+----\s+/, $new_message)) {
        ## print "user list ns: $name\n";
        $list_of_last_speakers{$speaker} = $name;
        $list_of_speakers{$speaker}->{$name} = 1;
      }
    } else {

      Irssi::signal_stop();
      print "about to run: echo -window $speaker -level public $message\n";
      $server->command("echo -window $speaker -level public $message\n");
#    Irssi::signal_emit( 'message public', $server, $new_message, $new_speaker,
#      $new_speaker, $speaker );


      ## print "ns: $new_speaker\n";
      $list_of_last_speakers{$speaker} = $new_speaker;
      $list_of_speakers{$speaker}->{$new_speaker} = 1;
    }
  }
}

Irssi::signal_add_first( 'complete word',  \&complete_to_last_nick );
# This has to be _first because I use trigger with it and it changes
# these messages into echoes; see FIXME: web page
Irssi::signal_add_first ( 'message private', \&store_last_speaker_private    );
#Irssi::signal_add_last ( 'message public', \&store_last_speaker    );
#Irssi::signal_add_last ( 'ctcp action',    \&store_last_actor      );
Irssi::settings_remove( 'completion_breakup_nicks' );
Irssi::settings_add_str( 'misc', 'campfire_hack_nicks', '' );
