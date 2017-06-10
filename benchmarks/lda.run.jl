using Distributions
using Turing
using Stan

include(Pkg.dir("Turing")*"/benchmarks/benchmarkhelper.jl")
include(Pkg.dir("Turing")*"/example-models/stan-models/lda-stan.data.jl")
include(Pkg.dir("Turing")*"/example-models/stan-models/lda.model.jl")

include(Pkg.dir("Turing")*"/benchmarks/"*"lda-stan.run.jl")

setchunksize(60)

#for alg in ["HMC(2000, 0.25, 10)", "HMCDA(1000, 0.65, 1.5)", "NUTS(2000, 1000, 0.65)"]
or alg in ["HMC(2000, 0.025, 10)"]
  bench_res = tbenchmark(alg, "ldamodel", "data=ldastandata[1]")
  bench_res[4].names = ["phi[1]", "phi[2]"]
  logd = build_logd("LDA", bench_res...)
  logd["stan"] = lda_stan_d
  logd["time_stan"] = lda_time
  print_log(logd)
end
