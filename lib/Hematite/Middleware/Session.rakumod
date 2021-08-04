use Hematite::Middleware;

unit class Hematite::Middleware::Session does Hematite::Middleware;

use Hematite::Middleware::Session::Data;
use X::Hematite::Session::NotFoundException;

my $lock  = Lock.new;
my $store = Nil;

sub get-store(*%config) {
    $lock.protect(sub {
        return if $store;

        my $type = %config<type>:delete;
        my $cls  = sprintf(
            'Hematite::Middleware::Session::Store::%s',
            $type.tclc,
        );

        require ::($cls);

        my $class = ::($cls);

        $store = $class.new(|%config);
    });

    return $store;
}

has $!store  = Nil;
has %!config = ();

method init(*%args) {
    my $store_cfg = %args<store>;

    $!store  = get-store(|%($store_cfg));
    %!config = %args;

    return self;
}

method CALL-ME {
    # read session cookie
    my $cookie_name = %!config<cookie>;
    my Str $sid     = self.req.cookies{$cookie_name} || Nil;
    my %data        = ();

    try {
        %data = $!store.get-session-data($sid) if $sid;
        $sid  = $!store.generate-sid if !$sid;

        # instantiate session data and set it in stash
        my $session_data = Hematite::Middleware::Session::Data.new(
            sid  => $sid,
            data => %data,
        );

        # set session object on stash and add the helper methods
        self.stash<__session__> = $session_data;

        self.add-helper('session', sub ($ctx) {
            return $ctx.stash<__session__>;
        });

        self.add-helper('flash', sub ($ctx) {
            return $ctx.session.flash;
        });

        # call next
        self.next;

        # if it's to renew the session, lets clean the data and generate
        #   a new session id
        if ($session_data.renew) {
            $!store.destroy-session($sid);

            %data = ();
            $sid  = $!store.generate-sid;
        }

        # calculate expires
        my (DateTime $expires_at, Int $max_age) = self._calculate-expires-at;

        # save session
        $!store.save-session-data($sid, %data, $expires_at);

        # set cookie
        self._set-cookie($sid, $max_age);

        CATCH {
            my $ex = $_;

            when X::Hematite::Session::NotFoundException {
                $sid = Nil;
                $ex.resume;
            }

            default {
                $ex.rethrow;
            }
        }

        LEAVE {
            self.stash<__session__>:delete;
            self.remove-helper('session');
            self.remove-helper('flash');
        }
    }

    return;
}

method _set-cookie(Str $sid, Int $max_age --> Nil) {
    my Str $name = %!config<cookie>;

    self.res.cookies{$name} = {
        value    => $sid,
        max-age  => $max_age.Str,
        httponly => %!config<httponly> // True,
        secure   => %!config<secure> // False,
    };

    return;
}

method _calculate-expires-at(--> List) {
    my $expires_in = %!config<expires_in> || '';
    my $match      = $expires_in ~~ m:i/^$<amount>=[\d+]$<unit>=[(sec||min||hour||day||month||year)s?]$/;
    my Int $amount = 1;
    my $unit       = 'hour';

    if ($match) {
        $amount = $match<amount>.Str.Int;
        $unit   = $match<unit>.Str;
    }

    my %units_mapping{Regex} = (
        rx:i/secs?/ => 'seconds',
        rx:i/mins?/ => 'minutes',
    );

    for %units_mapping.kv -> $key, $value {
        next if !($unit ~~ $key);

        $unit = $value;
        last;
    }

    my $current_dt = DateTime.now.utc;
    my $expires_at = $current_dt.later(|%($unit => $amount));
    my $diff       = $expires_at - $current_dt;

    return ( $expires_at, $diff.Int );
}
