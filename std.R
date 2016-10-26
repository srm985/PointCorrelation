df <- read.csv("C:\\Users\\xr7d\\Desktop\\Creative Thinking\\APR Tool Replacement\\max.csv", header=TRUE)

df.lm = lm(df[,5] ~ df[,6], data=df)
summary(df.lm)$r.squared

df[,3] <- as.numeric(as.character(df[,3]))

sum(df[,3])

df[,3]

fix(df)

df[,3] <- as.numeric(df[,3])
df[,4] <- as.numeric(df[,4])
df[,5] <- as.numeric(df[,5])
df[,6] <- as.numeric(df[,6])

ccf(df[,530],df[,6])
ccf(df[,2],df[,3])
