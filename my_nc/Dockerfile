# FROM nextcloud:26.0.3-fpm-alpine
FROM nextcloud:31.0.8-fpm

# Add face recognition
# https://github.com/matiasdelellis/facerecognition/wiki/Docker
# RUN apk add dlib bzip2-dev

RUN apt update && apt-get install ffmpeg exiftool imagemagick -y

RUN find /etc /usr -name policy.xml -type f 2>/dev/null | xargs -I {} sed -i 's|rights="none" pattern="PDF"|rights="read | write" pattern="PDF"|g' {} || true
