#!/bin/sh

buildakernel() {
    # run the registry
    if ! docker run -d -p 5000:5000 --name registry registry:latest; then
        echo "|> Error: it was not possible to run the registry. Exiting now..."
        return 1
    fi
    echo "|> ran the registry with success."

    # invoke compose to build the kernel target
    if ! docker compose -f ./compose.yml --progress=plain build kernel; then
        echo "|> Error: it was not possible to invoke compose to build the kernel target. Exiting now..."
        return 1
    fi
    echo "|> invoked compose to build the kernel target with success."

    # push the built image into the localhost:5000 registry
    if ! docker push localhost:5000/linux_build:latest; then
        echo "|> Error: it was not possible to push the built image into the localhost:5000 registry. Exiting now..."
        return 1
    fi
    echo "|> pushed the built image into the localhost:5000 registry with success."

    # retrieve kernel bzImage artifact from docker image
    if ! docker run -it --name kernel -d localhost:5000/linux_build:latest; then
        echo "|> Error: it was not possible to retrieve kernel bzImage artifact from docker image. Exiting now..."
        return 1
    fi
    echo "|> retrieved kernel bzImage artifact from docker image with success."

    # copy the kernel bzImage artifact into artifacts dir
    if ! docker cp kernel:/app/artifacts/bzImage ./artifacts/isogen/; then
        echo "|> Error: it was not possible to copy the kernel bzImage artifact into artifacts dir. Exiting now..."
        return 1
    fi
    echo "|> copied the kernel bzImage artifact into artifacts dir with success."

    # copy the kernel bzImage modules into the artifacts dir
    if ! docker cp kernel:/app/artifacts/ko_tarball.tar.gz ./artifacts/isogen/; then
        echo "|> Error: it was not possible to copy the kernel bzImage artifact into artifacts dir. Exiting now..."
        return 1
    fi
    echo "|> copied the kernel bzImage modules into the artifacts dir with success."
}
