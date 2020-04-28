require 'main_grpc_client'

module V1
  class UsersController < ApplicationController
    def show
      # TODO: implement
    end

    def index
      request = Main::Services::V1::ListUsersRequest.new(page: params[:page].to_i, per_page: params[:per_page].to_i)
      begin
        response = MainGrpcClient.stub(:user).list_users(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      render json: response
    end

    def create
      user = Main::Resources::V1::User.new(
        name: params[:name],
      )

      request = Main::Services::V1::CreateUserRequest.new(
        user: user,
      )
      begin
        response = MainGrpcClient.stub(:user).create_user(request)
      rescue GRPC::NotFound
        return render status: 404
      end

      render json: response
    end
  end
end
