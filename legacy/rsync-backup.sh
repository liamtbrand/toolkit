# rsync -naruvz --rsh='ssh -p25566' src frozen@bayview.liamtbrand.com:/home/LaCie/dest

rsync \
    --dry-run \
    --archive \
    --compress \
    --rsh='ssh -p25567' \
    --human-readable \
    --progress \
    --exclude=wikipedia_en_all_maxi_2020-11.zim \
    "$(pwd)" \
    frozen@bayview.liamtbrand.com:/home/LaCie/