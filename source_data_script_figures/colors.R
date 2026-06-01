# R/colors.R

colors <- list(
  
  cereals = c(
    "maize" = "#F8766D",
    "millet" = "#7CAE00",
    "millet_maize" = "#987116",
    "millet_sorghum" = "#7193A3",
    "rye" = "#C46243",
    "rye_wheat" = "#C9A647",
    "sorghum" = "#6d6bef",
    "teff" = "#884638",  
    "unknown" = "#999999",
    "wheat" = "#D4D479"
  ),
  
  cereals_couscous = c(
    "Maize" = "#F8766D",
    "Millet" = "#7CAE00",
    "Millet-Maize" = "#987116",
    "Sorghum" = "#6d6bef"
  ),
  
  product = c(
    "boza" = "#B8335D",
    "couscous" = "#E69F00",
    "fura" = "#E0B1B1",
    "injera" = "#a15646",
    "jalebi" = "#76888A",
    "koko" = "#009E73",
    "kunu" = "#81a146",
    "massa" = "#5b6fd5",
    "obiolor" = "#005439",
    "ogi" = "#d0718b",
    "pozol" = "#C49D82",
    "sourdough" = "#C9C765",
    "ugi" = "#8b96cb",
    "zonkom" = "#3B35B0"
  ),
  
  ferm = c(
    "no" = "#86BF94",
    "yes" = "#E69F00"
    ),
  
  couscous_colors = c(
    "Couscous" = "#E69F00",
    "Others fermented cereals" = "#B0AFED"
  ),
  
  
  
  # TAXONOMY
  kingdom = c(
    "Eukaryota" = "#F8766D",
    "Bacteria" = "#108a65"
  ),
  
  phylum = c(
    "Bacteroidota" = "#472E2E",
    "Pseudomonadota" = "#62bf51",
    "Actinomycetota" = "#E0B1B1",
    "Ascomycota" = "#B39759",                     
    "Bacillota" = "#c1ba50",                     
    "Others" = "#999999"
  ),
  
  class = c(
    "Gammaproteobacteria" = "#A9E09D",
    "Alphaproteobacteria" = "#62bf51",
    "Clostridia" = "#903193",
    "Saccharomycetes" = "#B39759",                     
    "Bacilli" = "#c1ba50",                     
    "Others" = "#999999"
  ),
  
  order = c(
    "Pseudomonadales" = "#A9E09D",
    "Acetobacterales" = "#62bf51",
    "Clostridiales" = "#903193",
    "Enterobacterales" = "#4f3e23",                     
    "Saccharomycetales" = "#B39759",                     
    "Staphylococcales" = "#20aaa8",                     
    "Bacillales" = "#0f5c96",
    "Actinomycetales" = "#C29584",                     
    "Lactobacillales" = "#c1ba50",                     
    "Exiguobacterales" = "#175957",  
    "Others" = "#999999"
  ),
  
  family = c(
    "f__Planococcaceae" = "#56a619",
    "f__Acetobacteraceae" = "#62bf51",
    "f__Clostridiaceae" = "#903193",
    "f__Enterobacteriaceae" = "#4f3e23",                     
    "f__Enterococcaceae" = "#80815b",                     
    "f__Staphylococcaceae" = "#20aaa8",                     
    "f__Bacillaceae" = "#0f5c96",
    "f__Moraxellaceae" = "#ac8faf",                     
    "f__Lactobacillaceae" = "#c1ba50",                     
    "f__Streptococcaceae" = "#dfee5b",  
    "Others" = "#999999"
  ),
  
  genus = c(
    "g__Acinetobacter" = "#56a619",
    "g__Acetobacter" = "#62bf51",
    "g__Clostridium" = "#903193",
    "g__Companilactobacillus" = "#7289dd",
    "g__Enterobacter" = "#4f3e23",                     
    "g__Enterococcus" = "#80815b",                     
    "g__Fructilactobacillus" = "#dfdd96",                     
    "g__Furfurilactobacillus" = "#ddd5b5",                     
    "g__Gluconobacter" = "#20aaa8",                     
    "g__Kosakonia" = "#0f5c96",
    "g__Kurthia" = "#ac8faf",                     
    "g__Lacticaseibacillus" = "#dfaa96",                     
    "g__Lapidilactobacillus" = "#d5d494",                     
    "g__Lactiplantibacillus" = "#bcc68a",                     
    "g__Lactobacillus" = "#9eaf4a",
    "g__Lactococcus" = "#5f5e4b",
    "g__Lentilactobacillus" = "#c3dd50",
    "g__Leuconostoc" = "#c1a829",
    "g__Levilactobacillus" = "#f9c224",
    "g__Ligilactobacillus" = "#8a781d",  
    "g__Limosilactobacillus" = "#c1ba50",
    "g__Loigolactobacillus" = "#eedf63",
    "g__Macrococcus" = "#1e7895",
    "g__Pediococcus" = "#856d1a",
    "g__Streptococcus" = "#dfee5b",  
    "g__Weissella" = "#eb7f70",
    "g__Staphylococcus" = "#15a388",
    "g__Pantoea" = "#9bde60",
    "g__Rothia" = "#8a16d8",
    "g__Klebsiella" = "#d964f0",
    "g__Cronobacter" = "#7289dd",
    "Others" = "#999999"
  ),
  
  species = c("Phytobacter diazotrophicus" = "#52614A",
                         "Cronobacter dublinensis" = "#7289dd",
                         "Cronobacter sakazakii" = "#6375B0",
                         "Cronobacter malonaticus" = "#828FC4",
                         "Empedobacter brevis" = "#BA965D",
                         "Enterobacter sichuanensis" = "#4f3e23",                     
                         "Enterococcus faecium" = "#80815b",                     
                         "Enterococcus faecalis" = "#816F5B",                     
                         "Enterococcus durans" = "#736250",                     
                         "Enterococcus casseliflavus" = "#626346",                     
                         "Escherichia coli" = "#B0B0A7",                     
                         "Klebsiella pneumoniae" = "#d964f0",
                         "Klebsiella aerogenes" = "#d964a0",
                         "Kosakonia cowanii" = "#0f5c96",
                         "Kurthia gibsonii" = "#7F5B82",
                         "Priestia megaterium" = "#20aaa8",
                         "Aeromonas caviae" = "#F2DFE5",
                         "Clostridium beijerinckii" = "#903193",
                         "Pseudomonas oryzihabitans" = "#62bf51",
                         "Latilactobacillus curvatus" = "#C9C881",                     
                         "Lactiplantibacillus plantarum" = "#bcc68a",                     
                         "Lactobacillus helveticus" = "#9eaf4a",                     
                         "Lactobacillus crispatus" = "#9adf4a",                     
                         "Lactococcus lactis" = "#5f5e4b",                     
                         "Leuconostoc mesenteroides" = "#c1a829",                     
                         "Levilactobacillus brevis" = "#c1e829",                     
                         "Limosilactobacillus fermentum" = "#c1ba50",
                         "Limosilactobacillus pontis" = "#DED657",
                         "Limosilactobacillus reuteri" = "#E8E082",
                         "Franconibacter pulveris" = "#614641",
                         "Fructilactobacillus sanfranciscensis" = "#79804E",
                         "Leclercia adecarboxylata" = "#95F0F5",
                         "Companilactobacillus paralimentarius" = "#4E7E80",
                         "Lacticaseibacillus rhamnosus" = "#d5d494",
                         "Lacticaseibacillus paracasei" = "#C9C881",
                         "Pantoea dispersa" = "#9bde60",
                         "Pantoea ananatis" = "#9bca60",
                         "Pantoea stewartii" = "#8ACC52",  
                         "Pantoea septica" = "#A9E079",  
                         "Pediococcus pentosaceus" = "#856d1a",
                         "Pediococcus acidilactici" = "#856a5a",
                         "Pseudomonas aeruginosa" = "#A26AA3",
                         "Pseudomonas fulva" = "#866AA3",
                         "Pseudomonas putida" = "#866AA3",
                         "Pseudomonas juntendi" = "#543870",
                         "Rothia koreensis" = "#8a16d8",
                         "Rothia kristinae" = "#691A9C",
                         "Staphylococcus gallinarum" = "#15a388",  
                         "Staphylococcus kloosii" = "#2F9680",  
                         "Staphylococcus hominis" = "#2a6800",  
                         "Staphylococcus carnosus" = "#175E52",  
                         "Serratia ureilytica" = "#D41326",  
                         "Weissella confusa" = "#eb7f70",
                         "Weissella cibaria" = "#A85A48",
                         "Weissella paramesenteroides" = "#7D3D2E",
                         "Bacillus subtilis" = "#1e7895",
                         "Bacillus velezensis" = "#1a5895",
                         "Agrobacterium pusense" = "#5D7A54",
                         "Acetobacter pasteurianus" = "#62bf51",
                         "Acetobacter tropicalis" = "#51BF76",
                         "Acetobacter indonesiensis" = "#7AD667",
                         "Acinetobacter baumannii" = "#56a619",
                         "Acinetobacter schindleri" = "#4D8F0A",
                         "Acinetobacter pittii" = "#36C241",
                         "Acinetobacter soli" = "#41E04D",
                         "Acinetobacter variabilis" = "#56b000",
                         "Acinetobacter nosocomialis" = "#00B003",
                         "Staphylococcus haemolyticus" = "#30D9B4",
                         "Stenotrophomonas maltophilia" = "#ac8faf",
                         "Staphylococcus warneri" = "#1F7866",
                         "Staphylococcus xylosus" = "#1A8246",
                         "Staphylococcus saprophyticus" = "#0D5246",
                         "Staphylococcus epidermidis" = "#1A8246",
                         "Leuconostoc holzapfelii" = "#9C8724",
                         "Others" = "#999999")
  
)






