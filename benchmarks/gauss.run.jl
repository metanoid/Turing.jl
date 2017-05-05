using Distributions
using Turing
using Stan

include(Pkg.dir("Turing")*"/benchmarks/benchmarkhelper.jl")
include(Pkg.dir("Turing")*"/example-models/benchmarks/gdemo.data.jl")
include(Pkg.dir("Turing")*"/example-models/benchmarks/gdemo.model.jl")

bench_res = tbenchmark("HMC(2000, 0.1, 3)", "simplegaussmodel", "simplegaussdata")
logd = build_logd("Simple Gaussian Model", bench_res...)
logd["analytic"] = Dict("s" => 49/24, "m" => 7/6)

include(Pkg.dir("Turing")*"/benchmarks/"*"gauss-stan.run.jl")

logd["stan"] = Dict("s" => mean(s_stan), "m" => mean(m_stan))
logd["time_stan"] = sg_time

print_log(logd)
