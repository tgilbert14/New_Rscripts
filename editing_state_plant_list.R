library(tidyverse)

wa_list<- read_csv("USDA_WA_state_list.csv")

#View(wa_list)

new_list<- wa_list %>% 
  filter(!is.na(`Common Name`)) %>% 
  arrange(`Common Name`)
new_list<- new_list %>% 
  select(`Accepted Symbol`, "CommonName usda"=`Common Name`)
#View(new_list)

vgs_list<- read_csv("VGS_plant_list.csv")
vgs_list<- vgs_list %>%
  select(Symbol, "Common Name vgs"=CommonName, ScientificName)
#View(vgs_list)
## update vgs name so same as new list (code)
names(new_list)[1]<- names(vgs_list)[1]

c<- left_join(new_list, vgs_list)
View(c)
write.csv(c, "Wa_plant_list_common_name_search.csv")

vgs_list<- read_csv("VGS_plant_list.csv")
View(vgs_list)
vgs_2<- vgs_list %>% 
  select(Symbol, Duration, GrowthHabit, NativeStatus)

d<- left_join(c, vgs_2)
View(d)

write.csv(d, "USDA_WA_Plants.csv")

nrow(c)
nrow(d)
nrow(vgs_list)
