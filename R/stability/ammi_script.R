


library("methods")
library("dplyr")
library("gridExtra")
library("agricolae")

##### Get data #####
args = commandArgs(trailingOnly = TRUE)

pheno <- read.table(args[1], sep = "\t", header = TRUE)
study_trait <- args[2]
cat("Study trait is ", study_trait[1])
figure1_file_name <- args[3]
figure2_file_name <- args[4]
figure3_file_name <- args[5]
AMMIFile <- args[6]

#Making names standard
names <- colnames(pheno)
new_names <- gsub(".CO.*","", names)
colnames(pheno) <- new_names
cat(colnames(pheno),"\n")

#Finding which column is the study trait
for (i in 1:ncol(pheno)){
	a = noquote(colnames(pheno[i]))
	b = study_trait
	if (a==b){
		print(a)
		col = i
		i = ncol(pheno)
	}else{
		cat("working ",i,"\n")
		i=i+1
	}
}


env <-as.factor(pheno$locationName)
gen <-as.factor(pheno$germplasmName)
rep <-as.factor(pheno$replicate)
# trait <-as.numeric(pheno[,col])

message<-"The analysis could not be completed. Please set your dataset with more than 1 location."
message2<-""
locations <- unique(pheno$locationDbId)
acc <- unique(pheno$germplasmDbId)
subGen <- unique(subset(pheno, select=c(germplasmDbId, germplasmName)))

if (! length(locations)>1){
	
	png(AMMIFile, height = 130, width=800)
	z<-tableGrob(message)
	grid.arrange(z)
	dev.off()

	sub1 <- unique(subset(pheno, locationDbId == locations[1], select=c(locationDbId, locationName)))
	png(figure1_file_name, height = 100, width=800)
	p<-tableGrob(sub1)
	grid.arrange(p)
	dev.off()

	acc <- unique(pheno$germplasmDbId)
	png(figure2_file_name, height = (21*length(acc)), width = 800)
	sub2 <- unique(subset(pheno, locationDbId == locations[1], select=c(germplasmDbId, germplasmName)))
	q<-tableGrob(sub2)
	grid.arrange(q)
	dev.off()

	png(figure3_file_name, height=5, width=5)
	y <- tableGrob(message2)
	grid.arrange(y)
	dev.off()

} else {
	cat("Starting AMMI...","\n")
}


model<- with(pheno,AMMI(env, gen, rep, pheno[,col], console=FALSE))

anova <-format(round(model$ANOVA, 3))
analysis <- model$analysis
anova
analysis

png(AMMIFile, height=130, width=800)
p<-tableGrob(anova)
grid.arrange(p)
dev.off()

# Biplot and Triplot 
png(figure1_file_name,height=400)
# par(mfrow=c(2,2))
plot(model, first=0,second=1, number=TRUE, xlab = study_trait)
dev.off()

#Preparing Germplasm name to be printed
tam <- nrow(model$analysis)
if (tam >2){
  png(figure2_file_name, height= 300)
  plot(model, type=2, number=TRUE, xlab = study_trait)
  dev.off()
}else{
  png(figure2_file_name, height=5, width=5)
  y <- tableGrob(message2)
  grid.arrange(y)
  dev.off()
}


png(figure3_file_name, height=(21*length(acc)))
q<-tableGrob(subGen)
grid.arrange(q)
dev.off()


# model$analysis
# cat("  ", "\n")
#Averages
#model$means
#data for graphical analysis
# model$biplot
# sink()
# dev.off()