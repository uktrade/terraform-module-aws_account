FROM gcr.io/sre-docker-registry/py-node:3.11

RUN apt-get update

RUN pip install checkov

# ENV POETRY_VIRTUALENVS_CREATE=false
# RUN poetry config installer.max-workers 10

WORKDIR /app

COPY . /app

# Run checkov checks on all folders individually
RUN checkov -d new-org-member
RUN checkov -d org-common
RUN checkov -d org-master
RUN checkov -d org-member
RUN checkov -d soc-integration
# RUN checkov -d org-member --skip-check CKV_AWS_144,CKV2_AWS_61,CKV_AWS_18,CKV_AWS_21,CKV2_AWS_34,CKV_AWS_145
