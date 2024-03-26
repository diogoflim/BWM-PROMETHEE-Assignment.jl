using DataFrames, XLSX
include("src/Methods.jl")

raw_data = XLSX.readxlsx("Data/Example.xlsx")

c = Dict()
d = Dict()
b = Dict()
Φ = Dict()
T = Set()
R = Set(1:15)

# Loop over routes for PROMETHEE application with BWM weights 
for r in R
    X = raw_data["Rota $r"]["D:M"]
    X = X[2:end, :]
    X = X[.!(any.(ismissing, eachrow(X))), :]
    d[r] = X[1,end]
    shipping_companies = X[:, 1]
    Decision_Matrix = raw_data["Rota $r"]["E:K"]
    Decision_Matrix = Decision_Matrix[2:end, :]
    Decision_Matrix = Decision_Matrix[.!(any.(ismissing, eachrow(Decision_Matrix))), :] 
    Decision_Matrix[:,1] *= (-1)
    n = size(Decision_Matrix, 2)
    net_flows = BWM_PROMETHEE_NetFlows(7, 2, [4,6,4,2,3,3,1], [3,1,3,5,4,4,6], Decision_Matrix, [0,0.02,0,0,0,0,0], [0,0.03,0.05,0.05,0,0,0], [0 for i in 1:n], [1,5,3,3,1,1,1]; alternative_names=shipping_companies)[3]
    for s in 1:length(shipping_companies)
        Φ[(shipping_companies[s], r)] = net_flows[s]
        b[(shipping_companies[s],r)] = 1
        if shipping_companies[s] ∉ T
            c[shipping_companies[s]] = X[s,end-1]
            push!(T, shipping_companies[s])       
        end
    end
end

M, x, y, z = Assignment(b, T, d, R, c, Φ)

for r in R
    for t in T
        if (t, r) ∈ keys(b)
            k=(t, r)
            println("x[$k] = ", value.(x[k]))
            println("y[$k] = ", value.(y[k]))
        end
    end
end

