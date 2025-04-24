#!/sh

isReg=$(podman container ls -a | grep registry | awk 'NR==1 {print $13}')
ociKernelImage="localhost:5000/linux_build:latest"

# before:
# localhost:5000/kernel-bzimage-6.6.22:latest

getbzImage() {
    # repository name (kernel-bzimage-6.6.22) must be lowercase
    docker compose -f ./compose.yml --progress=plain build kernel
    docker push "$ociKernelImage"
    docker run -it --name kernel -d "$ociKernelImage"
    docker cp kernel:/app/artifacts/bzimage ./artifacts/bzimage_0.3.1
}


if [ "$isReg" = "registry" ]; then
    getbzImage

else
    docker run -d -p 5000:5000 --name registry registry:latest
    getbzImage

fi
