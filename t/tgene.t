use strict;
use warnings;

# Gtest is a small package used to test the AI::Gene::Sequence
# package.  It provides a generate_token method and a seed_gene
# method, the first is highly deterministic (so tests of a module
# which hinge on randomness can work) and the second sets up a gene
# ready for a test.

# Also is a new method, which creates the gene and seeds it and
# 'd' and 'g' methods, which return (stringified) versions of the
# sequence ($self->[0]) and gene (@{$self->[1]}) respectively.

package GTest;
our (@ISA);
use AI::Gene::Sequence;
@ISA = qw(AI::Gene::Sequence);

sub new {
  my $class = shift;
  my $self = ['',[]];
  bless $self, $class;
  $self->seed_gene;
  return $self;
}

sub seed_gene {
  my $self = shift;
  $self->[0] = join('', 'a'..'j');
  @{$self->[1]} = ('a'..'j');
  return 1;
}

sub generate_token {
  my $self = shift;
  my ($type, $prev) = @_;
  $type ||= 'n';
  $prev = uc $type;
  return ($type, $prev);
}

sub d {
  my $self = shift;
  return $self->[0];
}

sub g {
  my $self = shift;
  return join('', @{$self->[1]});
}

package main;
use Test;
# see above for a small package ( GTest ) used to test G::G::S
BEGIN {plan tests => 111, todo =>[]}
my $hammer = 30; # set big to bash at methods with randomness

{ # test1
  # first of all, does our testing package behave
  my $gene = GTest->new;
  die "$0: Broken render" unless $gene->d eq 'abcdefghij'
                            and $gene->g eq 'abcdefghij';
  die "$0: Broken generate" unless ($gene->generate_token('a'))[1] eq 'A'
    and ($gene->generate_token())[0] eq 'n';
  ok(1);
}
my $main = GTest->new;
{ print "# clone\n";
  my $gene = $main->clone;
  ok($gene->g, $main->g);
}

{ print "# mutate_minor\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_minor(1);
  ok ($rt, 1); # return value
  ok ($gene->g ne $main->g); # changed
  $gene = $main->clone;
  $gene->mutate_minor(1,0);
  ok ($gene->g, 'Abcdefghij');
  $rt = $gene->mutate_minor(1,10); # outside of gene
  ok ($rt,0);
  ok ($gene->g, 'Abcdefghij');
  # hammer randomness, check for errors
  $rt = 0;
  for (1..$hammer) {
    eval '$gene->mutate_minor()';
    $rt = 1 if $@;
  }
  ok($rt,0);
}

{ print "# mutate_major\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_major(1,0);
  ok($rt, 1);
  ok($gene->g, 'Nbcdefghij');
  $gene = $main->clone;
  $gene->mutate_major;
  ok($gene->g ne $main->g, 1);
  $gene = $main->clone;
  $rt = $gene->mutate_major(1,10); # outside of gene
  ok($rt,0);
  ok($gene->g eq $main->g);
  # hammer randomness
  $rt = 0;
  for (1..$hammer) {
    eval '$gene->mutate_major()';
    $rt = 1 if $@;
  }
  ok($rt,0);
}

{ print "# mutate_remove\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_remove(1,0);
  ok($rt,1);
  ok($gene->g eq 'bcdefghij' and $gene->d eq 'bcdefghij');
  $rt = $gene->mutate_remove(1,0,2);
  ok($rt,1);
  ok($gene->g eq 'defghij' and $gene->d eq 'defghij');
  $rt = $gene->mutate_remove(1,7); # outside of gene
  ok($rt,0);
  ok($gene->g eq 'defghij');
  $rt = $gene->mutate_remove(1,5,5); # extends beyond gene
  ok($rt,1);
  ok($gene->g eq 'defgh');
  # hammer randomness
  $rt = 0;
  for (1..$hammer) {
    $gene = $main->clone;
    eval '$gene->mutate_remove(1,undef,0)';
    $rt = 1 if $@;
  }
  ok($rt,0);
}

{ print "# mutate_insert\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_insert(1,0);
  ok($rt,1);
  ok($gene->g eq 'Nabcdefghij' and $gene->d eq 'nabcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_insert(1,10); # last possible pos
  ok($rt,1);
  ok($gene->d eq 'abcdefghijn' and $gene->g eq 'abcdefghijN');
  $gene = $main->clone;
  $rt = $gene->mutate_insert;
  ok($rt,1);
  ok($gene->d ne 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_insert(1,11); # outside of gene
  ok($rt,0);
  ok($gene->g eq 'abcdefghij');
  # hammer randomness
  $rt = 0;
  for (1..$hammer) {
    $gene = $main->clone;
    eval '$gene->mutate_insert';
    $rt = 1 if $@;
  }
  ok($rt,0);
}

{ print "# mutate_overwrite\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_overwrite(1,0,1); # first to second
  ok($rt,1);
  ok($gene->g, 'aacdefghij');
  ok($gene->d, 'aacdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_overwrite(1,0,4,3); # has length
  ok($rt,1);
  ok($gene->g, 'abcdabchij');
  ok($gene->d, 'abcdabchij');
  $gene = $main->clone;
  $rt = $gene->mutate_overwrite(1,3,4,3); # overlap
  ok($rt,1);
  ok($gene->g, 'abcddefhij');
  ok($gene->d, 'abcddefhij');
  $gene = $main->clone;
  $rt = $gene->mutate_overwrite(1,0,10,3); # dump lies at end of gene
  ok($rt,1);
  ok($gene->g, 'abcdefghijabc');
  ok($gene->d, 'abcdefghijabc');
  $gene = $main->clone;
  $rt = $gene->mutate_overwrite(1,0,11); # dump lies beyond end of gene
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  ok($gene->d, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_overwrite(1,11,4); # area to copy lies outside gene
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  ok($gene->d, 'abcdefghij');
  # hammer randomness
  $rt = 0;
  for (1..$hammer) {
    $gene = $main->clone;
    eval '$gene->mutate_overwrite(1,undef,undef,0)';
    $rt = 1 if $@;
  }
  ok($rt,0);
}

{ print "# mutate_reverse\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_reverse(1,0,2);
  ok($rt,1);
  ok($gene->d, 'bacdefghij');
  ok($gene->g, 'bacdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_reverse(1,0,10); # whole gene
  ok($rt,1);
  ok($gene->d, 'jihgfedcba');
  ok($gene->g, 'jihgfedcba');
  $gene = $main->clone;
  $rt = $gene->mutate_reverse(1,8,4); # extends beyond gene
  ok($rt,0);
  ok($gene->d, 'abcdefghij');
  ok($gene->g, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_reverse(1,10,1); # starts outside gene
  ok($rt,0);
  ok($gene->d, 'abcdefghij');
  ok($gene->g, 'abcdefghij');
  # hammer randomness
  $rt = 0;
  for (1..$hammer) {
    $gene = $main->clone;
    eval '$gene->mutate_reverse(1,undef,0)';
    $rt = 1 if $@;
  }
  ok($rt,0);
}

{ print "# mutate_duplicate\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_duplicate(1,0,0);
  ok($rt,1);
  ok($gene->g, 'aabcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_duplicate(1,9,0); # from end of gene to front
  ok($rt,1);
  ok($gene->g, 'jabcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_duplicate(1,10,0); # from outside of gene
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_duplicate(1,0,11); # to posn beyond end of gene
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_duplicate(1,0,10); # to posn at very end of gene
  ok($rt,1);
  ok($gene->g, 'abcdefghija');
  $gene = $main->clone;
  $rt = $gene->mutate_duplicate(1,0,10,10); # double the gene
  ok($rt,1);
  ok($gene->g, 'abcdefghijabcdefghij');
  # hammer randomness
  $rt = 0;
  for (1..$hammer) {
    $gene = $main->clone;
    eval '$gene->mutate_duplicate(1,undef,undef,0)';
  }
  ok($rt,0);
}

{ print "# mutate_switch\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_switch(1,0,9); # first and last
  ok($rt,1);
  ok($gene->g, 'jbcdefghia');
  $gene = $main->clone;
  $rt = $gene->mutate_switch(1,0,8,2,2); # 1st 2 and last 2
  ok($rt,1);
  ok($gene->g, 'ijcdefghab');
  $gene = $main->clone;
  $rt = $gene->mutate_switch(1,0,5,2,4); # different lengths
  ok($rt,1);
  ok($gene->g, 'fghicdeabj');
  $gene = $main->clone;
  $rt = $gene->mutate_switch(1,0,10); # pos2 outside gene
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_switch(1,10,0); # pos1 outside gene (silently same as)
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_switch(1,0,9,1,2); # second section extends beyond
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_switch(1,0,2,5,3); # overlap of sections
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  # hammer randomness
  $rt = 0;
  for (1..$hammer) {
    $gene = $main->clone;
    eval '$gene->mutate_switch(1,undef,undef,0,0)';
    $rt = 1 if $@;
  }
  ok($rt,0);
}


{ print "# mutate_shuffle\n";
  my $gene = $main->clone;
  my $rt = $gene->mutate_shuffle(1,5,0); # from after to
  ok($rt,1);
  ok($gene->g, 'fabcdeghij');
  $gene = $main->clone;
  $rt = $gene->mutate_shuffle(1,5,0,2); # extended sequence
  ok($rt,1);
  ok($gene->g, 'fgabcdehij');
  $gene = $main->clone;
  $rt = $gene->mutate_shuffle(1,0,5,2); # to after from
  ok($rt,1);
  ok($gene->g, 'cdeabfghij');
  $gene = $main->clone;
  $rt = $gene->mutate_shuffle(1,0,9,1); # 1st to last
  ok($rt,1);
  ok($gene->g, 'bcdefghiaj');
  $gene = $main->clone;
  $rt = $gene->mutate_shuffle(1,0,3,8); # overlap
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_shuffle(1,0,10,1); # to posn outside gene
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  $gene = $main->clone;
  $rt = $gene->mutate_shuffle(1,0,8,5); # should suceed
  ok($rt,1);
  ok($gene->g, 'fghabcdeij');
  $gene = $main->clone;
  $rt = $gene->mutate_shuffle(1,8,5,5); # extends beyond gene
  ok($rt,0);
  ok($gene->g, 'abcdefghij');
  # hammer randomness
  $rt = 0;
  for (1..$hammer) {
    $gene = $main->clone;
    eval '$gene->mutate_shuffle(1,undef,undef,0)';
    $rt = 1 if $@;
  }
  ok($rt,0);
}

{ print "# mutate\n";
  my $rt = 0;
  # hammer with defaults
  for (1..$hammer) {
    my $gene = $main->clone;
    eval '$gene->mutate';
    $rt = 1 if $@;
  }
  ok($rt,0);
  # hammer with custom probs
  my %probs = (
               insert    =>1,
	       remove    =>1,
	       duplicate =>1,
	       overwrite =>1,
	       minor     =>1,
	       major     =>1,
	       switch    =>1,
	       shuffle   =>1,
	       );
  $rt = 0;
  for (1..$hammer) {
    my $gene= $main->clone;
    eval '$gene->mutate(1, \\%probs)';
    $rt = 1 if $@;
  }
  ok($rt,0);
}
1;
