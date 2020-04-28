# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'csv'

USER_COUNT = 1000000
# users = []
#
# USER_COUNT.times do |user|
#   users << User.new(name: "クック#{['A'..'Z', 0..9].map(&:to_a).flatten.sample(6).join}☆")
# end
#
# User.import(users)

RECIPE_COUNT = 1000000
INGREDIENTS_COUNT_PER_RECIPE = 5
STEPS_COUNT_PER_RECIPE = 5

recipes = []

recipes_data = CSV.read('db/data/recipes.csv', headers: true)
ingredients_data = CSV.read('db/data/ingredients.csv', headers: true)
steps_data = CSV.read('db/data/steps.csv', headers: true)

recipes = []
ingredients = []
steps = []

RECIPE_COUNT.times do |recipe_id|
  rrow = rand(0..99)
  recipe = Recipe.new(title: recipes_data[rrow]['title'], description: "美味しい#{recipes_data[rrow]['title']}です。", user_id: rand(1..(USER_COUNT * 2 - 1)))
  recipes << recipe
  INGREDIENTS_COUNT_PER_RECIPE.times do |i|
    irow = rand(0..99)
    ingredient = Ingredient.new(recipe_id: recipe_id, quantity: ingredients_data[irow]['quantity'], name: ingredients_data[irow]['name'], position: i + 1)
    ingredients << ingredient
  end
  STEPS_COUNT_PER_RECIPE.times do |i|
    srow = rand(0..60)
    step = Step.new(recipe_id: recipe_id, description: steps_data[srow]['memo'], position: i + 1)
    steps << step
  end
end

Recipe.import(recipes)
Ingredient.import(ingredients)
Step.import(steps)
