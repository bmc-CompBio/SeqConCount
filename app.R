# File size limit 
options(shiny.maxRequestSize = 2^32)

require("Biostrings")

my_databases <- c("ref_viruses_rep_genomes",
                  "ref_prok_rep_genomes",
                  "nt")

shinyApp(
        
        
        ui = fluidPage(
                titlePanel("SeqContCount"),
                sidebarLayout(
                        sidebarPanel(width = 3,
                                     strong("SeqContCount"), "identifies contamination (e.g. viral sequences) in NGS data (e.g. RNA-seq). 
                      It takes a FastQ file as input and uses BLAST to find the best matching sequence in the chosen database.
                    The output indicates the taxonomical information of the hits.",
                                     p(), br(),
                                     fileInput('file1', "Upload FastQ",
                                               accept = c(
                                                       '.fastq',
                                                       '.fastqsanger'
                                               )
                                     ),
                                     selectInput("database", label = "Database", 
                                                 choices = list("Viruses","Prokaryotes","Nucleotide sequences (slow)")
                                     ),
                                     selectInput("select", label = "Number of reads", 
                                                 choices = list(10,100,1000,10000,100000)
                                     ),
                                     selectInput("eval", label = "E-value cutoff", 
                                                 choices = list(10^0,10^-2,10^-5,10^-10,10^-15,10^-20)
                                     ),
                                     selectInput("hits", label = "Number of top hits", 
                                                 choices = list(5,4,3)
                                     ),
                                     downloadButton('download', 'Download Plot')
                        ),
                        mainPanel(
                                plotOutput('contents', height = "500px")
                        )
                )
                
        ), 
        
        
        server = function(input, output){
                
                
                blast_all <- reactive({
                        
                        progress <- shiny::Progress$new()
                        on.exit(progress$close())
                        
                        progress$set(message = "Progress:", value = 0)
                        
                        progress$inc(1, detail = paste("loading"))
                        
                        
                        inFile <- input$file1
                        
                        if (is.null(inFile)){
                                return(NULL)
                        }
                        
                        
                        system(paste("cat", inFile$datapath, 
                                     "| paste - - - - | head -n", as.integer(input$select),
                                     " | cut -f1,2 | tr '\t' '\n' | sed 's/^@/>@/' >  temp_file.fasta"))
                        
                        if(input$database == "Viruses"){
                                my_database <- my_databases[1]
                        } else if(input$database == "Prokaryotes"){
                                my_database <- my_databases[2]
                        } else if(input$database == "Nucleotide sequences (slow)"){
                                my_database <- my_databases[3]
                        }
                        
                        progress$inc(1, detail = paste("blasting"))
                        
                        system(paste("./blastn -num_threads 16 -db",
                                     my_database,
                                     "-query temp_file.fasta -task megablast -max_target_seqs 1  -evalue",
                                     input$eval,
                                     "-outfmt '6 qseqid sscinames evalue sseqid stitle' -out temp_file.blast"))
                        
                        
                        if(file.exists("temp_file.blast")){
                                
                                if(file.size("temp_file.blast") != 0){
                                        read.delim("temp_file.blast", sep = "\t", stringsAsFactors = FALSE, header = F) 
                                } else {
                                        return("Nomatch")
                                }
                                
                        }
                        
                        
                })    
                
                
                #output$blast_table <- (blast_all)
                
                plotInput  <- function(){
                        
                        
                        blast <- blast_all()
                        
                        if (is.null(blast)){
                                return(NULL)
                        }
                        
                        if((grepl("Nomatch", as.character(blast)))[1]){
                                plot(1,1, type = "n", xaxt="n", yaxt="n", xlab=NA,ylab=NA, bty = "n")
                                text(0.65,1.4,"No match!", adj = 0 , cex = 2, font = 2 )
                                text(0.65,1.3,"Try to change:", adj = 0 , cex = 1.75)
                                text(0.7,1.2," - higher number of reads", adj = 0, cex = 1.5 )
                                text(0.7,1.1," - less stringent E-value cutoff", adj = 0, cex = 1.5)
                                return(NULL)
                        }
                        
                        if(file.exists("temp_file.fasta")){
                                
                                reads <- read.table("temp_file.fasta", sep = "\t", stringsAsFactors = FALSE) 
                                reads <- reads[seq(1,nrow(reads),2),]
                                reads <- gsub(">","",reads)
                                reads <- data.frame(V1 = as.character(matrix(unlist(strsplit(reads, split = " ")),ncol = 2,byrow = TRUE)[,1]))
                        }
                        
                        blast <- blast[!(duplicated(blast[,1])),]
                        
                        blast_all <- merge(reads, blast, by = "V1", all =TRUE, sort=FALSE)
                        
                        blast_all[is.na(blast_all[,2]),2] <- "No match"
                        blast_all[,2] <- gsub("[0-9]","", blast_all[,2])
                        
                        #system(paste("rm temp_file*"))
                        
                        blast_species <- table(blast_all[,2])
                        blast_species <- blast_species/sum(blast_species)
                        blast_species <- blast_species[order(blast_species, decreasing = TRUE)]
                        
                        top_freq <- head(blast_species,(as.integer(input$hits)-1))
                        top_freq <- c(top_freq, 1-sum(top_freq))
                        names(top_freq)[length(top_freq)] <- "Other match"
                        
                        names(top_freq) <- gsub("Cyprinus carpio", "Adapter",  names(top_freq))
                        names(top_freq) <- substr(names(top_freq), 1, 49)
                        
                        par(mfrow=c(1,2), oma = c(5,15,2,2), cex=1.2,mar=c(6,6,6,2), mgp=c(2,1,0))
                        
                        my_colors <- c("snow4","snow3","snow2","snow1", "white")
                        
                        barplot(rev(top_freq),horiz = TRUE, las=2, xaxt="n", xlim = c(0,1),xlab = "Frequency",
                                col= rev(my_colors[seq_along(top_freq)]))
                        axis(side = 1, at = seq(0,1,0.25))
                        title(main = "BLAST Hits")
                        
                        
                        
                        hist(-1*log10(blast_all[,3]), col = "grey", breaks=100, xlab = "-log10(E-value)", main = "")
                        title(main = "BLAST E-values")
                        
                        inFile <- input$file1
                        
                        mtext(inFile$name,side = 3,  font=2, cex=2, outer = TRUE)
                        
                }
                
                output$contents <- renderPlot({
                        print(plotInput())
                })
                
                output$download = downloadHandler(
                        filename = "plot.pdf",
                        content = function(file) {
                                pdf(file, width = 12, height = 6)
                                plotInput()
                                dev.off()
                        })  
                
                
        }
)
