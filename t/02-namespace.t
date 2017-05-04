BEGIN {
  $ENV{TMPDIR} = 't/tmp/'
}

use Test::More;
use Test::SharedFork;

# test 1
use_ok("Sys::Linux::Namespace");

# test 2
SKIP: {
  skip "Need to be root to run test", 5 unless $< == 0;
  ok(my $namespace = Sys::Linux::Namespace->new(private_tmp => 1), "Setup object");

  my $ret = $namespace->run(code => sub {
      is_deeply([glob "/tmp/*"], [], "No files present in /tmp");
  });
  
  ok($ret, "run code in sandbox");

  ok($namespace->setup(), "Setup namespace in current process");
  is_deeply([glob "/tmp/*"], [], "No files present in /tmp");
}

done_testing;
