env = require('test_run')
test_run = env.new()
servers = { 'master0', 'master1' }
test_run:create_cluster(servers, 'node_down')
test_run:wait_fullmesh(servers)
test_run:cmd('switch master0')
shard.wait_connection()

-- Kill server and wait for monitoring fibers kill
_ = test_run:cmd("stop server master1")
shard.wait_epoch(2)
shard.is_table_filled()

test_run:cmd("cleanup server master1")
test_run:cmd("switch default")
test_run:drop_cluster({'master0'})
