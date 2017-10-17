env = require('test_run')
test_run = env.new()
test_run:cmd("create server master1 with script='redundancy1/master1.lua'")
test_run:cmd("create server master2 with script='redundancy1/master2.lua'")
test_run:cmd("start server master1")
test_run:cmd("start server master2")
shard.wait_connection()

shard.demo:insert{1, 'test'}
shard.demo:replace{1, 'test2'}
shard.demo:update({1}, {{'=', 2, 'test3'}})
shard.demo:insert{2, 'test4'}
shard.demo:insert{3, 'test5'}
shard.demo:delete({3})


shard.multipart:insert{1, 'a', 4}
shard.multipart:insert{1, 'b', 5}
shard.multipart:insert{1, 'c', 6}
shard.multipart:insert{1, 'd', 7}
shard.multipart:insert{2, 'b', 1}
shard.multipart:insert{2, 'a', 2}
shard.multipart:replace{2, 'a', 3}
shard.multipart:replace{1, 'c', 8}
shard.multipart:delete{1, 'd'}
shard.multipart:update({1, 'c'}, {{'+', 3, 1}})

box.space.demo:select()
box.space.multipart:select()
test_run:cmd("switch master1")
box.space.demo:select()
box.space.multipart:select()
test_run:cmd("switch master2")
box.space.demo:select()
box.space.multipart:select()
test_run:cmd("switch default")

_ = test_run:cmd("stop server master1")
_ = test_run:cmd("stop server master2")
test_run:cmd("cleanup server master1")
test_run:cmd("cleanup server master2")
test_run:cmd("restart server default with cleanup=1")
