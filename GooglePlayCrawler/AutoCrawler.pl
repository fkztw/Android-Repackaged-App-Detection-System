#!/usr/bin/env perl

use strict; 
use warnings; 
use 5.014;
use POSIX qw(strftime);
use Digest::MD5;

# This script should be put in the same level as googleplay/.
# That is, right under the GooglePlayCrawler/
my $pwd = `pwd`; 
chomp $pwd;

my $jar_location = "$pwd/googleplay/googleplay.jar";
my $crawler_conf = "$pwd/googleplay/crawler.conf";

my $root_download_dir = "$pwd/AppRepository/";
mkdir $root_download_dir unless -e $root_download_dir;

my $category_dir = "$pwd/categories/";
mkdir $category_dir unless -e $category_dir;

# for log
my $root_log_dir = "$pwd/log/";
mkdir $root_log_dir unless -e $root_log_dir;
my $normal_log = $root_log_dir . "normal.log";
my $error_log  = $root_log_dir . "error.log";

# for statics
my $new     = 0;
my $update  = 0;
my $old     = 0;

# when program quit, print the statics.
@SIG{qw( INT TERM HUP )} = \&print_statics;

# open normal_log and error_log
open my $h_log, ">>", $normal_log or die "Can't open > ./log/: $!";
#open(STDOUT, ">>&=", $h_log);
open my $e_log, ">>", $error_log or die "Can't open > ./log/: $!";
#open(STDERR, ">>&=", $e_log);
$e_log->autoflush(1);

print_timestamp($h_log, "Started at");
print_timestamp($e_log, "Started at");

my $start_time = time();

#----------------- main routine ----------------

my $main_categories = "$pwd/googleplay/categories.conf";
my $main_category;

open my $h_main_categories, "<", $main_categories or die "Can't open < ./googleplay/: $!";
<$h_main_categories>;
while(my $line = <$h_main_categories>) {
    chomp($line);
    if(substr($line, 0, 1) ne '#') {
        my @splited_line = split(';', $line);
        $main_category = $splited_line[0];

        my $download_dir = $root_download_dir . $main_category;
        mkdir($download_dir) unless (-e $download_dir);

        my $profile = "$pwd/categories/".$main_category;
        open my $h_profile, ">>", $profile or die "Can't open >> ./categories/$main_category: $!";

        # get current apk files list in the system.
        open my $r_profile, "<", $profile or die "Can't open < ./categories/$main_category: $!";
        my @apks;
        while(<$r_profile>) {
            my @apk = split/\t/;
            push @apks, $apk[1];
        }
        close $r_profile or do {
            print_error_log("Can't close apk list reader: $r_profile");
        };

        for (my $i = 0; $i < 2; $i++) {
            my %apk_list;

            if ($i == 0) {load_top_n_apklist($main_category, \%apk_list, 'apps_topselling_free');}
            if ($i == 1) {load_top_n_apklist($main_category, \%apk_list, 'apps_topselling_new_free');}

            while(my($key, $value) = each(%apk_list)) {
                my @ref_info = @$value;
                my $error_num = download_apk($download_dir, $ref_info[1]);

                if ($error_num == 1) {
                    print_error_log("Can't open OLDAPK", $ref_info[1]);
                    next;
                }

                if ($error_num == 2) {
                    print_error_log("Can't open NEWAPK", $ref_info[1]);
                    next;
                }

                # if downloaded apk not in the system apk files list, add it.
                unless(grep(/^$ref_info[1]$/, @apks)) {
                    for(my $i = 0; $i <= $#ref_info; $i++) {
                        print $h_profile "$ref_info[$i]\t";
                    }
                    say $h_profile "";
                    say $h_log "New apk file ".$ref_info[1]." added to ".$main_category;
                }
                else {
                    say $h_log "Not a new apk file of ".$main_category;
                }

                print_timestamp($h_log, "Timestamp");
            }
        }
        close $h_profile or do {
            print_error_log("Can't close apk list writer: $h_profile");
        };
    } 
}
close $h_main_categories or do {
    print_error_log("Can't close category.conf: $h_main_categories");
};

print_statics();

#---------------- print statics information into log   ----------------
sub print_statics {
    my $total = $new + $update + $old;
    say $h_log "====================\n";
    say $h_log "New apk files of this time:\t$new\t(". sprintf("%.2f", ($new/$total)*100) ."%)";
    say $h_log "Updated apk files of this time:\t$update\t(". sprintf("%.2f", ($update/$total)*100) ."%)";
    say $h_log "Old apk files of this time:\t$old\t(". sprintf("%.2f", ($old/$total)*100) ."%)";
    say $h_log "Total apk files of this time:\t$total";
    say $h_log "Time consumed: ".(time() - $start_time)." seconds";
    print_timestamp($h_log, "Ended at");
    print_timestamp($e_log, "Ended at");
    say $h_log "====================";
    say $e_log "====================";

    close $h_log;
    close $e_log;
    exit(0);
}

#---------------- load the list of top n new free apks ----------------
sub load_top_n_apklist {
    my $main_category = $_[0];
    my $ref_apk_list  = $_[1];
    my $sub_category  = $_[2];
    #my $sub_category = 'apps_topselling_free';
    #my $sub_category = 'apps_topselling_new_free';
    my $n = 100;
    my $index = 0;

    # can only get the first 500 apps name of the category
    for (my $o = 0; $o < 5; $o++) {
        my $command;
        $command = 'java -jar ';
        $command = $command . $jar_location . ' -f ' . $crawler_conf;
        $command = $command . ' list ' . $main_category;
        $command = $command . ' -s ' . $sub_category;
        $command = $command . ' -o ' . $o*100;
        $command = $command . " -n $n";

        say $h_log "$command";
        
        open my $pipe_read, "$command|" or die "Can't open pipe_read: $!";
        while(my $line = <$pipe_read>) {
            chomp($line);
            my @splited_line = split(';', $line);

            if ($splited_line[0] ne 'Title') {
                $ref_apk_list->{$index} = [@splited_line];
                $index++;
            }
        }
        close $pipe_read or do {
            print_error_log("Can't close pipe_read: $pipe_read")
        };
    }
}


#---------------- download apk ----------------
sub download_apk {
    my $download_dir = $_[0];
    my $target_sample_name, my $source_sample_name;
    my $apk = $_[1];
    my $command = 'java -jar ';
    
    $command = $command . $jar_location . ' -f ' . $crawler_conf;
    $command = $command . ' download ' . $apk;

    say $h_log "APK filename: " . $apk;
    my $result = `$command`;
    #my $result = system($command . "1>>$h_log 2>&1");

    # If item found, move the downloaded apk file to its download_dir
    if(index($result, 'This item cannot be installed in your country.') == -1) {
        print $h_log "$result";

        $target_sample_name = $download_dir . "/" . $apk . '.apk';
        $source_sample_name = "$pwd/" . $apk . '.apk';

        # do the md5checksum
        if (-e $target_sample_name) {
            open OLDAPK, $target_sample_name or do {
                print_error_log($0, "open $target_sample_name");
                return 1;
            };
            my $ctx = Digest::MD5->new;
            $ctx->addfile(*OLDAPK);
            my $old_apk_md5 = $ctx->hexdigest;
            close OLDAPK or do {print_error_log("Can't close target: $target_sample_name")};

            open NEWAPK, $source_sample_name or do {
                print_error_log($0, "open $source_sample_name");
                return 2;
            };
            $ctx->reset;
            $ctx->addfile(*NEWAPK);
            my $new_apk_md5 = $ctx->hexdigest;
            close NEWAPK or do { print_error_log("Can't close source: $source_sample_name"); };

            if ($old_apk_md5 eq $new_apk_md5) {
                say $h_log "Same md5checksum of the existed same name apk file.";

                `rm $source_sample_name`;
                $old++;
            }
            else {
                say $h_log "Different md5checksum of the existed same name apk file.";
                say $h_log "Now will replace the old apk file by the new one.";

                `mv $source_sample_name $target_sample_name`;
                $update++;
            }
        }
        else {
            say $h_log "It's a new apk file.";

            `mv $source_sample_name $target_sample_name`;
            $new++;
        }
    }
    else {
        say $h_log "This item cannot be downloaded in your contry.";
    }
}

#---------------- print error log ----------------
sub print_error_log {
    say $e_log "$!: @_.";
    print_timestamp($e_log, "Error at");
}

#---------------- print timestamp ----------------
sub print_timestamp {
    my $FH = shift;
    my $current_time = strftime("%Y-%m-%d %H:%M:%S.", localtime(time));
    say $FH "@_: $current_time\n";
}

