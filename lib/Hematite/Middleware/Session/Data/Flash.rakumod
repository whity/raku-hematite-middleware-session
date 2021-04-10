unit class Hematite::Middleware::Session::Data::Flash;

also does Associative;
also does Iterable;

has $!data;
has %!old_data;
has %!all_data handles <list kv keys values>;

method new(%data) {
    return self.bless(data => %data);
}

submethod BUILD(:%data!) {
    %!old_data = %data.raku.EVAL;
    $!data     = %data;
    %!all_data = %!old_data;

    $!data{$_}:delete for $!data.keys;

    return self;
}

multi method AT-KEY(Str $key) is rw {
    # set elements
    my $element_set     := $!data{$key};
    my $element_set_all := %!all_data{$key};

    # get element
    my $element_get := %!all_data{$key};

    return-rw Proxy.new(
        FETCH => method () { $element_get },
        STORE => method ($value) {
            $element_set     = $value;
            $element_set_all = $value;
        }
    );
}

method EXISTS-KEY(Str $key) {
    return %!all_data{$key}:exists;
}

method DELETE-KEY(Str $key) {
    $!data{$key}:delete;
    return %!all_data{$key}:delete;
}

method iterator { return %!all_data.iterator; }
