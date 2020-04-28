require 'tsukurepo_backend/services/v1/tsukurepo_services_pb'

class TsukurepoService < TsukurepoBackend::Services::V1::Tsukurepo::Service
  def get_tsukurepo(request, call)
    tsukurepo = Tsukurepo.find(request.id)

    TsukurepoBackend::Services::V1::GetTsukurepoResponse.new(
      tsukurepo: tsukurepo.as_protocol_buffer
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  end

  def list_tsukurepos(request, call)
    page = request.page unless request.page.zero?
    per_page = request.per_page unless request.per_page.zero?

    # TODO: Avoid to N+1 query, Use index
    tsukurepos = Tsukurepo.
      order(created_at: :desc).
      page(page).
      per(per_page)

      TsukurepoBackend::Services::V1::ListTsukureposResponse.new(
      tsukurepos: tsukurepos.map(&:as_protocol_buffer)
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  end

  def create_tsukurepo(request, call)
    tsukurepo = Tsukurepo.create(
      recipe_id: request.tsukurepo.recipe_id,
      user_id: request.tsukurepo.user_id,
      comment: request.tsukurepo.comment,
    )

    TsukurepoBackend::Services::V1::CreateTsukurepoResponse.new(
      tsukurepo: tsukurepo.as_protocol_buffer,
    )
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  end

  def delete_tsukurepo(request, call)
    tsukurepo = Tsukurepo.find(id: request.id)
    tsukurepo.destroy!

    TsukurepoBackend::Services::V1::DeleteTsukurepoResponse.new
  rescue ActiveRecord::RecordNotFound => e
    raise GRPC::NotFound.new(e.message)
  rescue ActiveRecord::RecordNotDestroyed => e
    raise GRPC::Aborted.new(e.message)
  end
end
