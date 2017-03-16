ORIGIN=${ORIGIN:-moretea}

set -e

cd k8s-hab-sup-bootstrap
echo "buillding & upoading"
time hab pkg build -R . 

pkg_ident=$(cat results/last_build.env | grep "pkg_ident" | awk -F '=' ' { print $2 }')

# Export it to docker, and load it into minikube
#time sudo hab studio run hab pkg export docker $pkg_ident

cd ..

# Adding the extra layer required, see README.md
cd docker
sed -e "s/@ORIGIN@/$ORIGIN/" < Dockerfile.template > Dockerfile
docker build -t $ORIGIN/k8s-sup-bootstrap-init --build-arg pkg_ident="$pkg_ident" .
