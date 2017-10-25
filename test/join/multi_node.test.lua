env = require('test_run')
test_run = env.new()
servers = { 'master0', 'master1', 'master2', 'master3', 'master4', 'master5' }
test_run:create_cluster(servers, 'join')
test_run:wait_fullmesh({'master0', 'master3'})
test_run:wait_fullmesh({'master1', 'master4'})
test_run:wait_fullmesh({'master2', 'master5'})
test_run:cmd('switch master0')
shard.wait_connection()

for i=1, 10 do shard.space.demo:insert{i, 'test'} end

-- check data
box.space.demo:select()
test_run:cmd("switch master3")
box.space.demo:select()

test_run:cmd("switch master1")
box.space.demo:select()
test_run:cmd("switch master4")
box.space.demo:select()

test_run:cmd("switch master2")
box.space.demo:select()
test_run:cmd("switch master5")
box.space.demo:select()
test_run:cmd("switch master0")

-- stop replica
test_run:cmd("stop server master1")
test_run:cmd("stop server master2")
-- add tuples
for i=11, 20 do shard.space.demo:insert{i, 'join_test'} end
status = shard.status()

test_run:cmd("start server master1")
test_run:cmd("start server master2")
test_run:wait_fullmesh({'master1', 'master4'})
test_run:wait_fullmesh({'master2', 'master5'})

status
_ = remote_join(status.offline[1].id)
_ = remote_join(status.offline[2].id)
shard.status()

-- check joined replica
box.space.demo:select()
test_run:cmd("switch master3")
box.space.demo:select()

test_run:cmd("switch master4")
box.space.demo:select()
test_run:cmd("switch master1")
box.space.demo:select()

test_run:cmd("switch master5")
box.space.demo:select()
test_run:cmd("switch master2")
box.space.demo:select()
test_run:cmd("switch master0")

-- cleanup
test_run:cmd('switch default')
test_run:drop_cluster(servers)
