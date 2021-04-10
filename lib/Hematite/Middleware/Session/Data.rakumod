use Hematite::Middleware::Session::Data::Flash;

unit class Hematite::Middleware::Session::Data;

also does Associative;
also does Iterable;

has Str $.id;
has Hash $!data handles <list kv keys values>;
has %!public_data;
has $.flash;
has $.renew is rw = False;

submethod BUILD(Str :$sid, :%data) {
    $!id          = $sid;
    $!data        = %data;
    %!public_data = %data.grep({ $_.key ne '__FLASH__' });

    $!data<__FLASH__> ||= {};

    $!flash = Hematite::Middleware::Session::Data::Flash.new(
        $!data<__FLASH__>,
    );

    return self;
}

multi method AT-KEY(Str $key) is rw {
    die X::Syntax::Reserved.new(
        reserved => $key
    ) if $key eq '__FLASH__';

    my $element1 := $!data{$key};
    my $element2 := %!public_data{$key};

    return-rw Proxy.new(
        FETCH => method () { $element2 },
        STORE => method ($value) {
            $element1 = $value;
            $element2 = $value;
        }
    );
}

method EXISTS-KEY(Str $key) {
    return %!public_data{$key}:exists;
}

method DELETE-KEY(Str $key) {
    return %!public_data{$key}:delete;
}

method iterator { return %!public_data.iterator; }
