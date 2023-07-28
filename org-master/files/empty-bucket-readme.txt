Do not delete this bucket if it's empty.
========================================
This bucket is used by VPC Flow log in all accounts for logs. Log files created
here notify the SQS queue, which is processed by a Logstash ECS task (in the
ELK account) which pushes the logs to Sentinel. The log file is then deleted.
If the bucket is empty (except for this file) it just means the ECS task is
currently up to date with all files to process.
