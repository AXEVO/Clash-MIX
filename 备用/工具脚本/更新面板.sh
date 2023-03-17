cd /data/clash/dashboard  
rm -rf gh-pages.zip
wget https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip
unzip gh-pages.zip
rm -rf dist
rm -rf gh-pages.zip
mv Yacd-meta-gh-pages dist