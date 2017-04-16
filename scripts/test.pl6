#!/usr/bin/env perl6

use lib '../lib';

use Hematite::Plugin::Session::Data;

my $data = Hematite::Plugin::Session::Data.new(
    sid => '12313',
    data => {'__FLASH__' => {'xpto' => 2}}
);

$data{'x'} = [1231, 12313, 'aasdad'];

say $data{'x'};
say $data<s>:exists;
#say $data<x>:delete;
#say $data{'x'};

say $data.list;

for $data.kv -> $k, $v {
    say "{ $k } - { $v }";
}



say "flash";

$data.flash{'s'} = 1;
say $data.flash.keys;
say $data.flash{'xpto'};
