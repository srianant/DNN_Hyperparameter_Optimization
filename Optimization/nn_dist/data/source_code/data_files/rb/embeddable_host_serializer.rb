class EmbeddableHostSerializer < ApplicationSerializer

  TO_SERIALIZE = [:id, :host, :path_whitelist, :category_id]

  attributes *TO_SERIALIZE

  TO_SERIALIZE.each do |attr|
    define_method(attr) { object.send(attr) }
  end

end
