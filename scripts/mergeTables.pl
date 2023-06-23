#!/usr/bin/env/perl

use strict;
use warnings;

my @files = @ARGV;
my $output = pop @files;

my %hash;

for my $file (@files){
	open FILE, $file or die "cannot open $file $!\n";
	
        print STDOUT "running $file\n";

	while(<FILE>){
		chomp;
		my @line = split /\t/;
		if($line[0] =~ /Contig/){
			$line[0] = "0_Contig";
			$line[1] =~ s/cat_mags.fa.(.*?)_mg.r1.preprocessed.fq.gz Trimmed Mean/$1/;
		}
		if(exists $hash{$line[0]}){
			$hash{$line[0]} .= "$line[1]\t";
		}else{
			$hash{$line[0]} = "$line[1]\t";
		}
	}
	close FILE;
}

open COV, ">", $output;

for my $i (sort keys %hash){
	print COV "$i\t$hash{$i}\n";
}

close COV;
