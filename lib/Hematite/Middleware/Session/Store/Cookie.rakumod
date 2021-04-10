use Hematite::Middleware::Session::Store;

unit class Hematite::Middleware::Session::Store::Cookie;

also does Hematite::Middleware::Session::Store;

use JSON::Fast;
use Gcrypt::Simple :AES256;
use MIME::Base64;
use UUID;
use Logger;

has @!secrets = ();

submethod BUILD(:$secret!, *%args) {
    my $secrets = $secret.raku.EVAL;

    $secrets = [$secrets] if !$secrets.isa(Array);

    @!secrets = $secrets.Array;

    return self;
}

method get-session-data(Str $sid is rw --> Hash) {
    # try to decrypt using all the registers secrets

    my $data_encrypted = MIME::Base64.decode($sid);
    my $data           = Nil;

    for @!secrets -> $secret {
        $data = try { AES256($secret).decrypt($data_encrypted) };

        next if !$data;

        Logger.get.debug(qq/[session] "{$sid}" decrypted with "{$secret}"/);

        last;
    }

    # if data was not successful decrypted, just empty hash
    if (!$data) {
        $sid = Nil;
        return {};
    }

    $data = from-json($data);
    $sid  = $data<sid>;

    return $data<data>;
}

method save-session-data(Str $sid is rw, %data, DateTime $expires_at --> Nil) {
    my $json = to-json(
        {
            sid  => $sid.Str,
            data => %data,
        },
        :!pretty,
    );

    # encrypt using the first key

    my $secret = @!secrets.first;

    $sid = MIME::Base64.encode(
        AES256($secret).encrypt($json),
        :oneline,
    );

    return;
}

method destroy-session(Str $sid --> Nil) {
    # no need to do anything
}
