#!/bin/bash
set -eu  # Exit on error

#storage_dir=$1
#librispeech_dir=$storage_dir/LibriSpeech
#wham_dir=$storage_dir/wham_noise
#librimix_outdir=$storage_dir/

storage_dir=/floyd/input/librimixx/corpus
librispeech_dir=$storage_dir/LibriSpeech
wham_dir=$storage_dir/wham_noise

sox_storage_dir=sox

librimix_outdir=librimix/

function install_sox() {
    apt-get update && apt-get install -y libsox-dev
    echo "Download sox"
    # If downloading stalls for more than 20s, relaunch from previous state.
    wget -c --tries=0 --read-timeout=20 https://sourceforge.net/projects/sox/files/sox/14.4.2/sox-14.4.2.tar.gz -P $sox_storage_dir
    tar -xzf $sox_storage_dir/sox-14.4.2.tar.gz -C $sox_storage_dir
    rm -rf $sox_storage_dir/sox-14.4.2.tar.gz
    cd $sox_storage_dir/sox-14.4.2
    ./configure
    make -s
    sudo make install
}


function LibriSpeech_dev_clean() {
	if ! test -e $librispeech_dir/dev-clean; then
		echo "Download LibriSpeech/dev-clean into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 http://www.openslr.org/resources/12/dev-clean.tar.gz -P $storage_dir
		tar -xzf $storage_dir/dev-clean.tar.gz -C $storage_dir
		rm -rf $storage_dir/dev-clean.tar.gz
	fi
}

function LibriSpeech_test_clean() {
	if ! test -e $librispeech_dir/test-clean; then
		echo "Download LibriSpeech/test-clean into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 http://www.openslr.org/resources/12/test-clean.tar.gz -P $storage_dir
		tar -xzf $storage_dir/test-clean.tar.gz -C $storage_dir
		rm -rf $storage_dir/test-clean.tar.gz
	fi
}

function LibriSpeech_clean100() {
	if ! test -e $librispeech_dir/train-clean-100; then
		echo "Download LibriSpeech/train-clean-100 into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 http://www.openslr.org/resources/12/train-clean-100.tar.gz -P $storage_dir
		tar -xzf $storage_dir/train-clean-100.tar.gz -C $storage_dir
		rm -rf $storage_dir/train-clean-100.tar.gz
	fi
}

function LibriSpeech_clean360() {
	if ! test -e $librispeech_dir/train-clean-360; then
		echo "Download LibriSpeech/train-clean-360 into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 http://www.openslr.org/resources/12/train-clean-360.tar.gz -P $storage_dir
		tar -xzf $storage_dir/train-clean-360.tar.gz -C $storage_dir
		rm -rf $storage_dir/train-clean-360.tar.gz
	fi
}

function wham() {
	if ! test -e $wham_dir; then
		echo "Download wham_noise into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 https://storage.googleapis.com/whisper-public/wham_noise.zip -P $storage_dir
		unzip -qn $storage_dir/wham_noise.zip -d $storage_dir
		rm -rf $storage_dir/wham_noise.zip
	fi
}

install_sox &
LibriSpeech_dev_clean &
LibriSpeech_test_clean &
LibriSpeech_clean100 &
LibriSpeech_clean360 &
wham &

wait

python /floyd/home/scripts/augment_train_noise.py --wham_dir $wham_dir

for n_src in 2; do
  metadata_dir=metadata/Libri$n_src"Mix"
  python /floyd/home/scripts/create_librimix_from_metadata.py --librispeech_dir $librispeech_dir \
    --wham_dir $wham_dir \
    --metadata_dir /floyd/home/$metadata_dir \
    --librimix_outdir $librimix_outdir \
    --n_src $n_src \
    --freqs 8k \
    --modes min \
    --types mix_clean mix_both
done
