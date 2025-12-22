import base64
import json

# Configuration
url = "k8s-harbor-harbor-e23646dd89-000fac67939de240.elb.us-east-1.amazonaws.com:80"
auth_b64 = "YWRtaW46SGFyYm9yMTIzNDU=" # admin:Harbor12345

# Create Docker Config JSON
docker_config = {
    "auths": {
        url: {
            "auth": auth_b64
        }
    }
}

# Serialize and Encode
json_str = json.dumps(docker_config)
b64_secret = base64.b64encode(json_str.encode("utf-8")).decode("utf-8")

# Write to file
yaml_content = f"""apiVersion: v1
kind: Secret
metadata:
  name: harbor-docker-config
  namespace: default
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {b64_secret}
"""

with open("tekton-setup/secret-docker-public-port.yaml", "w") as f:
    f.write(yaml_content)

print("Secret file created: tekton-setup/secret-docker-public-port.yaml")
