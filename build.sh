#!/usr/bin/env zsh
bundle exec jekyll build --destination gh-pages/docs
touch gh-pages/docs/.nojekyll
cp CNAME gh-pages/docs
rm gh-pages/docs/build.sh
cd gh-pages
git add -A
git commit -m "build"
git push