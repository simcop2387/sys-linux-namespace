use Test::More tests => 3;

# test 1
use_ok("Sys::Linux::Namespace", 'namespace');

# test 2
SKIP: {
  skip "Need to be root to run test", 2 unless $< == 0;
  ok(namespace({private_tmp => 1}), "Setup private /tmp");
  
  # tmp is empty
  is_deeply([glob "/tmp/*"], [], "/tmp is empty afterwards"); 
}
