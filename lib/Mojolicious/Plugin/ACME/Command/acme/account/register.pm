package Mojolicious::Plugin::ACME::Command::acme::account::register;
use Mojo::Base 'Mojolicious::Plugin::ACME::Command';

use Mojo::Util 'spurt';

has description => 'Register/verify your account with an ACME service';
has usage => sub {
  my $self = shift;
  $self->extract_usage . $self->common_usage;
};

sub run {
  my ($c, @args) = @_;
  my $acme = $c->build_acme(\@args);
  say $acme->register || die "Account not registered\n";

  my $key = $acme->account_key;
  if ($key->generated) {
    my $key_path = $key->path;
    say "Writing $key_path";
    spurt $key->string => $key_path;
  }
}

1;

=head1 NAME

Mojolicious::Plugin::ACME::Command::acme::account::register - ACME account registration/verification

=head1 SYNOPSIS

  Usage: APPLICATION acme account register [OPTIONS]
    myapp acme account register
    myapp acme account register -t -a myaccount.key

=cut

