for dir in ./charts/*; do
    helm package $dir -d build/
done

helm repo index ./
