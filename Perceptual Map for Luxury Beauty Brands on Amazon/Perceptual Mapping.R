library(jsonlite)
library(tidyverse)

#read in reviews and meta data
df1 <- stream_in(file("/deac/business/team20/marketing/Luxury_Beauty.json"))
reviews <- df1[,c("asin","reviewText")]
df2 <- stream_in(file("/deac/business/team20/marketing/meta_Luxury_Beauty.json"))
meta <- df2[,c("title","asin")]
Luxury_Beauty <- merge(meta, reviews, by= "asin")
#combine title and reviewtext, so that we can have the brand name and the review text together
Luxury_Beauty$title_reviewtext <- tolower(paste(Luxury_Beauty$title, Luxury_Beauty$reviewText, sep = "  ", collapse = NULL))

##check the most frequent brands
##b <- Luxury_Beauty %>% group_by(title) %>% summarize(n())

#create brand list
brands <- c('Toppik','Hot Tools','OPI','Shellac', 'Mario Badescu',
            'Essie','Merkur','Zoya','BaBylissPRO','Proraso','stila','Dermablend',
            'Grande Cosmetics','SEXYHAIR','Jane Iredale','Jack Black',
            'blinc','Revision','MONTBLANC','butter LONDON')
brands <- tolower(brands)

#detect where brand names exist
##### loop for each brand, 1 shows the brand is mentioned in the text #####
for (i in 1:20){
  Luxury_Beauty[i+4] <- as.numeric(str_detect(Luxury_Beauty$title_reviewtext, brands[i]))
}

##### loop for two-brand combinations, 1 shows both brands are mentioned in the text #####
for(i in 1:20)
{
  for(j in 1:20)
  {
    Luxury_Beauty[20*i+j+4] <- Luxury_Beauty[i+4]*Luxury_Beauty[j+4]
  }
}

#####====================================#####

#calculate the total count of the reviews
n = nrow(Luxury_Beauty)
#calculate the count of the brands
nsum = apply(Luxury_Beauty[5:424], 2, function(x) sum(x, na.rm = T))
#calculate the probability of the brand appearances
p = nsum/n

#create a matrix where calulates P(A)*P(B) for the 20 brands, this results in a 20*20 matrix
a = p[1:20]
mm=matrix(a,nrow=20,ncol=20)
m2=diag(a)
m3 = mm %*% m2
colnames(m3) <- brands

#create P(AB) table
b = p[21:420]
m1 = matrix(b,nrow=20,ncol=20, byrow = T)

#calculate lift=P(AB)/(P(A)*P(B))
#lift matrix (m4) = P(AB) matrix (m1) / P(A)*P(B) matrix (m3)
#the larger the lift is, the more similar the two brands are
m4 = m1/m3
diag(m4) = 0
rownames(m4) <- colnames(m4)

#transform the lift matrix (m4) into dissimilarity table (m6)
#find the max value from lift matrix, using that number to distract the lift, this results in dissimilarity matrix
#the larger the number in dissimilarity table, the more different the two brands are
m5 = matrix(max(m4),nrow=20,ncol=20)
m6 = m5 - m4
diag(m6) = 0
rownames(m6) <- colnames(m6)

#export lift matrix
write.csv(m4,file = "lift.csv")
#export dissimilarity matrix
write.csv(m6,file = "dissimilarity.csv")

#create perceptual map
dat.df <- m6
dat.mat <- data.matrix(dat.df)
dat.mds <- cmdscale(dat.mat, eig=TRUE, k=2)
#save results in new dataset
result = data.frame(dat.mds$points)
colnames(result) = c("Coordinate1", "Coordinate2")
#plot solution
#full perceptual map
ggplot(data = result, aes(x= Coordinate1, y = Coordinate2)) +
  annotate(geom = "text", x = result$Coordinate1, y = result$Coordinate2, label = row.names(result)) +
  ggtitle("MDS Perceptual Map of Luxury Beauty Brands")
#zoom into the crowded area
ggplot(data = result, aes(x= Coordinate1, y = Coordinate2)) +
  annotate(geom = "text", x = result$Coordinate1, y = result$Coordinate2, label = row.names(result)) +
  ggtitle("MDS Perceptual Map of Luxury Beauty Brands (contd)") + ylim(-0.4, -0.2) + xlim(0.2, 0.4)
