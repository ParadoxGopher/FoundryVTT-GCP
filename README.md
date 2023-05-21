# FoundryVTT-GCP
this repository should give you a hint on how to deploy foundry to GCP Cloud Run

> this is more like a snipped than a repository right now

## differences to felddy/foundryvtt docker image
- building gcsfuse for alpine image
- added env variable to skip download entirely (using the cached zip)
- deleting lock file on startup as the container never clears it (! could be dangerous if you have two instaces running in parallel !)

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

### 2. create service-account for foundry
```sh
gcloud iam service-accounts create foundry-identity
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:foundry-identity@$PROJECT_ID.iam.gserviceaccount.com" \
    --role "roles/storage.objectAdmin"
```

### 3. deploy to cloud run
you also need to provide a download url or username and password for downloading the foundry zip (details [here](https://github.com/felddy/foundryvtt-docker/#required-variable-combinations)).
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