# Prerequisitos: (dados de alta con terraform)
Cuando se crean los volumenes manuales tenemos que crear las politicas y adjuntarlas al grupo de nodos.
Adjuntar las policy (dada de alta con terraform)
IAM / Roles / spot_group-eks-node-group-20241106215222494400000001
~~~ec2AttachVolume
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AttachVolume",
				"ec2:DescribeVolumes",
				"ec2:DescribeVolumeStatus",
				"ec2:CreateVolume",
				"ec2:DeleteVolume",
				"ec2:ModifyVolume",
				"ec2:DescribeInstances",
				"ec2:CreateTags"
			],
			"Resource": "*"
		}
	]
}
~~~

Atach Manual

EC2 / Volumes / vol-0a85e5169b4ee47a3
Dar click en Actions
Dar click en Attach volume

Seleccionar el Nodo EKS
Seleccionamos un tipo de montage y guardamos.(dada de alta con terraform)

aws ec2 describe-volumes --volume-ids vol-0a85e5169b4ee47a3
~~~
{
    "Volumes": [
        {
            "Iops": 3000,
            "VolumeType": "gp3",
            "MultiAttachEnabled": false,
            "Throughput": 125,
            "VolumeId": "vol-0a85e5169b4ee47a3",
            "Size": 10,
            "SnapshotId": "",
            "AvailabilityZone": "us-east-1a",
            "State": "in-use",
            "CreateTime": "2024-11-06T23:06:16.795000+00:00",
            "Attachments": [
                {
                    "DeleteOnTermination": false,
                    "VolumeId": "vol-0a85e5169b4ee47a3",
                    "InstanceId": "i-0adcf4946dd9fe53e",
                    "Device": "/dev/xvdbc",
                    "State": "attached",
                    "AttachTime": "2024-11-06T23:20:36+00:00"
                }
            ],
            "Encrypted": false
        }
    ]
}
~~~
# Resultados de los Ejercicos.
~~~sh
kubectl get pv
# Resulado
NAME     CAPACITY  ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM           STORAGECLASS
my-ebs-pv   10Gi       RWO            Retain       Bound    default/my-ebs-pvc   gp3 
~~~
~~~sh
kubectl get pvc
# Resulado
NAME         STATUS   VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS
my-ebs-pvc   Bound    my-ebs-pv   10Gi       RWO            gp3
~~~
~~~sh
kubectl get po
# Resulado
NAME                           READY   STATUS    RESTARTS   AGE
app-gallery-79fb85ddcc-k785s   1/1     Running   0          13m
~~~
~~~sh
kubectl get pods -n kube-system | grep ebs-csi
# Resulado
ebs-csi-controller-74dc988548-92fcq   6/6     Running   0          114m
ebs-csi-controller-74dc988548-lmlxl   6/6     Running   0          114m
ebs-csi-node-7kp4q                    3/3     Running   0          113m
ebs-csi-node-d9v4s                    3/3     Running   0          113m
~~~
~~~sh
kubectl logs -n kube-system ebs-csi-controller-74dc988548-92fcq
# Resulado
I1106 23:41:44.700421       1 controller.go:424] "ControllerPublishVolume: attached" volumeID="vol-0a85e5169b4ee47a3" nodeID="i-0adcf4946dd9fe53e" devicePath="/dev/xvdbc"
~~~

Storage Class
~~~sh
kubectl get po
# Resulado
NAME                           READY   STATUS    RESTARTS 
app-gallery-79fb85ddcc-hdrsv   1/1     Running   0 
~~~
~~~sh
kubectl logs -n kube-system ebs-csi-controller-74dc988548-92fcq
# Resulado
I1107 00:15:52.820432       1 controller.go:415] "ControllerPublishVolume: attaching" volumeID="vol-091676433c6e294c9" nodeID="i-0adcf4946dd9fe53e"
I1107 00:15:54.474824       1 cloud.go:1106] "Waiting for volume state" volumeID="vol-091676433c6e294c9" actual="attaching" desired="attached"
I1107 00:15:56.072274       1 controller.go:424] "ControllerPublishVolume: attached" volumeID="vol-091676433c6e294c9" nodeID="i-0adcf4946dd9fe53e" devicePath="/dev/xvdaa"
~~~

~~~sh
kubectl get sc
# Resulado
NAME   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE    
gp2    kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer
gp3    kubernetes.io/aws-ebs   Delete          Immediate  
~~~
~~~sh
kubectl get pvc
# Resulado
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
my-ebs-pvc   Bound    pvc-7d72e7c7-a0c1-47d4-8bd5-780c1a47275b   10Gi       RWO            gp3            <unset>                 4m12s
~~~
# Revisar no dejar volumenes en funcionamiento.
Eliminar los volumenes dinamicos