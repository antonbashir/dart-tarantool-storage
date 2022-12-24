box.schema.create_space('test')
box.space.test:create_index('primary', {parts = {1,'number'}})
box.space.test:create_index('test', {parts = {2,'string'}})