use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Audio::OSC',
    VERSION_FROM      => 'lib/Audio/OSC.pm', # finds $VERSION
    PREREQ_PM         => {Test::More => 0.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Audio/OSC.pm', # retrieve abstract from module
       AUTHOR         => 'Christian Renz <crenz@web42.com>') : ()),
);
