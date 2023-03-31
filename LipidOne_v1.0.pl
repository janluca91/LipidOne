#!/usr/bin/perl

use Cwd;   
use Data::Dumper;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Statistics::Descriptive;
use Statistics::ANOVA 0.14;
use Chart::Gnuplot;
use Prima;
use Prima::Application;
use Prima::ComboBox;
use Prima::Dialog::FileDialog;
use Prima::MsgBox;
use Prima::Grids;
use Prima::Buttons;
use Prima::Label;
use Prima::FrameSet;
use Prima::StdBitmap;
use Prima::Utils;
use Prima::ExtLists;
use Prima::ImageViewer;
use Prima::Image::png; 
use Prima::Image::jpeg; 
use Prima::Image::gif; 
use Prima::Image::tiff; 
use Prima::Spinner;
use Prima::Dialog::ImageDialog;
use Prima::Classes;


print "LOADING...\n";

my %chains_for_classes=qw(Ac2PIM1 2 Ac2PIM2 2 Ac3PIM2 3 Ac4PIM2 4 ADGGA 3 AHexCer 3 BMP 2 BRS;Hex;FA 1 BRSE 1 CAR 1 CAS;Hex;FA 1 CASE 1 CE 1 Cer 2 CerP 2 CL 4 CS;Hex;FA 1 DCAE 1 DG 2 DGCC 2 DGDG 2 DGGA 2 DGTS 2 DLCL 2 FA 1 FAHFA 2 GM3 2 HBMP 3 Hex2Cer 2 Hex3Cer 2 HexCer 2 LDGCC 1 LDGTS 1 LPA 1 LPC 1 LPE 1 LPE-N 1 LPG 1 LPI 1 LPS 1 LPS-N 1 MG 1 MGDG 2 MLCL 3 NAE 1 NAGly 1 NAGlySer 1 NAOrn 1 PA 2 PC 2 PE 2 PE-Cer 2 PEtOH 2 PG 2 PI 2 PI-Cer 2 PMeOH 2 PS 2 SHexCer 2 SIS;Hex;FA 1 SISE 1 SL 2 SM 2 SMGDG 2 SPB 1 SQDG 2 STS;Hex;FA 1 STSE 1 TG 3 VAE 1 AAHFA 1 DMPE 2 MMPE 2);


my $window = Prima::Window-> new(
     centered=> 1,
     x_centered=> 1,
     y_centered=> 1,
     backColor => 0xc6dfc6,  
     borderIcons => bi::SystemMenu | bi::Minimize | bi::TitleBar,
     borderStyle => bs::None,  
     icon => $icon,
     geometry => gt::GrowMode,
     name => 'MainWindow',
     width=>  ($::application-> width)*80/100,
     height=>  ($::application-> height)*80/100,  
     text => 'LipidOne v1.0',
     menuItems => [
        [ '~File' => [
           [ '~Open', 'Ctrl+O', '^O', \&onOpenFile ],
           [],
           [ '~Exit', 'Alt+X', km::Alt | ord('x'), sub { $::application-> close } ], 
        ]],
        [ '~Options' => [
           [ '~Export chains table in MetaboAnalyst format', 'Ctrl+E', '^E', sub { export_table() } ],  
        ]],
     ],
);


my $open = Prima::Dialog::OpenDialog-> new(
        filter => [
                ['Text Files' => '*.txt'],
                ['All' => '*']
        ]
);



$fontsize_title=18*($::application-> height)/($::application-> width);
$label1=$window->insert(Label => 
		siblings => [qw(focusLink)],
		name => 'Label1',
		origin => [ 20, ($window-> height)*95/100],
                size => [($window-> width) -40, ($window-> height)*5/100],
                text => "LipidOne v1.0  -  An in-depth and user-friendly lipidomic data analysis tool",
        	showPartial => 0,
                wordWrap=>1,  
                alignment=> ta::Center,  
                valignment=> ta::Center, 
              )->font->set(
                 style => fs::Bold,
                 size => $fontsize_title,
  );


my $panel_LEFT = $window->insert( Widget =>
	origin => [ 20, 20 ],
        width=>  ($window-> width)*40/100-30,
        height=>  ($window-> height)*92/100, 
        backColor => 0xc6dfc6, 
);


my $panel_RIGHT = $window->insert( Widget =>
	origin => [ ($window-> width)*40/100+10, 20 ],
        width=>  ($window-> width)*60/100-30,
        height=>  ($window-> height)*92/100, 
        backColor => 0xc6dfc6, 
);



sub close_app ()
{
$::application-> close;
}


sub open_file ()
{
 my $filename= $_[0];
 print "filename:".$filename;
 %tabella_madre=();
 open(FILEIN, '<', $filename) or die $!; 
  # per ora globale
  $dir = getcwd;
  $submit->destroy if ($submit);
  if ($grid) {$label2->destroy; $grid->destroy; $panel_RIGHT->update_view();} 
  $options_CLASS->destroy if ($options_CLASS); 
  $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS);
  my @table=(); 
  @first_column=();
  @names=();
  @classes_unfiltered=(); 
  @class_parsed=();
  @total_first_column=();
  @classes=();
  @total_first_column_OX=();
  @OX=();
  @row=();
  @splitted=();
  $r=0;
  while(<FILEIN>){
	 chomp $_;
	 $firstrow=$_;
	 if ((!($_ =~ /\t/)) && ($_ ne '')) {     
		@table=();
		$opzioni_gruppi->destroy if $opzioni_gruppi;
		$analisi->destroy if $analisi;
		$label_gruppi->destroy if $label_gruppi;
		Prima::MsgBox::message_box( 'LipidOne', "Invalid Format: please use TAB-delimited data", mb::Ok); 
		last;
	 }   
	 if ($_ eq '') {     
	 next;
	 }
	 $_ =~ s/,/\./g; 
	 $_ =~ s/[_\/]0:0//g;
	 @row=split ("\t",$_);
	 if ($r<=1) { 
		for ($c=0; $c<=$#row; $c++) { $table[$r][$c]=$row[$c]; } 
		$r++;
	  } 
	elsif ($r>1) { 
	@class_parsed=split (" ", $row[0]);
	if (( () = $row[0] =~ m{_}g ) == $chains_for_classes{$class_parsed[0]}-1)   
	   {
	   for ($c=0; $c<=$#row; $c++) {  
		  $table[$r][$c]=$row[$c]; 
		  }
	   push (@first_column , $row[0]);
	   push (@classes_unfiltered, $class_parsed[0]);
	   $r++;
	   } 
	}      
 } 
 close (FILEIN);
 @classes = do { my %seen; grep { !$seen{$_}++ } @classes_unfiltered };
 @classes= sort @classes;
 foreach my $element (@first_column) 
  {
  $element=~ s/\s+$//; 
  @splitted = split(/[_]/, $element );
  if ($splitted[0]=~ /^[A-Za-z]/) {
	  $splitted[0]=~ s/[A-Za-z;-]*\s//g; 
	 } 
  push (@total_first_column, @splitted);
 }
 @names = do { my %seen; grep { !$seen{$_}++ } @total_first_column };
 @names= sort @names;

foreach my $element (@first_column) {
   @splitted_OX = split(/[_\-\s;()]/, $element );
   if ($splitted_OX[0]=~ /^[A-Za-z]/) {
		$splitted_OX[0]= ''; 
	   } 
  foreach my $element2 (@splitted_OX) {
	  if (( () = $element2 =~ m{O}g ) > 0) {       
		  push (@total_first_column_OX, $element2);
		}
   }
 } 
 @OX = do { my %seen; grep { !$seen{$_}++ } @total_first_column_OX };
 @OX= sort @OX;
  
if ($firstrow =~ /\t/) {  
	$image->destroy if $image;  
	inserisci_tabella_input(@table);  
	&crea_tabelle_madri(@table);

	$submit=$panel_LEFT-> insert( Button =>
   text   => '~SUBMIT',
   pack   => { side => 'bottom' , padx => 20 },
	  onClick => \&onSubmit
   );
 } 
} 



sub inserisci_tabella_input()
{
 my @table=@_;
 if (@table) {
 $grid=$panel_RIGHT->insert('Prima::Grid', 
         name => 'Grid1',
         origin => [ 0, ($panel_RIGHT-> height)*16/100],  
         size => [ $panel_RIGHT-> width, ($panel_RIGHT-> height)*84/100 ],
         visible => 1,
         multiSelect =>1,
         backColor => 0xffffff, 
         cells  => [@table],  
 );

 %samples=();
 for ($j=1; $j<$c; $j++) {
    $samples{$table[0][$j]} = $table[1][$j];   
    }
 @gruppi_unique = do { my %seen; grep { !$seen{$_}++ } values (%samples) };


 sub print_label2 ()
 {
 my $filename=$_[0];
 $num_samples=scalar(%samples);
 $num_gruppi=scalar(@gruppi_unique);
 $unique_chains=scalar(@names);
 $unique_classes=scalar(@classes);
 return ("Uploaded file: $filename\nData processing information:\nDetected $num_samples samples, $num_gruppi groups, $unique_chains lipid chain types grouped into $unique_classes lipid classes.\n");
 }

 $label2=$panel_RIGHT->insert('Prima::Label', 
                siblings => [qw(focusLink)], 
		name => 'Label2',
		origin => [ 0, 0],
                size => [$panel_RIGHT-> width, ($panel_RIGHT-> width)*14/100],
                wordWrap => 1,   
                valignment=> ta::Center,  
                text => &print_label2($open-> fileName)  
);

 $label_gruppi=$panel_LEFT->insert(Label => 
		siblings => [qw(focusLink)],
		name => 'Label_gruppi',
		origin => [ 0, ($panel_LEFT->height)*97/100],
                size => [$panel_LEFT-> width, ($panel_LEFT->height)*3/100],
                text => 'Select one or more groups to analyze / compare:',
	showPartial => 0,
 );

 $opzioni_gruppi->destroy if ($opzioni_gruppi);

 my $v = ''; 
 $opzioni_gruppi=$panel_LEFT->insert(CheckList=>,
          origin => [ 0, ($panel_LEFT->height)*89/100],  
          name => 'SampleGroup',
          size => [ $panel_LEFT-> width, ($panel_LEFT->height)*7/100],  
          text => 'GROUPS',
        backColor => 0xc6dfc6,  
          items => \@gruppi_unique,
	multiColumn => 1,
	vertical => 0,  
	multiSelect => 0,
	vector   => $v,
	extendedSelect => 0,
        drawGrid =>0, 
        offset => 300, 
 );
 $opzioni_gruppi->set_all_buttons;  
 $analisi=$panel_LEFT->insert('Prima::GroupBox',
          origin => [ 0, ($panel_LEFT->height)*30/100], 
          name => 'SampleGroup',
          size => [ ($panel_LEFT-> width)/2, ($panel_LEFT->height)*56/100],  
          text => 'ANALYSIS TYPES',
 );
$radio1=$analisi->insert('Prima::Radio',
          origin => [20, ($analisi->height)*83/100],
          name => 'ANALYSIS_1',
          size => [ ($analisi->width)-22, 36], 
          text => 'Lipid profile overview',
          onClick => sub {$options_ERROR->destroy if $options_ERROR; &insert_options_ERROR; $label_classi->destroy if $label_classi; $options_CLASS->destroy if $options_CLASS; $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS); $options_CLASS_CHAINS_DISTR->destroy if ($options_CLASS_CHAINS_DISTR);},  
);
$radio7=$analisi->insert('Prima::Radio',
          origin => [20, ($analisi->height)*70/100], 
          name => 'ANALYSIS_7',
          size => [ ($analisi->width)-22, 36], 
          text => 'Chain Class Distribution',
          onClick => sub {$options_ERROR->destroy if $options_ERROR; &insert_options_ERROR; $label_classi->destroy if $label_classi; $options_CLASS->destroy if $options_CLASS; $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS); insert_options_CLASS(7,@names);},  
);
$radio2=$analisi->insert('Prima::Radio',
          origin => [20, ($analisi->height)*57/100],   
          name => 'ANALYSIS_2',
          size => [ ($analisi->width)-22, 36], 
          text => 'Chains Length',
          onClick => sub {$options_ERROR->destroy if $options_ERROR; &insert_options_ERROR; $label_classi->destroy if $label_classi; $radio3_options_A=();$radio4_options_A=(); $options_CLASS->destroy if $options_CLASS; $label_classi->destroy if ($label_classi); $options_CLASS->destroy if ($options_CLASS); $options_CLASS_CHAINS_DISTR->destroy if ($options_CLASS_CHAINS_DISTR); insert_options_CLASS(2,@classes);},  
);
$radio3=$analisi->insert('Prima::Radio',
          origin => [20, ($analisi->height)*44/100],  
          name => 'ANALYSIS_3',
          size => [ ($analisi->width)-22, 36], 
          text => 'Chains unsaturation',
          onClick => sub {$options_ERROR->destroy if $options_ERROR; &insert_options_ERROR; $label_classi->destroy if $label_classi; $radio2_options_A=();$radio4_options_A=(); $options_CLASS->destroy if $options_CLASS; $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS); $options_CLASS_CHAINS_DISTR->destroy if ($options_CLASS_CHAINS_DISTR); insert_options_CLASS(3,@classes);},  
);
$radio4=$analisi->insert('Prima::Radio',
          origin => [20, ($analisi->height)*31/100],  
          name => 'ANALYSIS_4',
          size => [ ($analisi->width)-22, 36], 
          text => 'Chains ox/red ratio',
          onClick => sub {$options_ERROR->destroy if $options_ERROR; &insert_options_ERROR; $label_classi->destroy if $label_classi; $radio2_options_A=();$radio3_options_A=(); $options_CLASS->destroy if $options_CLASS; $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS); $options_CLASS_CHAINS_DISTR->destroy if ($options_CLASS_CHAINS_DISTR); insert_options_CLASS(4,@OX); },  
);
$radio5=$analisi->insert('Prima::Radio',
          origin => [20, ($analisi->height)*18/100],  
          size => [ ($analisi->width)-22, 36], 
          text => 'Chains Ether/Ester linked ratio',
          onClick => sub {$options_ERROR->destroy if $options_ERROR; &insert_options_ERROR; $label_classi->destroy if $label_classi; $options_CLASS->destroy if $options_CLASS; $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS); $options_CLASS_CHAINS_DISTR->destroy if ($options_CLASS_CHAINS_DISTR);},  
);
$radio6=$analisi->insert('Prima::Radio',
          origin => [20, ($analisi->height)*5/100],  
          name => 'ANALYSIS_6',
          size => [ ($analisi->width)-22, 36], 
          text => 'Chains odd/even ratio',
          onClick => sub {$options_ERROR->destroy if $options_ERROR; &insert_options_ERROR; $label_classi->destroy if $label_classi; $options_CLASS->destroy if $options_CLASS; $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS); $options_CLASS_CHAINS_DISTR->destroy if ($options_CLASS_CHAINS_DISTR);},  
 );
 } 
} 



sub insert_options_ERROR ()
{
 $options_ERROR=$panel_LEFT->insert('Prima::GroupBox',
           origin => [ ($panel_LEFT-> width)/2+20, ($panel_LEFT->height)*58/100],   
           name => 'SampleGroup',
           size => [ ($panel_LEFT-> width)/2-20, ($panel_LEFT->height)*28/100], 
           text => 'DISPLAY OPTIONS',
 );
 $options_ERROR_1=$options_ERROR->insert('Prima::Radio',
           origin => [20, ($options_ERROR->height)*60/100],
           name => 'Standard_error',
           size => [ ($options_ERROR->width)-22, 36], 
           text => 'Standard error',
           checked => 1,
 );
 $options_ERROR_2=$options_ERROR->insert('Prima::Radio',
           origin => [20, ($options_ERROR->height)*35/100], 
           name => 'Standard_deviation',
           size => [ ($options_ERROR->width)-22, 36], 
           text => 'Standard deviation',
 );
 $options_ERROR_3=$options_ERROR->insert('Prima::Radio',
           origin => [20, ($options_ERROR->height)*10/100], 
           name => 'None',
           size => [ ($options_ERROR->width)-22, 36], 
           text => 'None',
 );
}


sub insert_options_CLASS ()
{
my $param=shift(@_); 
my @items=@_;  
if ($param == 4) 
  {
   $label_classi=$panel_LEFT->insert(Label => 
		siblings => [qw(focusLink)],
		name => 'Label_classi',
		origin => [ 0, ($panel_LEFT->height)*25/100], 
                size => [$panel_LEFT-> width, ($panel_LEFT->height)*3/100],
                text => 'Select ONLY ONE lipid class for the analysis:',
               showPartial => 0,
  );
  $v = ''; 
  $options_CLASS=$panel_LEFT->insert(CheckList=>,
            origin => [ 0, ($panel_LEFT->height)*8/100],  
            name => 'SampleGroup',
            size => [ $panel_LEFT-> width, ($panel_LEFT->height)*16/100], 
            text => 'OPTIONS for Chains Length',
            backColor => 0xc6dfc6,  
            items => \@items,
  	    multiColumn => 1,
     	    vertical => 0,  
  	    multiSelect => 1,
  	    vector   => $v,
  	    extendedSelect => 0,
            drawGrid =>0,  
            onChange => sub { 
                             $numcliccati=0;
                 	     for ( 0 .. $options_CLASS-> count - 1) 
                                {$numcliccati++ if $options_CLASS-> button($_); }
                             if ($numcliccati==1)
                                {
                   	        for ( 0 .. $options_CLASS-> count - 1) 
                                   {$first_clicked=$_ if $options_CLASS-> button($_); }
                                $clicked_text=$options_CLASS->get_item_text($first_clicked);
                                }
                             elsif ($numcliccati > 1)
                                {
                                $options_CLASS->button($first_clicked,0);
                                }
                     },
  );

 } 
 elsif ($param == 2)   
  {
   $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS);
   $options_CLASS_CHAINS=$panel_LEFT->insert('Prima::GroupBox',
           origin => [ ($panel_LEFT-> width)/2+20, ($panel_LEFT->height)*30/100],   
           name => 'SampleGroup',
           size => [ ($panel_LEFT-> width)/2-20, ($panel_LEFT->height)*28/100], 
           text => 'Class and carbon number:',
   );
   $options_CLASS_CHAINS_1=$options_CLASS_CHAINS->insert('Prima::Radio',
           origin => [20, ($options_CLASS_CHAINS->height)*65/100],
           size => [ ($options_CLASS_CHAINS->width)-22, 36], 
           text => 'All classes',
           checked => 1,
           onClick => sub {
                   $options_CLASS->destroy if ($options_CLASS);
                   $options_CLASS_CHAINS_3->destroy if $options_CLASS_CHAINS_3;
                   @names_copy=@names;
                   @names_pulito=();
                   foreach my $name (@names_copy) 
                       {
                        $name=~ s/[OP]-//ig; 
                        my @splitted= split (':', $name);
                        push (@names_pulito, $splitted[0]);
                        }
                   @catene_menu = do { my %seen; grep { !$seen{$_}++ } @names_pulito};  
                   @catene_menu = sort {$a<=>$b}  @catene_menu; 
                   $options_CLASS_CHAINS_3=$options_CLASS_CHAINS->insert('Prima::ComboBox',
                           style => cs::DropDown,
                           origin => [ ($options_CLASS_CHAINS-> width)*1/6, ($options_CLASS_CHAINS->height)*10/100],
                           size => [ ($options_CLASS_CHAINS-> width)*4/6, ($options_CLASS_CHAINS->height)*20/100], 
                           text => 'All/select chain lenght:',
                           items => [ @catene_menu ],
                           literal    => 1,
                   );

                },  
   );
   $options_CLASS_CHAINS_2=$options_CLASS_CHAINS->insert('Prima::Radio',
           origin => [20, ($options_CLASS_CHAINS->height)*40/100], 
           size => [ ($options_CLASS_CHAINS->width)-22, 36], 
           text => 'Only 1 class (below)',
           onClick => sub {
                 $v = ''; 
                 $options_CLASS=$panel_LEFT->insert(CheckList=>,
                        origin => [ 0, ($panel_LEFT->height)*11/100],  
                        name => 'SampleGroup',
                        size => [ $panel_LEFT-> width, ($panel_LEFT->height)*16/100],  
                        text => 'OPTIONS for Chains Length',
                        backColor => 0xc6dfc6, 
                        items => \@items,
                        multiColumn => 1,
               	        vertical => 0, 
  	                multiSelect => 1,
  	                vector   => $v,
   	                extendedSelect => 0,
                        drawGrid =>0,  
                        onChange => sub { 
                             $numcliccati=0;
                 	     for ( 0 .. $options_CLASS-> count - 1) 
                                {$numcliccati++ if $options_CLASS-> button($_); }
                             if ($numcliccati==1)
                                {
                   	        for ( 0 .. $options_CLASS-> count - 1) 
                                   {$first_clicked=$_ if $options_CLASS-> button($_); }
                                $clicked_text=$options_CLASS->get_item_text($first_clicked);
                                &populate_menu($clicked_text);
                                }
                             elsif ($numcliccati > 1)
                                {
                                $options_CLASS->button($first_clicked,0);
                                }
                         }, 
                 ); 
             },
   );
   $options_CLASS_CHAINS_3->destroy if $options_CLASS_CHAINS_3;
   @names_copy=@names;
   @names_pulito=();
   foreach my $name (@names_copy) 
       {
        $name=~ s/[OP]-//ig; 
        my @splitted= split (':', $name);
        push (@names_pulito, $splitted[0]);
        }
   @catene_menu = do { my %seen; grep { !$seen{$_}++ } @names_pulito};  
   @catene_menu = sort {$a<=>$b}  @catene_menu; 
   $options_CLASS_CHAINS_3=$options_CLASS_CHAINS->insert('Prima::ComboBox',
           style => cs::DropDown,
           origin => [ ($options_CLASS_CHAINS-> width)*1/8, ($options_CLASS_CHAINS->height)*10/100],
           size => [ ($options_CLASS_CHAINS-> width)*6/8, ($options_CLASS_CHAINS->height)*20/100], 
           text => 'All/select chain lenght:',
           items => [ @catene_menu ],
           literal    => 1,
   );

  } 
 elsif ($param == 3)    
  {
   $options_CLASS_CHAINS->destroy if ($options_CLASS_CHAINS);
   $options_CLASS_CHAINS=$panel_LEFT->insert('Prima::GroupBox',
           origin => [ ($panel_LEFT-> width)/2+20, ($panel_LEFT->height)*30/100],   
           name => 'SampleGroup',
           size => [ ($panel_LEFT-> width)/2-20, ($panel_LEFT->height)*28/100], 
           text => 'Classes:',
   );
   $options_CLASS_CHAINS_1=$options_CLASS_CHAINS->insert('Prima::Radio',
           origin => [20, ($options_CLASS_CHAINS->height)*65/100],
           size => [ ($options_CLASS_CHAINS->width)-22, 36], 
           text => 'All classes',
           checked => 1,
           onClick => sub {$options_CLASS->destroy if ($options_CLASS); },  
   );
   $options_CLASS_CHAINS_2=$options_CLASS_CHAINS->insert('Prima::Radio',
           origin => [20, ($options_CLASS_CHAINS->height)*40/100], 
           size => [ ($options_CLASS_CHAINS->width)-22, 36], 
           text => 'Only 1 class (below)',
           onClick => sub {
                 $v = ''; 
                 $options_CLASS=$panel_LEFT->insert(CheckList=>,
                        origin => [ 0, ($panel_LEFT->height)*11/100],  
                        size => [ $panel_LEFT-> width, ($panel_LEFT->height)*16/100], 
                        text => 'OPTIONS for Chains Length',
                        backColor => 0xc6dfc6,  
                        items => \@items,
                        multiColumn => 1,
               	        vertical => 0,  
  	                multiSelect => 1,
  	                vector   => $v,
   	                extendedSelect => 0,
                        drawGrid =>0,  
                        onChange => sub { 
                             $numcliccati=0;
                 	     for ( 0 .. $options_CLASS-> count - 1) 
                                {$numcliccati++ if $options_CLASS-> button($_); }
                             if ($numcliccati==1)
                                {
                   	        for ( 0 .. $options_CLASS-> count - 1) 
                                   {$first_clicked=$_ if $options_CLASS-> button($_); }
                                $clicked_text=$options_CLASS->get_item_text($first_clicked);
                                }
                             elsif ($numcliccati > 1)
                                {
                                $options_CLASS->button($first_clicked,0);
                                }
                         }, 
                 ); 
             },
   );
  } 
 elsif ($param == 7)    
  {
   $options_CLASS_CHAINS_DISTR->destroy if ($options_CLASS_CHAINS_DISTR);
   $options_CLASS_CHAINS_DISTR=$panel_LEFT->insert('Prima::GroupBox',
           origin => [ ($panel_LEFT-> width)/2+20, ($panel_LEFT->height)*40/100],   
           size => [ ($panel_LEFT-> width)/2-20, ($panel_LEFT->height)*18/100], 
           text => 'Chain type:',
   );
   $options_CLASS_CHAINS_7=$options_CLASS_CHAINS_DISTR->insert('Prima::ComboBox',
                  style => cs::DropDown,
                  origin => [ ($options_CLASS_CHAINS_DISTR-> width)*1/8, ($options_CLASS_CHAINS_DISTR->height)*30/100],
                  size => [ ($options_CLASS_CHAINS_DISTR-> width)*6/8, ($options_CLASS_CHAINS_DISTR->height)*20/100], 
                  text => 'Select chain type:',
                  items => [ @names ],
                  literal    => 1,
             );
  } 
} 


sub populate_menu ()
{
  $dacercare=$_[0];
  @first_column_filtered=();
  foreach (@first_column) 
       { 									
        if ($_=~ /^$dacercare\s/)  {push (@first_column_filtered, $_);}	
       }
  @catene_menu=();
  @names_copy=@names;
  @names_pulito=();
  foreach my $name (@names_copy) 
       {
        $name=~ s/[OP]-//ig;
        my @splitted= split (':', $name);
        push (@names_pulito, $splitted[0]);
        }
  @names_pulito = do { my %seen; grep { !$seen{$_}++ } @names_pulito };  
  foreach my $name (@names_pulito) 
      { 	
       foreach (@first_column_filtered) 						 
           {	
            @first_column_positive = grep /[-_\s]$name:/, @first_column_filtered;
            if (@first_column_positive) 
               {push (@catene_menu, $name);}
        }
      }
  @catene_menu = do { my %seen; grep { !$seen{$_}++ } @catene_menu};  
  @catene_menu = sort {$a<=>$b}  @catene_menu; 
  $options_CLASS_CHAINS_3->destroy if $options_CLASS_CHAINS_3;
  $options_CLASS_CHAINS_3=$options_CLASS_CHAINS->insert('Prima::ComboBox',
           style => cs::DropDown,
           origin => [ ($options_CLASS_CHAINS-> width)*1/6, ($options_CLASS_CHAINS->height)*10/100],
           size => [ ($options_CLASS_CHAINS-> width)*4/6, ($options_CLASS_CHAINS->height)*20/100], 
           text => 'All/select chain lenght:',
           items => [ @catene_menu ],
           literal    => 1,
   );
}


sub crea_tabelle_madri ()
{
  print "PRE-PROCESSING...\n";
  my @table=@_;
  $p=0;
  $spinner = $panel_LEFT->insert('Spinner',
         	style => 'circle',
                color => cl::Blue,
                hiliteColor => cl::White,
                pack => { side => 'left', fill => 'both', expand => 1 },
                active => 1,
                value=>0,
                backColor => 0xc6dfc6,  
                );
  if (@table) { 
        $dasommare=();
	foreach $element0 (sort keys %samples) { 
		print "----------------------------$element0-----------------------------\n";
                $p++;
                @numero_el=keys %samples;
                $perc=$p/scalar(@numero_el)*100;
                print "$perc\n";
                $spinner->value($perc);
                $panel_LEFT-> update_view();  
                if (($perc == 100)) {$spinner->destroy;}
		for ($k=0; $k<=$c; $k++)
		      {
		      if (defined $table[0][$k]) { if ($table[0][$k] eq $element0) {$col=$k;}}
		      }
		 foreach my $element1 (sort @classes) {
		     foreach my $element2 (sort @names) {
		         for ($i=2; $i<=$r; $i++) {
                                   if (defined $table[$i][0]) {
			           if ($table[$i][0] =~ /^$element1\s/) { 
  			                     my @matches = grep (/[\s_]\Q$element2\E[_]/ || /[\s_]\Q$element2\E$/ig, $table[$i][0]); 
				             my @count =();
				             if (@matches) {  
					           if (($element1 eq 'CL') || ($element1 eq 'TG')|| ($element1 eq 'Ac4PIM2')|| ($element1 eq 'MLCL')|| ($element1 eq 'HBMP')|| ($element1 eq 'ADGGA')|| ($element1 eq 'Ac3PIM2') || ($element1 eq 'AHexCer')) {  
					                   @count_1 = $matches[0] =~ /[\s_]*\Q$element2\E[_]/ig; 
					                }  
					                else {
					                     @count_1 = $matches[0] =~ /[\s_]{1,}+\Q$element2\E[_]/ig;  
					                     } 
				                   my @count_2 = $matches[0] =~ /[\s_]\Q$element2\E$/ig;   
				                   my @count=(@count_1, @count_2);                      
			  	                   $times=scalar(@count); 
				                   $dasommare=$table[$i][$col]/$chains_for_classes{$element1}*$times;
				                   $tabella_madre{$element0}{$element1}{$element2} += $dasommare; 
				               }
			            }
                                  }
	  	          }
	            } 
                }
             }
  } 
} 



sub CLASSES()
{
 @elenco_classi=();
 if ($options_CLASS) {
     if ($options_CLASS-> count) 
           {
	     for ( 0 .. $options_CLASS-> count - 1) 
                 {
		 push @elenco_classi, $options_CLASS-> get_item_text($_) if $options_CLASS-> button($_);
		 }
           }
 }
 if (@elenco_classi) {  
    if (scalar(@elenco_classi) != 1) 
       { Prima::MsgBox::message_box( 'LipidOne', "ALERT: Select only ONE class..", mb::Ok); }
   }
  else { Prima::MsgBox::message_box( 'LipidOne', "ALERT: Select a class...", mb::Ok); } 
}


sub collect_options()     
{
	my @elenco_gruppi=$_[0];
	if ($radio1->checked){
		$titolo_analisi=$radio1->text;
		$titolo_classe='';
		&crea_file_gnuplot(1,@elenco_gruppi); 
	}
	if ($radio2->checked) {
		$selected_lenght=$options_CLASS_CHAINS_3->text;  
		$titolo_analisi=$radio2->text;
		if ($options_CLASS_CHAINS_1->checked){
			$options_CLASS->destroy if ($options_CLASS); 
			$options_CLASS=() if ($options_CLASS);   
			$titolo_classe='';
			&crea_file_gnuplot(2,@elenco_gruppi);
		}
		if ($options_CLASS_CHAINS_2->checked) {
			&CLASSES(); 
			if (scalar(@elenco_classi) == 1)   
			{
				$titolo_classe=$elenco_classi[0];
				&crea_file_gnuplot(2,@elenco_gruppi);
			}
		}
	} 
	if ($radio3->checked) {
		 $titolo_analisi=$radio3->text;
		 if ($options_CLASS_CHAINS_1->checked)      
			{
			$options_CLASS->destroy if ($options_CLASS); 
			$options_CLASS=() if ($options_CLASS);   
			$titolo_classe='';
			&crea_file_gnuplot(3,@elenco_gruppi);
			}
		if ($options_CLASS_CHAINS_2->checked) {
			 &CLASSES(); 
			 if (scalar(@elenco_classi) == 1)   
			   {
			   $titolo_classe=$elenco_classi[0];
			   &crea_file_gnuplot(3,@elenco_gruppi);
			   }
		}
	} 
	 if ($radio4->checked) {
		 &CLASSES(); 
		 $titolo_analisi=$radio4->text;
		 $titolo_classe=$elenco_classi[0];
		 &crea_file_gnuplot(4,@elenco_gruppi) if (scalar(@elenco_classi) == 1);
	}
	 if ($radio5->checked) {
		 $titolo_analisi=$radio5->text;
		 $titolo_classe='';
		 &crea_file_gnuplot(5,@elenco_gruppi);
	   }
	 if ($radio6->checked) {
		 $titolo_analisi=$radio6->text;
		 $titolo_classe='';
		 &crea_file_gnuplot(6,@elenco_gruppi);
	  }

	 if ($radio7->checked) {
		 $titolo_analisi=$radio7->text;
		 $titolo_classe='';
		 $selected_chain_type=$options_CLASS_CHAINS_7->text; 
		 if ($selected_chain_type eq 'Select chain type:') {Prima::MsgBox::message_box( 'LipidOne', "Please select a chain type" , mb::Ok);}
		 else {    
			$titolo_classe=$selected_chain_type;
			&crea_file_gnuplot(7,@elenco_gruppi);
		 }
	  }
} 


sub crea_file_gnuplot ()
{
 my $parametro=$_[0]; 
 my @elenco_gruppi = $_[1];
 print "\ncrea file gnuplot chiamato con parametro: ".$parametro;
 @catene_in_classe=();
 @asseXgraph2=();
 @asseXgraph2_pulito=();
 @asseXgraph2_filtered=();
 $done=0;
 $spinner->destroy if ($spinner);
 $grid->destroy if ($grid);
 $image->destroy if ($image);
 $spinner = $panel_RIGHT->insert('Spinner',
         	style => 'circle',
                color => cl::Blue,
                hiliteColor => cl::White,
                pack => { side => 'left', fill => 'both', expand => 1 },
                active => 1,
                value=>0,
                backColor => 0xc6dfc6,  
               );
 if (($parametro==2) || ($parametro==3)) 
    {
    $dacercare=$elenco_classi[0]; 
    @names_copy=@names;
    foreach my $name (@names_copy) 
         {
         if ($parametro==2)
            {
             $name=~ s/[OP]-//ig; 
             my @splitted= split (':', $name);
             push (@names_pulito, $splitted[0]);
            }
         if ($parametro==3)
            {
             my @splitted= split (';', $name);         
             my @splitted2= split (':', $splitted[0]); 
             push (@names_pulito, $splitted2[1]);      
            }
       } 
     @catene = do { my %seen; grep { !$seen{$_}++ } @names_pulito};  
     @first_column_filtered=();
     @catene_in_classe= ();
    if (($parametro==2)||($parametro==3)) 
      {
       if ($options_CLASS_CHAINS_2->checked) 
          { 
            foreach (@first_column) 
               { 									
               if ($_=~ /^$dacercare\s/)  {push (@first_column_filtered, $_);}	
               }
          }
          elsif ($options_CLASS_CHAINS_1->checked) {
             @elenco_classi=();
             foreach (@first_column) 
               { 									
               push (@first_column_filtered, $_);	 
               }
             @elenco_classi=@classes;			 
         }
      } 
   @first_column_filtered = do { my %seen; grep { !$seen{$_}++ } @first_column_filtered};  
   foreach my $catena (@catene) 
        { 		
        foreach my $element (@first_column_filtered) 						 
           { 
            @first_column_positive=();
            if ($parametro==2) {                                                                                  
                   if ($element=~/$catena/) {
                             if ($element=~/[-_\s]$catena:/) {push (@first_column_positive, $element);}					
                   }
             }         
           if ($parametro==3) {@first_column_positive = grep /:$catena[;_]|:$catena$/, @first_column_filtered;}  
           if (@first_column_positive) 
              {push (@catene_in_classe, $catena);}
           if ((@first_column_positive)  && ($parametro==2))
              {push (@asseXgraph2, @first_column_positive);}
        } 
        $done++;
        $perc1=$done/(scalar(@catene))*50;  
        $spinner->value($perc1);
        $panel_RIGHT-> update_view();  
   } 
   @catene_in_classe = do { my %seen; grep { !$seen{$_}++ } @catene_in_classe };  
   @catene_in_classe= sort {$a<=>$b} @catene_in_classe; 
   if ($parametro==2) 
        { 
        @asseXgraph2 = do { my %seen; grep { !$seen{$_}++ } @asseXgraph2 }; 
        @asseXgraph2= sort {$a<=>$b} @asseXgraph2; 
        foreach my $element (@asseXgraph2) 
         {
         $element=~ s/\s+$//; 
         @splitted = split(/[_]/, $element );
         if ($splitted[0]=~ /^[A-Za-z]/) {
             $splitted[0]=~ s/[A-Za-z]*\s//g; 
            } 
         push (@asseXgraph2_pulito, @splitted);
        }
        @asseXgraph2_pulito = do { my %seen; grep { !$seen{$_}++ } @asseXgraph2_pulito };
        @asseXgraph2_pulito= sort @asseXgraph2_pulito;
        foreach my $element (@asseXgraph2_pulito)
           {
            if (($element=~/^$selected_lenght:/) || ($element=~/^O-$selected_lenght:/) || ($element=~/^P-$selected_lenght:/))
             {push (@asseXgraph2_filtered, $element);}
           }     
      }
  }

  $filegnuplot = $dir.'/data.dat';  
  open(FILEOUT, '>', $filegnuplot) or die $!;
  if ($parametro==1) {print FILEOUT "Classes"; @dausare=@classes; }	
  if ($parametro==2) {print FILEOUT "Chain length"; @dausare=@catene_in_classe;}   
  if ($parametro==3) {print FILEOUT "Unsaturations"; @dausare=@catene_in_classe;}
  if ($parametro==4) {print FILEOUT "Ox/Red ratio"; @dausare=@classes;}
  if ($parametro==5) {print FILEOUT "Alkyl/Acyl ratio"; @dausare=@classes;}
  if ($parametro==6) {print FILEOUT "Odd/Even ratio"; @dausare=@classes;}
  if ($parametro==7) {print FILEOUT "Chain Class Distribution"; @dausare=@classes;}
  foreach my $gruppo (sort @elenco_gruppi) {
      print FILEOUT ",$gruppo";
      if ($options_ERROR) {if ($options_ERROR->Standard_error->checked) { print FILEOUT ",Standard_Error";  }}
      if ($options_ERROR) {if ($options_ERROR->Standard_deviation->checked) { print FILEOUT ",Standard_Deviation"; }}
      if ($options_ERROR) {if ($options_ERROR->None->checked) {print FILEOUT ",ERR";  }} 
      }
  print FILEOUT ",P-value\n";  
  $done=0;
  foreach my $element (sort {$a<=>$b} @dausare) { 
        $somma=$somma2=$somma_ox=$somma_red=$somma_alkyl=$somma_acyl=$somma_odd=$somma_even=0;
        @damediare=@damediare2=();
        my $aov = Statistics::ANOVA->new();
        my $flag_anova=0;
        my $flag_allequal=0;
        $done++;
        if (($parametro==2)|| ($parametro==3)) {$perc2=$perc1+$done/(scalar(@dausare))*50;} 
          else {$perc2=$done/(scalar(@dausare))*100;}
        $spinner->value($perc2);
        $panel_RIGHT-> update_view();  
        if (($perc2 == 100)) {$spinner->destroy;}
        print FILEOUT "$element";
        foreach my $gruppo (sort @elenco_gruppi) {  
              $somma=$somma2=$somma_ox=$somma_red=$somma_alkyl=$somma_acyl=$somma_odd=$somma_even=0;
    	      @damediare=@damediare2=();
       	      foreach my $sample (sort keys %samples) {
                      $somma=$somma2=$somma_ox=$somma_red=$somma_alkyl=$somma_acyl=$somma_odd=$somma_even=0;
            	      if ($samples{$sample} eq $gruppo) {  
                         if ($parametro==1) {
     	                       foreach my $name (@names) { 
                                      $somma=$somma+$tabella_madre{$sample}{$element}{$name};   
                                }
                                push (@damediare, $somma);  
                         } 
                         if ($parametro==4) { 
     	                       foreach my $name (@names) { 
                                      if (($name=~/\;$elenco_classi[0]$/) || ($name=~/\;$elenco_classi[0]\(/) || ($name=~/\($elenco_classi[0]\)/) ) {  
                                         $somma_ox=$somma_ox+$tabella_madre{$sample}{$element}{$name};   
                                      }
                                      else
                                         {
                                          $somma_red=$somma_red+$tabella_madre{$sample}{$element}{$name};   
                                         }
                                }
				if ($somma_red) {$rapporto_ox_red=$somma_ox/$somma_red;} else {$rapporto_ox_red=0;} 
                                push (@damediare, $rapporto_ox_red);  
                         } 
                         if ($parametro==5) {
     	                       foreach my $name (@names) { 
                                      if (($name=~/O-/) || ($name=~/P-/)) {
                                         $somma_alkyl=$somma_alkyl+$tabella_madre{$sample}{$element}{$name};   
                                      }
                                      else
                                         {
                                          $somma_acyl=$somma_acyl+$tabella_madre{$sample}{$element}{$name};   
                                         }
                                }
				if ($somma_acyl) {$rapporto_alkyl_acyl=$somma_alkyl/$somma_acyl;} else {$rapporto_alkyl_acyl=0;} 
                                push (@damediare, $rapporto_alkyl_acyl);  
                         } 
                         if ($parametro==6) {
                               @names_copy=@names;
                               foreach my $name (@names_copy) {
                                   $name=~ s/[OP]-//ig; 
                                   my @lungh= split (':', $name);
                                   push @lunghezze_odd_even, $lungh[0];
                                  }
                               @lunghezze_odd_even = do { my %seen; grep { !$seen{$_}++ } @lunghezze_odd_even };
     	                       foreach my $lunghezza (@lunghezze_odd_even) { 
       	                         foreach my $name (@names) { 
                                       if (($lunghezza % 2 == O) && (($name =~ /-$lunghezza:/) || ($name =~ /^$lunghezza:/))) {              
                                           $somma_even=$somma_even+$tabella_madre{$sample}{$element}{$name};   
                                        }
                                        elsif (($lunghezza % 2 != O) && (($name =~ /-$lunghezza:/) || ($name =~ /^$lunghezza:/)))
                                           {
                                           $somma_odd=$somma_odd+$tabella_madre{$sample}{$element}{$name};  
                                           }
                                  }
                               }
			       if ($somma_even) {$rapporto_odd_even=$somma_odd/$somma_even;} else {$rapporto_odd_even=0;} 
                               push (@damediare, $rapporto_odd_even);  
                         } 
                         if  (($parametro==2) || ($parametro==3)) {
   	                    foreach my $name (@names) { 
                                 if ($parametro==2) {
                                      foreach my $class (@elenco_classi) {       
                                        if ((($name=~ /^$element:/) || ($name=~ /^O-$element:/) || ($name=~ /^P-$element:/)) && ($tabella_madre{$sample}{$class}{$name} ne '')) {   
                                           $somma=$somma+$tabella_madre{$sample}{$class}{$name};    
                                         }
                                       } 
                                     }
                                  if ($parametro==3) {
                                        foreach my $class (@elenco_classi) {        
          	                        if ((($name=~ /:$element[;_]/) || ($name=~ /:$element$/)) && ($tabella_madre{$sample}{$class}{$name} ne '')) 
                                           { 
                                           $somma=$somma+$tabella_madre{$sample}{$class}{$name};   
                                           }
                                       } 
                                      }
         	               } 
                               push (@damediare, $somma);  
                         } 
                         if ($parametro==7) {
     	                      foreach my $name (@names) { 
                                    if ($selected_chain_type eq $name) {    
                                        $somma=$somma+$tabella_madre{$sample}{$element}{$name};   
                                    }
                              }
                              push (@damediare, $somma);  
                         } 
         	     } 
	 	} 
     my $stat = Statistics::Descriptive::Full->new();
     $stat->add_data(@damediare);
     my $mean = $stat->mean();
     my $SD = $stat->standard_deviation();
     my $err_sdt = $SD/sqrt(scalar(@damediare));
     if ($options_ERROR) {if ($options_ERROR->Standard_error->checked) { print FILEOUT ",$mean,$err_sdt";  }}
     if ($options_ERROR) {if ($options_ERROR->Standard_deviation->checked) { print FILEOUT ",$mean,$SD"; }}
     if ($options_ERROR) {if ($options_ERROR->None->checked) {print FILEOUT ",$mean,0";  }} 
     if (@damediare == grep { $_ == 0 } @damediare) { $flag_anova++; }
    if (($damediare[0] != 0) && (@damediare == grep { $_ == $damediare[0] } @damediare)) { $flag_allequal++; }
     $aov->add($gruppo, \@damediare);  
     } 
    if ($options_ERROR) 
         {
         if ((scalar(@elenco_gruppi) == 2)  && ($flag_anova!=2) && ($flag_allequal==0)) 
             {
             my $res = $aov->anova(independent => 1, parametric => 1, ordinal => 0);
             my $pval=$res->{'_stat'}->{'p_value'};
             $pval=$pval/2; 
             print FILEOUT ",$pval";
            }
         elsif ((scalar(@elenco_gruppi) > 2)  && ($flag_anova!=scalar(@elenco_gruppi)) && ($flag_allequal==0)) 
             {
             my $res = $aov->anova(independent => 1, parametric => 1, ordinal => 0);
             my $pval=$res->{'_stat'}->{'p_value'};
             print FILEOUT ",$pval";
            }
        else  {print FILEOUT ",N/A";}
        }
    print FILEOUT "\n";
  } 

  if ($parametro==2) {
  foreach my $element (@asseXgraph2_filtered) {  
        $somma2=0;
        @damediare2=();
        my $aov = Statistics::ANOVA->new();
        my $flag_anova=0;
        my $flag_allequal=0;
        print FILEOUT "$element";
        foreach my $gruppo (sort @elenco_gruppi) { 
              $somma2=0;
    	      @damediare2=();
       	      foreach my $sample (sort keys %samples) {
                      $somma2=0;
            	      if ($samples{$sample} eq $gruppo) {  
                                   foreach my $class (@elenco_classi) {       
                                   	      foreach my $name (@names) { 
                                                     if (($name=~ /^\Q$element\E/) && ($tabella_madre{$sample}{$class}{$name} ne '')) {  
                                                     $somma2=$somma2+$tabella_madre{$sample}{$class}{$name};  
                                                    }
                                             }
                                    } 
                          push (@damediare2, $somma2);  
                     }
             }
   my $stat = Statistics::Descriptive::Full->new();
   $stat->add_data(@damediare2);
   my $mean = $stat->mean();
   my $SD = $stat->standard_deviation();
   my $err_sdt = $SD/sqrt(scalar(@damediare2));
   if ($options_ERROR) {if ($options_ERROR->Standard_error->checked) { print FILEOUT ",$mean,$err_sdt";  }}
   if ($options_ERROR) {if ($options_ERROR->Standard_deviation->checked) { print FILEOUT ",$mean,$SD"; }}
   if ($options_ERROR) {if ($options_ERROR->None->checked) {print FILEOUT ",$mean,0";  }} 
   if (@damediare2 == grep { $_ == 0 } @damediare2)  {$flag_anova++; }
    if (($damediare2[0] != 0) && (@damediare2 == grep { $_ == $damediare2[0] } @damediare2))    { $flag_allequal++;  }
    $aov->add($gruppo, \@damediare2);  
    } 
    if ($options_ERROR) 
         {
         if ((scalar(@elenco_gruppi) == 2)  && ($flag_anova!=2) && ($flag_allequal==0))
             {
             my $res = $aov->anova(independent => 1, parametric => 1, ordinal => 0);
             my $pval=$res->{'_stat'}->{'p_value'};
             $pval=$pval/2; 
             print FILEOUT ",$pval";
            }
         elsif ((scalar(@elenco_gruppi) > 2)  && ($flag_anova!=scalar(@elenco_gruppi)) && ($flag_allequal==0)) 
             {
             my $res = $aov->anova(independent => 1, parametric => 1, ordinal => 0);
             my $pval=$res->{'_stat'}->{'p_value'};
             print FILEOUT ",$pval";
            }
        else  {print FILEOUT ",N/A";}
        }
    print FILEOUT "\n";

  } 
 }
  close (FILEOUT);
  if ($options_ERROR) {if ($options_ERROR->Standard_error->checked) { &crea_image(1,$titolo_analisi,$titolo_classe,@elenco_gruppi);  }}
  if ($options_ERROR) {if ($options_ERROR->Standard_deviation->checked) { &crea_image(1,$titolo_analisi,$titolo_classe,@elenco_gruppi); }}
  if ($options_ERROR) {if ($options_ERROR->None->checked) {&crea_image(0,$titolo_analisi,$titolo_classe,@elenco_gruppi);  }}
}


sub crea_image()
{
  my $param=$_[0];  
  my $title_analysis=$_[1];
  my $title_class=$_[2];
  my @elenco_gruppi=$_[3];
  print "\ncrea_image chiamato con i parametri:";
  print "\nparametro0: ".$param;
  print "\nparametro1: ".$title_analysis;
  print "\nparametro2: ".$title_class;
  my @comandi;
  my $chart = Chart::Gnuplot->new();
  $comandi[0]='set terminal png size '.($panel_RIGHT-> width).','.(($panel_RIGHT-> height)*91/100); 
  $comandi[1]='set output \''. $dir. '/graph.png\'';
  if ($parametro == 2) {
     $comandi[2]='set multiplot layout 2,1 rowsfirst';
     }
  $comandi[3]='set style data histogram';
  if ($param == 1)  
      {$comandi[4]='set style histogram cluster gap 1 errorbars'; }
    elsif ($param == 0)  
      {$comandi[4]='set style histogram cluster gap 1'; }
  $comandi[5]='set style fill solid border rgb "black"';
  $comandi[6]='set auto x';
  $comandi[7]='set datafile separator ","';
  if ($parametro=~/[14567]/) 
    {
     $comandi[8]='set xtics rotate by 45 right';  
    } 
   $comandi[9]='set key noenhanced';  
   $chart->command(\@comandi);
   if ($parametro != 2) {  
      if ($title_class ne '') {$titolo="$title_analysis - class: $title_class";}
        else {$titolo=$title_analysis;}
       $comandotitolo='set title "'.$titolo.'"';
       $chart->command($comandotitolo); 
       open(FILEGNUPLOT, '<', $filegnuplot ) or die $!; 
       $row=<FILEGNUPLOT>; 
       $i=0;
       my @comandi_asterisk;
       my @altezze_max;
       while ($row=<FILEGNUPLOT>)
        {
          chomp($row);
          @yerr=@y=();
          @elementi=split(',', $row);
          @elementi_interni=@elementi[1..$#elementi-1]; 
          for(my $j=0;$j<=$#elementi_interni;$j++)     
             {
             if ($j%2 != 0) 
               {push (@yerr, $elementi_interni[$j]);}
               else { push (@y, $elementi_interni[$j]);}
             }
          @y=sort{$a<=>$b} @y;
          @yerr=sort{$a<=>$b} @yerr;
          my $max_y= $y[-1];
          my $max_yerr= $yerr[-1];
          my $altezza_max=($max_y + $max_yerr) + ($max_y + $max_yerr)*20/100; 
          push (@altezze_max, $altezza_max);
          if (($elementi[-1] < 0.05) and ($elementi[-1] ne "N/A"))  
              { 
              my $altezza_asterisk= ($max_y + $max_yerr) + ($max_y + $max_yerr)*10/100;  
              if ($elementi[-1] < 0.001) { $comandi_asterisk[$i]= 'set label \'***\' at '.$i.', '.$altezza_asterisk.' center';}
                elsif ($elementi[-1] < 0.01)  {$comandi_asterisk[$i]= 'set label \'**\' at '.$i.', '.$altezza_asterisk.' center';}
                   else {$comandi_asterisk[$i]= 'set label \'*\' at '.$i.', '.$altezza_asterisk.' center';}
              }
         $i++;        
         } 
      @altezze_max=sort {$a <=> $b} @altezze_max;
      $comando_enlarge_y='set yrange [0:'.$altezze_max[-1].']';
      $chart->command($comando_enlarge_y);
      $chart->command(\@comandi_asterisk); 
      close(FILEGNUPLOT);
      if ($param == 1)  
         {
         $comandoplot='plot \''. $filegnuplot. '\' using 2:3:xtic(1) title col(2)';  
         for (my $k=2;$k<=scalar(@elenco_gruppi);$k++)
            {
            $comandoplot=$comandoplot.', \'\' using '.($k*2).':'.($k*2+1).' title col('.($k*2).')'; 
           }
         }
         elsif ($param == 0)  
           {
           $comandoplot='plot \''. $filegnuplot. '\' using 2:xtic(1) title col(2)';  
           for (my $k=2;$k<=scalar(@elenco_gruppi);$k++)
              {
              $comandoplot=$comandoplot.', \'\' using '.($k*2).' title col('.($k*2).')'; 
              }
           }
      $chart->command($comandoplot);
      $chart->execute;
  }

  if ($parametro == 2) {  
       open(FILEGNUPLOT, '<', $filegnuplot ) or die $!; 
       $row=<FILEGNUPLOT>; 
       my $i=$i2=0;
       my @comandi_asterisk;
       my @altezze_max;
       my @comandi_asterisk2;
       my @altezze_max2;
       while ($row=<FILEGNUPLOT>)
        {
         chomp($row);
         @yerr=@y=(); 
         @elementi=split(',', $row);
         @elementi_interni=@elementi[1..$#elementi-1]; 
         for(my $j=0;$j<=$#elementi_interni;$j++)     
             {
             if ($j%2 != 0) 
               {push (@yerr, $elementi_interni[$j]);}
               else { push (@y, $elementi_interni[$j]);}
             }
          @y=sort{$a<=>$b} @y;
          @yerr=sort{$a<=>$b} @yerr;
          my $max_y= $y[-1];
          my $max_yerr= $yerr[-1];
          my $altezza_max=($max_y + $max_yerr) + ($max_y + $max_yerr)*20/100;  

          if ($row=~/:/)   
                {
                push (@altezze_max2, $altezza_max); 
                  if (($elementi[-1] < 0.05) and ($elementi[-1] ne "N/A"))  
                     { 
                      $altezza_asterisk= ($max_y + $max_yerr) + ($max_y + $max_yerr)*10/100; 
                      if ($elementi[-1] < 0.001) { $comandi_asterisk2[$i2]= 'set label \'***\' at '.$i2.', '.$altezza_asterisk.' center';}
                         elsif ($elementi[-1] < 0.01)  {$comandi_asterisk2[$i2]= 'set label \'**\' at '.$i2.', '.$altezza_asterisk.' center';}
                            else {$comandi_asterisk2[$i2]= 'set label \'*\' at '.$i2.', '.$altezza_asterisk.' center';}
                      }
                 $i2++;        
               }  
          else  {
             push (@altezze_max, $altezza_max); 
             if (($elementi[-1] < 0.05) and ($elementi[-1] ne "N/A"))  
                 { 
                 $altezza_asterisk= ($max_y + $max_yerr) + ($max_y + $max_yerr)*10/100;  
                 if ($elementi[-1] < 0.001) { $comandi_asterisk[$i]= 'set label \'***\' at '.$i.', '.$altezza_asterisk.' center';}
                    elsif ($elementi[-1] < 0.01)  {$comandi_asterisk[$i]= 'set label \'**\' at '.$i.', '.$altezza_asterisk.' center';}
                      else {$comandi_asterisk[$i]= 'set label \'*\' at '.$i.', '.$altezza_asterisk.' center';}
                 }
              $i++;        
           } 
      }
      close(FILEGNUPLOT);
      @altezze_max=sort {$a <=> $b} @altezze_max;
      @altezze_max2=sort {$a <=> $b} @altezze_max2;
      $comando_enlarge_y='set yrange [0:'.$altezze_max[-1].']';
      $comando_enlarge_y2='set yrange [0:'.$altezze_max2[-1].']';
      $chart->command($comando_enlarge_y);
      $chart->command(\@comandi_asterisk); 
      if ($title_class ne '') {$titolo="$title_analysis - class: $title_class";}
           else {$titolo="$title_analysis - All classes";}
       $comandotitolo='set title "'.$titolo.'"';
       $chart->command($comandotitolo); 
      if ($param == 1)  
         {
         $comandoplot='plot \''. $filegnuplot. '\' every ::0::'.($i-1).' using 2:3:xtic(1) title col(2)';  
         for (my $k=2;$k<=scalar(@elenco_gruppi);$k++)
            {
            $comandoplot=$comandoplot.', \'\' every ::0::'.($i-1).' using '.($k*2).':'.($k*2+1).' title col('.($k*2).')'; 
           }
         }
         elsif ($param == 0)  
           {
           $comandoplot='plot \''. $filegnuplot. '\' every ::0::'.($i-1).' using 2:xtic(1) title col(2)';  
           for (my $k=2;$k<=scalar(@elenco_gruppi);$k++)
              {
              $comandoplot=$comandoplot.', \'\' every ::0::'.($i-1).' using '.($k*2).' title col('.($k*2).')'; 
              }
           }
      $chart->command($comandoplot);
      $chart->command($comando_enlarge_y2);
      $chart->command('unset label'); 
      $chart->command(\@comandi_asterisk2); 
      if ($title_class ne '') {$titolo="$title_analysis - class: $title_class - carbons: $selected_lenght";}
           else {$titolo="$title_analysis - All classes - carbons: $selected_lenght";}
       $comandotitolo='set title "'.$titolo.'"';
       $chart->command($comandotitolo);   
       $chart->command('set xtics rotate by 45 right');  
      if ($param == 1)  
         {
         $comandoplot='plot \''. $filegnuplot. '\' every ::'.$i.'::'.($i+$i2-1).' using 2:3:xtic(1) title col(2)'; 
         for (my $k=2;$k<=scalar(@elenco_gruppi);$k++)
            {
            $comandoplot=$comandoplot.', \'\' every ::'.$i.'::'.($i+$i2-1).' using '.($k*2).':'.($k*2+1).' title col('.($k*2).')'; 
           }
         }
         elsif ($param == 0)  
           {
           $comandoplot='plot \''. $filegnuplot. '\' every ::'.$i.'::'.($i+$i2-1).' using 2:xtic(1) title col(2)';  
           for (my $k=2;$k<=scalar(@elenco_gruppi);$k++)
              {
              $comandoplot=$comandoplot.', \'\' every ::'.$i.'::'.($i+$i2-1).' using '.($k*2).' title col('.($k*2).')'; 
              }
           }
      $chart->command($comandoplot);
      $chart->command('unset multiplot');
      $chart->execute;
 }
} 


sub load_image ()
{
 $grid->destroy if $grid;
 $label2->destroy if $label2;
 $download_image->destroy if ($download_image);
 $image=$panel_RIGHT->insert (Prima::ImageViewer,
        imageFile=> "$dir/graph.png",
        name=>'graph',
        autoZoom =>1,  
        origin => [ 0, ($panel_RIGHT-> height)*8/100],  
        size => [ $panel_RIGHT-> width, ($panel_RIGHT-> height)*91/100 ],
 );
    $download_image=$panel_RIGHT-> insert( Button =>
       text   => 'Download Graph',
       pack   => { side => 'bottom' , padx => 20 },
       onClick => sub{ 
  	       my $iv = $image;
	       my $dlg  = Prima::Dialog::ImageSaveDialog-> create( image => $iv-> image);
	       $iv-> {fileName} = $dlg-> fileName if $dlg-> save( $iv-> image);
               print "saved as ", $dlg-> fileName, "\n";
	       $dlg-> destroy;
       },
   );
}



sub export_table {
 my @table=@_;
 if (@table) 
  {
  @gruppi_export=values %samples;
  @gruppi_export = do { my %seen; grep { !$seen{$_}++ } @gruppi_export };
  my $fileout = $dir.'/output.txt';  
  open(FILEOUT, '>', $fileout) or die $!;
  print "Sample";
  print FILEOUT "Sample";
  foreach my $gruppo (sort @gruppi_export) {  
      foreach my $sample (sort keys %samples) {
          print "\t$sample" if ($samples{$sample} eq $gruppo);  
          print FILEOUT "\t$sample" if ($samples{$sample} eq $gruppo);  
        }
  }
  print "\n";
  print FILEOUT "\n";
  print "Label";
  print FILEOUT "Label";
  foreach my $gruppo (sort @gruppi_export) {  
      foreach my $sample (sort keys %samples) {
          print "\t$gruppo" if ($samples{$sample} eq $gruppo);  
          print FILEOUT "\t$gruppo" if ($samples{$sample} eq $gruppo);  
        }
  }
  print "\n";
  print FILEOUT "\n";
  foreach my $name (@names) { 
     print "$name";
     print FILEOUT "$name";
     foreach my $gruppo (sort @gruppi_export) { 
          foreach my $sample (sort keys %samples) {
               my $somma_newtab;
               if ($samples{$sample} eq $gruppo) {
                  foreach my $element (sort @classes) {  
                        $somma_newtab=$somma_newtab+$tabella_madre{$sample}{$element}{$name};   
                      }
             if ($somma_newtab!=0) {
               print "\t$somma_newtab";
               print FILEOUT "\t$somma_newtab";
              }
              else {
               print "\t";
               print FILEOUT "\t";
              }
           }
         }
      }
     print "\n";
     print FILEOUT "\n";
  }
  close (FILEOUT);
  }
 else 
 {
 Prima::MsgBox::message_box( 'LipidOne', "ERROR: please, upload a dataset." , mb::Ok);
 }
} 

sub onOpenFile(){
	if($open->execute){
		&open_file($open-> fileName);
	}
}

sub onSubmit()
{
	my @elenco_gruppi=();
	if (  $opzioni_gruppi-> count) {
		for ( 0 .. $opzioni_gruppi-> count - 1) {
			printf $opzioni_gruppi-> get_item_text($_);
			push @elenco_gruppi, $opzioni_gruppi-> get_item_text($_) if $opzioni_gruppi-> button($_);
		}
	}
	&collect_options(@elenco_gruppi); 
	&load_image;
}
Prima->run;
