#__precompile__()


module DeepRL

using POMDPs
using GenerativeModels

export 
    # Environment types
    AbstractEnvironment,
    POMDPEnvironment,
    MDPEnvironment,
    # supporting methods
    reset,
    step!,
    actions,
    sample_action,
    n_actions,
    obs_dimensions,
    render


abstract AbstractEnvironment

type MDPEnvironment{S} <: AbstractEnvironment
    problem::MDP 
    state::S
    rng::AbstractRNG
end
function MDPEnvironment(problem::MDP; rng::AbstractRNG=MersenneTwister())
    return MDPEnvironment(problem, create_state(problem), rng)
end

type POMDPEnvironment{S} <: AbstractEnvironment
    problem::POMDP 
    state::S
    rng::AbstractRNG
end
function POMDPEnvironment(problem::POMDP; rng::AbstractRNG=MersenneTwister())
    return POMDPEnvironment(problem, create_state(problem), rng)
end

"""
    reset(env::MDPEnvironment)
Reset an MDP environment by sampling an initial state returning it.
"""
function Base.reset(env::MDPEnvironment)
    s = initial_state(env.problem, env.rng)
    env.state = s
    return s
end

"""
    reset(env::POMDPEnvironment)
Reset an POMDP environment by sampling an initial state, 
generating an observation and returning it.
"""
function Base.reset(env::POMDPEnvironment)
    s = initial_state(env.problem, env.rng)
    env.state = s
    o = generate_o(env.problem, s, env.rng)
    return o
end


"""
    step!{A}(env::POMDPEnvironment, a::A)
Take in an POMDP environment, and an action to execute, and 
step the environment forward. Return the state, reward, 
terminal flag and info
"""
function step!{A}(env::MDPEnvironment, a::A)
    s, r = generate_sr(env.problem, env.state, a, env.rng)
    env.state = s
    t = isterminal(env.problem, s)
    info = nothing
    obs = vec(env.problem, s)
    return obs, r, t, info
end

"""
    step!{A}(env::MDPEnvironment, a::A)
Take in an MDP environment, and an action to execute, and 
step the environment forward. Return the observation, reward, 
terminal flag and info
"""
function step!{A}(env::POMDPEnvironment, a::A)
    s, o, r = generate_sor(env.problem, env.state, a, env.rng)
    env.state = s
    t = isterminal(env.problem, s)
    info = nothing
    obs = vec(env.problem, o)
    return obs, r, t, info
end

"""
    actions(env::Union{POMDPEnvironment, MDPEnvironment})
Return an action object that can be sampled with rand.
"""
function POMDPs.actions(env::Union{POMDPEnvironment, MDPEnvironment})
    return actions(env.problem)
end

"""
    sample_action(env::Union{POMDPEnvironment, MDPEnvironment})
Sample an action from the action space of the environment.
"""
function sample_action(env::Union{POMDPEnvironment, MDPEnvironment})
    return rand(env.rng, actions(env), create_action(env.problem))
end

"""
    n_actions(env::Union{POMDPEnvironment, MDPEnvironment})
Return the number of actions in the environment (environments with discrete action spaces only)
"""
function POMDPs.n_actions(env::Union{POMDPEnvironment, MDPEnvironment})
    return n_actions(env.problem)
end


function obs_dimensions(env::MDPEnvironment)
    return size(vec(env.problem, create_state(env.problem))) 
end


function obs_dimensions(env::POMDPEnvironment)
    return size(vec(env.problem, create_observation(env.problem))) 
end
"""
    render(env::AbstractEnvironment)
Renders a graphic of the environment
"""
POMDPs.@pomdp_func render(env::AbstractEnvironment)

end # module