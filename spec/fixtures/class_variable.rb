# frozen_string_literal: true

using Typerb

class ClassVariableFixture
  def call(arg)
    @@arg = arg # rubocop: disable Style/ClassVars
    @@arg.type!(Integer)
  end
end
