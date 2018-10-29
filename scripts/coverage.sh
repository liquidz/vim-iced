covimerage write_coverage /tmp/vim-profile.txt
coverage xml
bash <(curl -s https://codecov.io/bash)
