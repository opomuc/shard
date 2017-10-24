env = require('test_run')
test_run = env.new()
servers = { 'master0', 'master1', 'master2' }
test_run:create_cluster(servers, 'redundancy3')
test_run:wait_fullmesh(servers)
test_run:cmd('switch master0')
shard.wait_connection()

shard.space.demo:insert{1, 'test'}
shard.space.demo:replace{1, 'test2'}
shard.space.demo:update({1}, {{'=', 2, 'test3'}})
shard.space.demo:insert{2, 'test4'}
shard.space.demo:insert{3, 'test5'}
shard.space.demo:delete({3})

box.space.demo:select()
test_run:cmd("switch master1")
box.space.demo:select()
test_run:cmd("switch master2")
box.space.demo:select()

test_run:cmd('switch default')
test_run:drop_cluster(servers)
