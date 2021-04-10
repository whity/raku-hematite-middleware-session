use Hematite::Middleware::Session::Store;

unit class Hematite::Middleware::Session::Store::Redis;

also does Hematite::Middleware::Session::Store;

use Redis;
use JSON::Fast;
use X::Hematite::Session::NotFoundException;

has Redis $!redis = Nil;

submethod BUILD(*%args) {
    $!redis = Redis.new("{%args{'host'}}:{%args{'port'}}");
    return self;
}

method get-session-data(Str $sid) {
    if (!$!redis.exists($sid)) {
        die X::Hematite::Session::NotFoundException.new;
    }

    return from-json($!redis.get($sid).decode);
}

method save-session-data(Str $sid, %data, DateTime $expires_at) {
    my $json = to-json(%data);

    $!redis.set($sid, $json);
    $!redis.expireat($sid, $expires_at.posix);

    return;
}

method destroy-session(Str $sid --> Nil) {
    return if !$!redis.exists($sid);

    $!redis.del($sid);

    return;
}
