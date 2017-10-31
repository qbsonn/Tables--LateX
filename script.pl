#!bin/perl

use warnings;
use strict;
use diagnostics;
use feature 'say';
use feature 'switch';

my $start_info=<<"END";
Tabelki 
Sk³adnia scipt.pl plik.txt separatory_kolumn separatory_wierszy [opcje] 

Opcje:
-r Rotacja tabeli o 90stopni
-w Podsumowanie wierszy w ostatniej kolumnie
-c Podsumowanie kolumn w ostatnim wierszu
-h puste naglowki wierszy i kolumn


END

my $arg_nums=$#ARGV+1;

#SPRAWDZANIE LICZBY ARGUMENTOW
if ($arg_nums<3)
{
print "B³¹d! Za ma³o argumentów \n";
print $start_info;
exit;
}

my $filename=$ARGV[0];
my $separators="$ARGV[1]";
my $new_line="$ARGV[2]";
my @options;
my $rotate=0;
my $sum_row=0;
my $sum_col=0;;
my $empty_head=0;


#SPRAWDZANIE OPCJI
for (my $i=3; $i< $arg_nums;$i++)
{
	$options[$i-2]=$ARGV[$i];
	if ($options[$i-2] eq "-r")
	{
		$rotate=1;
	}	
	elsif ($options[$i-2] eq "-w")
	{
		$sum_row=1;
	}
	elsif ($options[$i-2] eq "-c")
	{
		$sum_col=1;
	}
	
	elsif ($options[$i-2] eq "-h")
	{
		$empty_head=1;
	}
	else 
	{
		print "B³ad! Nieprawid³owa opcja \n";
		print $start_info;
		exit;
	}
}
local $/;
open(my $fh, "<", $filename)
or die "Nie mozna otworzyc pliku: $!";

my @row;
my @array;
my $rows_counter=0; 
my $column_counter=0;
my $entire;
#ODCZYT PLIKU LINIA PO LINII
$entire=<$fh>;
#PARSOWANIE LINII
my @lines=split(/[$new_line]/,$entire);
for (my $i=0; $i<scalar(@lines);$i++)
{
	#PARSOWANIE KOLUMN
	@row=split(/[$separators]/,$lines[$i]);
if ($column_counter<$#row+1)
	{
		$column_counter=$#row+1;
	}
	push(@array,[@row]);
	$rows_counter++;
}


my @sumr=0;
my @sumc=0;
my @temp;
#ZAPIS WARTOSCI Z PLIKU DO TABLICY 2D

for (my $i=0; $i<scalar(@array);$i++)
{

for (my $j=0;$j <$column_counter; $j++)
{
 no warnings;

 #print "$array[$i]->[$j] " //0
#SUMOWANIE KOLUMN I WIERSZY

if ($rotate==0)
{
	 $sumr[$i]+=$array[$i]->[$j];
         $sumc[$j]+=$array[$i]->[$j];
}
else 
{#ROTACJA
 $temp[$j]->[scalar(@array)-1-$i]=$array[$i]->[$j];
  $sumr[$j]+=$temp[$j]->[scalar(@array)-1-$i];
  $sumc[scalar(@array)-1-$i]+=$temp[$j]->[scalar(@array)-1-$i];
}
}
}


if ($rotate==1)
{
	$column_counter=scalar(@array);
	@array=@temp;
}


my $slash=rindex($filename,"/");

if ($slash!=-1)
{
	$filename=substr($filename,$slash+1,(length $filename)-$slash);
}
#WYCIAGANIE PREFIXU Z NAZWY PLIKU WEJSCIOWEGO
my $file_prefix;
if (index($filename, '.')!=-1)
{
$file_prefix=substr($filename,0,index($filename,'.'));
}
else
{
$file_prefix=$filename;
}

#OTWIERANIE STRUMIENIA WYJSCIOWEGO -> PLIK TEX
open (my $writer, ">", "$file_prefix".".tex")
or die "Nie mo¿na otworzyæ pliku: $!";

my $output=<<"END";
\\documentclass[12pt]{article}
\\usepackage[latin1]{inputenc}

\\title{Tabela wartosci z pliku $filename}
\\author{wygenerowane przez skrypt}
\\date{\\today}
\\begin{document}

\\maketitle
\\center
Wygenerowana tabela z opcjami:
END
print $writer $output;
	if ($rotate==1)
	{
		print $writer " rotacja,";
	}	
	if ($empty_head==1)
	{
		print $writer " puste naglowki kolumn i wierszy,";
	}
	if ($sum_col==1)
	{
		print $writer " sumowanie kolumn,";
	}
	
	if ($sum_row==1)
	{
		print $writer " sumowanie wierszy,";
	}
print $writer "\n \n";
	
print $writer "\\bigskip \n";

my $counter=$column_counter;;
	if ($sum_row==1)
	{
		$counter++;
	}	
	if ($empty_head==1)
	{
		$counter++;
	}	

print $writer "\\begin{tabular}{*{$counter}{|c}|} \n";

print $writer "\\hline \n";

#DODAWANIE PUSTEGO NAGLOWKA KOLUMN
if ($empty_head==1)
{	
	for (my $i=0;$i<$counter;$i++)
{
if ($i!=$counter-1)
{
	print $writer " &";
}
}
print $writer "\n \\\\\\hline \n";
}
#APIS TABLICY DO PLIKU TEX
for (my $i=0; $i<scalar(@array);$i++)
{
#DODAWANIE PUSTEGO NAGLOWKA WIERSZY
if ($empty_head==1)
{
	print $writer " &";
}
for (my $j=0;$j <$column_counter; $j++)
{
 no warnings;
if (($j!=$column_counter-1)||($sum_row==1))
{
 print $writer " $array[$i]->[$j] ". '&' //0;
}
else
{
 print $writer " $array[$i]->[$j] " //0;

}
}
#DODAWANIE SUMY WIERSZY W OSTATNIEJ KOLUMNIE
if ($sum_row==1)
{
print $writer " $sumr[$i]";
}
print $writer "\\\\\\hline \n"
}

#DODAWANIE WIERSZA SUMUJACEGO KOLUMNY
my $del=0;
if ($sum_col==1)
{
if ($empty_head==1)
{
print $writer " & ";
$del=1
}
for (my $j=0;$j <$counter-$del; $j++)
{
if ($j!=$counter-1-$del)
{
 print $writer "$sumc[$j] &";
}
else 
{
print $writer $sumc[$j];
}
}
print $writer "\n \\\\\\hline \n"
}
print $writer "\\end{tabular} \n";
print $writer "\\end{document}";
system('pdflatex -output-directory ' . '.' . ' ' . "$file_prefix".".tex");
my $log="$file_prefix".".log";
my $aux="$file_prefix".".aux";
print "Usuwanie plików .log i .aux \n";
system ('rm '. "$log "." $aux");
close ($writer);
print "Zakonczono dzialanie skryptu. Wynik zapisano w katalogu w ktorym znajduje sie skrypt. \n";
close ($fh);
