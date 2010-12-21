use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
#use Data::Dumper;

$VERSION = '1.0';
%IRSSI = (
    authors	=> 'Tijmen "timing" Ruizendaal',
    contact	=> 'tijmen@fokdat.nl',
    name	=> 'BitlBee_nick_change',
    description	=> 'Shows an IM nickchange in an Irssi way. (in a query and in the bitlbee channel).',
    license	=> 'GPLv2',
    url		=> 'http://the-timing.nl/stuff/irssi-bitlbee',
    changed	=> '2006-03-28',
);

my $bitlbee_channel = "&bitlbee";
my $bitlbee_server_tag = "localhost";

Irssi::signal_add_last 'channel sync' => sub {
  my( $channel ) = @_;
  if( $channel->{topic} eq "Welcome to the control channel. Type \x02help\x02 for help information." ){
    #print Dumper($channel);
    $bitlbee_server_tag = $channel->{server}->{tag};
    $bitlbee_channel = $channel->{name};
  }
};

sub message {
  my ($server, $msg, $nick, $address, $target) = @_;
  if($server->{tag} eq $bitlbee_server_tag) {
    if($msg =~ /User.*changed name to/) {
      $nick =$msg;
      $nick =~ s/.* - User //;
      $nick =~ s/'//;
      $nick =~ s/`//;
      $nick =~ s/ changed name to.*//;
      my $window = $server->window_find_item($nick);  
      
      if ($window) {
        $window->printformat(MSGLEVEL_CRAP, 'nick_change',$msg);
        Irssi::signal_stop();
      } else {
        my $window = $server->window_find_item($bitlbee_channel);
        $window->printformat(MSGLEVEL_CRAP, 'nick_change',$msg);
        Irssi::signal_stop();
      }
    }
  }    
}

Irssi::signal_add_last ('message public', 'message');

Irssi::theme_register([
  'nick_change', '$0'
 ]);
