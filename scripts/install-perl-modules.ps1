# cpan o conf http_proxy http://10.0.2.2:3128
perl -MCPAN -e @'
my @modules = qw (CGI Digest::SHA DateTime DateTime::TimeZone Date::Format DBI URI
                  Template Email::Send Email::Sender Email::MIME List::MoreUtils
                  Math::Random::ISAAC File::Slurp JSON::XS Win32 Win32::API
                  Test::Taint SOAP::Lite XMLRPC::Lite JSON::RPC Moo
                  DateTime::TimeZone::Local::Win32);
foreach my $module (@modules) {
  CPAN::Shell->notest('install', $module);
}
'@
