# create a cloud database instance with at least one database and one user.

require_relative 'boilerplate'

step 'authenticating.'
service = log_me_in Fog::Rackspace::Databases

step 'choosing the smallest flavor.'
flavor = service.flavors.min_by { |f| f.ram }

step 'creating an instance.'
instance = service.instances.create name: 'small',
  flavor_id: flavor.id,
  volume_size: 1

progress('waiting for the instance to launch') do
  instance.wait_for { ready? }
end

step 'creating a database.'
db = instance.databases.create name: 'development'

step 'creating a user.'
user = instance.users.create name: 'racker', password: 'trustno1', databases: [db]

step 'deleting the database.'
db.destroy

step 'complete.'
