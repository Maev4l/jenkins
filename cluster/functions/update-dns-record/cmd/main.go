package main

import (
	"context"
	"encoding/json"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	ec2types "github.com/aws/aws-sdk-go-v2/service/ec2/types"
	"github.com/aws/aws-sdk-go-v2/service/route53"
	r53types "github.com/aws/aws-sdk-go-v2/service/route53/types"
	log "github.com/sirupsen/logrus"
)

var region string = os.Getenv("REGION")
var hosted_zone_id string = os.Getenv("HOSTED_ZONE_ID")

type Instance struct {
	Id string `json:"instance-id"`
}

func handler(ctx context.Context, event events.CloudWatchEvent) {

	var instance Instance
	err := json.Unmarshal(event.Detail, &instance)
	if err != nil {
		log.Errorf("Failed to unmarshal details: %s", err.Error())
		return
	}

	config, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {

		log.Errorf("Fail create AWS SDK config: %s", err.Error())
		return
	}

	ec2client := ec2.NewFromConfig(config)

	dtoutput, err := ec2client.DescribeTags(ctx, &ec2.DescribeTagsInput{
		Filters: []ec2types.Filter{
			{
				Name: aws.String("resource-type"),
				Values: []string{
					string(ec2types.ResourceTypeInstance),
				},
			},
			{
				Name: aws.String("resource-id"),
				Values: []string{
					instance.Id,
				},
			},
		},
	})

	if err != nil {
		log.Errorf("Fail fetch tags for instance '%s': %s", instance.Id, err.Error())
		return
	}

	var dns string
	for _, tag := range dtoutput.Tags {
		if *tag.Key == "dns" {
			dns = strings.TrimSpace(*tag.Value)
			break
		}
	}

	if dns != "" {
		dioutput, err := ec2client.DescribeInstances(ctx, &ec2.DescribeInstancesInput{
			InstanceIds: []string{instance.Id},
		})

		if err != nil {
			log.Errorf("Failed to describe instance '%s': %s", instance.Id, err.Error())
			return
		}

		address := *dioutput.Reservations[0].Instances[0].PublicIpAddress

		r53client := route53.NewFromConfig(config)

		ttl := int64(300)
		_, err = r53client.ChangeResourceRecordSets(ctx, &route53.ChangeResourceRecordSetsInput{
			HostedZoneId: aws.String(hosted_zone_id),
			ChangeBatch: &r53types.ChangeBatch{
				Changes: []r53types.Change{
					{
						Action: r53types.ChangeActionUpsert,
						ResourceRecordSet: &r53types.ResourceRecordSet{
							Name: aws.String(dns),
							Type: r53types.RRTypeA,
							TTL:  &ttl,
							ResourceRecords: []r53types.ResourceRecord{
								{
									Value: aws.String(address),
								},
							},
						},
					},
				},
			},
		})

		if err != nil {
			log.Errorf("Failed to describe update Route53 record: %s", err.Error())
			return
		}

		log.Infof("DNS record '%s' successfully updated to: %s", dns, address)
	}
}

func main() {
	log.SetOutput(os.Stdout)
	lambda.Start(handler)
}
