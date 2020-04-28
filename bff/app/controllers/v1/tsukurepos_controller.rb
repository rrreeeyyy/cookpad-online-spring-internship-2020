require 'main_grpc_client'
require 'tsukurepo_grpc_client'

module V1
  class TsukureposController < ApplicationController
    def show
      request = TsukurepoBackend::Services::V1::GetTsukurepoRequest.new(id: params[:id].to_i)
      begin
        response = TsukurepoGrpcClient.stub(:tsukurepo).get_tsukurepo(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      recipe_request = Main::Services::V1::GetRecipeRequest.new(id: response.tsukurepo.recipe_id)
      begin
        recipe_response = MainGrpcClient.stub(:recipe).get_recipe(recipe_request)
        response.tsukurepo.recipe = recipe_response.recipe
      rescue GRPC::NotFound
        response.tsukurepo.recipe = nil
      end

      user_request = Main::Services::V1::GetUserRequest.new(id: response.tsukurepo.user_id)
      begin
        user_response = MainGrpcClient.stub(:user).get_user(user_request)
        response.tsukurepo.user = user_response.user
      rescue GRPC::NotFound
        response.tsukurepo.user = nil
      end

      render json: response
    end

    def index
      request = TsukurepoBackend::Services::V1::ListTsukureposRequest.new(page: params[:page].to_i, per_page: params[:per_page].to_i)
      begin
        tsukurepo_response = TsukurepoGrpcClient.stub(:tsukurepo).list_tsukurepos(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      response = tsukurepo_response.tsukurepos.map do |tsukurepo|
        recipe_request = Main::Services::V1::GetRecipeRequest.new(id: tsukurepo.recipe_id)
        begin
          recipe_response = MainGrpcClient.stub(:recipe).get_recipe(recipe_request)
          tsukurepo.recipe = recipe_response.recipe
        rescue GRPC::NotFound
          tsukurepo.recipe = nil
        end

        user_request = Main::Services::V1::GetUserRequest.new(id: tsukurepo.user_id)
        begin
          user_response = MainGrpcClient.stub(:user).get_user(user_request)
          tsukurepo.user = user_response.user
        rescue GRPC::NotFound
          tsukurepo.user = nil
        end

        JSON.parse(tsukurepo.to_json)
      end

      render json: response
    end

    def create
      tsukurepo = TsukurepoBackend::Resources::V1::Tsukurepo.new(
        recipe_id: params[:recipe_id],
        user_id: params[:user_id],
        comment: params[:comment],
      )

      request = TsukurepoBackend::Services::V1::CreateTsukurepoRequest.new(
        tsukurepo: tsukurepo,
      )
      begin
        response = TsukurepoGrpcClient.stub(:tsukurepo).create_tsukurepo(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      recipe_request = Main::Services::V1::GetRecipeRequest.new(id: response.tsukurepo.recipe_id)
      begin
        recipe_response = MainGrpcClient.stub(:recipe).get_recipe(recipe_request)
        response.tsukurepo.recipe = recipe_response.recipe
      rescue GRPC::NotFound
        response.tsukurepo.recipe = nil
      end

      user_request = Main::Services::V1::GetUserRequest.new(id: response.tsukurepo.user_id)
      begin
        user_response = MainGrpcClient.stub(:user).get_user(user_request)
        response.tsukurepo.user = user_response.user
      rescue GRPC::NotFound
        response.tsukurepo.user = nil
      end

      render json: response
    end
  end
end
