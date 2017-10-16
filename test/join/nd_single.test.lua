env = require('test_run')
test_run = env.new()
executed = false

test_run:cmd("setopt delimiter ';'")
-- start shards
cluster(function(id)
    test_run:cmd("create server master"..id.." with script='join/master"..id..".lua'")
    test_run:cmd("start server master"..id)
end);

function on_join(self)
    if not executed then
        test_run:cmd('stop server master2')
        executed = true
    end
end;

test_run:cmd("setopt delimiter ''");
shard.wait_connection()

_ = rawset(shard, 'on_action', on_join)


for i=1, 10 do shard.demo:insert{i, 'test'} end

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
test_run:cmd("switch default")

-- stop replica
test_run:cmd("stop server master1")
-- add tuples
for i=11, 20 do shard.demo:insert{i, 'join_test'} end

-- join replica
test_run:cmd("create server join1 with script='join/join1.lua'")
test_run:cmd("start server join1")

status = shard_status()
status
_ = remote_join(status.offline[1].id)
shard_status()

-- check joined replica
box.space.demo:select()
test_run:cmd("switch master3")
box.space.demo:select()

test_run:cmd("switch master4")
box.space.demo:select()
test_run:cmd("switch join1")
box.space.demo:select()

test_run:cmd("switch master5")
box.space.demo:select()
test_run:cmd("switch default")

-- join one more replica
test_run:cmd("create server join2 with script='join/join2.lua'")
test_run:cmd("start server join2")

status = shard_status()
status
_ = remote_join(status.offline[1].id)
shard_status()

-- check joined replica
test_run:cmd("switch join2")
box.space.demo:select()
test_run:cmd("switch master5")
box.space.demo:select()
test_run:cmd("switch default")

-- cleanup
test_run:cmd("setopt delimiter ';'")
cluster(function(id)
    if id ~= '1' and id ~= '2' then
        _ = test_run:cmd("stop server master"..id)
    end
    test_run:cmd("cleanup server master"..id)
end);

_ = test_run:cmd("stop server join1")
test_run:cmd("cleanup server join1")
_ = test_run:cmd("stop server join2")
test_run:cmd("cleanup server join2")
test_run:cmd("setopt delimiter ''");
test_run:cmd("restart server default with cleanup=1")
