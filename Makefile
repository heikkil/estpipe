
#
# Makefile to run baboon EST cleanup and processing for dbEST
#

# directories

PWD = .
RAWDIR = $(PWD)/raw
WORKDIR = $(PWD)/work
DONEDIR = $(PWD)/done
DATADIR = $(PWD)/data
BINDIR = $(PWD)/bin

# the default function
# main pipeline for est processing

run_estpipe: dbformat  estpipe  finalize

all: run_estpipe



dbformat: $(DATADIR)/uniprot_human.fa $(DATADIR)/humanmito.fa.nin

# Pre-process human uniprot database for blast homology search
$(DATADIR)/uniprot_human.fa:	$(DATADIR)/uniprot_sprot_human.dat.gz  \
				$(DATADIR)/uniprot_trembl_human.dat.gz
	$(BINDIR)/sw2fasta $(DATADIR)/uniprot_sprot_human.dat.gz 'UniProtKB/Swiss-Prot' > $(DATADIR)/sprot.fasta
	$(BINDIR)/sw2fasta $(DATADIR)/uniprot_trembl_human.dat.gz 'UniProtKB/TrEMBL' > $(DATADIR)/trembl.fasta
	cat $(DATADIR)/sprot.fasta $(DATADIR)/trembl.fasta > $(DATADIR)/uniprot_human.fa
	formatdb -i $(DATADIR)/uniprot_human.fa
	rm $(DATADIR)/*.fasta

# format human mitochondiral sequence for BLAST homology search
$(DATADIR)/humanmito.fa.nin: $(DATADIR)/humanmito.fa
	formatdb -p F -i $(DATADIR)/humanmito.fa





estpipe: $(RAWDIR)/bab.fa $(WORKDIR)/bab.fa.masked \
	$(WORKDIR)/repeat_ids $(WORKDIR)/estpipe.log \
	$(WORKDIR)/cleaned.qual $(WORKDIR)/est_seqs


$(RAWDIR)/bab.fa:
	gunzip $(RAWDIR)/bab.fa.gz

$(RAWDIR)/bab.qual:
	gunzip $(RAWDIR)/bab.qual.gz

$(RAWDIR)/bab.fa.masked:
	gunzip $(RAWDIR)/bab.fa.masked.gz

# run repeatmasker
$(WORKDIR)/bab.fa.masked: $(RAWDIR)/bab.fa $(RAWDIR)/bab.fa.masked
#	RepeatMasker -e crossmatch  -qq -pa 24 -dir $WORKDIR  $(RAWDIR)/bab.fa
	cp  $(RAWDIR)/bab.fa.masked $(WORKDIR)/bab.fa.masked

# apply rule that there has to be at least 64 nt of nonrepeat sequence
$(WORKDIR)/repeat_ids: $(WORKDIR)/bab.fa.masked
	$(BINDIR)/detect_repeat_only_seqs 64 $(WORKDIR)/bab.fa.masked > $(WORKDIR)/repeat_ids

# run the main estpipe programme
$(WORKDIR)/estpipe.log: $(WORKDIR)/repeat_ids $(RAWDIR)/bab.fa $(DATADIR)/uniprot_human.fa \
			$(DATADIR)/humanmito.fa.nin
	$(BINDIR)/estpipe -m $(WORKDIR)/repeat_ids -o $(WORKDIR) $(RAWDIR)/bab.fa


# remove discarded ESTs from the qual file
$(WORKDIR)/cleaned.qual: $(WORKDIR)/est_seqs $(RAWDIR)/bab.qual
	$(BINDIR)/select_fastas $(WORKDIR)/est_seqs $(RAWDIR)/bab.qual > $(WORKDIR)/cleaned.qual





finalize: $(WORKDIR)/libraryname $(DONEDIR)/done

$(WORKDIR)/libraryname:
	$(BINDIR)/determine_libraryname

# split the dbest file into chunks and move to done dir
$(DONEDIR)/done: $(WORKDIR)/estpipe.log $(WORKDIR)/libraryname
	cp $(WORKDIR)/dbest $(DONEDIR)
	$(BINDIR)/rename_file $(DONEDIR)/dbest
	$(BINDIR)/split_dbest $(DONEDIR)/*.dbest

	gzip -f $(DONEDIR)/*dbest*

# copy fasta and qual files over and compress
	cp $(WORKDIR)/est_seqs $(DONEDIR)/fasta
	$(BINDIR)/rename_file $(DONEDIR)/fasta
	gzip -f $(DONEDIR)/*fasta

	cp $(WORKDIR)/cleaned.qual $(DONEDIR)/qual
	$(BINDIR)/rename_file $(DONEDIR)/qual
	gzip -f $(DONEDIR)/*qual

	touch $(DONEDIR)/done






# independent commands to run after (or before) the main run


compress: 
	gzip $(RAWDIR)/* $(WORKDIR)/bab.fa.masked

uncompress: 
	gunzip $(RAWDIR)/* $(WORKDIR)/bab.fa.masked.gz

clean:
	rm $(DATADIR)/uniprot_human.fa*
	rm $(DATADIR)/humanmito.fa.*
	rm $(WORKDIR)/*
	rm $(DONEDIR)/*
	rm formatdb.log

