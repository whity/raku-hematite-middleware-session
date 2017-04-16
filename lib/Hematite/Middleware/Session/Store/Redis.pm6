use Redis;
use JSON::Fast;
use Hematite::Middleware::Session::Store;
use Hematite::Middleware::Session::Exceptions;

unit class Hematite::Middleware::Session::Store::Redis is
    Hematite::Middleware::Session::Store;

has Redis $!redis = Nil;

submethod BUILD(*%args) {
    $!redis = Redis.new("$( %args{'host'} ):$( %args{'port'} )");
    return self;
}

method get-session-data(Str $sid) {
    if (!$!redis.exists($sid)) {
        die(X::Hematite::Middleware::Session::SessionNotFoundException.new);
    }

    return from-json($!redis.get($sid).decode);
}

method save-session-data(Str $sid, %data, DateTime $expires_at) {
    my $json = to-json(%data);

    $!redis.set($sid, $json);
    $!redis.expireat($sid, $expires_at.posix);

    return;
}

method clean {
    $!redis.quit;
}
