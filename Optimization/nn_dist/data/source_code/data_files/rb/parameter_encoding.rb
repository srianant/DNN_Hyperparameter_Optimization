module ActionController
  # Allows encoding to be specified per parameter per action.
  module ParameterEncoding
    extend ActiveSupport::Concern

    module ClassMethods
      def inherited(klass) # :nodoc:
        super
        klass.setup_param_encode
      end

      def setup_param_encode # :nodoc:
        @_parameter_encodings = {}
      end

      def encoding_for_param(action, param) # :nodoc:
        if @_parameter_encodings[action.to_s] && @_parameter_encodings[action.to_s][param.to_s]
          @_parameter_encodings[action.to_s][param.to_s]
        else
          super
        end
      end

      def parameter_encoding(action, param_name, encoding)
        @_parameter_encodings[action.to_s] ||= {}
        @_parameter_encodings[action.to_s][param_name.to_s] = encoding
      end
    end
  end
end
