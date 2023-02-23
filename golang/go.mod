module github.com/sequoiacapital-oss/cauthl/golang

go 1.18

replace golang.org/x/oauth2 => github.com/sequoiacapital-oss/oauth2-go v0.0.0-20220505132248-677c006d111c

require (
	cloud.google.com/go/iam v0.3.0
	golang.org/x/oauth2 v0.0.0-20220411215720-9780585627b5
	google.golang.org/api v0.79.0
	google.golang.org/genproto v0.0.0-20220505152158-f39f71e6c8f3
)

require (
	cloud.google.com/go/compute v1.6.1 // indirect
	github.com/golang/groupcache v0.0.0-20200121045136-8c9f03a8e57e // indirect
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/google/go-cmp v0.5.8 // indirect
	github.com/googleapis/gax-go/v2 v2.3.0 // indirect
	go.opencensus.io v0.23.0 // indirect
	golang.org/x/net v0.0.0-20220425223048-2871e0cb64e4 // indirect
	golang.org/x/sys v0.0.0-20220722155257-8c9f86f7a55f // indirect
	golang.org/x/text v0.3.8 // indirect
	google.golang.org/appengine v1.6.7 // indirect
	google.golang.org/grpc v1.46.0 // indirect
	google.golang.org/protobuf v1.28.0 // indirect
)
