require 'main/services/v1/user_services_pb'

class UserService < Main::Services::V1::User::Service
  def get_user(request, call)
    # TODO: implement
  end

  def list_users(request, call)
    page = request.page unless request.page.zero?
    per_page = request.per_page unless request.per_page.zero?

    # TODO: Use index
    users = User.
      order(created_at: :desc).
      page(page).
      per(per_page)

    Main::Services::V1::ListUsersResponse.new(
      users: users.map(&:as_protocol_buffer),
      count: User.count,
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFoundss.new(e.message)
  end

  def create_user(request, call)
    user = User.create!(
      name: request.user.name
    )

    Main::Services::V1::CreateUserResponse.new(
      user: user.as_protocol_buffer,
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  end

  def delete_user(request, call)
    user = user.find(id: request.id)
    user.destroy!

    Main::Services::V1::DeleteUserResponse.new
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  rescue ActiveRecord::RecordNotDestroyed => e
    raise GRPC::Aborted.new(e.message)
  end
end
