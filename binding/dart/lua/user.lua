initializeUser = function(user, password)
  box.once("initialize-user", function()
    box.schema.user.create(user, { password = password })
    box.schema.user.grant(user, 'read,write,execute,create,alter,drop,replication', 'universe', nil)
  end)
end