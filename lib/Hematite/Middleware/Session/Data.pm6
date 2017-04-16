use Hematite::Middleware::Session::Data::Flash;

unit class Hematite::Middleware::Session::Data does Associative does Iterable;

has Str $.id;
has %!data handles <list kv keys values>;
has Hash $!real_data;
has $.flash;

submethod BUILD(Str :$sid, :%data) {
    $!id        = $sid;
    %!data      = %data.grep({ $_.key !~~ m/__\w+__/ });
    $!real_data = %data;

    $!real_data{'__FLASH__'} ||= {};

    $!flash = Hematite::Middleware::Session::Data::Flash.new($!real_data{'__FLASH__'});

    return self;
}

multi method AT-KEY(Str $key) is rw {
    my $element1 := $!real_data{$key};
    my $element2 := %!data{$key};

    return Proxy.new(
        FETCH => method () { $element1; },
        STORE => method ($value) {
            $element1 = $value;
            $element2 = $value;
        }
    );
}

method EXISTS-KEY(Str $key) {
    return $!real_data{$key}:exists;
}

method DELETE-KEY(Str $key) {
    %!data{$key}:delete;
    return $!real_data{$key}:delete;
}

method iterator() { return %!data.iterator; }
