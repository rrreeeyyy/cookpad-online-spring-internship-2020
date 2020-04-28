require 'main_grpc_client'

module V1
  class RecipesController < ApplicationController
    def show
      request = Main::Services::V1::GetRecipeRequest.new(id: params[:id].to_i)
      begin
        response = MainGrpcClient.stub(:recipe).get_recipe(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      render json: response
    end

    def index
      request = Main::Services::V1::ListRecipesRequest.new(page: params[:page].to_i, per_page: params[:per_page].to_i)
      begin
        response = MainGrpcClient.stub(:recipe).list_recipes(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      render json: response
    end

    def create
      user = Main::Resources::V1::User.new(
        id: params[:user][:id].to_i
      )

      ingredients = params[:ingredients].map do |ingredient|
        Main::Resources::V1::Ingredient.new(
          name: ingredient[:name],
          quantity: ingredient[:quantity],
        )
      end

      steps = params[:steps].map do |step|
        Main::Resources::V1::Step.new(
          description: step[:description],
        )
      end

      request = Main::Services::V1::CreateRecipeRequest.new(
        recipe: Main::Resources::V1::Recipe.new(
          user: user,
          ingredients: ingredients,
          steps: steps,
          title: params[:title],
          description: params[:description],
        ),
      )
      begin
        response = MainGrpcClient.stub(:recipe).create_recipe(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      render json: response
    end
  end
end
