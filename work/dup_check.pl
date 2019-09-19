#!/usr/bin/perl
# This is a quick hack to check if JPGs are in archive
#   (using similarity to accept cropping, sharpening, color fix...)
#
# - collects all files from SRC
# - filter SRC list to get only JPG
# - checks if a file with same filehash exists (if so, it obviously exists)
# - otherwise, symlink to MISSING folder (that contains images
#   that do not binrary wise exist in arc)
# - otherwise, all files with same name (and different filehash) are compared
#   with imagemagick compare metric
# - if metric > 25 (empirically picked value) count as "very similar existing"
#   so produce a state file 0000_A_FOUND
# - if none of the same named files is "very similar", produce a
#   state file 0000_A_MISSING
#
# TODO:
# - avoid comaparing with itself and remove special handling for PSNR==0 (equality)
# - how to evalutate the result / state files?
# - What next? delete existing from MISSING?
# -- maybe first check if all Google Takeout files have at least
#    one instance in a date folder?
# - how to handle result?
#   state file extension bin (bad) because alert-alike icon (VLC),
#   extension .sfv (good) is a green check icon in win 7 explorer
#
# Notes:
#   ARC "/raid1/pics/arc"
#       (the pic archive)
#   SRC "/raid1/pics/GooglePhotos/Takeout/Google Fotos"
#       (from ZIP "D:\01_GooglePhotoDownload")
#   TMP $missingroot="/raid1/pics/GooglePhotos/Takeout/missing/"
#
# Some metrics:
#   Found    54292 Google entries in /raid1/pics/GooglePhotos/Takeout/Google Fotos
#   Found    24105 Google JPGs in /raid1/pics/GooglePhotos/Takeout/Google Fotos
#   Found   102904 ARC entries in /raid1/pics/arc
#   Found    87383 ARC JPGs in /raid1/pics/arc
#   Found    10286 FOUND entries in /raid1/pics/GooglePhotos/Takeout/found
#   Hashed   10286 FOUND entries in /raid1/pics/GooglePhotos/Takeout/found
#   Found    13808 MISSING entries in /raid1/pics/GooglePhotos/Takeout/missing
#   Hashed   13808 MISSING entries in /raid1/pics/GooglePhotos/Takeout/missing
#
#   real    157m16,288s
#   user    94m28,768s
#   sys     25m11,636s

use strict;
use POSIX;
#use utf8;
#use encoding 'utf8';
use File::Basename;
#use Digest::MD5 qw(md5_hex);

binmode(STDERR, ':utf8' );
binmode(STDOUT, ':utf8' );
select(STDERR); $| = 1;
select(STDOUT); $| = 1;
#print "I owe you \N{U+20AC}160\n";


my $filelist = "/raid1/pics/GooglePhotos/Takeout/files.txt";
my $googleroot = "/raid1/pics/GooglePhotos/Takeout/Google Fotos";
my $arcroot = "/raid1/pics/arc";

# These two must be direct subdirs of GooglePhotos/Takeout/:
my $missingroot = "/raid1/pics/GooglePhotos/Takeout/missing";
my $foundroot = "/raid1/pics/GooglePhotos/Takeout/found";
my $outputroot =  "/raid1/pics/GooglePhotos/Takeout/check_result";

# Recursively finds files such as JPGs
sub findFiles($)
{
    my $path = shift;
    my $handle;
    # We use "find */" to "follow first-level symlinks"
    open $handle, "-|:encoding(UTF-8)", "cd '$path' && find */ -type f"
      or die "Could pipe find in '$path;': $!\n";
    chomp(my @images = <$handle>);
    close $handle
      or die "Don't care error while closing pipe find in '$path': $!\n";
    return @images;
}

# Filter off all known non-Jpgs (i.e. keep Jpg and unknown)
sub filterJpg($)
{
    my $inlist = shift;
    my @jpgs = @${inlist};

    @jpgs = grep { !/.(json|mp4|mts|m4v|mov|avi|bin)$/i } @jpgs;
    @jpgs = grep { !/.(par2|db|db.1|db.2|info|info.1|cr2|tmp|thm|ini|cpt|7z|log|zip|tps|xmp|putt|pspimage|rss|hdr)$/i } @jpgs;
    @jpgs = grep { !/.(gif|png|pdf|psd|webp)$/i } @jpgs;
    @jpgs = grep { !/descript.ion(.1)?|Online.url anzeigen$/i } @jpgs;
    # Some strange webp files without extension, like "./2019-04-04/13.07(1).14 - 1"
    @jpgs = grep { !/\/\d\d[.]\d\d([(]\d+[)])?[.]\d\d - [123]$/i } @jpgs;
    # Test: remove jpgs
    #@jpgs = grep { !/.(jpg|jpeg)$/i } @jpgs;
}

sub getJsonDate($)
{
  my $filename = shift;
  my $fallback = "";
  # use a fast line processing hack for our specific format:
  #   "photoTakenTime": {
  #       "timestamp": "1450924625",
  #       "formatted": "24.12.2015, 02:37:05 UTC"
  #   }
  if (! -e $filename) {
    # print "no $filename\n";
    my $originalname = $filename;
    my $fbname = $filename;
    # edited files sometime (?) have no .json, try to use the one
    # of the unedited orignal file instead.
    # IMG_20130811_202331_522-bearbeitet.jpg -> IMG_20130811_202331_522.jpg.json
    # I think these are google photos bugs:
    #   IMG_20130811_202331_522(1).jpg -> IMG_20130811_202331_522.jpg(1).json
    #   DSC_0026(1).JPG.json -> DSC_0026.JPG(1).json
    #   DSC_0045-EFFECTS-bearbeitet(1).jpg -> DSC_0045-EFFECTS.jpg(1).json
    #   2014-01-23.jpg -> 2014-01-23.json (in album 2014-01-23)
    #   download_20140927_224311(1).jpeg -> download_20140927_224311.jpeg.json
    #   Then the few in 2018-05-04 (see below)
    {
      $fbname =~ s/-bearbeitet((\(\d\))?.jpg.json)$/$1/;
      if (-e $fbname) {
        $fallback = "(direct fallback)";
        $filename = $fbname;
      }
      if (!-e $filename) {
        # special handling for cases like:
        #    FILE0142-bearbeitet.jpg FILE0142.JPG.json
        my $altfb = $fbname;
        $altfb =~ s/.jpg.json$/.JPG.json/g;
        if (-e $altfb) {
          $filename = $altfb;
          $fallback = "(JPG fallback)";
        }
      }
      if (!-e $filename) {
        # special handling for cases like:
        #    DSC_0045-EFFECTS-bearbeitet(1).jpg -> DSC_0045-EFFECTS.jpg(1).json
        #    DSC_0026(1).JPG.json -> DSC_0026.JPG(1).json
        #    2019-03-23(19).jpg -> 2019-03-23.jpg(19).json
        my $altfb = $fbname;
        $altfb =~ s/(\(\d\d?\)).(jpg|JPG).json$/.$2$1.json/g;
        if (-e $altfb) {
          $filename = $altfb;
          $fallback = "(jpg(1).json fallback)";
        } else {
          # print "no altfb = $altfb\n";
        }
      }
      if (!-e $filename) {
        # special handling for cases like:
        #    download_20140927_224311(1).jpeg -> download_20140927_224311.jpeg.json
        my $altfb = $fbname;
        $altfb =~ s/(\(\d\)).jpeg.json$/.jpeg.json/g;
        if (-e $altfb) {
          $filename = $altfb;
          $fallback = "(jpeg(1).json removal fallback)";
        } else {
          #print "removal no altfb = $altfb\n";
        }
      }
      if (!-e $filename) {
        # special handling for cases like:
        #    2014-01-23.jpg -> 2014-01-23.json
        my $altfb = $fbname;
        $altfb =~ s/.jpg.json$/.json/g;
        if (-e $altfb) {
          $filename = $altfb;
          $fallback = "(no jpg fallback)";
        }
      }
      if (!-e $filename) {
        # special handling for cases like:
        #    cartoon-yeah-shout-hand-drawn-illustration-retr(1).jpg ->
        #    cartoon-yeah-shout-hand-drawn-illustration-ret.json
        #    yeah-comic-speech-bubble-cartoon-art-illustrati(2).jpg
        #    yeah-comic-speech-bubble-cartoon-art-illustrat.json
        #    5914dfe9116a17da226ce063b50273aa--fun-quotes-qu.jpg
        #    5914dfe9116a17da226ce063b50273aa--fun-quotes-q.json
        #    Screenshot_20190803-122038_Package installer.jpg
        #    Screenshot_20190803-122039_Package installer.j.json
        #    Screenshot_20190820-130145_Scanner [REDACTED].jpg
        #    Screenshot_20190820-130145_Scanner [REDACTED]..json
        #    schnellschuss_1510508_675781009190002_300210882.jpg
        #    schnellschuss_1510508_675781009190002_30021088.json
        #    IMG_2467_std1_extra_makeup_crop_right_light_vog.jpg
        #    IMG_2467_std1_extra_makeup_crop_right_light_vo.json
        #    VVS-Vertical-Video-Syndrome-Ellis-Benus-Web-Des.jpg
        #    VVS-Vertical-Video-Syndrome-Ellis-Benus-Web-De.json
        #  maybe some strange length limit?
        my $altfb = $fbname;
        my $basenamestr = basename($fbname);
        my $basenameshort = $basenamestr;
        #my $maxlenstr = "cartoon-yeah-shout-hand-drawn-illustration-ret";
        my $maxlenstr = "yeah-comic-speech-bubble-cartoon-art-illustrat";
        if (length($basenameshort) > length($maxlenstr)) {
          $basenameshort = substr($basenameshort, 0, length($maxlenstr));
          # print "from $fbname to\n"
          #     . " via $basenamestr\n"
          #     . "  to $basenameshort\n"
          #     . " max $maxlenstr\n";
        }
        $altfb =~ s/(\Q$basenameshort\E).*.json$/$1.json/g;
        if (-e $altfb) {
          $filename = $altfb;
          $fallback = "(length limit fallback)";
        } else {
          #print "no length limit altfb = $altfb\n";
        }
      }
      if (!-e $filename) {
        my $shortfb = $filename;
        $shortfb =~ s/\Q$googleroot\E\///;
        print "no fallbacks for $shortfb\n"
            . " fbname = $fbname\n";
      } else {
        my $shortorg = $originalname;
        $shortorg =~ s/\Q$googleroot\E\///;
        my $shortfb = $filename;
        $shortfb =~ s/\Q$googleroot\E\///;
        #print "trying $shortfb\n"
        #    . "   for $shortorg\n";
      }
    }
  }
  open(JSON, '<:encoding(UTF-8)', $filename) or die "Cannot read '$filename': $!\n";
  my @lines = <JSON>;
  close(JSON);
  my $inPhotoTakenTime = 0;
  foreach my $line (@lines) {
    chomp $line;
    # print "line $line\n";
    if (!$inPhotoTakenTime) {
      next if $line !~ m/photoTakenTime/;
      $inPhotoTakenTime = 1;
      next;
    } else {
      if ($line =~ m/\}/) {
        $inPhotoTakenTime = 0;
        next;
      }
      if ($line =~ m/"timestamp": "(\d+)"/) {
        my $takenTime = $1;
        my $shortfn = $filename;
        $shortfn =~ s/\Q$googleroot\E\///;
        my $gmtime = strftime("%Y-%m-%d %H:%M:%S", gmtime($takenTime));
        # print "  JSON gmtime = $gmtime from takenTime = $takenTime\n"
        #     . "   for $shortfn $fallback\n";
        return $takenTime;
      }
    }
  }
}

my @gimages = findFiles($googleroot);
printf "Found %8d Google entries in $googleroot\n", $#gimages + 1;
@gimages = filterJpg(\@gimages);
# renumbered inside, checked manually (OK)
@gimages = grep { !/^2015_12_09\//i } @gimages;
printf "Found %8d Google JPGs in $googleroot\n", $#gimages + 1;
# Note: "2013-12-31-", "2013-12-31 -", "2013-12-31 -  #2" etc.
#   are per-date backup folders (Google Photos mobile upload)
#   They may have duplicates in other folders (created albums).
#   Images from other folders don't need to be here (if not a
#   mobile backup photo was used, but an album e.g. uploaded)

#open T, ">/tmp/f4.lst";
#print T join("\n", @gimagebases), "\n";
#close T;

# Create by-name index to lookup takenTime for google
my $gimagedate_by_fn = {};
foreach my $pickedfull (@gimages) {
  my $gpath = $googleroot . "/" . $pickedfull;
  #$gpath = Encode::decode_utf8( $gpath );
  my $takentime = getJsonDate($gpath . ".json");
  my $show = 0;
  if (exists $gimagedate_by_fn->{$pickedfull}) {
    die "ALREADY HASHED $pickedfull\n";
  }
  #if ($gimage =~ m/IMG_1077.jpg/) { $show = 1; }
  $gimagedate_by_fn->{$pickedfull} = $takentime;
}
printf "Hashed%8d Google for timestamps in $googleroot\n", scalar keys %$gimagedate_by_fn;



my @arcimages = findFiles($arcroot);
printf "Found %8d ARC entries in $arcroot\n", $#arcimages + 1;
@arcimages = filterJpg(\@arcimages);
printf "Found %8d ARC JPGs in $arcroot\n", $#arcimages + 1;

sub addArcByFn($$$)
{
  my $arc_by_fn = shift; # struct
  my $lcfile    = shift; # key
  my $arcimage  = shift; # relative path
  my $show = 0;
  if (!exists $arc_by_fn->{$lcfile}) {
    $arc_by_fn->{$lcfile} = [];
  } else {
    # Normally we find each arc file twice: once by name and once
    # by timestamp. We might already have the path added.
    foreach my $arcmatch (@{$arc_by_fn->{$lcfile}}) {
      if ($arcmatch->{path} eq $arcimage) {
        # print "Already having arc_by_fn for lcfile = $lcfile\n";
        return;
      }
    }
    # If the same path does not exist it means we have the same basename
    # in a different path (and have to add it), such as:
    # 2008_09_13/IMG_0001.JPG, 2010_04_24/IMG_0001.JPG, 2013_08_11/IMG_0001.jpg
    # $show = 1;
  }
  #if ($lcfile eq lc("IMG_1077.jpg")) { $show = 1; }
  # We expect that we have to check each file twice, so lets allowing store
  # hash too, but calc on demand only (i.e. cache file hashes)
  push @{$arc_by_fn->{$lcfile}}, { path => $arcimage };
  if ($show) {
    use Data::Dumper;
    print Data::Dumper->Dump( [$arc_by_fn->{$lcfile}], ["add_arcimages_$lcfile"] );
  }
}

my $arc_by_fn = {};
# this processing takes > 500ms!
foreach my $arcimage (@arcimages) {
  addArcByFn($arc_by_fn, lc(basename($arcimage)), $arcimage);
}
printf "Hashed%8d ARC lookup by same name\n", scalar keys %$arc_by_fn;

# Create by-date index for arc as helper to find images with
# matching timestamp
my $arcimgage_by_date = {};
foreach my $arcimage (@arcimages) {
  my $arcpath = $arcroot . "/" . $arcimage;
  #$arcpath = Encode::decode_utf8( $arcpath );
  my @stat = stat($arcpath) or die "cannot stat '$arcpath': $!\n";
  my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
        $atime, $mtime, $ctime, $blksize, $blocks) = @stat;
  my $gmtime = strftime("%Y-%m-%d %H:%M:%S", gmtime($mtime));
  # print "file = $arcimage\n"
  #    . "  with gmtime = $gmtime, mtime = $mtime, ctime = $ctime\n";
  my $filedate=$mtime;
  my $show = 0;
  if (!exists $arcimgage_by_date->{$filedate}) {
    $arcimgage_by_date->{$filedate} = [];
  } else {
    # $show = 1; # TODO debug
  }
  #if ($arcimage =~ m/IMG_1077.jpg/) { $show = 1; }
  #if ($arcimage =~ m/DSC_2895.JPG/) { $show = 1; }
  push @{$arcimgage_by_date->{$filedate}}, { path => $arcimage, filedate => $filedate };
  if ($show) {
    use Data::Dumper;
    $Data::Dumper::Indent = 1; # simple ident
    print Data::Dumper->Dump( [$arcimgage_by_date->{$filedate}], ["add_arcimgage_by_date_$filedate"] );
  }
  #sleep 1;
}
printf "Hashed%8d ARC timestamps in $arcroot\n", scalar keys %$arcimgage_by_date;

# associate files by timestamps
# we need to consider wrong timezone (e.g. UTC vs. CEST), a jitter of few seconds,
#   and that we have many series with closely following flase
#   positives
# TODO  push @{$arc_by_fn->{$lcfile}}, { path => $arcimage }; or new?
my $arc_by_fn_name_count = scalar keys %$arc_by_fn;
{
  my $matches = 0;
  my $nomatches = 0;

  #  '0' => 5422,
  #  '1' => 4071,
  # '-1' => 1967,
  # '-2' =>  887,
  #  '2' => 1860,
  # '-3' =>  954,
  #  '3' => 1130
  #  '4' =>  864, # manually checked: filenames differ (1 exception?)
  # '-4' =>  827, # manually checked: filenames differ
  #  '5' =>  873, # manually checked: filenames differ
  # '-5' =>  790, # manually checked: filenames differ
  my @jitters = qw( 0 1 -1 2 -2 3 -3 );

  #       '0' => 12850, # "2016-08-12" 0 1 "2016-08-19" 3
  #    '3600' =>  2588, # "2013_03_16.tmp", "2016-10-01", many others look reasonable
  #   '-3600' =>  1872  # "2010_11_27 Klappe Die Erste" 0 -1, "2012_07_02" 3 4
  #    '7200' =>   353, # manually checked: filenames differ
  #   '-7200' =>  1447, # "2010_11_27 Klappe Die Erste"  (again!) 0 -1 "24.04.2010" 1
  #   '10800' =>   292, # manually checked: filenames differ
  #  '-10800' =>   243, # manually checked: filenames differ
  my @zones   = qw( 0 3600 -3600 -7200 );

  my $jitter_stats = {};
  my $zone_stats = {};
  my $jitter_sum_stats = {};
  my $allmatches = 0;
  my $truepos = 0;
  my $falsepos = 0;
  foreach my $gfilename (@gimages) {
    my $takenTime = $gimagedate_by_fn->{$gfilename};
    my $falseposcheck = 0;
    my $gfilebasename = basename($gfilename);
    {
      # If we have such a stem and if does NOT match it is likely
      # a false positive
      if ($gfilebasename =~ m/^(DSC.\d\d\d\d|IMG_\d\d\d\d|FILE\d\d\d\d)/) {
        $falseposcheck = 1;
      }
    }
    my $foundit = 0;
    foreach my $zone (@zones) {
      foreach my $jitter (@jitters) {
        my $lookuptime = $takenTime + $zone + $jitter;
        if (exists $arcimgage_by_date->{$lookuptime}) {
          $jitter_stats->{$jitter}++;
          $zone_stats->{$zone}++;
          $jitter_sum_stats->{$zone + $jitter}++;
          $allmatches++;
          if (!$foundit) {
            # print "For GFILE $gfilename with lookuptime = $takenTime\n";
            # " there are ", $#arcinfos + 1, " matches:\n";
            $foundit = 1;
          }
          {
            my $arcinfo_r = $arcimgage_by_date->{$lookuptime};
            my @arcinfos  = @$arcinfo_r;
            foreach my $arcinfo (@arcinfos) {
              my $path = $arcinfo->{path};
              # if first 8 chars are DSC or IMG but do NOT match,
              # its likely a false positive
              # printf " - %5d %2d: %s\n", $zone, $jitter, $path;
              if ($falseposcheck) {
                my $arcbasename = basename($path);
                if ($arcbasename =~ m/^(DSC.\d\d\d\d|IMG_\d\d\d\d|FILE\d\d\d\d)/) {
                  my $gstem = substr($gfilebasename, 0, 8);
                  my $astem = substr($arcbasename, 0, 8);
                  if ($gstem ne $astem) {
                    # these make no sense to check, false positive
                    # print "  POS FALSE gstem = $gstem, astem = $astem\n";
                    $falsepos++;
                    if ($zone + $jitter == 0) {
                      print "  POS EXACT FALSE: $gfilename -> $path\n";
                    }
                  } else {
                    # These are positives. Mostly already
                    # included in $arc_by_fn, but we can have
                    # postfixes (such as DSCF1470_small.jpg)
                    $truepos++;
                    # print "  POS positive gstem = $gstem, astem = $astem\n";
                    # check if already marked. Note that we use
                    # the Google filename as lookup key (lcfile).
                    addArcByFn($arc_by_fn, lc(basename($gfilename)), $path);
                  }
                } else {
                  # these include the "renamed for import"
                  addArcByFn($arc_by_fn, lc(basename($gfilename)), $path);
                  # print "  POS none arcbasename = $arcbasename, gfilebasename = $gfilebasename\n";
                }
              } else {
                addArcByFn($arc_by_fn, lc(basename($gfilename)), $path);
                # print "  POS none gfilebasename = $gfilebasename\n";
              }
            }
          }
        }
      }
    }
    $nomatches++ unless ($foundit);
  }
  printf "Found %8d timestamp matches (%d missed, %d likely, %d unlikely)\n",
    $allmatches, $nomatches, $truepos, $falsepos;
  # print Data::Dumper->Dump([ $jitter_stats, $zone_stats, $jitter_sum_stats ]);
}
my $arc_by_fn_name_and_timestamp_count = scalar keys %$arc_by_fn;
printf "Hashed%8d new ARC lookup by only timestamp (%d total lookups)\n",
  $arc_by_fn_name_and_timestamp_count - $arc_by_fn_name_count,
  $arc_by_fn_name_and_timestamp_count;
die "debug\n";

#{
#    use Data::Dumper;
#    print Data::Dumper->Dump( [$arc_by_fn->{"img_1077.jpg"}], ["img_1077"] );
#}

# Prefix-block instead use of "foreach my $pickedfull (@gimages)":
#for (my $n=1; $n<100; $n++) {
#  my $pickidx = int(rand($#gimages + 1));
#  my $pickedfull = $gimages[$pickidx];
#  # $pickedfull = "Silvester 2012/IMG_0113.JPG";
#  #$pickedfull = "2018-08-18/DSC_0003.JPG";
#  #$pickedfull = "2015_12_09/IMG_1077.jpg";
#  # printf "Picked %8d = %s\n", $pickidx, $googleroot . "/" . $pickedfull;
#}

my $pickidx=-1; # counter for array index (compat to old log messages)
foreach my $pickedfull (@gimages) {
  $pickidx++;
  # TODO debug shortcut:
  # next if ($pickedfull =~ m/Klappe.Die.Erste/);
  if (0) {
    print "DEBUG SHORTCUT: assuming being done with checking\n";
    last;
  }

  my $gpath = $googleroot . "/" . $pickedfull;
  my ($ghash, $rest) = split /\s+/, `md5sum '$gpath'`;
  my $picked=basename($pickedfull);
  my $lcfile = lc($picked);

  my $jpgid = $pickedfull;
  $jpgid =~ tr|a-zA-Z0-9_# .-|!|c;
  $jpgid =~ tr| |_|;

  # printf "Picked #%8d: %s (%s)\n", $pickidx, $pickedfull, $ghash;
  my $found = 0;
  if (exists $arc_by_fn->{$lcfile}) {
    #use Data::Dumper;
    #print Dumper $arc_by_fn->{$lcfile};

    my $arcmatches =  $arc_by_fn->{$lcfile};
    foreach my $arcmatch (@$arcmatches) {
       my $path = $arcroot . "/" . $arcmatch->{path};
       if (!exists ($arcmatch->{md5sum})) {
         # 62620688f7c28517e5e5e88788ab9abb  /raid1/pics/arc/2016/2016_07_29/DSC_0003.JPG
         my ($sum, $rest) = split /\s+/, `md5sum '$path'`;
         $arcmatch->{md5sum} = $sum;
       }
       if ($arcmatch->{md5sum} eq $ghash) {
         $found = $arcmatch;
       }
    }

    #use Data::Dumper;
    #print Dumper $arc_by_fn->{$lcfile};
  }

  {
    print `[ -d '$missingroot' ] || mkdir '$missingroot'`;
    print `[ -d '$foundroot' ] || mkdir '$foundroot'`;
  }
  if ($found) {
    #use Data::Dumper;
    #print Dumper $found, "found";
    printf "+++ %8s: #%7d %s\n", "Found", $pickidx, $pickedfull;
    print `ln -fs '../Google Fotos/$pickedfull' '$foundroot/equal_$jpgid'`;
  } else {
    if (exists $arc_by_fn->{$lcfile}) {
      my $samenamecount = $#{$arc_by_fn->{$lcfile}} + 1;
      my $samestr = sprintf "Name %3d", $samenamecount;
      printf "  = %8s: #%7d %s\n", , $samestr, $pickidx, $pickedfull;
      if (0) {
        printf "xxx %d -> %d -> %s\n", $#{$arc_by_fn->{$lcfile}}, $samenamecount;
        use Data::Dumper;
        print Data::Dumper->Dump( [$arc_by_fn->{$lcfile} ], ["lcfile"] );
        die "end"
      }
      my $destdir=$missingroot . "/tmp_$jpgid";
      $destdir =~ s/.jpe?g$//i;
      print `[ -d '$destdir' ] || mkdir '$destdir'`;
      print `ln -fs '../../Google Fotos/$pickedfull' '$destdir/0000_GooglePhotos__$jpgid'`;
      foreach my $arcmatch (@{$arc_by_fn->{$lcfile}}) {
        my $path = $arcroot . "/" . $arcmatch->{path};
        my $dest = $arcmatch->{path};
        $dest =~ tr|a-zA-Z0-9_.-|!|c;
        #print "$picked  --> $dest\n";
        `ln -fs '$path' '$destdir/arc_$dest'`;
      }
      {
        if (1) {
          # [ -d t ] || mkdir t
          # rm -f DIFF_*.JPG;
          # mogrify -path t -thumbnail 128x128 *.JPG
          # for i in *JPG ; do
          #   # compare -metric PSNR 0000_*.JPG "$i" "DIFF_$i";
          #   echo "$i:" ;
          #   r=$(compare -metric PSNR 0000_*.JPG "$i" "DIFF_$i" 2>&1);
          #   ret=$?;
          #   echo "RESULT: $ret ($r)";
          #   echo; echo;
          # done
          # 2:
          # rm -f DIFF_*.JPG; for i in *JPG ; do echo "$i:" ; r=$(compare -metric PSNR 0000_*.JPG "$i" "DIFF_$i" 2>&1); ret=$?; rf=$( LC_ALL=C printf "%07.2f" $r 2>/dev/null) ; echo "RESULT: $ret --> $rf ($r))"; mv  "DIFF_$i"  "DIFF_${rf}_${i}" ; echo; echo; done
          # 3:
          # rm -f *_DIFF_*.JPG; for i in *JPG ; do echo "$i:" ; r=$(compare -metric PSNR "$i" 0000_*.JPG "tmp_DIFF_$i" 2>&1); ret=$?; rf=$( LC_ALL=C printf "%07.2f" $r 2>/dev/null) ; echo "RESULT: $ret --> $rf ($r))"; mv  "tmp_DIFF_$i"  "JPG_DIFF_${rf}_${i}" ; echo; echo; done

          # diff in PSNR is "similarity", >= 25 is "same" for us
          # NOTE: state file extension bin (bad) because
          # alert-alike icon (VLC), extension .sfv (good) is a green check icon
          # in win 7 explorer
          # TODO NOTE: we ignore the 11 -iname '*jpeg' files for now!
          print `
            cd '$destdir';
            [ -d tmp ] || mkdir tmp;
            mogrify -path tmp -thumbnail 128x128 -auto-orient *.[Jj][Pp][Gg];
            cd tmp;
            pwd;
            rm -f *_DIFF_*.JPG 0000_A_FOUND* 0000_A_MISSING*;
            touch 0000_A_MISSING.bin;
            for i in *[Jj][Pp][Gg]; do
              echo "Analysing \$i:";
              r=\$(compare -metric PSNR "\$i" 0000_*.[Jj][Pp][Gg] "tmp_DIFF_\$i" 2>&1);
              ret=\$?;
              echo "ret=\$ret, r=\$r";
              if [ \$ret -eq 0 ] ; then
                echo "FOUND SAME";
                mv "tmp_DIFF_\$i" "JPG_DIFF_\${rf}_\${i}";
              elif [ \$ret -eq 1 ] ; then
                rf=\$( LC_ALL=C printf "%06.2f" \$r 2>/dev/null);
                ri=\${r%%.*};
                echo "RESULT: \$ret --> \$rf (\$r) --> \$ri";
                mv "tmp_DIFF_\$i" "JPG_DIFF_\${rf}_\${i}";
                if [ "\$ri" -gt 25 ] ; then
                  echo "FOUND (with \$r)!";
                  rm -f 0000_A_MISSING.bin;
                  touch 0000_A_FOUND_\${rf}_\${i}.sfv;
                else
                  echo "NOT_FOUND (with \$r)";
                fi
              else
                echo "UNCOMPARABLE (\$ret:\$r)";
              fi
              echo; echo;
            done;
            cp -a 0000_A_* ..;
          `;
          # If missing in form "different versions exist only",
          # then add link in missing directory as well:
          {
            my @a_missing = glob("$destdir/0000_A_MISSING*");
            my @a_found = glob("$destdir/0000_A_FOUND*");
            if (@a_missing) {
              print `ln -fs '../Google Fotos/$pickedfull' '$missingroot/diff_$jpgid'`;
            } elsif (@a_found) {
              print `ln -fs '../Google Fotos/$pickedfull' '$foundroot/same_$jpgid'`;
            } else {
              print "$destdir/0000_A_MISSING*\n";
              print @a_missing, "\n";
              print "glob=", glob("$destdir/0000_A_MISSING*"), "\n";
              print "$destdir/0000_A_FOUND*\n";
              print @a_found, "\n";
              print "glob=", glob("$destdir/0000_A_FOUND*"), "\n";
              die "neither found nor missing: $destdir\n";
            }
          }
        }
      }
    } else {
      printf "--- %8s: #%7d %s\n", "Missing", $pickidx, $pickedfull;
      print `ln -fs '../Google Fotos/$pickedfull' '$missingroot/none_$jpgid'`;
    }
  }
  # die "debug end\n";
}


# Now present the output somehow.
# Assume results in "found" and "missing" in form of symlinks
{
  # Read in found root. Note: unfortunately, we did not rename
  # direct found matches and thus they are maybe not unique.
  my %found_gfiles = ();
  if (1) {
    {
      my @found;
      @found = glob("$foundroot/*.[Jj][Pp][Gg]");
      printf "Found %8d FOUND entries in $foundroot\n", $#found + 1;
      foreach my $found (@found) {
        my $dest = readlink($found);
        # we now our filesystem is UTF-8 and thus is readlink result:
        $dest = Encode::decode_utf8( $dest );
        #print "LINK: $found -> $dest\n";
        $dest =~ s/^..\/Google Fotos\///;
        my $gfile = $googleroot . "/" . $dest;
        if (!-e $gfile) {
          die "file not found $gfile\n";
        } else {
          #print "GFILE: $gfile\n";
        }
        # ($dest=~m/FILE0273/) && print "HASH: $dest -> $found\n";
        if (exists $found_gfiles{$dest}) {
          die "ALREADY HASHED $dest -> $found\nas $found_gfiles{$dest}\n";
        }
        $found_gfiles{$dest} = $found;
        #die "debug\n";
      }
    }
    printf "Hashed%8d FOUND entries in $foundroot\n", scalar keys %found_gfiles;
  }

  # Read in missing files
  my %missing_gfiles = ();
  if (1) {
    {
      my @missing;
      @missing = glob("$missingroot/*.[Jj][Pp][Gg]");
      printf "Found %8d MISSING entries in $missingroot\n", $#missing + 1;
      foreach my $missing (@missing) {
        my $dest = readlink($missing);
        # we now our filesystem is UTF-8 and thus is readlink result:
        $dest = Encode::decode_utf8( $dest );
        $dest =~ s/^..\/Google Fotos\///;
        my $gfile = $googleroot . "/" . $dest;
        #print "LINK: $missing -> $dest\n";
        if (!-e $gfile) {
          die "file not found $gfile\n";
        } else {
          #print "GFILE: $gfile\n";
        }

        #print "HASH: $dest -> $missing\n";
        if (exists $missing_gfiles{$dest}) {
          die "ALREADY HASHED $dest -> $missing\nas $missing_gfiles{$dest}\n";
        }
        $missing_gfiles{$dest} = $missing;
        #die "debug\n";
      }
    }
    printf "Hashed%8d MISSING entries in $missingroot\n", scalar keys %missing_gfiles;
  }

  print `[ -d '$outputroot' ] || mkdir '$outputroot'`;
  my $pickidx = -1; # counter for array index (compat to old log messages)
  my $foundcount = 0;
  my $missingcount = 0;
  foreach my $pickedfull (@gimages) {
    # TODO debug shortcut:
    #next if ($pickedfull =~ m/Klappe.Die.Erste/);
    # TODO NOTE: we ignore the 11 -iname '*jpeg' files for now!
    next if ($pickedfull =~ m/.jpeg$/);
    if (0) {
      print "DEBUG SHORTCUT: assuming being done with postprocessing\n";
      last;
    }
    # DEBUG:
    #last if ($pickidx > 10);

    $pickidx++;
    my $gpath = $googleroot . "/" . $pickedfull;
    #print "pickedfull = $pickedfull\n";

    # replicate structure for JPGs
    {
      my $destdir = $outputroot . "/" . dirname($pickedfull);
      my $destfile = $outputroot . "/" . $pickedfull;
      print `[ -d '$destdir' ] || mkdir '$destdir'`;
      print `ln -fs '$gpath' '$destdir'`;
      if (exists $missing_gfiles{$pickedfull}) {
        $missingcount++;
        print `touch '$destfile'.bin`;
        #print "  is missing ($missing_gfiles{$pickedfull})\n";
      } elsif (exists $found_gfiles{$pickedfull}) {
        $foundcount++;
        print `touch '$destfile'.sfv`;
        #print "  was found  ($found_gfiles{$pickedfull})\n";
      } else {
        print "  neither found or missing: $pickedfull\n";
        print `ls -l '$gpath'`;
        #print `md5sum '$gpath'`;
        print `md5sum '$googleroot/$pickedfull'`;
        die "  neither found or missing: $pickedfull\n";
      }
    }

  }
  print "postprocess done, found = $foundcount, missing = $missingcount\n";
}



####
#
# wrong file name
# 0000_GooglePhotos__2015_12_09!IMG_1077.jpg
#     --> D:\av\pics\arc\2015\2015_12_10\IMG_0047.JPG
# new numbering for D:\av\pics\arc\GooglePhotos\Takeout\Google Fotos\2015_12_09
#
# MISSING RUN 1
#   0000_GooglePhotos__2019-07-18!DSC_0160.JPG
#     -> hole in date range!
#
#   0000_GooglePhotos__2019-07-20!DSC_0276.JPG
#     -> hole in date range!
#
#   0000_GooglePhotos__Reise!nach!Ungarn!und!Tschechien!DSC_2131.JPG
#     -> diffrent of same day 2017!2017_09_22!DSC_2131.JPG
#     -> similar of same day IMG_9949.JPG
#
#   0000_GooglePhotos__2015_10_31_Abitreffen_Jan_Wehrmann!DSC04093.JPG
#     -> maybe foreign
#
#   OK 0000_GooglePhotos__2017-03-25!DSCF2652.JPG
#   OK   -> fremde kamera
#   OK   -> from_others/2017_03_25_Hochzeitsfeier/Hochzeit_von_Gordon_K/DSCF2652.JPG
#
#   OK 0000_GooglePhotos__2017_03_09_ski!IMG_0002_1.JPG
#   OK   -> D:\av\pics\arc\2017\2017_03_11\DSC01640.JPG
#
#   OK 0000_GooglePhotos__2019-03-16!IMG_0018.JPG
#   OK   -> D:\pics\2019_03_17\DSC01712.JPG
