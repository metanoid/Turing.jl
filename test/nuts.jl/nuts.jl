using Distributions, Turing

@model gdemo(x) = begin
  s ~ InverseGamma(2,3)
  m ~ Normal(0,sqrt(s))
  x[1] ~ Normal(m, sqrt(s))
  x[2] ~ Normal(m, sqrt(s))
  return s, m
end

alg = NUTS(1000, 200, 0.65)
res = sample(gdemo([1.5, 2.0]), alg)

check_numerical(res, [:s, :m], [49/24, 7/6])
