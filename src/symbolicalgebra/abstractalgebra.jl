"""
    SymbolicAlgebra

Abstract supertype for working with symbolic (operator) algebras.
"""
abstract type SymbolicAlgebra{T<:Number} end

# Building blocks
# ---------------
struct Op{T<:Number,A}
  id::A
end

struct Scaled{O,T<:Number}
  op::O
  scalar::T
end

struct Sum{O,T<:Number}
  terms::Dictionary{O,T}
  Sum{O,T}() where {O,T} = new{O,T}(Dictionary{O,T}())
  Sum{O,T}(terms::Dictionary{O,T}) where {O,T} = new{O,T}(terms)
end

struct Prod{O}
  factors::Vector{O}
  Prod{O}() where {O} = new{O}(O[])
  Prod{O}(factors::Vector{O}) where {O} = new{O}(factors)
end

struct Kron{O}
  factors::Vector{O}
  Kron{O}() where {O} = new{O}(O[])
  Kron{O}(factors::Vector{O}) where {O} = new{O}(factors)
end

struct Fun{O}
  f::Any
  args::Vector{O}
  Fun{O}(f) where {O} = new{O}(f, O[])
  Fun{O}(f, args::Vector{O}) where {O} = new{O}(f, args)
end


# Properties
# ----------
VectorInterface.scalartype(::Type{<:SymbolicAlgebra{T}}) where {T} = scalartype(T)
algebratype(a::SymbolicAlgebra) = algebratype(typeof(a))

# Linear algebra
# --------------

# functionality to rewrite basic operations in terms of a more limited set
(O::SymbolicAlgebra * λ::Number) = scale(O, λ)
(λ::Number * O::SymbolicAlgebra) = scale(O, λ)
(O::SymbolicAlgebra / λ::Number) = scale(O, inv(λ))
(λ::Number \ O::SymbolicAlgebra) = scale(O, inv(λ))

+(O::SymbolicAlgebra) = scale(O, one(scalartype(O)))
-(O::SymbolicAlgebra) = scale(O, -one(scalartype(O)))
(O₁::SymbolicAlgebra + O₂::SymbolicAlgebra) = add(O₁, O₂)
(O₁::SymbolicAlgebra - O₂::SymbolicAlgebra) = add(O₁, O₂, -one(scalartype(O₁)))
# (O1::SymbolicAlgebra - O2::SymbolicAlgebra) = -(promote(O1, O2)...)

# Show utility
# ------------
# functionality to display symbolic expressions
# -> expressions show have two variants: show and show_unquoted to determine whether
#    the expressions should be using parentheses

"""
    show_scaled(io::IO, operator, scalar)

Utility function to display a scaled operator as `scalar * operator`.
"""
function show_scaled(io::IO, operator, scalar)
  if isone(scalar)
    show(io, operator)
    return nothing
  end

  if isreal(scalar) && isone(abs(scalar))
    print(io, '-')
    show(io, operator)
    return nothing
  end

  show_unquoted(io, scalar, 0, Base.operator_precedence(:*))
  print(io, " * ")
  show_unquoted(io, operator, 0, Base.operator_precedence(:*))

  return nothing
end

"""
    show_scaled_unquoted(io::IO, operator, scalar, indent::Int, precedence::Int)

Utility function to display a scaled operator as `scalar * operator` within the context of
a larger expression. This function will parenthesize the scaled operator if necessary, based
on the relative precedence of `*` over `precedence`.

See also `Base.show_unquoted` and `Base.operator_precedence`.
"""
function show_scaled_unquoted(io::IO, operator, scalar, indent::Int, precedence::Int)
  should_parenthesize =
    !isone(scalar) &&
    (!isreal(scalar) || !isone(abs(scalar))) &&
    Base.operator_precedence(:*) ≤ precedence

  if should_parenthesize
    print(io, "(")
    show_scaled(io, operator, scalar)
    print(io, ")")
  else
    show_scaled(io, operator, scalar)
  end

  return nothing
end

"""
    show_summed(io::IO, operators, [scalars])

Utility function to display a sum of operators as `operators[1] + operators[2] + ...`.
"""
function show_summed(io::IO, operators)
  precedence = Base.operator_precedence(:+)
  for (i, operator) in enumerate(operators)
    if i == 1
      show_unquoted(io, operator, 0, precedence)
    else
      print(io, " + ")
      show_unquoted(io, operator, 0, precedence)
    end
  end
  return nothing
end

function show_summed(io::IO, operators, scalars)
  precedence = Base.operator_precedence(:+)

  for (i, (operator, scalar)) in enumerate(zip(operators, scalars))
    if i == 1
      show_scaled_unquoted(io, operator, scalars[i], 0, precedence)
      continue
    end

    # attempt to absorb the sign of the scalar
    if isreal(scalar) && scalar < 0
      print(io, " - ")
      scalar = abs(scalar)
    else
      print(io, " + ")
    end

    show_scaled_unquoted(io, operator, scalar, 0, precedence)
  end

  return nothing
end

function show_summed_unquoted(io::IO, operators, indent::Int, precedence::Int)
  if length(operators) == 1
    show_unquoted(io, operators[1], indent, precedence)
    return nothing
  end

  if Base.operator_precedence(:+) ≤ precedence
    print(io, "(")
    show_summed(io, operators)
    print(io, ")")
  else
    show_summed(io, operators)
  end

  return nothing
end
function show_summed_unquoted(io::IO, operators, scalars, indent::Int, precedence::Int)
  if length(operators) == 1
    show_scaled_unquoted(io, only(operators), only(scalars)indent, precedence)
    return nothing
  end

  if Base.operator_precedence(:+) ≤ precedence
    print(io, "(")
    show_summed(io, operators, scalars)
    print(io, ")")
  else
    show_summed(io, operators, scalars)
  end

  return nothing
end

function show_product(io::IO, factors)
  precedence = Base.operator_precedence(:*)

  for (i, factor) in enumerate(factors)
    if i == 1
      show_unquoted(io, factor, 0, precedence)
    else
      print(io, " * ")
      show_unquoted(io, factor, 0, precedence)
    end
  end
end

function show_product_unquoted(io::IO, factors, indent::Int, precedence::Int)
  if length(operators) == 1
    show_unquoted(io, only(factors), indent, precedence)
    return nothing
  end

  if Base.operator_precedence(:*) ≤ precedence
    print(io, "(")
    show_prod(io, factors)
    print(io, ")")
  else
    show_prod(io, factors)
  end

  return nothing
end
