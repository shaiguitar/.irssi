#CHANGELOG:
#
#28-11-2004:
#it gives a join message in a query if a user joins &bitlbee and you hve a query open with that person.
#
#/statusbar window add join_notice
#use Data::Dumper;

use strict;
use Irssi::TextUI;
#use Irssi::Themes;

use vars qw($VERSION %IRSSI);

$VERSION = '1.0';
%IRSSI = (
    authors     => 'Tijmen "timing" Ruizendaal',
    contact     => 'tijmen@fokdat.nl',
    name        => 'BitlBee_join_notice',
    description => '	1. Adds an item to the status bar wich shows [joined: <nicks>] when someone is joining &bitlbee.
    			2. Shows join messages in the query.',
    license => 'GPLv2',
    url     => 'http://the-timing.nl/stuff/irssi-bitlbee',
    changed => '2005-12-05',
);
my %online;
my %tag;
my $line;
my $bitlbee_channel= "&bitlbee";
my $bitlbee_server_tag="localhost";

Irssi::theme_register([
  'join', '{channick_hilight $0} {chanhost $1} has joined {channel $2}',
]);

Irssi::signal_add_last 'channel sync' => sub {
  my( $channel ) = @_;
  if( $channel->{topic} eq "Welcome to the control channel. Type \x02help\x02 for help information." ){
    #print Dumper($channel);
    $bitlbee_server_tag = $channel->{server}->{tag};
    $bitlbee_channel = $channel->{name};
  }	
};

sub event_join {
  my ($server, $channel, $nick, $address) = @_;
  if ($channel eq ":$bitlbee_channel" && $server->{tag} eq $bitlbee_server_tag){
    $online{$nick} = 1;
    Irssi::timeout_remove($tag{$nick});
    $tag{$nick} = Irssi::timeout_add(7000, 'empty', $nick);
    Irssi::statusbar_items_redraw('join_notice');
    my $window = Irssi::window_find_item($nick);
    if($window){
      $window->printformat(MSGLEVEL_JOINS, 'join', $nick, $address, $bitlbee_channel); 
    }
  }
}
sub join_notice {
  my ($item, $get_size_only) = @_; 
  foreach my $key (keys(%online) )
  {
    $line = $line." ".$key;
  }
  if ($line ne "" ){
    $item->default_handler($get_size_only, "{sb joined:$line}", undef, 1);
    $line = "";
  }else{
    $item->default_handler($get_size_only, "", undef, 1);
  } 
}
sub empty{
  my $nick = shift;
  delete($online{$nick});
  Irssi::timeout_remove($tag{$nick});
  Irssi::statusbar_items_redraw('join_notice');
}

Irssi::signal_add("event join", "event_join");
Irssi::statusbar_item_register('join_notice', undef, 'join_notice');
Irssi::statusbars_recreate_items();

