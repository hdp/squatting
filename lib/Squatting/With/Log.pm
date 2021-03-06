package Squatting::With::Log;

#use strict;
#no  strict 'refs';
#use warnings;

sub service {
  my ($app, $c, @args) = @_;
  my $config = \%{$app.'::CONFIG'};
  $c->log ||= Squatting::Log->new($config);
  $app->next::method($c, @args);
}

package Squatting::Log;

#use strict;
#no  strict 'refs';
#use warnings;
use IO::All;

our $log;

sub new {
  my ($class, $config) = @_;
  return $log if ($log);
  my $path   = $config->{'with.log.path'}   || '='; # (default STDERR)
  my $level  = $config->{'with.log.levels'} || 'debug,info,warn,error,fatal';
  my $levels = +{ map { $_ => 1 } split(/\s*,\s*/, $level) };
  $log = bless({ path => $path, levels => $levels } => $class);
}

sub timestamp {
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
  sprintf(
    '%d-%02d-%02dT%02d:%02d:%02d',
    $year + 1900, $mon + 1, $mday,
    $hour, $min, $sec
  );
}

for my $level (qw(debug info warn error fatal)) {
  *{$level} = sub {
    my ($self, @messages) = @_;
    my $is_level = "is_$level";
    return unless $self->$is_level;
    for (@messages) {
      sprintf('%-5s %s ! %s'."\n", $level, timestamp, $_) >> io($self->{path});
    }
  };
  *{"is_$level"} = sub {
    $_[0]->{levels}->{$level};
  };
}

sub enable {
  my $self = shift;
  $self->{levels}->{$_} = 1 for (@_);
}

*{"levels"} = \&enable;

sub disable {
  my $self = shift;
  $self->{levels}->{$_} = 0 for (@_);
}

1;

=head1 NAME

Squatting::With::Log - a simple error log for Squatting apps

=head1 SYNOPSIS

Adding simple logging to your Squatting app:

  use App 'With::Log', 'On::CGI';

This will let log from within your controllers:

  C(
    Day => [ '/(\d+)/(\d+)/(\d+)' ],
    get => sub {
      my ($self, $year, $month, $day) = @_;
      my $log = $self->log;
      $log->debug(" year: $year");
      $log->info ("month: $month");
      $log->warn ("  day: $day");
      # you also get $log->error and $log->fatal
      $self->render('day');
    }
  )

=head1 DESCRIPTION

Squatting::With::Log provides a simple logging object that can be used from
within your controllers to send messages to either a log file or STDERR for
informational purposes.  Typically, these messages would be useful during
development and debugging but would be disabled for production use.

To use this module, pass the string C<'With::Log'> to the C<use> statement that
loads your Squatting app.

=head1 CONFIGURATION

Squatting apps may set the following values in their C<%CONFIG> hash to control
the behavior of this module.

=over 4

=item with.log.path

This should be a string that specifies the full path to where you want the
logs to be sent.

B<Example>:

  $CONFIG{'with.log.path'} = "/tmp/error_log";

=item with.log.levels

This should be a comma-separated string that lists all the log levels you
want to enable.

B<Example>:  Only output messages with a log level of C<error> or C<fatal>.

  $CONFIG{'with.log.levels'} = "error,fatal";

=back

=head1 API

=head2 Object Construction

=head3 $log = Squatting::Log->new(\%config)

=head2 Configuration

=head3 $log->enable(@levels)

This method enables the list of log levels you send it.

=head3 $log->disable(@levels)

This method disables the list of log levels you send it.

=head2 Introspection

=head3 $log->is_debug

=head3 $log->is_info

=head3 $log->is_warn

=head3 $log->is_error

=head3 $log->is_fatal

These methods return true if their respective log levels are enabled.

=head2 Logging

=head3 $log->debug(@messages)

=head3 $log->info(@messages)

=head3 $log->warn(@messages)

=head3 $log->error(@messages)

=head3 $log->fatal(@messages)

These methods output the list of log messages you send it using the
specified log level.

=head1 SEE ALSO

L<Catalyst::Log>

=cut
