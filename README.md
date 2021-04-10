# Hematite Session Middleware

## Usage

```raku

use Logger;
use Hematite;
use Hematite::Middleware::Session;

class App is Hematite::App {
    method startup {
        self.log.level = Logger::DEBUG;

        # encrypted cookie
        # self.use(
        #     Hematite::Middleware::Session.create(
        #         store => {
        #             type   => 'cookie',
        #             secret => 'secret', # encryption secret key (required),
        #             # secret => ['current', 'old'],
        #         },
        #         cookie     => 'sid',
        #         expires_in => '1hour',
        #     )
        # );

        # redis
        # self.use(
        #     Hematite::Middleware::Session.create(
        #         store => {
        #             type => 'redis',
        #             host => '127.0.0.1',
        #             port => '6379',
        #         },
        #         cookie     => 'sid',
        #         expires_in => '1hour',
        #     )
        # );

        self.GET('/', sub ($ctx) {
            # get session/flash value
            say $ctx.flash<y>;
            say $ctx.session<x>;

            # set session/flash values
            $ctx.flash<y>   = 'y';
            $ctx.session<x> = 'x';

            return $ctx.render('session middleware test', inline => True);
        });
    }
}
```

## TODO

- better doc
- unit tests
- ...

## Contributing

1. Fork it ( https://github.com/[your-github-name]/raku-hematite-middleware-session/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- whity(https://github.com/whity) André Brás - creator, maintainer
