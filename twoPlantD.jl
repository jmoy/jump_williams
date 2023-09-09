using JuMP,HiGHS,CSV,DataFrames,DataFramesMeta

##
time_use_df = CSV.read("time_use.csv",DataFrames.DataFrame)
resources_df = CSV.read("resources.csv",DataFrames.DataFrame)
##

##
plants = unique(time_use_df.plant)
products = unique(time_use_df.product)
operations = unique(time_use_df.operation)

##

##
ProfitMargin = Dict("Standard"=>10,"Deluxe"=>15)
RawMaterialPerUnit = 4
TotalRawMaterial = 120
##

##
model = Model(HiGHS.Optimizer)
##

## 
@variable(model,X[plants,products]>=0)
##

##
@constraint(model,cons_opr[i=operations,j=plants],
            sum([@subset(time_use_df,:operation .== i, :plant .== j, :product .==k).time * 
                                                            X[j,k] for k in products]) <= 
                @subset(resources_df,:operation .==i, :plant .== j).time_avail)
##


##
@expression(model,raw_mat_use[i=plants],RawMaterialPerUnit*sum(X[i,:]))
@constraint(model,cons_raw,
            sum(raw_mat_use) <= TotalRawMaterial)
##

##
@expression(model,profit_contrib[i=plants],sum([X[i,j] .* ProfitMargin[j] for j in products]))
@objective(model,Max,
            sum(profit_contrib))
##

##
optimize!(model)
##

##
solution_summary(model)
##
