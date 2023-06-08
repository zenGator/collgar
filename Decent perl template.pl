#!/usr/bin/perl
# https://github.com/zenGator/[name]
# zG:[2023xxxx]

# other notes
=for comment 
Comment text, spanning multiple lines. 
It ends with the first blank line.

=cut

=begin comment
Multi-paragraph comment section.
Which is terminated by an =end comment on a line by itself.

This is a second paragraph.  Note that the blank lines are part of the syntax and the "=" must be the initial characters.

=end comment

=cut

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#use and constants here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use strict;
use warnings;
use Getopt::Std;
use POSIX;
#use File::Copy;
#use constant XWFLIM => 100000;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#declare subroutines here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#sub usage;
#sub capOutput;

# switches followed by a : expect an argument
# see usage() below for explanation of switches
my $commandname=$0=~ s/^.*\///r;				#let's know our own name
my %opt=();
getopts('dhi:l:o:', \%opt) or usage();				#typical options: debug, help, infile, outfile, logfile

my $debugging=TRUE if $opt{d};
usage () if ( $opt{h} or (scalar keys %opt) == 0 ) ;		#show help if requesting or a bad flag is provided

=begin method 
#to ensure options needed for other options are provided do this (in this case, s requires o):
if ( $opt{s} and ! $opt{o}) {
    print "ERROR ($commandname):  -o required when using -s.\n\n";
    usage();
    }
=end method

=cut

#show positional parameters (anything after flagged options
for my $i (0 .. $#ARGV) {
  printf "%d: \t%s\n", $i,$ARGV[$i];
}


#allow for piping /dev/stdin|stdout|stderr or redirect if specified at command-line
my $inFH=*STDIN;
if ($opt{i}) {
	open($inFH, '<:encoding(UTF-8)', $opt{i})
	  or die "Could not open file '$opt{i}' $!";
	}
*STDIN=$inFH;

my $outFH=*STDOUT;
if ($opt{o}) {
    open($outFH, '>:encoding(UTF-8)', $opt{o}) 
        or die "Could not open file '$opt{o}': $!\n";
    }
*STDOUT=$outFH;

my $logFH=*STDERR;
if ($opt{l}) {
    open($logFH, '>:encoding(UTF-8)', $opt{l}) 
        or die "Could not open file '$opt{l}': $!\n";
    }
*STDERR=$logFH;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#declare variables here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
my $x=0;  		#primary counter, the line we are currently processing

my $starttime= strftime ("%Y.%m.%dT%H:%M:%SZ", gmtime time);	#provide for standard time
printf $logFH "started at %s\n",$starttime if $debugging;  #dbg


while (my $row = <$inFH>) {
    #get a line
    $x++;  # increment line counter
    $regEx=0;
    chomp $row;  #drop the newline at the end of the row
    my $orig_row=$row;	#store this off for later reference

    # transforms
    $row =~ s/([^\\]\[[^]]*)\\d([^]]*\])/$1#$2/g;
    $row =~ s/\\d/#/g;

    if ( $row =~ /[^\\]\[[^]]*\\b[^\]]*\]/ ) {
    warn "word boundary inside braces (could be problematic):  ## on line $x\n";
    }
    $row =~ s/\\b/[^_a-z#]/g;
    $row =~ s/([^\\]\[[^]]*)\\W([^\]]*\])/$1\\x21-\\x2F\\x3A-\\x40\\x5B-\\x60\\x7B-\\x7E$2/g;
    $row =~ s/\\W/[\\x21-\\x2F\\x3A-\\x40\\x5B-\\x60\\x7B-\\x7E]/g;
    $row =~ s/,\}/,9\}/g;

#show results
            capOutput($reFiCount++,length($row),$refile, $reFH);
        $chars+=length($row)+2; # the 2 is for the \r\n
        printf $outFH "%s\r\n", $row;
        }
    
exit 0;

sub usage() {
    print "like this: \n\t".$commandname." -i [infile] -o [outfile] [-l [logfile]] [-s] [-d]\n";
    print "\nThis adjusts RegEx (as used in mwscan, possibly POSIX-compliant) into XWF-compatible RegEx/grep strings.  Because XWF has a limit of ".XWFLIM." characters for any set of simultaneous-search strings, if the output file reaches that limit, multiple output files are created by appending a digit (zero-indexed, of course) to the output file name.  Each will need to be run as a separate simultaneous search.\n";
    print "\n-s\t[s]plit the output into two [sets of] files:  one that works as simple string search terms and another that contains RegEx terms which will require the 'GREP syntax' option be selected in XWF.  You must identify an output file if using -s.\n";
    print "\n-d\tfor some [d]ebugging messages.";
    exit 1;
    }

sub capOutput {
    # XWF can only ingest XWFLIM chars for simul-search
    my $count=shift;
    my $len=shift;
    my $file=shift;
    my $FH=shift;
    printf STDERR "XWF limit reached, saving output file segment as: %s\n",$file."_".$count;
    close $FH;
    move($file,$file."_".$count) or die "Couldn't rename '$file': $!\n";
    if ($regEx){
        open($FH, '>:encoding(UTF-8)', $file) or die "Could not open file '$file' $!";
        }
    else {
        open($FH, '>:encoding(UTF-8)', $file) or die "Could not open file '$file' $!";
        }
    }
