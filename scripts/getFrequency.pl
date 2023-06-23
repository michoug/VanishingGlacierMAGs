#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my ($file, $fileout) = @ARGV;

my $name = $file;
$name =~ s/.faa//g;
$name =~ s/.*\///g,

my $seqio_object = Bio::SeqIO->new(-file => $file);

my $finalcount;
my $finallength;

while (my $seq = $seqio_object->next_seq) {

	my $sequence = $seq->seq();
	my $id = $seq->id;
	my $length =  $seq->length;

	$finallength += $length;
	
	my $count = $sequence =~ tr/IVYWREL//;
	$finalcount += $count;
}

my $perc = $finalcount / $finallength;

my $ogt = 937 * $perc - 335;

open OUT, ">", $fileout;
print OUT "$name\t$ogt\n";
close OUT;
