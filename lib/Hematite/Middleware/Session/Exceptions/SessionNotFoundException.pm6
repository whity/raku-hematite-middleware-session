unit class X::Hematite::Middleware::Session::SessionNotFoundException is Exception;

method message() returns Str {
    return 'invalid session';
}
