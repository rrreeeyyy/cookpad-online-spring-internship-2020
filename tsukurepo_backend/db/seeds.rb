# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

TSUKUREPO_COUNT = 100000
USER_COUNT = 100000
RECIPE_COUNT = 100000

tsukurepos = []

tsukurepos_data = %w(
  おいしかったです！
  リピ決定です！
  とても美味しかったです！
  おいしくつくれました！
  美味しく作れました！
  子供も喜びました！
  旦那も喜びました！
)

TSUKUREPO_COUNT.times do
  tsukurepos << Tsukurepo.new(recipe_id: rand(1..(RECIPE_COUNT - 1)), user_id: rand(1..(USER_COUNT - 1)), comment: tsukurepos_data.sample)
end

Tsukurepo.import(tsukurepos)
