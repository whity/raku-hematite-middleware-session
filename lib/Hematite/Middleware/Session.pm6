use UUID;
use Hematite::Middleware::Session::Data;
use Hematite::Middleware::Session::Store;
use Hematite::Middleware::Session::Exceptions;

unit class Hematite::Middleware::Session does Callable;

has %!config = ();
has $!store  = Nil;

submethod BUILD(*%args) {
    %!config = %args;

    # instantiate store
    my %store = %!config{'store'};
    my Str $store_cls = sprintf( 'Hematite::Middleware::Session::Store::%s',
        %store{'type'}:delete.tclc );
    require ::($store_cls);

    $!store = ::($store_cls);

    return self;
}

method CALL-ME($ctx, $next) {
    # read session cookie
    my $cookie_name = %!config{'cookie'};
    my Str $sid     = $ctx.req.cookies{$cookie_name} || Nil;
    my %data        = ();

    try {
        # TODO get store object
        my $store = self._get-store;

        # get session from store
        if ($sid) {
            %data = $store.get-session-data($sid);
        }
        else {
            $sid = self._generate-sid;
        }

        # instantiate session data and set it in stash
        my $session_data = Hematite::Middleware::Session::Data.new(
            sid  => $sid,
            data => %data,
        );

        # set session object on stash and add the helper methods
        $ctx.stash{'__session__'}        = $session_data;
        $ctx.stash{'__helper_session__'} = sub ($ctx) {
            return $ctx.stash{'__session__'};
        };
        $ctx.stash{'__helper_flash__'}   = sub ($ctx) {
            return $ctx.session.flash;
        };

        # call next
        $next($ctx);

        # calculate expires
        my DateTime $expires_at = self._calculate-expires-at;

        # save session
        $store.save-session-data($sid, %data, $expires_at);

        # set cookie
        self._set-cookie($ctx, $cookie_name, $sid, $expires_at);

        CATCH {
            my $ex = $_;

            when X::Hematite::Middleware::Session::SessionNotFoundException {
                $sid = self.generate-sid;
                $ex.resume;
            }

            default {
                $ex.rethrow;
            }
        }

        LEAVE {
            if ($store) {
                # destroy store
                $store.clean;
                $store = Nil;
            }

            # clean stash
            my @stash_keys_to_delete = (
                '__session__',
                '__helper_session__',
                '__helper_flash__'
            );
            for @stash_keys_to_delete -> $item {
                $ctx.stash{$item}:delete;
            }
        }
    }

    return;
}

method _generate-sid() returns Str {
    my $uuid = UUID.new(version => 4);
    return $uuid.Str;
}

method _set-cookie($ctx, Str $name, Str $sid, DateTime $expires_at) returns Nil {
    $ctx.res.cookies{$name} = {
        'value'   => $sid,
        'expires' => $expires_at.posix,
    };

    return;
}

method _calculate-expires-at() returns DateTime {
    my $expires_in = %!config{'expires_in'};
    my $match      = $expires_in ~~ m:i/^$<amount>=[\d+]$<unit>=[(sec||min||hour||day||month||year)s?]$/;

    if (!$match) {
        # TODO invalid expires
    }

    my $unit = $match.hash{'unit'};
    my %units_mapping{Regex} = (
        rx:i/secs?/ => 'seconds',
        rx:i/mins?/ => 'minutes',
    );
    for %units_mapping.kv -> $key, $value {
        if ($unit ~~ $key) {
            $unit = $value;
            last;
        }
    }

    my $amount = $match.hash{'amount'};
    return DateTime.now.later(|%($unit => $amount));
}

method _get-store() {
    # create store object and return
    my %store = %!config{'store'};
    return $!store.new(|%store);
}
