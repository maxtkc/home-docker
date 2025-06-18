# FROM nextcloud:26.0.3-fpm-alpine
FROM nextcloud:31.0.6-fpm

# Add face recognition
# https://github.com/matiasdelellis/facerecognition/wiki/Docker
# RUN apk add dlib bzip2-dev

RUN apt update && apt-get install ffmpeg exiftool imagemagick -y

RUN sed -i'' 's|.*<policy domain="coder".*"PDF".*|<policy domain="coder" rights="read \| write" pattern="PDF" />|g' /etc/ImageMagick-6/policy.xml
