#!/usr/bin/perl -w
# Copyright (c) 2000-2002 SuSE Linux AG, Nuernberg, Germany.
# All rights reserved.
#
# Author: Petr Mladek <pmladek@suse.cz>

use strict;

# the directory where to find java configuration files
my $configDir = '/etc/java';
# default suffix for java configuration files
my $configSuf = '.conf';
# in this direcory are installed all javas
my $libdir = '/usr/lib';

# link name to default java
my $defaultJava = 'java';

# name of this script
my $myName = 'setJava.pl';
# this name will be used in help when this script called by another script
my $encaps = "";

# dynamic arguments
my @argv = @ARGV;

# required function
my $reqFunc;

# values from configs in $configDir/*$configSuf
# it is list of references to hashes with config values
my @javas;

# required values
my %reqJava;

sub MainHelp
{
  print "Universal script to support java configuration on your computer\n\n";

  print "Usage: $myName --help\n";
  print "       $myName [--encaps script_name] function [function_options]\n\n";
  
  print "Command line options:\n";
  print "       --help   - print this help\n";
  print "       --encaps - define parent script path (see below for details)\n";
  print "       function - function selection\n";
  print "       function_options - additional function specific options\n\n";
  
  print "Functions:\n";
  print "       \"setenv\" - print bash commands to set a java for current shell\n";
  print "       \"link\"   - set link in \"$libdir/java\" which defining default java\n";
  print "                  for your computer\n";
  print "	        - set also another compatibility links in \"$libdir\"\n\n";

  print "You can get function specific help with command:\n";
  print "        $myName function --help\n\n";
  
  print "This script contain support to encapsulate selected function into shell\n";
  print "script. Function specific help will be fixed for new script name.\n\n";

  print "Examples:\n\n";
  
  print "       1. Get help for \"setenv\" function:\n";
  print "          $myName setenv --help\n\n";
  
  print "       2. Encapsulate link function into setDefaultJava script\n";
  print "          $myName --encaps setDefaultJava link \"\$@\"\n";
  

}

# this part is common for both functions
sub CommonHelp
{
  my $command = shift;
  
  print "Note: The option --version generally defines minimal required java version\n";
  print "      When the option --strict is used then the option --version defines\n";
  print "      pattern for required java version\n\n";
  
  print "Note: See files /etc/java/*.conf for information about available javas\n\n";
  
  print "Examples:\n\n";
  
  print "	1. Set any java with version 1.3 or higher:\n";
  print "	   $command --version 1.3\n\n";
  
  print " 	2. Set any java with version 1.3.x\n";
  print "	   $command --strict --version 1.3\n\n";

  print " 	3. Set any java with version 1.3.1\n";
  print "	   $command --strict --version 1.3.1\n\n";

  print " 	2. Set any java from Sun Microsystems\n";
  print "	   $command --vendor Sun\n\n";
  
  print "Appendix: Transformation table for java_name argument\n\n";
  
  print "	    java_name	     related options\n";
  print "	    ---------	     -------------------\n";
  print "	    SunJava1         --vendor Sun  --version 1.1 --strict\n";
  print "	    SunJava2         --vendor Sun  --version 1.3\n";
  print "	    IBMJava2         --vendor IBM  --version 1.3\n";
  print "	    Java2	     --version 1.3\n";
  print "	    default          none\n";
}

# help for setenv function
sub SetEnvHelp
{
  my $command;
  if ($encaps) {
    $command = $encaps;
  } else {
    $command = "$myName setenv";
  }
  
  unless ($encaps) {
    print "This function print bash commands to set java for current shell\n\n";
  }    
  print "It sets environment variables: PATH, JAVA_BINDIR, JAVA_ROOTDIR,\n";
  print "                               JAVA_HOME, JRE_HOME, JDK_HOME, SDK_HOME\n\n";

  print "Usage: $command --help\n";
  print "       $command [--devel][--strict][--vendor vendor][--version version]\n";
  print "       $command [--devel] java_name\n\n";

  print "Command line options:\n";
  print "	--help    - print this help\n";
  print "	--devel	  - defines that you request the development kit\n";
  print "	--strict  - defines that you request strict java version\n";
  print "	--vendor  - defines strict java vendor name\n";
  print "	--version - defines minimal or strict java version (see below)\n\n";
  
  print "	java_name - added for backward compatibility with old setJava script\n";
  print "                    valid java_name is transformed into equivalent --version\n";
  print "                    and --vendor options (see below)\n\n";

  CommonHelp($command);
}

# help for link function
sub LinkHelp
{
  my $command;
  if ($encaps) {
    $command = $encaps;
  } else {
    $command = "$myName setenv";
  }
  
  my $commandLen = length $command;
  
  unless ($encaps) {
    print "This script changes the link \"$libdir/java\" which defines default java\n";
    print "for your computer or it changes another compactibility links in\n";
    print "the directory \"$libdir\"\n\n";
  }    

  printf "Usage: %-" . $commandLen . "s --help\n", $command;
  printf "       %-" . $commandLen . "s [--noreplace][--devel][--strict][--linkname link_name\n", $command;
  printf "       %-" . $commandLen . "s [--vendor vendor][--version version]\n", "";
  printf "       %-" . $commandLen . "s [--noreplace][--devel] java_name\n\n", $command;

  print "Command line options:\n";
  print "	--help      - print this help\n";
  print "	--noreplace - do not change valid link\n";
  print "	--devel	    - defines that you request the development kit\n";
  print "	--strict    - defines that you request strict java version\n";
  print "	--linkname  - defines another java link name in /usr/lib\n";
  print "		      default value is \"java\"\n";
  print "	--vendor    - defines strict java vendor name\n";
  print "	--version   - defines minimal or strict java version (see below)\n\n";
  
  print "	java_name   - added due to compactibility with old setJava script\n";
  print "		      valid java_name is transformed into equivalent --version\n";
  print "		      and --vendor options (see below)\n\n";

  CommonHelp($command);
}

# process main (function independent) options
sub SelectFunction
{
  my $arg;

  unless ($arg = shift @argv) {
    MainHelp;
    exit 1;
  }
  if ($arg eq '--help') {
    MainHelp;
    exit 0;
  }
  if ($arg eq '--encaps') {
    unless ($encaps = shift @argv) {
      print STDERR "Error: A value for --encaps option is missing\n";
      exit 1;
    }  
    SelectFunction();
    return;
  }
  unless (($arg eq 'setenv') || ($arg eq 'link')) {
    print STDERR "Unknown function \"$arg\"\n";
    exit 1;
  }    
  $reqFunc = $arg
}

# process options for setenv function
sub ReadSetEnvArgs
{
  my $curArg;
  
  while ($curArg = shift @argv) {
    if ($curArg eq '--help') {
      SetEnvHelp;
      exit 0;
    }
    if ($curArg eq '--devel') {
      $reqJava{'Devel'} = 1;
      next;
    }  
    if ($curArg eq '--strict') {
      $reqJava{'Strict'} = 1;
      next;
    }  
    if ($curArg eq '--vendor') {
      unless ($reqJava{'Vendor'} = shift @argv) {
        print STDERR "Error: A value for vendor option is missing\n";
	exit 1;
      }
      next;
    }
    if ($curArg eq '--version') {
      unless ($reqJava{'Version'} = shift @argv) {
        print STDERR "Error: A value for --version option is missising\n";
	exit 1;
      }
      unless ($reqJava{'Version'} =~ /^[0-9]+[0-9\.]*$/) {
        print STDERR "Error: A value for --version option is invalid\n";
	exit 1;
      }
      next;
    }
    # unknown option, should be java version defined as string
    $reqJava{'JavaName'} = $curArg;
    if ($curArg = shift @argv) {
      print STDERR "Error: Unknown option \"" . $reqJava{'JavaName'} . "\"\n";
      exit 1;
    }
    if ((defined $reqJava{'Vendor'}) ||
        (defined $reqJava{'Version'}) ||
	(defined $reqJava{'Strict'})) {
      print STDERR "Error: Options --strict, --vendor and  --version may not\n";
      print STDERR "       be used with java_name parametr\n";
      exit 1;
    }      
  }
}

# process options for link function
# It is the same as ReadSetEnvArgs
# Only LinkHelp is called instead of SetEnvHelp
# In Addition --noreplace --linkname options are here
sub ReadLinkArgs
{
  my $curArg;
  
  while ($curArg = shift @argv) {
    if ($curArg eq '--help') {
      LinkHelp;
      exit 0;
    }
    if ($curArg eq '--noreplace') {
      $reqJava{'NoReplace'} = 1;
      next;
    }  
    if ($curArg eq '--devel') {
      $reqJava{'Devel'} = 1;
      next;
    }  
    if ($curArg eq '--strict') {
      $reqJava{'Strict'} = 1;
      next;
    }  
    if ($curArg eq '--linkname') {
      unless ($reqJava{'LinkName'} = shift @argv) {
        print STDERR "Error: A value for --linkname option is missing\n";
	exit 1;
      }
      next;
    }
    if ($curArg eq '--vendor') {
      unless ($reqJava{'Vendor'} = shift @argv) {
        print STDERR "Error: A value for --vendor option is missing\n";
	exit 1;
      }
      next;
    }
    if ($curArg eq '--version') {
      unless ($reqJava{'Version'} = shift @argv) {
        print STDERR "Error: A value for --version option is missising\n";
	exit 1;
      }
      unless ($reqJava{'Version'} =~ /^[0-9]+[0-9\.]*$/) {
        print STDERR "Error: A value for --version option is invalid\n";
	exit 1;
      }
      next;
    }
    # unknown option, should be java version defined as string
    $reqJava{'JavaName'} = $curArg;
    if ($curArg = shift @argv) {
      print STDERR "Error: Unknown option \"" . $reqJava{'JavaName'} . "\"\n";
      exit 1;
    }
    if ((defined $reqJava{'Vendor'}) ||
        (defined $reqJava{'Version'}) ||
	(defined $reqJava{'Strict'})) {
      print STDERR "Error: Options --strict, --vendor and  --version may not\n";
      print STDERR "       be used with java_name parametr\n";
      exit 1;
    }      
  }
}

# generates related requested values from java_name parametr
sub ProcessJavaName
{
  if (defined $reqJava{'JavaName'}) {
    if ($reqJava{'JavaName'} eq "SunJava1") {
      $reqJava{'Vendor'} = "Sun";
      $reqJava{'Version'} = "1.1";
      $reqJava{'Strict'} = 1;
    } elsif ($reqJava{'JavaName'} eq "SunJava2") {
      $reqJava{'Vendor'} = "Sun";
      $reqJava{'Version'} = "1.3";
    } elsif ($reqJava{'JavaName'} eq "IBMJava2") {
      $reqJava{'Vendor'} = "IBM";
      $reqJava{'Version'} = "1.3";
    } elsif ($reqJava{'JavaName'} eq "Java2") {
      $reqJava{'Version'} = "1.3";
    } elsif ($reqJava{'JavaName'} eq "default") {
      # no special requests
    } else {
      print STDERR "Error: Unknown java_name \"$reqJava{'JavaName'}\"\n";
      print STDERR "       You can use one from: SunJava1, SunJava2, IBMJava2\n";
      print STDERR "                             Java2, default\n";
      exit 1;
    }
  }    
}

# generate list of config files
sub ConfigList
{
  my @configList;
  unless (opendir DIR, $configDir) {
    print STDERR "Error: $!\n";
    print STDERR "       Directory $configDir not found!\n";
    exit 1;
  }
  
  @configList = grep { /$configSuf$/ && -f "$configDir/$_" } readdir(DIR);
  
  closedir DIR;
  return @configList;
}    

# check wheter requested value was defined in config file
sub IsConfigValue
{
  my ($refCurJava, $valueName, $file) = @_;

  unless (defined $refCurJava->{$valueName}) {
    print STDERR "Warning: $valueName is not defined in file $configDir/$file\n";
    print STDERR "         Java from $configDir/$file is ignored\n";
    return 0;
  }
  return 1;    
}

# read all configuration files into internal structure @javas
sub ReadConfigs
{
  foreach my $file (@_) {
    # hash for current Java values
    my %curJava;

    # open config file    
    unless (open FILE, "$configDir/$file") {
      print STDERR "Warning: $!\n";
      print STDERR "         Can not open file $configDir/$file!\n";
      next;
    }

    # save config name
    $curJava{'ConfigName'} = $file;

    # read line by line and check syntax and find Values    
    my $syntax = 1;
    while (my $line = <FILE>) {
      chomp $line;
      # remove comments after #
      $line =~ s/#.*//;
      if ($line =~ /^\s*Vendor\s*[:=]\s*(.+)\s*$/) {
        $curJava{'Vendor'} = $1;
      } elsif ($line =~ /^\s*Version\s*[:=]\s*([0-9]+[0-9\.]*)\s*$/) {
        $curJava{'Version'} = $1;
      } elsif ($line =~ /^\s*Priority\s*[:=]\s*([0-9]+)\s*$/) {
        $curJava{'Priority'} = $1;
      } elsif ($line =~ /^\s*Devel\s*[:=]\s*([Tt][Rr][Uu][Ee])\s*$/) {
	  $curJava{'Devel'} = 1;
      } elsif ($line =~ /^\s*Devel\s*[:=]\s*([Ff][Aa][Ll][Ss][Ee])\s*$/) {
	  $curJava{'Devel'} = 0;
      } elsif ($line =~ /^\s*JAVA_BINDIR\s*[:=]\s*([^\s]+)\s*$/) {
        $curJava{'JAVA_BINDIR'} = $1;
      } elsif ($line =~ /^\s*JAVA_ROOT\s*[:=]\s*([^\s]+)\s*$/) {
        $curJava{'JAVA_ROOT'} = $1;
      } elsif ($line =~ /^\s*JAVA_HOME\s*[:=]\s*([^\s]+)\s*$/) {
        $curJava{'JAVA_HOME'} = $1;
      } elsif ($line =~ /^\s*JRE_HOME\s*[:=]\s*([^\s]+)\s*$/) {
        $curJava{'JRE_HOME'} = $1;
      } elsif ($line =~ /^\s*JDK_HOME\s*[:=]\s*([^\s]*)\s*$/) {
        $curJava{'JDK_HOME'} = $1 if $1;;
      } elsif ($line =~ /^\s*SDK_HOME\s*[:=]\s*([^\s]*)\s*$/) {
        $curJava{'SDK_HOME'} = $1 if $1;
      } elsif ($line =~ /^\s*JAVA_LINK\s*[:=]\s*([^\s]+)\s*$/) {
        $curJava{'JAVA_LINK'} = $1 if $1;
      } elsif ($line =~ /^\s*$/) {
        # empty line
      } else {
        # this syntax is not known
        print STDERR "Warning: Can not process line $. in configDir/$file\n";
	print STDERR "         Java from $configDir/$file is ignored\n";
	$syntax = 0;
	last;
      }      
    }
    
    close FILE;
    
    # did all lines have valid syntax?
    unless ($syntax) { next; }
    
    # do we have all important values
    unless (IsConfigValue \%curJava, 'Vendor', $file) {next;}
    unless (IsConfigValue \%curJava, 'Version', $file) {next;}
    unless (IsConfigValue \%curJava, 'Priority', $file) {next;}
    unless (IsConfigValue \%curJava, 'Devel', $file) {next;}
    unless (IsConfigValue \%curJava, 'JAVA_BINDIR', $file) {next;}
    unless (IsConfigValue \%curJava, 'JAVA_ROOT', $file) {next;}
    unless (IsConfigValue \%curJava, 'JAVA_HOME', $file) {next;}
    unless (IsConfigValue \%curJava, 'JRE_HOME', $file) {next;}
    if ($curJava{'Devel'}) {
      unless (IsConfigValue \%curJava, 'JDK_HOME', $file) {next;}
    }  
    unless (IsConfigValue \%curJava, 'JAVA_LINK', $file) {next;}

    # does this java exist?
    my @checkDirList = ('JAVA_BINDIR', 'JAVA_ROOT', 'JAVA_HOME', 'JRE_HOME');
    if ($curJava{'Devel'}) {
      push @checkDirList, 'JDK_HOME';
      if (defined $curJava{'SDK_HOME'}) {
        push @checkDirList, 'SDK_HOME';
      }
    }  	

    my $areDirValid = 1;
    foreach my $dirName (@checkDirList) {
      stat $curJava{$dirName};
      unless (-d _) {
        print STDERR "Warning: The directory \"" . $curJava{$dirName} . "\" does not exist\n";
	print STDERR "         Please fix $dirName in $configDir/$file\n";
	print STDERR "         Java from $configDir/$file is ignored\n";
	$areDirValid = 0;
	last;
      }	
    }  
    next unless ($areDirValid);

    my @checkBinList = ('/java');
    if ($curJava{'Devel'}) {
      push @checkBinList, '/javac';
    }
    
    my $areBinValid = 1;
    foreach my $fileName (@checkBinList) {
      stat $curJava{'JAVA_BINDIR'} . $fileName;
      unless (-x _) {
        print STDERR "Warning: The binary \"" . $curJava{'JAVA_BINDIR'} . $fileName . "\" is not executable\n";
	print STDERR "         Possibly JAVA_BINDIR in $configDir/$file has invalid value\n";
	print STDERR "         Java from $configDir/$file is ignored\n";
	$areBinValid = 0;
	last;
      }	
    } 
    next unless ($areBinValid);

    # all values are valid, we can save them into main array
    push @javas, \%curJava;
  }
}      

# checks devel value wheter given java match to requested java
sub IsDevelValid
{
  my $curJavaNum = shift;

  # curJava is valid when there are no requests on devel
  return 1 unless (defined $reqJava{'Devel'});
  # curent java is wrong when devel is required and is not supported by this java
  return 0 if (($reqJava{'Devel'}) && (! $javas[$curJavaNum]->{'Devel'}));
  # this java is good
  return 1;
}

# checks version value wheter given java match to requested java
sub IsVersionValid
{
  my $curJavaNum = shift;

  # curJava is valid when there are no requests on version
  return 1 unless (defined $reqJava{'Version'});

  # split versions levels
  my @reqJavaVersion = split(/\./, $reqJava{'Version'});
  my @curJavaVersion = split(/\./, $javas[$curJavaNum]->{'Version'});

  # check versions level by level
  my $verNum = 0;
  while ($verNum < @reqJavaVersion) {
    # curJava must have defined this version level
    return 0 unless (defined $curJavaVersion[$verNum]);

    if (defined $reqJava{'Strict'}) {
      # this version level must strictly match
      return 0 unless ($curJavaVersion[$verNum] eq $reqJavaVersion[$verNum]);
    } else {
      # current java is wrong when the version is less then required version
      return 0 if ($curJavaVersion[$verNum] < $reqJavaVersion[$verNum]);
      # this java is good when the version is higher then required version
      return 1 if ($curJavaVersion[$verNum] > $reqJavaVersion[$verNum]);
    }
    $verNum += 1;
  } 

  # this java is good
  return 1;
}

# checks vendor value wheter given java match to requested java
sub IsVendorValid
{
  my $curJavaNum = shift;

  # curJava is valid when there are no requests on vendor
  return 1 unless (defined $reqJava{'Vendor'});
  # curent java is good when Vendor is equal with required
  return 1 if ($reqJava{'Vendor'} eq $javas[$curJavaNum]->{'Vendor'});
  # this java has wrong Vendor
  return 0;
}

# try to find Valid Java
sub FindBestJava
{
  my @validJavas;
  my $curJavaNum = 0;
  
  # test which javas are valid
  while ($curJavaNum < @javas) {
    $validJavas[$curJavaNum] = 1;
    $validJavas[$curJavaNum] = IsDevelValid($curJavaNum) if ($validJavas[$curJavaNum]);
    $validJavas[$curJavaNum] = IsVersionValid($curJavaNum) if ($validJavas[$curJavaNum]);
    $validJavas[$curJavaNum] = IsVendorValid($curJavaNum) if ($validJavas[$curJavaNum]);
    $curJavaNum += 1;
  }

  # find the best java by priority
  my $bestJava;
  my $bestPriority;
  
  $curJavaNum = 0;
  while ($curJavaNum < @javas) {
    if ($validJavas[$curJavaNum]) {
      unless (defined $bestPriority) {
        $bestPriority = $javas[$curJavaNum]->{'Priority'};
	$bestJava = $curJavaNum;
      } else {
        if ($bestPriority > $javas[$curJavaNum]->{'Priority'}) {
	  $bestPriority = $javas[$curJavaNum]->{'Priority'};
	  $bestJava = $curJavaNum;
	}  
      }
    }  	  
    $curJavaNum += 1;
  }
  
  return $bestJava;
}

# print bash commands to define environment variables for selected java
sub PrintEnv
{
  my $javaNum = shift;
  
  # find old java path in $ENV{'PATH'}
  my @javaBinPaths = ('/usr/lib/java/bin', '/usr/lib/java/jre/bin');
  foreach my $java (@javas) {
    if (defined $java->{'JAVA_BINDIR'}) {
      push @javaBinPaths, $java->{'JAVA_BINDIR'};
    }
  }
  
  # create new value for $ENV{'PATH'}
  my $newPath = $ENV{'PATH'};
  my $newPathFixed = 0;
  foreach my $javaBinPath (@javaBinPaths) {
    if ($newPath =~ /$javaBinPath/) {
      $newPath =~ s/$javaBinPath/$javas[$javaNum]->{'JAVA_BINDIR'}/;
      $newPathFixed = 1;
    }
  }      
  
  # write bash code for new $PATH
  if ($newPathFixed) {
    print "export PATH=$newPath\n"
  } else {
    print 'export PATH=$PATH:' . $javas[$javaNum]->{'JAVA_BINDIR'} . "\n"
  }    
  
  # write bash code for java related variables
  foreach my $param ('JAVA_BINDIR', 'JAVA_ROOT', 'JAVA_HOME',
                     'JRE_HOME', 'JDK_HOME', 'SDK_HOME') {
    if (defined $javas[$javaNum]->{$param}) {
      print "export $param=" . $javas[$javaNum]->{$param} . "\n";
    } else {
      print "unset $param\n";
    }  
  }
}

# check current link to default java
# returns:  0 - link exist and is valid (probably nothink to do)
#	    1 - link exist and is invalid (must be fixed)
#	    2 - link does not exist (must be created)
sub CheckCurrentLink
{
  my $linkPath = shift;

  my @linkPathStat = lstat "$linkPath";

  # return undefine value when link does not exist
  return 2 unless (@linkPathStat);
  
  #check wheter $linkPath is link
  unless (-l _) {
    print STDERR "Error: \"$linkPath\" is not link\n";
    exit 1;
  }    
  
  # check if current link point to valid java
  my $isLinkPathValid = 1;
  my @checkBinList = ("java");
  foreach my $file (@checkBinList) {
    my @checkDirList = ("bin", "jre/bin");
    my $binaryFound = 0;
    foreach my $dir (@checkDirList) {
      stat "$linkPath/$dir/$file";
      $binaryFound = 1 if (-x _);
    }
    $isLinkPathValid = 0 unless ($binaryFound);    
  }
  
  return 0 if ($isLinkPathValid);
  # link exist but must be fixed
  return 1;
}

sub DeleteInvalidLink
{
  # which link name should we check
  my $linkPath;
  if (defined $reqJava{'LinkName'}) {
    $linkPath = "$libdir/$reqJava{'LinkName'}";
  } else {
    $linkPath = "$libdir/$defaultJava";
  }

  if (CheckCurrentLink($linkPath) == 1) {
    # save current link target and delete it
    my $oldLinkTarget = readlink($linkPath);
    # delete invalid link
    if (unlink "$linkPath") {
      print "Link removed: $linkPath -> $oldLinkTarget\n";
    } else {
      print STDERR "Error: $!\n";
      print STDERR "       Can not delete link \"$linkPath\"\n";
      exit 1;
    }  
  }
}

# create requested link if needed
sub CreateLink
{
  my $javaNum = shift;

  my $linkPath;
  if (defined $reqJava{'LinkName'}) {
    $linkPath = "$libdir/$reqJava{'LinkName'}";
  } else {
    $linkPath = "$libdir/$defaultJava";
  }
 
  my $linkStat = CheckCurrentLink($linkPath);
  # nothink to do when link is valid and --noreplace is used
  if (($linkStat == 0) && (defined $reqJava{'NoReplace'})) {
    print "Current link \"$linkPath\" points to valid java directory\n";
    print "Nothing changed!\n";
    return;
  }
  
  # delete old link if needed
  if (($linkStat == 0) || ($linkStat == 1)) {
    # save current link target and delete it
    my $oldLinkTarget = readlink($linkPath);
    # in has new link another target?
    if ($oldLinkTarget eq $javas[$javaNum]->{'JAVA_LINK'}) {
      print "Current link $linkPath points to required java directory\n";
      print "Nothing changed!\n";
      return;
    }
    # delete old link  
    if (unlink "$linkPath") {
      print "Link removed: $linkPath -> $oldLinkTarget\n";
    } else {
      print STDERR "Error: $!\n";
      print STDERR "       Can not delete link \"$linkPath\"\n";
      exit 1;
    }  
  }
  
  # create new link
  unless (symlink $javas[$javaNum]->{'JAVA_LINK'}, $linkPath) {
    print STDERR "Error: $!\n";
    print STDERR "       Can not create symbolic link $linkPath -> $javas[$javaNum]->{'JAVA_LINK'}\n";
    exit 1;
  }
  
  print "Link created: $linkPath -> $javas[$javaNum]->{'JAVA_LINK'}\n";
  
  # does new link point to valid java directory
  if (CheckCurrentLink($linkPath) == 1) {
    print STDERR "Error: New link $linkPath does not pointo to valid java directory\n";
    print STDERR "       Please, fix JAVA_LINK value in $configDir/$javas[$javaNum]->{'ConfigName'}\n";
    print STDERR "       and run this script again\n";
  }
  return;
}

#####################################################
###         		main			  ###
#####################################################		

# select function by first parametr in @argv
SelectFunction;

# read the rest of @argv by required function
ReadSetEnvArgs if ($reqFunc eq 'setenv');
ReadLinkArgs   if ($reqFunc eq 'link');

# transform potential java_name parametr into vendor and version request
ProcessJavaName;

# read all configuration files in $configDir
ReadConfigs(ConfigList);

# exist at least one java
if (@javas == 0) {
  print STDERR "Error: no valid java configuration found in directory $configDir\n";
  DeleteInvalidLink if ($reqFunc eq 'link');
  exit 1;
}  

my $bestJava = FindBestJava;

unless (defined $bestJava) {
  print STDERR "Error: No valid java found\n";
  DeleteInvalidLink if ($reqFunc eq 'link');
  exit 1;
}

# process requested function
PrintEnv($bestJava) if ($reqFunc eq 'setenv');
CreateLink($bestJava) if ($reqFunc eq 'link');