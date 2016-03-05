package Mojo::ACME::ChallengeServer;

use Mojo::Base -base;

use Mojo::Server::Daemon;
use Mojo::Util 'hmac_sha1_sum';
use Mojolicious;
use Scalar::Util;

has acme => sub { die 'Mojo::ACME instance is required' };
has callbacks => sub { {} };
has server => sub { shift->_start };

sub start { shift->tap('server') }

sub _start {
  my $self = shift;
  my $secret = $self->acme->secret;
  my $app = Mojolicious->new(
    secrets => [$secret],
  );
  $app->log->unsubscribe('message');
  my $server = Mojo::Server::Daemon->new(
    app    => $app,
    listen => [$self->acme->server_url],
    silent => 1,
  );
  Scalar::Util::weaken $self;
  $app->routes->get('/:token' => sub {
    return unless $self;
    my $c = shift;
    my $token = $c->stash('token');
    my $hmac = $c->req->headers->header('X-HMAC');

    return $c->reply->not_found
      unless my $cb = delete $self->callbacks->{$token};
    $c->on(finish => sub { $cb->($self->acme, $token) if $self });

    return $c->render(text => 'Unauthorized', status => 401)
      unless $hmac eq hmac_sha1_sum($token, $secret);

    my $auth = $self->acme->keyauth($token);
    $c->res->headers->header('X-HMAC' => hmac_sha1_sum($auth, $secret));
    $c->render(text => $auth);
  });
  return $server->start;
}

1;

