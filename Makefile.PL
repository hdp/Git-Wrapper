use inc::Module::Install;

name     'Git-Wrapper';
all_from 'lib/Git/Wrapper.pm';
author   'Hans Dieter Pearcey <hdp@cpan.org>';

build_requires 'Test::More';

requires 'File::pushd';

auto_manifest;

WriteAll;
