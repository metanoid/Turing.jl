using ..Turing.Interface: init_callback, NoCallback

###
### DynamicHMC backend - https://github.com/tpapp/DynamicHMC.jl
###
struct DynamicNUTS{AD, space} <: Hamiltonian{AD} end

"""
    DynamicNUTS()

Dynamic No U-Turn Sampling algorithm provided by the DynamicHMC package.
To use it, make sure you have the DynamicHMC package installed.

"""
DynamicNUTS(args...) = DynamicNUTS{ADBackend()}(args...)
DynamicNUTS{AD}() where AD = DynamicNUTS{AD, ()}()
function DynamicNUTS{AD}(space::Symbol...) where AD
    DynamicNUTS{AD, space}()
end

mutable struct DynamicNUTSState{V<:VarInfo, D} <: AbstractSamplerState
    vi::V
    draws::Vector{D}
end

getspace(::Type{<:DynamicNUTS{<:Any, space}}) where {space} = space
getspace(alg::DynamicNUTS{<:Any, space}) where {space} = space

function sample_init!(
    rng::AbstractRNG,
    model::Model,
    spl::Sampler{<:DynamicNUTS},
    N::Integer;
    kwargs...
)
    # Set up lp function.
    function _lp(x)
        value, deriv = gradient_logp(x, spl.state.vi, model, spl)
        return ValueGradient(value, deriv)
    end

    runmodel!(model, spl.state.vi, SampleFromUniform())

    if spl.selector.tag == :default
        link!(spl.state.vi, spl)
        runmodel!(model, spl.state.vi, spl)
    end

    # Set the parameters to a starting value.
    initialize_parameters!(spl; kwargs...)

    spl.state.draws, _ = NUTS_init_tune_mcmc(
        FunctionLogDensity(
            length(spl.state.vi[spl]),
            _lp
        ),
        N
    )
end

function step!(
    rng::AbstractRNG,
    model::Model,
    spl::Sampler{<:DynamicNUTS},
    N::Integer;
    kwargs...
)
    # Pop the next draw off the vector.
    draw = popfirst!(spl.state.draws)
    spl.state.vi[spl] = draw.q
    return Transition(spl)
end

function Sampler(
    alg::DynamicNUTS{AD},
    model::Turing.Model,
    s::Selector=Selector()
) where AD
    # Construct a state, using a default function.
    state = DynamicNUTSState(VarInfo(model), [])

    # Return a new sampler.
    return Sampler(alg, Dict{Symbol,Any}(), s, state)
end

# Disable the callback for DynamicHMC, since it has it's own progress meter.
function Turing.Interface.init_callback(
    rng::AbstractRNG,
    model::Model,
    s::Sampler{<:DynamicNUTS},
    N::Integer;
    kwargs...
) where {ModelType<:Sampleable, SamplerType<:AbstractSampler}
    return NoCallback()
end