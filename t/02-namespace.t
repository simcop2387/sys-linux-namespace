use Test::More tests => 4;

# test 1
use_ok("Sys::Linux::Namespace");

# test 2
SKIP: {
  skip "Need to be root to run test", 3 unless $< == 0;
  ok(my $namespace = Sys::Linux::Namespace->new(private_tmp => 1), "Setup object");

  ok($namespace->setup(code => sub {
      is_deeply([glob "/tmp/*"], [], "No files present in /tmp");
    }), "run code in sandbox"); 
}
