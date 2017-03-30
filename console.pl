#!/usr/bin/env perl

use strict;
use warnings;
use POSIX 'setsid';
use POSIX 'strftime';
use Cwd 'abs_path';
use File::Basename;
use Switch;
use Getopt::Long;
Getopt::Long::Configure("bundling");

our @remotelist = ("openwrt", "packages", "luci", "routing", "telephony", "newpackages");

our @commitlist = ({
        "name" => "14.07",
        "type" => "branch",
        "dict" => {
            "openwrt"     => "c6d19927013c52d73d6fa5212da0af7c37361266",
            "packages"    => "1ab5d3643a470a40c81ae18fc55571d8b590e8f6",
            "luci"        => "3ccdaa9b48f5da6073ac5f0badd23de2e18f3242",
            "routing"     => "ba11f8d9d3f5e6aebb21ea952ac52ad1bf8474a4",
            "telephony"   => "12485ef0ef44bbf43a126365e229736c6c83fdd7",
            "newpackages" => ""
        }
    },{
        "name" => "15.05",
        "type" => "branch",
        "dict" => {
            "openwrt"     => "b20a2b48901195a79d86eaecb386d45fe5d63c39",
            "packages"    => "f55314de0ed1d91c8143946e101515c70587565b",
            "luci"        => "e11b5e49f894af7f63ade77d06b87177249c8649",
            "routing"     => "e26942118bced52ead0ce753f3c9d931436110b0",
            "telephony"   => "608a59a693e8b0b1edeed6079196745bfcab6c7e",
            "newpackages" => "c22aa6a8437199a6ad35e6f3fc657104e8c653f1"
        }
    },{
        "name" => "17.01",
        "type" => "branch",
        "dict" => {
            "openwrt"     => "b9a408c2b49ccfa0e906bda00ef77f4002e401fd",
            "packages"    => "640d377622f315a60599ec6a8fd33da8de9d045b",
            "luci"        => "44bf3f0c1640040561306caff39f34ac916b4357",
            "routing"     => "eca18c2d621c18fed127680cfae5ed953771dcc2",
            "telephony"   => "1f0fb2538ba6fc306198fe2a9a4b976d63adb304",
            "newpackages" => "c22aa6a8437199a6ad35e6f3fc657104e8c653f1"
        }
    },{
        "name" => "17.01.0-rc1",
        "type" => "tag",
        "dict" => {
            "openwrt"     => "ec095b5bf3bf0e6c570232522004c17084ba909d",
            "packages"    => "31d89be9e69bac261bfe7440512cb4e0f3356255",
            "luci"        => "472dc4b9e2ca71c114f5da70cb612c1089b8daa7",
            "routing"     => "a6c7413594a0e4b42dab42bb5fa68534e39b7d0c",
            "telephony"   => "1f0fb2538ba6fc306198fe2a9a4b976d63adb304",
            "newpackages" => "c22aa6a8437199a6ad35e6f3fc657104e8c653f1"
        }
    },{
        "name" => "17.01.0-rc2",
        "type" => "tag",
        "dict" => {
            "openwrt"     => "42f3c1fe1ca051dec2ef828b4a412ed73e29acae",
            "packages"    => "06198d9c8c1ba061a0a5d566545a5c0bbce2b0a4",
            "luci"        => "e306ee6c93c1ef600012f47e40dd75020d4ab555",
            "routing"     => "dd36dd47bbd75defcb3c517cafe7a19ee425f0af",
            "telephony"   => "1f0fb2538ba6fc306198fe2a9a4b976d63adb304",
            "newpackages" => "c22aa6a8437199a6ad35e6f3fc657104e8c653f1"
        }
    },{
        "name" => "17.01.0",
        "type" => "tag",
        "dict" => {
            "openwrt"     => "59508e309e91ba152ae43ef1d6983f2f6f873632",
            "packages"    => "ed90827282851ad93294e370860320f1af428bb2",
            "luci"        => "a100738163585ae1edc24d832ca9bef1f34beef0",
            "routing"     => "dd36dd47bbd75defcb3c517cafe7a19ee425f0af",
            "telephony"   => "1f0fb2538ba6fc306198fe2a9a4b976d63adb304",
            "newpackages" => "c22aa6a8437199a6ad35e6f3fc657104e8c653f1"
        }
    }
);

our %mirrorlist = (
    "github" => {
        "lede"        => "https://github.com/lede-project/source.git",
        "openwrt"     => "https://github.com/speadup/openwrt.git",
        "packages"    => "https://github.com/openwrt/packages.git",
        "luci"        => "https://github.com/openwrt/luci.git",
        "routing"     => "https://github.com/openwrt-routing/packages.git",
        "telephony"   => "https://github.com/openwrt/telephony.git",
        "newpackages" => "https://git.oschina.net/phoenix-openwrt/newpackages.git"
    },
    "lede" => {
        "lede"        => "https://git.lede-project.org/source.git",
        "openwrt"     => "https://git.lede-project.org/openwrt/source.git",
        "packages"    => "https://git.lede-project.org/feed/packages.git",
        "luci"        => "https://git.lede-project.org/project/luci.git",
        "routing"     => "https://git.lede-project.org/feed/routing.git",
        "telephony"   => "https://git.lede-project.org/feed/telephony.git",
        "newpackages" => "https://git.oschina.net/phoenix-openwrt/newpackages.git"
    },
    "oschina" => {
        "lede"        => "https://git.oschina.net/openwrt-mirrors/lede-project.git",
        "openwrt"     => "https://git.oschina.net/openwrt-mirrors/openwrt.git",
        "packages"    => "https://git.oschina.net/openwrt-mirrors/packages.git",
        "luci"        => "https://git.oschina.net/openwrt-mirrors/luci.git",
        "routing"     => "https://git.oschina.net/openwrt-mirrors/routing.git",
        "telephony"   => "https://git.oschina.net/openwrt-mirrors/telephony.git",
        "newpackages" => "https://git.oschina.net/phoenix-openwrt/newpackages.git"
    }
);


sub daemon() {
    exit if fork();
    exit if fork();
    setsid();
    umask 002;
    #chdir '/';
    exit if fork();

    close STDIN;
    close STDOUT;
    close STDERR;
    open STDIN, '/dev/null';
    open STDOUT, '>/dev/null';
    open STDERR, '>/dev/null';
}

sub syslog {
    my $msg = shift @_;
    my $time = strftime("%Y-%m-%d %H:%M:%S",localtime());
    printf("[$time] $msg\n", @_);
}

sub file_write {
    my ($name, $contents, $mode) = @_;
    $mode or $mode = ">";
    open(FH, "$mode$name");
    print(FH $contents);
    close(FH);
}

sub shell_exec {
    my ($cmd) = @_;
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub get_cpu_siblings() {
    open(FH, "/proc/cpuinfo");
    while(<FH>) {
        if(/^siblings\s*:\s(\d*)$/) {
            close(FH);
            return $1;
        }
    }
    close(FH);
    return -1;
}

sub get_cpu_cores() {
    open(FH, "/proc/cpuinfo");
    while(<FH>) {
        if(/^cpu cores\s*:\s(\d*)$/) {
            close(FH);
            return $1;
        }
    }
    close(FH);
    return -1;
}

sub get_sys_processors() {
    my $count = 0;
    open(FH, "/proc/cpuinfo");
    while(<FH>) {
        if(/^processor\s*:\s(\d*)$/) {
            $count ++;
        }
    }
    close(FH);
    return $count;
}

sub get_sys_cores() {
    return get_sys_processors() / get_cpu_siblings() * get_cpu_cores();
}

sub git_remote_get_url {
    my ($remote) = @_;
    my $cmd = "git remote get-url '$remote'";
    my $url = qx($cmd);
    $url =~ s/\s*$//g;
    if($? >> 8) {
        return "";
    } else {
        return $url;
    }
}

sub git_remote_set_url {
    my ($remote, $url) = @_;
    my $cmd = "git remote set-url '$remote' '$url'";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_remote_add {
    my ($remote, $url, $fetch) = @_;
    my $cmd = "git remote add";
    if ($fetch) {
        $cmd .= " -f"
    }
    $cmd .= " '$remote' '$url'";
    syslog($cmd);
    $url = qx($cmd);
    return $? >> 8;
}

sub git_remote_exists {
    my ($remote) = @_;
    my $cmd = "git remote";
    return qx($cmd) =~ m/^$remote$/m;
}

sub git_status {
    my ($text) = @_;
    if($text) {
        my $cmd = "git status";
        my $output = qx($cmd);
        return $output =~ /$text/;
    } else {
        my $cmd = "git status --porcelain";
        return qx($cmd);
    }
}

sub git_commit {
    my ($amend, $comments) = @_;
    my $cmd = "git commit";
    if($amend) {
        $cmd .= " --amend";
    }
    if($comments) {
        $cmd .= " -m '$comments'";
    }
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_reset {
    my ($hard, $commit) = @_;
    my $cmd = "git reset";
    if($hard) {
        $cmd .= " --hard";
    }
    if($commit) {
        $cmd .= " '$commit'";
    }
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_checkout {
    my ($commit, $branch) = @_;
    my $cmd = "git checkout '$commit'";
    if($branch) {
        $cmd .= " -b '$branch'";
    }
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_head {
    my $cmd = "git log -n1 --pretty=%H";
    my $output = qx($cmd);
    $output =~ s/\s//g;
    return $output;
}

sub git_branch {
    my ($branch) = @_;
    my $cmd = "git branch '$branch'";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_branch_exists {
    my ($branch) = @_;
    my $cmd = "git branch --list '$branch'";
    return qx($cmd);
}

sub git_init {
    my ($path) = @_;
    my $cmd = "git init '$path'";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_config {
    my ($name, $value) = @_;
    my $cmd = "git config '$name' '$value'";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_add {
    my ($list) = @_;
    my $cmd = "git add $list";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_fetch {
    my ($remote) = @_;
    my $cmd = "git fetch '$remote'";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_subtree_add {
    my ($subtree, $commit, $branch) = @_;
    my $cmd = '';
    if($branch) {
        my $remote = $commit;
        $cmd = "git-subtree add --squash --prefix='$subtree' '$remote' '$branch'";
    } else {
        $cmd = "git-subtree add --squash --prefix='$subtree' '$commit'";
    }
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_subtree_merge {
    my ($subtree, $commit) = @_;
    my $cmd = "git-subtree merge --squash --prefix='$subtree' '$commit'";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_subtree_pull {
    my ($subtree, $remote, $branch) = @_;
    my $cmd = "git-subtree pull --squash --prefix='$subtree' '$remote' '$branch'";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_subtree_merged {
    my ($subtree, $commit) = @_;
    my $cmd = "git log --pretty=%H --all-match --grep='git-subtree-split: $commit'";
    if($subtree) {
        $cmd .= " --grep='git-subtree-dir: $subtree'";
    }
    return qx($cmd);
}

sub git_subtree_last {
    my ($subtree) = @_;
    my $cmd = "git log -n1 --grep='git-subtree-dir: $subtree'";
    my $output = qx($cmd);
    $output =~ s/^[\s\S]*git-subtree-split: (\S+)[\s\S]*$/$1/;
    return $output;
}

sub git_subtree_list {
    my ($subtree) = @_;
    my $cmd = "git log --grep='git-subtree-dir: $subtree'";
    my $output = qx($cmd);
    $output =~ s/([\s\S]*?git-subtree-split: (\S+\s)[\s\S]*?)*?/$2/g;
    return split(/\s/, $output);
}

sub git_stash_save {
    my $cmd = "git stash save -u";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub git_stash_pop {
    my $cmd = "git stash pop";
    syslog($cmd);
    system($cmd);
    return $? >> 8;
}

sub init_get_remote_name {
    my ($remote, $rev, $prefix) = @_;
    if(($rev eq "14.07" or $rev eq "15.05" or $rev ge "17.01")
            and $remote eq "openwrt") {
        $remote = "lede";
    }
    if($prefix) {
        return "origin-$remote";
    }
    return $remote;
}

sub init_get_remote_prefix {
    my ($remote) = @_;
    if($remote eq "openwrt"){
        return $remote;
    } else {
        return "feeds/$remote";
    }
}

sub init_get_branch_name {
    my ($rev) = @_;
    return $rev if $rev eq "master";
    $rev =~ s/(\d\d\.\d\d).*/$1/;
    if($rev lt "17.01") {
        return "openwrt-$rev";
    } else {
        return "lede-$rev";
    }
}

sub init_get_remote_branch_name {
    my ($remote, $rev) = @_;
    return $rev if $rev eq "master";
    $rev =~ s/(\d\d\.\d\d).*/$1/;
    if($rev ge "17.01") {
        return "lede-$rev";
    }
    switch("$remote-$rev") {
        case "openwrt-12.09" { return "attitude_adjustment"; }
        case "openwrt-14.07" { return "barrier_breaker"; }
        case "openwrt-15.05" { return "chaos_calmer"; }
        case "luci-14.07" { return "luci-0.12"; }
        else { return "for-$rev"; }
    }
}

sub init_drop_shell {
    $ENV{"PS1"} = 'git\s-\v \#\$';
    if(git_status("fix conflicts")) {
        syslog("please fix conflicts ...");
        system("/bin/bash");
        if($? >> 8 == 1) {
            return 1;
        }
    }
    return 0;
}

sub build_symlink_tree {
    my $destdir = shift @_;
    shell_exec("mkdir -p $destdir") unless -d $destdir;
    shell_exec("mkdir -p $destdir/tmp");
    shell_exec("ln -sf ../../feeds ./openwrt/package/");
    shell_exec("ln -sf ../openwrt/BSDmakefile $destdir/");
    shell_exec("ln -sf ../openwrt/config $destdir/");
    shell_exec("ln -sf ../openwrt/Config.in $destdir/");
    shell_exec("ln -sf ../openwrt/LICENSE $destdir/");
    shell_exec("ln -sf ../openwrt/Makefile $destdir/");
    shell_exec("ln -sf ../openwrt/README $destdir/");
    shell_exec("ln -sf ../openwrt/feeds.conf.default $destdir/");
    shell_exec("ln -sf ../openwrt/include $destdir/");
    shell_exec("ln -sf ../openwrt/package $destdir/");
    shell_exec("ln -sf ../openwrt/rules.mk $destdir/");
    shell_exec("ln -sf ../openwrt/scripts $destdir/");
    shell_exec("ln -sf ../openwrt/target $destdir/");
    shell_exec("ln -sf ../openwrt/toolchain $destdir/");
    shell_exec("ln -sf ../openwrt/tools $destdir/");
    shell_exec("ln -sf ../openwrt/feeds.conf $destdir/") if -f "./openwrt/feeds.conf";
}
sub cmd_help {
    my ($cmd) = @_;
    print "help:\n";
    if($cmd) {
        print "command $cmd is not exists!\n";
    }
}

sub cmd_init {
    my ($debug,$force,$quiet,$stash) = (0) x 4;
    my ($mirror,$destdir,$stop,$pull) = ('') x 4;
    GetOptions(
        "debug|x+"    => \$debug,
        "force|f+"    => \$force,
        "mirror|m=s"  => \$mirror,
        "destdir|d=s" => \$destdir,
        "quiet|q+"    => \$quiet,
        "stop|s=s"    => \$stop,
        "pull|p=s"    => \$pull
    );
    $destdir or $destdir = "phoenix-$$";
    $mirror or $mirror = "github";

    $ENV{'PATH'} = dirname(abs_path($0)) . ":" . $ENV{'PATH'};
    if(not -d "$destdir/.git") {
        git_init($destdir);
    }
    chdir($destdir);
    git_config("merge.renameLimit", 65536);
    if(not git_head()) { 
        mkdir("defconfig");
        file_write(".gitignore", "*.o\n*.orig\n*.rej\n*.swp\n*.log\n.tags\n/build");    
        file_write("README.md", "");    
        file_write("defconfig/.gitignore", "");
        git_add(".gitignore README.md defconfig/.gitignore");
        git_commit(0, "Initialization repository")
    }
    if(not git_status("nothing to commit")) {
        git_stash_save();
        $stash = 1;
    }
    foreach my $dict (@commitlist) {
        my $rev = ${$dict}{"name"};
        my $branch = init_get_branch_name($rev);
        my $checkout = "master";
        my $ok = 0;
        if(git_branch_exists($branch)) {
            $checkout = $branch;
        }
        syslog("rev -> %s", $rev);
        syslog("branch -> %s", $branch);
        git_checkout($checkout);
        my $savepoint = git_head(); 
        syslog("savepoint -> %s", $savepoint);
        foreach my $remote (@remotelist) {
            syslog("remote -> %s", $remote);
            my $prefix = init_get_remote_prefix($remote);
            my $commit = ${$dict}{"dict"}{$remote};
            my $remote2 = init_get_remote_name($remote, $rev, 0);
            my $url = $mirrorlist{$mirror}{$remote2};
            my $remote = init_get_remote_name($remote, $rev, 1);

            next unless $commit and $url;

            syslog("merge [%s] -> %s", $prefix, $commit);

            if(git_subtree_merged($prefix, $commit)) {
                syslog("merged, skip it!");
                next;
            }

            if(git_remote_exists($remote)) {
                git_remote_set_url($remote, $url);
            } else {
                git_remote_add($remote, $url);
            }
            $ok = git_fetch($remote);
            last if $ok;

            $ENV{"GIT_EDITOR"} = "sed -i \"s@\\(Merge commit '[a-f0-9]*'\\).*@\\1 as '$prefix' for '$rev'@\"";
            if(-d $prefix) {
                $ok = git_subtree_merge($prefix, $commit);
                if($ok) {
                    last if init_drop_shell();
                    if(git_status("All conflicts fixed")) {
                        $ok = git_commit(0, "");
                    }
                }
            } else {
                $ok = git_subtree_add($prefix, $commit);
                git_commit(1, "");
            }
            last if $ok;
        }
        if($ok) {
            syslog("subtree merge fail, rollback!");
            git_reset(1, $savepoint);
            last;
        }

        last if $rev eq $stop;

        if($checkout eq "master") {
            git_branch($branch);
        }
    }
    if($pull) {
        my $branch = init_get_branch_name($pull);
        my $ok = 0;
        $pull =~ s/(\d\d\.\d\d).*/$1/;
        syslog("pull branch -> %s", $branch);
        git_checkout($branch);
        my $savepoint = git_head(); 
        syslog("savepoint -> %s", $savepoint);
        foreach my $remote (@remotelist) {
            if($pull eq "14.07" and $remote eq "newpackages") {
                next;
            }
            syslog("remote -> %s", $remote);
            my $prefix = init_get_remote_prefix($remote);
            my $remote2 = init_get_remote_name($remote, "$pull.1", 0);
            my $branch2 = init_get_remote_branch_name($remote, $pull);
            my $url = $mirrorlist{$mirror}{$remote2};
            my $remote = init_get_remote_name($remote, "$pull.1", 1);

            next unless $url;

            syslog("pull [%s]", $prefix);

            if(git_remote_exists($remote)) {
                git_remote_set_url($remote, $url);
            } else {
                git_remote_add($remote, $url);
            }
            $ok = git_fetch($remote);
            last if $ok;

            $ENV{"GIT_EDITOR"} = "sed -i \"s@\\(Merge commit '[a-f0-9]*'\\).*@\\1 as '$prefix' for '$pull+'@\"";
            if(-d $prefix) {
                $ok = git_subtree_pull($prefix, $remote, $branch2);
                if($ok) {
                    last if init_drop_shell();
                    if(git_status("All conflicts fixed")) {
                        $ok = git_commit(0, "");
                    }
                }
            } else {
                $ok = git_subtree_add($prefix, $remote, $branch2);
                git_commit(1, "");
            }
            last if $ok;
        }
        if($ok) {
            syslog("subtree pull fail, rollback!");
            git_reset(1, $savepoint);
        }
    }
    if($stash) {
        git_stash_pop()
    }
}

sub cmd_update {

}

sub cmd_build {
    my ($debug,$force,$quiet,$verbose,$clean) = (0) x 5;
    my ($destdir,$config,$jobs,$mirror,$user,$domain) = ('') x 6;
    GetOptions(
        "debug|x"    => \$debug,
        "force|f"    => \$force,
        "destdir|d=s" => \$destdir,
        "mirror|m=s"  => \$mirror,
        "quiet|q"    => \$quiet,
        "config|c=s"  => \$config,
        "jobs|j=s"    => \$jobs,
        "verbose|v"  => \$verbose,
        "user=s"      => \$user,
        "domain=s"    => \$domain,
        "clean"      => \$clean
    );
    $destdir = "build" unless $destdir;
    $user = "compile" unless $user;
    $domain = "ntcmd.net" unless $domain;
    $jobs = get_sys_processors() unless $jobs;
    my $opt = "@ARGV";
    $opt = "$opt V=99" if $verbose;
    if(not $config) {
        syslog("no config is specified!");
        return 0;
    }
    if($destdir eq ".") {
        syslog("can not build at $destdir!");
        return 0;
    }

    if(not -f "./openwrt/Makefile") {
        syslog("there is no source code here!");
        return 0;
    }

    if(not -f $config) {
        syslog("$config is not exists!");
        return 0;
    }
    if(not $force) {
        pipe(PREAD, PWRITE);
        my $pid = fork();
        if($pid) {
            close PWRITE;
            waitpid($pid, 0);
            do {
                $pid = <PREAD>;
            } while(not $pid);
            close PREAD;
            $pid =~ s/\s$//g;
            shell_exec("tail --pid=$pid -f .build.log");
            return 0;
        } else {
            close PREAD;
            daemon();
            open STDOUT, ">.build.log";
            open STDERR, ">&STDOUT";
            print PWRITE "$$\n";
            close PWRITE;
        }
    }
    if($mirror) {
        $ENV{"DOWNLOAD_MIRROR"} = $mirror;
    } else {
        $ENV{"DOWNLOAD_MIRROR"} = "";
    }
    if($clean) {
        shell_exec("rm -rf $destdir");
        shell_exec("rm -f openwrt/scripts/config/zconf.lex.c");
        shell_exec("rm -f openwrt/scripts/config/mconf_check");
        shell_exec("find openwrt/scripts \\( -name '*.o' -o  -name '*conf' \\) -a -xtype f -delete");
    }
    build_symlink_tree($destdir);
    shell_exec("cp -f $config $destdir/.config");

    shell_exec("sed -i 's#^\\(CONFIG_KERNEL_BUILD_USER=\\).*\$#\\1\"$user\"#' $destdir/.config");
    shell_exec("sed -i 's#^\\(CONFIG_KERNEL_BUILD_DOMAIN=\\).*\$#\\1\"$domain\"#' $destdir/.config");
    shell_exec("sed -i 's#^\\(CONFIG_BINARY_FOLDER=\\).*\$#\\1\"\$(TOPDIR)/release/\$(BOARD)\"#' $destdir/.config");
    shell_exec("sed -i 's#^\\(CONFIG_DOWNLOAD_FOLDER=\\).*\$#\\1\"\$(TOPDIR)/../downloads\"#' $destdir/.config");

    syslog("--------------------------------------------");
    my $t1 = time();
    shell_exec("make  -C $destdir oldconfig");
    shell_exec("make  -C $destdir -j $jobs $opt");
    my $t2 = time();
    syslog("--------------------------------------------");
    my $tx = $t2 - $t1;
    syslog("time=%s", sprintf("%d:%d:%d", int($tx / 3600), int($tx / 60) % 60, $tx % 60));
}

sub cmd_defconfig {
    my ($destdir,$config) = ('') x 2;
    GetOptions(
        "destdir|d=s" => \$destdir,
        "config|c=s"  => \$config
    );
    $destdir = "build" unless $destdir;
    if($destdir eq ".") {
        syslog("can not build at $destdir!");
        return 0;
    }

    if(not -f "./openwrt/Makefile") {
        syslog("there is no source code here!");
        return 0;
    }

    build_symlink_tree($destdir);
    if(-f $config) {
        shell_exec("cp -f $config $destdir/.config");
    } else {
        shell_exec("rm -f $destdir/.config");
    }
    shell_exec("make -C $destdir menuconfig");
    shell_exec("make -C $destdir oldconfig");
    shell_exec("cd $destdir; ./scripts/diffconfig.sh | tee ./tmp/.defconfig.tmp");
}

sub cmd_diffconfig {
    my ($destdir,$config) = ('') x 2;
    GetOptions(
        "destdir|d=s" => \$destdir,
        "config|c=s"  => \$config
    );
    $destdir = "build" unless $destdir;
    if(not $config) {
        syslog("no config is specified!");
        return 0;
    }
    if($destdir eq ".") {
        syslog("can not build at $destdir!");
        return 0;
    }

    if(not -f "./openwrt/Makefile") {
        syslog("there is no source code here!");
        return 0;
    }

    if(not -f $config) {
        syslog("$config is not exists!");
        return 0;
    }
    build_symlink_tree($destdir);
    shell_exec("make -C $destdir defconfig") unless -f "openwrt/scripts/config/conf";
    shell_exec("cp -f $config $destdir/.config");
    shell_exec("cd $destdir; ./scripts/diffconfig.sh | tee ./tmp/.diffconfig.tmp");
}

sub cmd_checklog {
    my ($log, $edit) = (0) x 2;
    my ($destdir) = ("") x 1;
    GetOptions(
        "log|l"    => \$log,
        "edit|e"   => \$edit,
        "destdir|d=s" => \$destdir
    );
    my $f = ".build.log";
    if($log and $edit) {
        syslog("--log|-l can not with --edit|-e !");
        return 0;
    }
    if(not -f $f) {
        syslog("log file is not exists!");
        return 0;
    }
    $destdir = "build" unless $destdir;
    my $text = qx(sed -n -e '/\\*\\*\\* \\[.*\\/\\(compile\\|install\\)\\]/p' $f);
    $text =~ s/.*\*\*\* \[(.*)\/(compile|install)\].*/$1/g;
    my $p = $text;
    $p =~ s/package\/feeds\//feeds\//g;
    print $p;
    $text =~ s/\/host$//g;
    $text =~ s/\n/ /g;
    if(not $text) {
        syslog("no error!");
        return 0;
    }
    if($log) {
        my $l = $text;
        $l =~ s/(\S+)/$destdir\/logs\/$1/g;
        $l = qx(find $l -name '*.txt');
        $l =~ s/\n/ /g;
        system("vim $l");
    } elsif($edit) {
        my $e = $text;
        $e =~ s/(\S+)/openwrt\/$1\/Makefile/g;
        $e =~ s/openwrt\/package\/feeds\//feeds\//g;
        system("vim $e");
    }
}

sub cmd_checklog2 {
    my ($log, $edit) = (0) x 2;
    my ($destdir) = ("") x 1;
    GetOptions(
        "log|l"    => \$log,
        "destdir|d=s" => \$destdir
    );
    if($log and $edit) {
        syslog("--log|-l can not with --edit|-e !");
        return 0;
    }
    $destdir = "build" unless $destdir;
    my $text = qx(grep -E '\\*\\*\\* \\[' -r build/logs/ | awk -F: '{print \$1}');
    print $text;
    $text =~ s/\n/ /g;
    if(not $text) {
        syslog("no error!");
        return 0;
    }
    if($log) {
        system("vim $text");
    }
}


sub main {
    my $cmd = shift @ARGV;
    if(not $cmd){
        cmd_help();
        return 0;
    }
    my $func = "cmd_$cmd";
    $ENV{"LANG"} = "en_US.UTF-8";
    if(__PACKAGE__->can($func)) {
        no strict 'refs';
        &$func(@ARGV);
    } else {
        cmd_help($cmd);
    }
}

main();
