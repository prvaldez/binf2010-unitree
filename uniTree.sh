#!/usr/local/bin/bash
# usage: gets many *.fasta from uniprotKB
# writes onto one *.fasta file
# plugs *.fasta into clustalw for MSA
# spits out *.ph in Newick format using clustalw2
# additional feature: program usage help AND delete intermediates option (worth 5%)

###############################################################################################################################

checkInput () {
    # if no argument, program will terminate
    if [[ $GENE == '' ]]
    then
        echo '#####################################################################'        
        echo 'Error: no GENE symbol entered (e.g. insulin -> INS)'
        echo 'Syntax: /uniTree.sh GENE'
        echo 'Note: any additional arguments will be ignored'
        echo '#####################################################################'        
        echo 'Enter /uniTree.sh -h for usage'
        echo '#####################################################################'        
        echo '!!! WARNING: any exactly-named files may be overwritten !!!'
        echo '#####################################################################'        
        exit 1
    
    # ADDITIONAL FEATURE: usage (invoked by /uniTree.sh -h)
    # gives usage, some details of function, and syntax help
    elif [[ $GENE == '-h' ]]
    then
        echo '#####################################################################'        
        echo 'uniTree mammalian alignment and phylogenetic tree constructor'
        echo 'Retrieves *.fasta from UniProtKB for all mammalia [40674]'
        echo 'Performs multiple sequence alignment on ClustalW'
        echo 'Uses MSA to build Newick phylogenetic tree on ClustalW2'
        echo 'Will delete intermediate files on command'
        echo '#####################################################################'        
        echo 'Syntax: /uniTree.sh GENE'
        echo 'Output: GENE.ph'
        echo 'GENE: any gene abbreviation (e.g. insulin -> INS)'
        echo '#####################################################################'        
        echo 'Note: any additional arguments will be ignored'
        echo '#####################################################################'        
        echo '!!! WARNING: any exactly-named files may be overwritten !!!'
        echo '#####################################################################'        
        exit 1
    # else /uniTree.sh continues running
    fi
}

###############################################################################################################################

getFasta () {
    echo "Retrieving sequence for $GENE..."
    wget -O $GENE.fasta 'https://www.uniprot.org/uniprot/?query=gene_exact:'$GENE'%20taxonomy:%22Mammalia%20[40674]%22&fil=reviewed:yes&sort=score&format=fasta'
    # 'gene:GENE taxonomy:"Mammalia [40674]" AND reviewed:yes AND sort=score AND format=fasta'
    # based on this perl code my $query = "https://www.uniprot.org/uniprot/?query=organism:$taxon&format=fasta";
    # by the fine folks at uniprot https://www.uniprot.org/help/api_downloading
    # oi josuke
    # i used [za hando] to bring an "_exact" right next to "gene"
    # and now i don't get transmembrane protein when i look for titin
    # but i also don't get insulin variants
    # ain't that neat?
}

###############################################################################################################################

headerEdit () {
    # a progressive deletion of header, leaving only the >Species name
    
    echo "Editing $GENE.fasta..."
    perl -i -p -e 's/[\w\s\|-]+OS\=//' $GENE.fasta
    # replaces first third with nothing

    perl -i -p -e 's/\b\sOX.*\b//' $GENE.fasta
    # replaces final third with nothing

    perl -i -p -e 's/([a-z])\s([a-z])/\1_\2/' $GENE.fasta
    # replaces remaining whitespaces with underscore, so entire species name shows on tree

    echo "$GENE.fasta edited!"
}

###############################################################################################################################

clustalOmega () {
    echo "Aligning mammalian $GENE..."
    clustalw $GENE.fasta -align
    # clustalw performs MSA on *.fasta, producing output *.

    echo "Building phylogenetic tree for $GENE..."
    clustalw2 -INFILE=$GENE.aln -TREE -OUTPUTTREE=phylip
    # clustalw2 -TREE -OUTPUTTREE=phylip makes phylogenetic tree from protein sequences, producing output *.ph
    # clustalw2 chosen because it's available online
}

###############################################################################################################################

deleteMonika () {
    # haha gedit because it deletes files by moniker but not really actually by extension
    # it's not a ddlc reference at all i'm not a weeb haha

    # ADDITIONAL FEATURE: do you really want to delete those intermediate files?
	# this block lists targeted files for user reassurance
    echo "!!!WARNING!!! Delete intermediate files (NOT $GENE.ph)?"
    find . -name "$GENE.aln" -type f        # retrieves clustalw output from all directories, even trash
    find . -name "$GENE.dnd" -type f        # retrieves clustalw guide tree from all directories, even trash
    find . -name "$GENE.fasta" -type f      # retrieves downloaded fasta from all directories, even trash

    # case sensitive to prevent unintended deletion
    echo '[y to delete]'
    read deletePrompt

    # for now, the only files with the above names are either in the pwd or trash
    if [[ $deletePrompt == 'y' ]]
    then
        find . -name "$GENE.aln" -type f -delete       # deletes alignment
        find . -name "$GENE.dnd" -type f -delete       # deletes guide tree
        find . -name "$GENE.fasta" -type f -delete     # deletes fasta
        echo '!!! Intermediate files deleted !!!'
    else
        echo 'Intermediate files retained!'
    fi
}

###############################################################################################################################

source ~binftools/setup-env.sh      # source ensures binf software packages are ready to use (e.g. clustalw)
GENE=$1                             # GENE is assigned to whatever argument the user enters $1
checkInput
getFasta
headerEdit
clustalOmega
deleteMonika
echo 'Done.'                        # indicates script has finished running, regardless of outcome
















