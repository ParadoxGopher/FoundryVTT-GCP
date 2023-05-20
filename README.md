# FoundryVTT-GCP
this repository should give you a hint on how to deploy foundry to GCP Cloud Run

> this is more like a snipped than a repository right now

## FAQ ?!
Q: what is the difference to `felddy/foundryvtt` docker image?\
A: your bucket needs to be populated with container_cache and there will be no download of data. Why this ? because I do not want to download over and over again :-D

Q: why the different entrypoint to `felddy/foundryvtt`?\
A: GCP Cloud Run does not offer mounting filesystems (yet?) so we have to wrap the original entrypoint to mount the cloud storage bucket the rest could be called like it was intended by `felddy/foundryvtt`

## cloud setup
set your account id
```sh
export PROJECT_ID=abc-123 #replace this with your project id
```

assuming you are going for the region `europe-west1` but feel free to change things up here
```sh
export REGION=europe-west1
export BUCKET_NAME=foundryvtt-data-$(echo $RANDOM | md5sum | head -c 10)
```
> bucket names need to be globally unique on cloud storage

### 1. prepare cloud storage bucket
```sh
gcloud storage buckets create gs://$BUCKET_NAME
```
the bucket has to be populated with a folder `container_cache` containing the foundryvtt zip that you can download from the froundry website for node.

### 2. prepare `Artifact Repository` (optional)
> if you don't want to build locally you can skip this and go to #4
```sh
gcloud artifacts repositories create foundry-app --repository-format=docker --mode=standard-repository
gcloud auth configure-docker $REGION-docker.pkg.dev
```

### 3. build the image locally (optional)
> if you don't want to build locally you can skip this
```sh
docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/foundry-app/foundry
docker push $REGION-docker.pkg.dev/$PROJECT_ID/foundry-app/foundry
```

### 4. create service-account for foundry
```sh
gcloud iam service-accounts create foundry-identity
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:fs-identity@$PROJECT_ID.iam.gserviceaccount.com" \
    --role "roles/storage.objectAdmin"
```

### 5. deploy to cloud run
if you build the image locally you want to replace the `--source .` with `--image=$REGION-docker.pkg.dev/$PROJECT_ID/foundry-app/foundry`
```sh
gcloud run deploy foundry-app --source . \
    --execution-environment gen2 \
    --allow-unauthenticated \
    --service-account foundry-identity \
    --update-env-vars BUCKET=$BUCKET_NAME \
    --port 30000
```
after deploying the first time you can ommit all config parameters if you do not want to change them.
```sh
gcloud run deploy foundry-app --source .
```
or for direct image deployment
```sh
gcloud run deploy foundry-app --image=$REGION-docker.pkg.dev/$PROJECT_ID/foundry-app/foundry
```

## local run

to run this image locally do not forget the `--privileged` flag that is required to use `gcsfuse`

```sh
docker run --privileged --rm -p 30000:30000 \
	-e BUCKET=foundry \
	-v ~/.config/gcloud/:/root/.config/gcloud \
	foundry
```
you need to mount your gcloud credentials so the local container has valid ones.
Assuming you have valid ones in your gcloud folder!

## thanks to

[FoundryVTT](https://foundryvtt.com) for making a great Pen&Paper tool (even though it is not easily put on cloud run ;-))\
[felddy/foundryvtt](https://github.com/felddy/foundryvtt-docker/) for making a great docker image for foundry (even though I butchered some of it :-D)