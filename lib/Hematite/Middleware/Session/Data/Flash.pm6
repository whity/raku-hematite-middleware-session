unit class Hematite::Middleware::Session::Data::Flash does Associative does Iterable;

has $!data;
has %!old_data;
has %!all_data handles <list kv keys values>;

method new(%data) {
    return self.bless(data => %data);
}

submethod BUILD(:%data!) {
    %!old_data = %data;
    $!data     = %data = ();
    %!all_data = ($!data.Hash, %!old_data);

    return self;
}

multi method AT-KEY(Str $key) is rw {
    # set elements
    my $element_set     := $!data{$key};
    my $element_set_all := %!all_data{$key};

    # get elements
    my $element1 := $!data{$key};
    my $element2 := %!old_data{$key};

    return Proxy.new(
        FETCH => method () { $element1 || $element2; },
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
    %!all_data{$key}:delete;
    return $!data{$key}:delete;
}

method iterator() { return %!all_data.iterator; }
