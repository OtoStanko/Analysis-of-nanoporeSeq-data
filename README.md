# Analysis-of-nanoporeSeq-data
Basecalling and follow-up processing and analysis of water sample from a pond near Studentka town (Czech Republic)

Tento súbor slúži na popis funkcionality skriptu "workflow.sh".
Popisuje ako a prečo sme spúšťali jednotlivé nástroje tak, ako sú volané v skripte.
Na to aby bol skript funkčný je bohužiaľ potrebné dodržať presnú štruktúru a obsah priečinku s nástrojmi a databázami,
ktorý je zadávaný pomocou voľby -t. 
Priečinok musí obsahovať: 1. podpriečinky pre každý nástroj {guppy, Porechop, FastQC, fastp, krona, kraken2}
			                    2. v každom priečinku musí byť spustiteľný súbor pre daný nástroj a všetky ďalšie súbory a databázy, ktoré nástroj potrebuje
                          3. v priečinku kraken2 musí byť priečinok s databázami s presným pomenovaním
                          4. v priečinku krona musí byť priečinok s taxonomickou databázou

Voľbou -d zadávame priečinok do ktorého bude skript vkladať výstupy z jednotlivých nástrojov
Voľbou -i zadávame priečinok so vstupnými fast5 dátami zo sekvenátora
Voľbou -b zadávame číslo barkódu našej vzorky

Skript bol vyrobený pre účely automatizácie jednotlivých krokov práce s dátami, štruktúra je preto prispôsobená štruktúre nášho pracovného
adresára a jeho opätovná prevádzka je komplikovaná. 
Je určený na ilustráciu nami použitého workflowu, teda: aké nástroje sme použili, v akom poradí a na akých vstupných dátach sme ich spúšťali.

BASECALLING:
Skopírujeme ready s naším barcodom do pracovného adresára.
Vyrobíme adresár na ukladanie výstupov.
Spustíme basecalling na skopírovaných dátach. Použili sme high=accuracy config file "dna_r9.4.1_450bps_hac.cfg"

OUTPUT CONCAT:
Zlúčime všetky výstupné fastq sekvencie označené ako "pass" s naším barcodom do jedného súboru pre lepšiu manipuláciu

RAW QUALITY REPORT:
Vyrobíme quality report z čistých dát z basecalleru.

TRIMMING ADAPTERS:
Vyrežeme adaptéry zo sekvencií. Nástroj guppy pozná nanopore adaptéry.
Pomocou voľby --no_split zakážeme vyrezávanie adaptérov zo stredu readov.

TRIMMED QUALITY REPORT:
Vyrobíme quality report z dát bez adaptérov.

QUALITY IMPROVMENT:
Vyfiltrujeme nekvalitné dáta, teda tie, ktoré majú phred score menšie ako 20.

IMPROVED QUALITY REPORT:
Vyrobíme quality report z vylepšených dát.

TAXONOMIC ANALYSIS:
Postupne vyrobíme taxonomickú analýzu dát s použitím 4 rôznych databáz, pretože každá lepšie detekuje istú skupinu organizmov.
V prvom volaní kraken2 nástroja pomocou voľby --classified-out vyfiltrujeme iba tie fastq sekvencie, ktoré daná databáza identifikuje.
V druhom volaní kraken2 použijeme iba tieto fastq sekvencie čo nám zaručí 100% match pri taxonomickej analýze.
Následne všetky 4 výsledné subory zlúčime do jedného, ktorý obsahuje všetky tax ID ktoré sa nachádzajú aspoň v jednej z databáz.
Dáta, ktoré sa nachádzajú vo viacerých databázach sa vo výsledku objavia viackrát, čo mierne skresluje kvantitu zastúpenia vo vzorke.
Výhodou je však zachytenie širokého spektra organizmov.

TAXONOMIC REPORT:
Zo zlúčeného výstupu taxonomickej analýzy vystrihneme 2., 3. a 4. stĺpec, pretože iba tie sú vstupom do nástroja krona.
2. stĺpec je querry ID
3. stĺpec je taxonomy ID
4. stĺpec je score (zodpovedá kvantite organizmu s daným taxID) 

Následne zavoláme 2x nástroj krona. Pomocou voľby --tax určime cestu k stiahnutej taxonomickej databáze z NCBI.
Pri prvom spustení si chybový výstup presmerujeme do súboru. 
Chybový výstup obsahuje zoznam taxID, ktoré neboli v NCBI nájdené. Tie pomocou python skriptu "parser.py" spracujeme a vložíme 
do samostatného súboru, kde na každom riadku je jedno taxID. Následne postupne prechádzane tieto taxID a vo vstupných dátach
pre kronu vymažeme postupne všetky riadky s danými taxID, ktoré sa v NCBI databáze vôbec nenachádzajú. Takto vyčistíme výstupný
graf krony. 
Následne na upravenom vstupe spustíme druhýkrát kronu a obdržíme výsledný koláčový graf obsahujúci všetky organizmy nachádzajúce sa vo vzorke.
Aj napriek úprave dát, sa môže stať, že malé % taxID sa zobrazí ako tzv. other root. 
To môže byť spôsobené tým, že niektoré taxID sa v NCBI databáze síce nachádzajú, ale ich taxonomické zaradenie je odlišné alebo žiadne
a nevedia sa zobraziť v koreňovej štruktúre grafu.
