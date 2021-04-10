unit role Hematite::Middleware::Session::Store;

use UUID;

method get-session-data(Str $sid --> Hash) { ... }

method save-session-data(Str $sid, %data, DateTime $expires_at --> Nil) { ... }

method generate-sid(--> Str) {
    my $uuid = UUID.new(version => 4);
    return $uuid.Str;
}

method destroy-session(Str $sid --> Nil) { ... }
