#!/usr/bin/perl
# 
# Сбор статистики по авторству на основе git blame
# 

use Getopt::Long;

sub blame_single_file {
    # получение статистики по одному файлу
    $filename = shift;  # путь к файлу
    $lines_per_author_ref = shift; # ссылка на словарь, который
                                   # надо заполнить статистикой

    my $current_commit = '';
    my %authors_of_commit = ();

    open(BLAME, "git blame --porcelain \"$filename\" |") || die "Failed: $!\n";

    while (<BLAME>) {
        my $line = $_;
        if ($line =~ /^([abcdef0-9]{40})[\s\d]*$/) {
            # последующие строчки относятся к этому коммиту
            $current_commit = $1;
        } elsif ($line =~ /^author (.*)$/) {
            # теперь мы знаем автора текущего коммита
            $authors_of_commit{$current_commit} = $1;
        } elsif ($line =~ /^\t.*/) {
            # а это сама строка из файла, надо увеличить счетчик
            my $author = $authors_of_commit{$current_commit};
            if (exists $lines_per_author_ref->{$author}) {
                $lines_per_author_ref->{$author} += 1;
            } else {
                $lines_per_author_ref->{$author} = 1;
            }
        }
    }

    close BLAME;

    delete $lines_per_author_ref->{"Not Committed Yet"};
}

sub print_stats {
    # печать статистики по авторам для отдельного файла
    my $filename = shift;
    my $lines_per_author_ref = shift;

    while (($author, $count) = each(%{$lines_per_author_ref})) {
        print "$filename\t$author\t$count\n";
    }
}

sub read_aliases_file {
    # читаем файл с псевдонимами и возвращаем ссылку на хеш
    # вида (псевдоним => тру-имя автора)
    my $filename = shift;
    
    my %aliases = ();
    open(ALIASES, $filename) or die $!;
    while (<ALIASES>) {
        chomp;
        /^([^=]*)=(.*)$/;
        $aliases{$1} = $2;
    }
    close ALIASES;
    return \%aliases;
}

sub apply_aliases {
    # пересчитываем статистику, сливая данные по псевдонимам автора
    # в ключ хеша с его настоящим именем
    my $stats_ref = shift;
    my $aliases_ref = shift;

    while (my ($alias, $truename) = each %{$aliases_ref}) {
        if ($alias eq $truename) {
            die "Alias `$alias` equals author's true name!\n"
        }

        if (exists $stats_ref->{$alias}) {
            if (!exists $stats_ref->{$truename}) {
                $stats_ref->{$truename} = 0;
            }
            $stats_ref->{$truename} += $stats_ref->{$alias};
            delete $stats_ref->{$alias};
        }
    }
}

sub filename_has_one_of_extensions {
    # возвращает true, если переданное имя файла имеет одно из
    # указанных расширений
    my $filename = shift;
    my $extensions_ref = shift;

    foreach $ext (@{$extensions_ref}) {
        if ($filename =~ /\.$ext$/) {
            return 1;
        }
    }
    return 0;
}

my $aggregate = '';  # собирать статистику по нескольким файлам в одну кучу?
my $needhelp = '';
my $aliases_filename = '';
my $extensions_string = '';
my $use_common_extensions = '';
my $read_from_stdin = '';

GetOptions ('totals' => \$aggregate, 'help' => \$needhelp, 'aliases=s' => \$aliases_filename, 'extensions=s' => \$extensions_string, 'common-exts' => \$use_common_extensions, 'stdin' => \$read_from_stdin);

if ($needhelp) {
    print "Сбор статистики по авторству в репозитории Git\n";
    print "Использование:\n";
    print "    perl blamestats.pl [OPTIONS] <имена файлов из репозитория>\n";
    print "Параметры:\n";
    print "    --stdin\n";
    print "         Читать имена файлов из stdin вместо командной строки.\n";
    print "    --aliases=<файл с псевдонимами авторов>\n";
    print "         Файл со строками вида 'псевдоним=настоящее имя автора',\n";
    print "         используется для объединения статистики по\n";
    print "         разным псевдонимам одного автора.\n";
    print "    --extensions=<список расширений файлов через запятую>\n";
    print "         Обрабатывать только файлы с указанными расширениями.\n";
    print "         Расширения указываются без точки.\n";
    print "    --common-exts\n";
    print "         Использовать заранее указанный в коде скрипта список\n";
    print "         расширений как значение параметра --extensions\n";
    print "    --totals\n";
    print "         Если задано - выводится общая статистика по всем\n";
    print "         указанным файлам вместо отдельной по каждому файлу.\n";
    die;
}

my %aliases = ();
if ($aliases_filename) {
    my $aliases_ref = &read_aliases_file($aliases_filename);
    %aliases = %{$aliases_ref};
}

if ($use_common_extensions) {
    $extensions_string = "py,php,pl,rb,sql,c,sh,cpp,h,hpp,cxx,hxx,as,js,html,css,scss,txt,xml,xsd,xsl,conf,ini,yaml,json,m4,ui,pro,pri,md";
}

my @extensions = split(/,/, $extensions_string);

my @filenames = @ARGV;
if ($read_from_stdin) {
    @filenames = <>;
}

my %stats = ();
FILE_LOOP: foreach $filename (@filenames) {
    chomp $filename;
    if ($extensions_string) {
        if (!&filename_has_one_of_extensions($filename, \@extensions)) {
            next FILE_LOOP;
        }
    }

    &blame_single_file($filename, \%stats);
    &apply_aliases(\%stats, \%aliases);
    if (!$aggregate) {
        &print_stats($filename, \%stats);
        %stats = ();
    }
}

if ($aggregate) {
    &print_stats("<total>", \%stats);
}

