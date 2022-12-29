box.schema.create_space('test')
box.space.test:create_index('primary', {parts = {1,'number'}})
box.space.test:create_index('test', {parts = {2,'string'}})


function validateCreatedSpace() return true end
function validateCreatedIndex() return false end
function validateCreatedUser() return false end
function validateChangedUser() return false end