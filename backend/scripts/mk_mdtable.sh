#!/usr/bin/env bash
##-----------------------------------------------------------
## Generate final table in markdown format 
##
## Usage: $0 <env>
## the <env> could be one of dev, pp, prod, q1, q2, st, test, uat
## 
## the script invokes ./fetch_resize_info.sh
##
## output file: $BACKEND_DIR/data/table.${env}.${ostype}md
##------------------------------------------------------------

f_prt_usage () {
  echo "Usage: $pgm <env>"
  echo "       <env> is one of  dev, pp, prod, q1, q2, st, test, uat"
  echo "Example: $pgm dev"
  exit 1
}
##-----------------------------
# Main
##-----------------------------

pgm=${0##*/}
[[ $# -lt 1 ]] && f_prt_usage
env=$1

export OUTPUT_FILE=$BACKEND_DIR/data/table.${env}.$OSTYPE.md
TSV_FILE=$BACKEND_DIR/data/table.${env}.$OSTYPE.tsv
> $OUTPUT_FILE
> $TSV_FILE


./fetch_resize_info.sh $env | perl -lne '
  BEGIN {
    $/ = "";              # paragraph mode
    @rows = ();
    @width = ();
  }

  my ($host, $cpu_cur, $cpu_new, $mem_cur, $mem_new) = ("", "N/A", "N/A", "N/A", "N/A");

  for my $line (split /\n/) {
    if ($line =~ /(.+?)\s*\.\.\./) {
      $host = $1;
    } elsif ($line =~ /CPU:\s+([\d\.]+)\s+([\d\.]+)/) {
      ($cpu_cur, $cpu_new) = ($1, $2);
    } elsif ($line =~ /Mem:\s+([\d\.]+)\s+([\d\.]+)/) {
      ($mem_cur, $mem_new) = ($1, $2);
    }
  }

  if ($. == 1) {
    @header = (
      "Host Name",
      "vCPU (Current)",
      "vCPU (Target)",
      "Memory (Current GB)",
      "Memory (Target GB)"
    );
    push @rows, \@header;
    print join("\t", @header);
  }

  my @row = ($host, $cpu_cur, $cpu_new, $mem_cur, $mem_new);
  push @rows, \@row;

  # Original TSV output
  print join("\t", @row);

  END {
    # Calculate column widths
    for my $r (@rows) {
      for my $i (0 .. $#$r) {
        my $len = length($r->[$i]);
        $width[$i] = $len if !defined $width[$i] || $len > $width[$i];
      }
    }

    my $mdfile = $ENV{OUTPUT_FILE};
    open my $md, ">", $mdfile or die "Cannot write $mdfile: $!";

    # Header
    print $md "| " .
      join(" | ", map { sprintf("%-*s", $width[$_], $rows[0]->[$_]) } 0 .. $#width)
      . " |";

    # Separator
    print $md "| " .
      join(" | ", map { "-" x $width[$_] } 0 .. $#width)
      . " |";

    # Data rows
    for my $r (1 .. $#rows) {
      print $md "| " .
        join(" | ", map { sprintf("%-*s", $width[$_], $rows[$r]->[$_]) } 0 .. $#width)
        . " |";
    }

    close $md;

  }
' |tee $TSV_FILE

echo
echo "Markdown table saved as $OUTPUT_FILE";
echo ".tsv table saved as $TSV_FILE";


