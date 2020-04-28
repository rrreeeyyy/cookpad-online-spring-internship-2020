require 'main/services/v1/recipe_services_pb'

class RecipeService < Main::Services::V1::Recipe::Service
  def get_recipe(request, call)
    recipe = Recipe.find(request.id)

    Main::Services::V1::GetRecipeResponse.new(
      recipe: recipe.as_protocol_buffer
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  end

  def list_recipes(request, call)
    page = request.page unless request.page.zero?
    per_page = request.per_page unless request.per_page.zero?

    # TODO: Avoid to N+1 query, Use index
    recipes = Recipe.
      order(created_at: :desc).
      page(page).
      per(per_page)

    Main::Services::V1::ListRecipesResponse.new(
      recipes: recipes.map(&:as_protocol_buffer),
      count: Recipe.count,
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  end

  def list_recipes_by_user(request, call)
    page = request.page unless request.page.zero?
    per_page = request.per_page unless request.per_page.zero?

    user_id = request.user_id unless request.user_id.zero?

    # TODO: Avoid to N+1 query, Use multi-column indexs
    recipes = Recipe.
      where(user_id: user_id).
      order(created_at: :desc).
      page(page).
      per(per_page)

    Main::Services::V1::ListRecipesByUserResponse.new(
      recipes: recipes.map(&:as_protocol_buffer)
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  end

  def create_recipe(request, call)
    user = User.find(request.recipe.user.id)

    recipe = Recipe.new(
      user: user,
      title: request.recipe.title,
      description: request.recipe.description,
    )

    ActiveRecord::Base.transaction do
      recipe.save!

      request.recipe.ingredients.each_with_index do |ingredient, idx|
        Ingredient.create!(
          recipe: recipe,
          name: ingredient.name,
          quantity: ingredient.quantity,
          position: idx + 1,
        )
      end

      request.recipe.steps.each_with_index do |step, idx|
        Step.create!(
          recipe: recipe,
          description: step.description,
          position: idx + 1,
        )
      end
    end

    Main::Services::V1::CreateRecipeResponse.new(
      recipe: recipe.as_protocol_buffer,
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  end

  def delete_recipe(request, call)
    recipe = Recipe.find(id: request.id)
    recipe.destroy!

    Main::Services::V1::DeleteRecipeResponse.new
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  rescue ActiveRecord::RecordNotDestroyed => e
    raise GRPC::Aborted.new(e.message)
  end
end
