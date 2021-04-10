use X::Hematite::Exception;

unit class X::Hematite::Session::NotFoundException is X::Hematite::Exception;

method message() returns Str {
    return 'invalid session';
}
