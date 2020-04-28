require 'main_grpc_client'

module V1
  class UserRecipesController < ApplicationController
    def index
      request = Main::Services::V1::ListRecipesByUsersRequest.new(user_id: params[:user_id].to_i)
      begin
        response = MainGrpcClient.stub(:recipe).list_recipes_by_user(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      render json: response
    end
  end
end
