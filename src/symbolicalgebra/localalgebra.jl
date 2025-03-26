@doc """
    LocalOp{T,A}

Symbolic operator algebra for representing local operators acting on a a number of sites.
The type parameter `T` denotes the scalar type of the operator, while `A` denotes the algebra.
""" LocalOp

@sumtype LocalOp{T,A}(
  Op{T,A},
  Scaled{LocalOp{T,A},T},
  Sum{LocalOp{T,A},T},
  Prod{LocalOp{T,A}},
  Kron{LocalOp{T,A}},
  Fun{LocalOp{T,A}},
) <: SymbolicAlgebra{T}

const VariantTypes = Union{Op,Scaled,Sum,Prod,Kron,Fun}

# Properties
# ----------
algebratype(::Type{LocalOp{T,A}}) where {T,A} = A

"""
    support(O::LocalOp) -> Int

Return the support of the operator `O`, defined as the number of sites on which it acts.
For composite objects that arent `Kron`, this property must always be homogenous.
"""
support(O::LocalOp) = support(variant(O))
support(::Op) = 1
support(o::Scaled) = support(o.op)
support(o::Sum) = support(first(keys(o.terms)))
support(o::Prod) = support(first(o.factors))
support(o::Kron) = sum(support, o.factors)

function checksupport(O₁, O₂)
  return checksupport(Bool, O₁, O₂) ||
         throw(ArgumentError("Operators act on different spaces"))
end
function checksupport(::Type{Bool}, O₁::LocalOp, O₂::LocalOp)
  return support(O₁) == support(O₂) && algebratype(O₁) == algebratype(O₂)
end

# VectorInterface
# ---------------
function VectorInterface.scale(O::LocalOp, λ::Number)
  T′ = VectorInterface.promote_scale(scalartype(O), scalartype(λ))
  TO = LocalOp{T′,algebratype(O)}
  return TO(Scaled{TO,T′}(O, λ))
end

function VectorInterface.add(O₁::LocalOp, O₂::LocalOp, α::Number, β::Number)
  checksupport(O₁, O₂)
  T′ = VectorInterface.promote_add(
    scalartype(O₁), scalartype(O₂), scalartype(α), scalartype(β)
  )
  TO = LocalOp{T′,algebratype(O₁)}

  res = Sum{TO,T′}()

  # add terms from O₁
  if !iszero(β)
    o₁ = variant(O₁)
    if o₁ isa Sum
      for (o, λ) in pairs(o₁.terms)
        insert!(res.terms, o, T′(β * λ))
      end
    elseif o₁ isa Scaled
      insert!(res.terms, o₁.op, T′(β * o₁.scalar))
    else
      insert!(res.terms, O₁, T′(β))
    end
  end

  # add terms from O₂
  if !iszero(α)
    o₂ = variant(O₂)
    if o₂ isa Sum
      for (o, λ) in pairs(o₂.terms)
        setwith!(+, res.terms, o, T′(α * λ))
      end
    elseif o₂ isa Scaled
      setwith!(+, res.terms, o₂.op, T′(α * o₂.scalar))
    else
      setwith!(+, res.terms, O₂, T′(α))
    end
  end

  return TO(res)
end

# LinearAlgebra
# -------------
function (O₁::LocalOp * O₂::LocalOp)
  checksupport(O₁, O₂)
  T = Base.promote_op(*, scalartype(O₁), scalartype(O₂))
  TO = LocalOp{T,algebratype(O₁)}

  res = Prod{TO}()

  # add factors from O₁
  o₁ = variant(O₁)
  if o₁ isa Prod
    append!(res.factors, o₁.factors)
  else
    push!(res.factors, O₁)
  end

  # add factors from O₂
  o₂ = variant(O₂)
  if o₂ isa Prod
    append!(res.factors, o₂.factors)
  else
    push!(res.factors, O₂)
  end

  return TO(res)
end

function (O₁::LocalOp ⊗ O₂::LocalOp)
  algebratype(O₁) == algebratype(O₂) ||
    throw(ArgumentError("Operators act on different spaces"))
  T = Base.promote_op(*, scalartype(O₁), scalartype(O₂))
  TO = LocalOp{T,algebratype(O₁)}

  res = Kron{TO}()
  # add factors from O₁
  o₁ = variant(O₁)
  if o₁ isa Kron
    append!(res.factors, o₁.factors)
  else
    push!(res.factors, O₁)
  end

  # add factors from O₂
  o₂ = variant(O₂)
  if o₂ isa Kron
    append!(res.factors, o₂.factors)
  else
    push!(res.factors, O₂)
  end

  return TO(res)
end

# Sorting
# -------
# dispatch to variants:
Base.isless(O₁::LocalOp, O₂::LocalOp) = isless(variant(O₁), variant(O₂))

# order by types
const _order = (:Op, :Kron, :Scaled, :Sum, :Prod, :Fun)

for (i, O₁) in enumerate(_order)
  for (j, O₂) in enumerate(_order)
    i == j && continue
    @eval Base.isless(::$O₁, ::$O₂) = $(i < j)
  end
end

# then sort by inner data
Base.isless(O₁::Op, O₂::Op) = isless(O₁.id, O₂.id)
Base.isless(O₁::Scaled, O₂::Scaled) = isless((O₁.op, O₁.λ), (O₂.op, O₂.λ)) # inherit from Tuple
Base.isless(O₁::Sum, O₂::Sum) = isless(O₁.terms, O₂.terms) # inherit from Dictionary
Base.isless(O₁::Prod, O₂::Prod) = isless(O₁.factors, O₂.factors) # inherit from Vector
Base.isless(O₁::Kron, O₂::Kron) = isless(O₁.factors, O₂.factors) # inherit from Vector

# Equality
# --------
# dispatch to variants:
Base.:(==)(O₁::LocalOp, O₂::LocalOp) = variant(O₁) == variant(O₂)

# order by types
Base.:(==)(O₁::VariantTypes, O₂::VariantTypes) = false
Base.:(==)(O₁::Op, O₂::Op) = O₁.id == O₂.id
Base.:(==)(O₁::Scaled, O₂::Scaled) = (O₁.op, O₁.scalar) == (O₂.op, O₂.scalar)
Base.:(==)(O₁::Sum, O₂::Sum) = O₁.terms == O₂.terms
Base.:(==)(O₁::Prod, O₂::Prod) = O₁.factors == O₂.factors
Base.:(==)(O₁::Kron, O₂::Kron) = O₁.factors == O₂.factors
Base.:(==)(O₁::Fun, O₂::Fun) = O₁.f == O₂.f && O₁.args == O₂.args

# TermInterface
# -------------
TermInterface.isexpr(O::LocalOp) = TermInterface.isexpr(variant(O))
TermInterface.isexpr(::Op) = false
TermInterface.isexpr(::Scaled) = true
TermInterface.isexpr(::Sum) = true
TermInterface.isexpr(::Prod) = true
TermInterface.isexpr(::Kron) = true
TermInterface.isexpr(::Fun) = true

TermInterface.head(O::LocalOp) = TermInterface.head(variant(O))
TermInterface.head(::Scaled) = :(*)
TermInterface.head(::Sum) = :(+)
TermInterface.head(::Prod) = :(*)
TermInterface.head(::Kron) = :(⊗)
TermInterface.head(o::Fun) = o.f

TermInterface.children(O::LocalOp) = TermInterface.children(variant(O))
TermInterface.children(o::Scaled) = (o.op, o.scalar)
TermInterface.children(o::Sum) = [o * λ for (o, λ) in pairs(o.terms)]
TermInterface.children(o::Prod) = o.factors
TermInterface.children(o::Kron) = o.factors
TermInterface.children(o::Fun) = o.args

TermInterface.iscall(O::LocalOp) = TermInterface.iscall(variant(O))
TermInterface.iscall(::Op) = false
TermInterface.iscall(::Scaled) = true
TermInterface.iscall(::Sum) = true
TermInterface.iscall(::Prod) = true
TermInterface.iscall(::Kron) = true
TermInterface.iscall(::Fun) = true

TermInterface.operation(O::LocalOp) = TermInterface.operation(variant(O))
TermInterface.operation(::Scaled) = (*)
TermInterface.operation(::Sum) = (+)
TermInterface.operation(::Prod) = (*)
TermInterface.operation(::Kron) = (⊗)
TermInterface.operation(o::Fun) = o.f

TermInterface.arguments(O::LocalOp) = TermInterface.arguments(variant(O))
TermInterface.arguments(o::Scaled) = (o.op, o.scalar)
TermInterface.arguments(o::Sum) = [o * λ for (o, λ) in pairs(o.terms)]
TermInterface.arguments(o::Prod) = o.factors
TermInterface.arguments(o::Kron) = o.factors
TermInterface.arguments(o::Fun) = o.args

function TermInterface.maketerm(::Type{<:LocalOp}, ::typeof(+), args, metadata=nothing)
  @debug "maketerm(+)" args
  return +(args...)
end

function TermInterface.maketerm(::Type{<:LocalOp}, ::typeof(*), args, metadata=nothing)
  return *(args...)
  T = mapreduce(scalartype, (x, y) -> Base.promote_op(*, x, y), args; init=Bool)
  if length(args) == 2 && args[1] isa LocalOp && args[2] isa Number
    A = algebratype(args[1])
    TO = LocalOp{T,A}
    return TO(Scaled{TO,T}(args[1], args[2]))
  end

  # TODO: rewrite check
  @assert allequal(algebratype, args)
  A = algebratype(first(args))
  TO = LocalOp{T,A}
  res = Prod{TO}(args)
  return TO(res)
end

function TermInterface.maketerm(::Type{<:LocalOp}, ::typeof(⊗), args, metadata=nothing)
  return ⊗(args...)
  T = mapreduce(scalartype, (x, y) -> Base.promote_op(*, x, y), args; init=Bool)
  @assert allequal(algebratype, args)
  A = algebratype(first(args))
  TO = LocalOp{T,A}
  res = Kron{TO}(args)
  return TO(res)
end

function TermInterface.maketerm(::Type{<:LocalOp}, f::Function, args, metadata=nothing)
  T = mapreduce(scalartype, (x, y) -> Base.promote_op(*, x, y), args; init=Bool)
  @assert allequal(algebratype, args)
  A = algebratype(first(args))
  TO = LocalOp{T,A}
  res = Fun{TO}(f, args)
  return TO(res)
end

# Show
# ----

function Base.show(io::IO, O::LocalOp)
  if !(get(io, :typeinfo, Any) <: LocalOp)
    summary(io, O)
    println(io, ":")
    print(io, " ")
  end

  ctx = IOContext(io, :typeinfo => typeof(O))
  show(ctx, variant(O))
  return nothing
end

function Base.show_unquoted(io::IO, O::LocalOp, indent::Int, precedence::Int)
  if !(get(io, :typeinfo, Any) <: LocalOp)
    summary(io, O)
    println(io, ":")
    print(io, " ")
  end

  show_unquoted(IOContext(io, :typeinfo => typeof(O)), variant(O), indent, precedence)
  return nothing
end

function Base.show(io::IO, O::Op{T,A}) where {T,A}
  if get(io, :typeinfo, Any) <: LocalOp
    print(io, "Op(")
    show(IOContext(io, :typeinfo => A), O.id)
    print(io, ")")
  else
    show(io, typeof(O))
    print(io, "(")
    show(IOContext(io, :typeinfo => A), O.id)
    print(io, ")")
  end
  return nothing
end

function Base.show(io::IO, O::Scaled{LocalOp{T,A},T}) where {T,A}
  if !(get(io, :typeinfo, Any) <: LocalOp{T,A})
    print(io, typeof(O))
    println(io, ":")
    print(io, " ")
  end

  show_scaled(io, O.op, O.scalar)
  return nothing
end

function Base.show(io::IO, O::Sum{LocalOp{T,A},T}) where {T,A}
  if !(get(io, :typeinfo, Any) <: LocalOp{T,A})
    print(io, typeof(O))
    println(io, ":")
    print(io, " ")
  end

  show_summed(io, collect(keys(O.terms)), collect(values(O.terms)))
  return nothing
end
function Base.show_unquoted(io::IO, O::Sum, indent::Int, precedence::Int)
  if !(get(io, :typeinfo, Any) <: LocalOp)
    print(io, typeof(O))
    println(io, ":")
    print(io, " ")
  end

  show_summed_unquoted(
    io, collect(keys(O.terms)), collect(values(O.terms)), indent, precedence
  )
  return nothing
end

function Base.show(io::IO, O::Prod{LocalOp{T,A}}) where {T,A}
  if !(get(io, :typeinfo, Any) <: LocalOp{T,A})
    print(io, typeof(O))
    println(io, ":")
    print(io, " ")
  end

  show_product(io, O.factors)
  return nothing
end

function Base.show_unquoted(
  io::IO, O::Prod{LocalOp{T,A}}, indent::Int, precedence::Int
) where {T,A}
  if !(get(io, :typeinfo, Any) <: LocalOp{T,A})
    print(io, typeof(O))
    println(io, ":")
    print(io, " ")
  end

  show_product_unquoted(io, O.factors, indent, precedence)
  return nothing
end

function Base.show(io::IO, O::Kron{LocalOp{T,A}}) where {T,A}
  if !(get(io, :typeinfo, Any) <: LocalOp{T,A})
    print(io, typeof(O))
    println(io, ":")
    print(io, " ")
  end

  show_kron(io, O.factors)
  return nothing
end
