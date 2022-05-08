import boto3
import json
import random
import string
import os

def get_bucket_policy(client, bucket_name):
	result = client.get_bucket_policy(Bucket=f"{bucket_name}")
	result = json.loads(result['Policy'])
	return result

def update_bucket_policy(client, bucket_name, bucket_policy, value):
	bucket_policy['Statement'][1]['Condition']['StringNotLike'] = {'aws:Referer': f'{value}'}
	bucket_policy = json.dumps(bucket_policy)
	client.put_bucket_policy(Bucket=bucket_name, Policy=bucket_policy)
	print(bucket_policy)

def random_pass():
	length = 20
	chars = string.ascii_letters + string.digits + '!@#$%^&*'

	rnd = random.SystemRandom()
	password = ''.join(rnd.choice(chars) for i in range(length))
	return password

def get_cloudfront_headers(client, value):
	distro = client.get_distribution_config(Id='EUCQJDP2T02XF')
	distro['DistributionConfig']['Origins']['Items'][0]['CustomHeaders']['Items'] = [{'HeaderName': 'Referer', 'HeaderValue': f'{value}'}]
	distro['DistributionConfig']['Origins']['Items'][1]['CustomHeaders']['Items'] = [{'HeaderName': 'Referer', 'HeaderValue': f'{value}'}]
	return distro['DistributionConfig'], distro['ETag']





def lambda_handler(event, context):
	s3 = boto3.client('s3')
	bucket = os.environ['primary_bucket']
	backup_bucket = os.environ['backup_bucket']
	value = random_pass()
	policy = get_bucket_policy(s3, bucket)
	backup_policy = get_bucket_policy(s3, backup_bucket)
	update_bucket_policy(s3, bucket, policy, value)
	update_bucket_policy(s3, backup_bucket, backup_policy, value)

	cloudfront = boto3.client('cloudfront')
	updated_distro = get_cloudfront_headers(cloudfront, value)
	update_distro_request = updated_distro[0]
	etag = updated_distro[1]
    dist_id = cloudfront.list_distributions()
    dist_id = dist_id['DistributionList']['Items'][0]['Id']
	print(update_distro_request)
	cloudfront.update_distribution(DistributionConfig=update_distro_request, Id=dist_id, IfMatch=etag)