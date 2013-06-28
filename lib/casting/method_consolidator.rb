module Casting
  module MethodConsolidator
    def methods(all=true)
      (super + delegated_methods(all)).uniq
    end

    def public_methods(include_super=true)
      (super + delegated_public_methods(include_super)).uniq
    end

    def protected_methods(include_super=true)
      (super + delegated_protected_methods(include_super)).uniq
    end

    def private_methods(include_super=true)
      (super + delegated_private_methods(include_super)).uniq
    end
  end
end